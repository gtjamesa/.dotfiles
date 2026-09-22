# GraphQL API

Endpoint `https://api.octopus.energy/v1/graphql/`, POST with a JSON body. This is the API the Octopus dashboard itself runs on, and it reaches data the REST surface has no endpoint for.

Where REST is silent, GraphQL is **loud**: it validates arguments explicitly and answers with an `errors[]` array carrying a machine-readable code. The cost is that the failure never reaches the status line — see *Errors* below.

## REST or GraphQL

| Want | Use | Why |
|---|---|---|
| Half-hourly consumption from a **smart** meter | REST | Simpler, and the same data. |
| Meter **readings** from a non-smart meter | **GraphQL** | REST has no endpoint for them. |
| Tariff rates, standing charges, products | REST | Public, no token exchange. |
| The account number, given only an API key | **GraphQL** | `viewer` resolves it; REST makes you already know it. |
| Meter metadata — gas units, correction factor, install dates | **GraphQL** | Absent from the REST payload. |

## Auth

Two steps: exchange the REST API key for a Kraken JWT, then send that JWT.

```bash
TOKEN=$(curl -s -X POST https://api.octopus.energy/v1/graphql/ \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"mutation(\$k:String!){ obtainKrakenToken(input:{APIKey:\$k}){ token } }\",\"variables\":{\"k\":\"$OCTOPUS_API_KEY\"}}" \
  | jq -r .data.obtainKrakenToken.token)

curl -s -X POST https://api.octopus.energy/v1/graphql/ \
  -H "Content-Type: application/json" -H "Authorization: $TOKEN" \
  -d '{"query":"{ viewer { accounts { number } } }"}'
```

The JWT goes in `Authorization` **bare** — `Bearer <jwt>` also works. What fails is REST's `Token <key>` prefix, which is the natural habit to carry over: it returns `KT-CT-1143`, "Value of 'Authorization' header is not a valid credential". Reach for the bare form and the question never arises.

The token lasts **one hour** (`payload.exp` minus `payload.iat` is 3600). `obtainKrakenToken` also returns `refreshToken` and `refreshExpiresIn` — the latter is an **absolute Unix timestamp** about seven days out, not the duration its name suggests. For a script that runs for minutes, exchange a fresh token each run and skip refresh entirely.

`{ viewer { accounts { number } } }` turns a bare API key into an account number, which is the input every other query wants.

## Discovery by introspection

Introspection is enabled and the published GraphQL docs are thin, so the schema is the reference. Listing types finds the noun; listing a type's fields finds the path:

```bash
# find candidate types
'{ __schema { types { name kind } } }'

# then the workhorse — one type's fields, their args, and their return types
'{ __type(name:"ElectricityMeterType"){ fields { name args { name } type { name kind ofType { name } } } } }'
```

Root query fields worth knowing: `viewer` (no args), `account(accountNumber:)`, `accounts(phoneNumber:, portfolioNumber:)`.

## Meter readings

Readings hang off a meter, which hangs off a meter point, which hangs off a property:

```graphql
query($acc: String!, $after: String) {
  account(accountNumber: $acc) {
    properties {
      electricityMeterPoints {            # gasMeterPoints for gas
        mpan                              # mprn for gas
        meters(includeInactive: true) {
          serialNumber
          readings(first: 100, after: $after) {
            pageInfo { hasNextPage endCursor }
            edges { node {
              readAt readingSource readingType
              registers { identifier name value digits }
            } }
          }
        }
      }
    }
  }
}
```

- **`meters` defaults to active only.** Pass `includeInactive: true` or a meter exchange is invisible — you get the current meter's short history and no sign the older one existed.
- **`readings` is a plain Relay connection**: `first`, `after`, `before`, `last`, and nothing else. There is **no date filter**, so page the whole history and filter client-side.
- **`first` caps at 100**, and exceeding it is a hard error (`KT-CT-1202`), never a clamp. Page with `after: endCursor` until `hasNextPage` is false.

### Node fields

| Field | Notes |
|---|---|
| `readAt` | `DateTime`, offset-aware, rendered `+00:00` rather than `Z`. |
| `readingType` | Plain `String`, not an enum — `Customer reading`, `Estimated reading`, `Data collector reading`, `Field agent reading`, `Smart meter reading`. |
| `readingSource` | Plain `String` — `Your reading`, `Estimated reading`, `Change of supply reading`, `Data collector reading`. |
| `registers[].value` | A **string** decimal like `"12345.00000"` — parse before arithmetic. |
| `registers[].name` | `Standard` on a single-rate meter; `Day`/`Night` on Economy 7. |
| `registers[].identifier` | Present on electricity (e.g. `S`), `null` on gas. Key on `name` for portable code. |
| `registers[].digits` | The meter's dial count. This is the modulus a rollover wraps at. |
| `registers[].isQuarantined` | Flags a reading held back as suspect. |

Because both string fields are `String` and not enums, introspection cannot enumerate their values — collect them from the data you actually get back.

## Indices, not consumption

The single fact this branch turns on: **a reading is a cumulative meter index, not an amount used.** Consumption is the **delta** between consecutive indices, and a rate is that delta over the elapsed days. The REST file's half-hour has no counterpart here — intervals are irregular, weeks to months apart, set by whenever somebody read the meter.

Deriving a clean series from raw readings takes three rules:

1. **Drop estimates first.** `readingType == "Estimated reading"` rows interleave with real ones and are not monotonic against them; differencing a mixed list yields nonsense. Filtering to non-estimated rows leaves a clean, rising series.
2. **A negative delta is a series break, not negative usage.** It means a meter exchange or a dial rollover. Segment there and difference within each segment — never across the break. (A rollover specifically wraps at `10 ** digits`; an exchange restarts near zero with no fixed relationship to the old index.)
3. **Sort by `readAt` before differencing.** The connection returns newest-first.

The interval that spans a break is unrecoverable — the consumption is split across two indices with no way to apportion it. Show it as a gap rather than inventing a number.

### The consumption connection is not a shortcut

`ElectricityMeterType` and `GasMeterType` both expose `consumption(startAt:, grouping:, timezone:, first:)` returning `ConsumptionType { value startAt endAt }`, with `ConsumptionGroupings` of `QUARTER_HOUR`, `HALF_HOUR`, `HOUR`, `DAY`, `WEEK`, `MONTH`, `QUARTER`. It looks like server-side differencing of the readings above. It is not — it is the same smart-meter half-hourly data REST serves, and on a non-smart meter it returns **zero buckets**. Difference the indices yourself.

## Meter metadata

Gas readings are a volume whose unit the readings themselves never state. The meter record does:

```graphql
gasMeterPoints { meters(includeInactive: true) {
  serialNumber imperial units correction readingFactor mechanism modelName
} }
```

`imperial` is the one that decides the unit — `false` for m³, `true` for ft³. `correction` is the volume correction factor (typically `1.02264`) and `readingFactor` scales the dial reading. From m³, the kWh conversion and its calorific-value caveat are in [`../SKILL.md`](../SKILL.md#consumption); no calorific value appears anywhere in this schema, so it has to come off the bill.

## Errors

Failures arrive as **HTTP 200** with an `errors[]` array, so checking the status code detects nothing. Check `errors` on every response.

```json
{ "errors": [ {
  "message": "Invalid pagination parameters.",
  "extensions": {
    "errorType": "VALIDATION",
    "errorCode": "KT-CT-1202",
    "errorDescription": "Requested more records through the `first` value than the maximum limit.",
    "validationErrors": [ { "inputPath": ["input","first"], "message": "…exceeds the `first` limit of 100 records." } ]
  } } ] }
```

`extensions.errorCode` carries Kraken's `KT-CT-####` codes and `validationErrors[].inputPath` points at the offending argument. Codes seen in practice:

| Code | Meaning |
|---|---|
| `KT-CT-1112` | No `Authorization` header. |
| `KT-CT-1143` | Header present but not a valid credential — an expired token, or REST's `Token ` prefix. |
| `KT-CT-1202` | Pagination out of range, e.g. `first` above 100. |

One more, cheap to hit while templating queries: a declared-but-unreferenced variable is a hard error (`Variable '$x' is never used.`). Build the query string and its variables together.

## Working script

Stdlib only — token exchange, cursor pagination, and the index-to-delta rules:

```python
import json, os, urllib.request

ENDPOINT = "https://api.octopus.energy/v1/graphql/"

def gql(query, variables=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = token
    req = urllib.request.Request(
        ENDPOINT, data=json.dumps({"query": query, "variables": variables or {}}).encode(), headers=headers)
    with urllib.request.urlopen(req) as resp:
        payload = json.load(resp)
    if payload.get("errors"):                      # HTTP 200 hides these
        raise SystemExit(json.dumps(payload["errors"], indent=2))
    return payload["data"]

READINGS = """
query($acc: String!, $after: String) {
  account(accountNumber: $acc) { properties { %s {
    meters(includeInactive: true) { serialNumber
      readings(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        edges { node { readAt readingType registers { name value } } } } } } } }
}"""

def readings(token, account, collection):
    rows, after = [], None
    while True:
        points = gql(READINGS % collection, {"acc": account, "after": after}, token)["account"]["properties"][0][collection]
        conn = points[0]["meters"][0]["readings"]
        rows += [{"readAt": e["node"]["readAt"], "type": e["node"]["readingType"],
                  "value": float(e["node"]["registers"][0]["value"])} for e in conn["edges"]]
        if not conn["pageInfo"]["hasNextPage"]:
            return sorted(rows, key=lambda r: r["readAt"])
        after = conn["pageInfo"]["endCursor"]

def intervals(rows):
    """Consecutive non-estimated readings -> consumption per day, split at series breaks."""
    actual, out, prev = [r for r in rows if r["type"] != "Estimated reading"], [], None
    for r in actual:
        if prev:
            delta, days = r["value"] - prev["value"], (parse(r["readAt"]) - parse(prev["readAt"])).days
            if delta < 0:
                out.append({"break": True, "at": r["readAt"]})   # exchange or rollover
            elif days:
                out.append({"from": prev["readAt"], "to": r["readAt"], "used": delta, "perDay": delta / days})
        prev = r
    return out

token = gql("mutation($k:String!){ obtainKrakenToken(input:{APIKey:$k}){ token } }",
            {"k": os.environ["OCTOPUS_API_KEY"]})["obtainKrakenToken"]["token"]
account = gql("{ viewer { accounts { number } } }", token=token)["viewer"]["accounts"][0]["number"]
elec = readings(token, account, "electricityMeterPoints")
gas  = readings(token, account, "gasMeterPoints")
```

`parse` is `datetime.datetime.fromisoformat`, which handles the `+00:00` offset directly.
