---
name: octopus-energy-api
description: Octopus Energy API (api.octopus.energy), REST and GraphQL. Use when fetching half-hourly consumption or manual meter readings for an electricity or gas meter, resolving an account number to MPAN/MPRN and meter serials, or pricing usage against Agile, Go, or a fixed tariff.
---

# Octopus Energy API

Two surfaces. **REST** — base URL `https://api.octopus.energy/v1/`, HTTPS only — carries consumption, tariffs, and products, and is what this file documents. **GraphQL** carries meter readings and account metadata REST has no endpoint for: [`references/graphql.md`](references/graphql.md).

On REST, every meter series — consumption and Agile prices alike — is a list of **half-hours**, and most of the work is getting those half-hours stamped correctly.

REST is also **silent**. Bad input rarely 4xx's: an oversized `page_size` is clamped, a timezone-less datetime is reinterpreted, a meter with no data returns `200` with an empty list. Treat a clean `200` as evidence of nothing until the payload says otherwise.

The live OpenAPI spec is `https://api.octopus.energy/v1/schema/` (YAML) — the authority when this file and reality disagree.

## Auth

Personal API key from the [dashboard](https://octopus.energy/dashboard/new/accounts/personal-details/api-access). Two equivalent forms:

```bash
curl -u "$OCTOPUS_API_KEY:" "$URL"                         # key as basic-auth username
curl -H "Authorization: Token $OCTOPUS_API_KEY" "$URL"     # note the "Token " prefix
```

The trailing `:` in `-u` is load-bearing — omit it and curl blocks on a password prompt.

Products and prices are public. Account and consumption need the key; a bad key is `401`, a key scoped to someone else's account is `403`.

Credentials live in `.env` (`OCTOPUS_API_KEY`, plus the meter identifiers). Load with `set -a && . ./.env && set +a`.

## Start at the account

The account number (on any bill, format `A-AAAA1111`) is the root of everything else — it yields each MPAN/MPRN, the meter serials that the consumption endpoints require, and the tariff agreements that price them.

```bash
curl -u "$OCTOPUS_API_KEY:" "https://api.octopus.energy/v1/accounts/A-AAAA1111/"
```

The identifiers you need sit at:

```
properties[].electricity_meter_points[].mpan
properties[].electricity_meter_points[].meters[].serial_number
properties[].electricity_meter_points[].agreements[].tariff_code
properties[].gas_meter_points[].mprn
properties[].gas_meter_points[].meters[].serial_number
```

One MPAN routinely lists **several serials** — meters replaced over the years, with nothing marking which is live.

Full response shape, export meters, Economy 7 registers, and how agreements extend: [`references/account.md`](references/account.md).

## Consumption

```
GET /v1/electricity-meter-points/{mpan}/meters/{serial_number}/consumption/
GET /v1/gas-meter-points/{mprn}/meters/{serial_number}/consumption/
```

| Param | Behaviour |
|---|---|
| `period_from` | ISO 8601, **inclusive**. Valid on its own. |
| `period_to` | ISO 8601, **exclusive**. Ignored unless `period_from` is also given. |
| `page_size` | Default 100, max 25000 (a year of half-hours). Over the max is silently clamped. |
| `order_by` | `-period` (default, newest first) or `period` (oldest first). |
| `group_by` | `hour`, `day`, `week`, `month`, `quarter`. Omit for half-hours. |
| `page` | 1-indexed; prefer a large `page_size` over paging. |

```json
{
  "count": 17520,
  "next": "https://api.octopus.energy/v1/electricity-meter-points/.../consumption/?page=2",
  "previous": null,
  "results": [
    { "consumption": 0.063, "interval_start": "2018-05-19T00:30:00+0100", "interval_end": "2018-05-19T01:00:00+0100" }
  ]
}
```

`consumption` is kWh for electricity. For gas it depends on the meter generation: **SMETS1 reports kWh, SMETS2 reports m³** — the payload does not say which. Read the meter type off the bill, or infer it from magnitude, since the kWh figure runs about 11× the m³ one for the same gas. Convert with `m³ × 1.02264 × calorific_value ÷ 3.6`, where the calorific value (≈39.5 MJ/m³) is printed on the bill and varies by region and period.

An **export** MPAN reports under the same `consumption` key; the number is energy exported, not drawn.

### Diagnosing an empty result

`{"count": 0, "next": null, "previous": null, "results": []}` at `200` is the single answer to several different questions — a non-smart meter (half-hourly data only exists for smart meters), a decommissioned serial, an MPAN/serial mismatch, and a range genuinely without data all look identical. Separate them:

1. Drop `period_from`/`period_to` and request `?page_size=1`. Data anywhere in the meter's history rules out the range being wrong.
2. Confirm the MPAN resolves: `GET /v1/electricity-meter-points/{mpan}/` returns `{"gsp", "mpan", "profile_class"}`. A wrong MPAN 404s here.
3. Try every `serial_number` the account lists for that meter point.
4. Still empty across all serials with no range filter — the meter is not sending half-hourly data, which no parameter fixes.

**Half-hourly consumption exists only for smart meters.** A non-smart meter has none, and REST offers nothing else — but the meter still has readings, taken by hand or estimated, and those are reachable over GraphQL: [`references/graphql.md`](references/graphql.md). Readings are cumulative indices rather than amounts used, so consumption there is the delta between them.

### Clock changes

The UK clock change is where this API bites, and it bites silently.

- **Always append `Z`** to `period_from`/`period_to`. A datetime with no offset is read as `Europe/London`, which shifts your window by an hour for half the year.
- **`interval_start` changes offset mid-response**, from `...Z` to `...+01:00` at the spring transition. Parse as offset-aware datetimes; string-slicing or assuming a fixed suffix corrupts exactly the rows around the transition.
- **`group_by` buckets on local midnight**, not UTC. The spring change day holds 23 hours and the autumn day 25 — a daily series that assumes 48 half-hours per bucket is wrong twice a year.

### Rounding

Consumption is reported to 0.001 kWh. Billing first rounds each figure to 0.01 kWh using **half-to-even**, then multiplies by the price — so 0.015 → 0.02 and 0.025 → 0.02. Reproducing a bill means matching that: Python's `decimal` with `ROUND_HALF_EVEN` (or bare `round()`) does; JavaScript's `toFixed` rounds half away from zero and drifts from the bill over thousands of rows.

## Recipes

A full year of half-hours in one request, oldest first:

```bash
curl -sG -u "$OCTOPUS_API_KEY:" \
  "https://api.octopus.energy/v1/electricity-meter-points/$MPAN/meters/$SERIAL/consumption/" \
  -d "period_from=2025-01-01T00:00:00Z" \
  -d "period_to=2026-01-01T00:00:00Z" \
  -d "page_size=25000" \
  -d "order_by=period"
```

Daily totals for a month:

```bash
curl -sG -u "$OCTOPUS_API_KEY:" \
  "https://api.octopus.energy/v1/gas-meter-points/$MPRN/meters/$SERIAL/consumption/" \
  -d "period_from=2026-07-01T00:00:00Z" -d "period_to=2026-08-01T00:00:00Z" \
  -d "group_by=day" -d "order_by=period"
```

Follow `next` when a response is paginated:

```bash
url="https://api.octopus.energy/v1/.../consumption/?page_size=25000"
while [ -n "$url" ] && [ "$url" != "null" ]; do
  body=$(curl -s -u "$OCTOPUS_API_KEY:" "$url")
  echo "$body" | jq -c '.results[]'
  url=$(echo "$body" | jq -r '.next')
done
```

## Pricing consumption

Turning kWh into pounds needs the tariff behind each half-hour: decode the `tariff_code` from the account's agreements, fetch that tariff's unit rates and standing charge, and match rate periods to consumption periods.

The two series do not line up row for row: for an identical range the consumption endpoint returns every half-hour **overlapping** it, while the price endpoints return only periods **contained** by it. Join on `interval_start` against each rate's validity window; zipping the two lists by position silently misaligns them.

Tariff code anatomy, product discovery, the rate endpoints, VAT, and the Agile/Go/Economy 7 differences: [`references/tariffs.md`](references/tariffs.md).

The bar for a costing that reconciles with a bill: **every half-hour matched to the rate valid at its own `interval_start`, and one standing charge counted per local day in the range** — including the days at either end that the range only partly covers.

## Operational notes

- No rate-limit headers are published and no quota is documented. A single 25000-row request still beats the 250 paged ones it replaces.
- Every response carries `x-kraken-correlation-id`. Capture it — Octopus support asks for it when a payload looks wrong.
- `/v1/products/` ignores `page_size` and returns the full list (~39 products) in one response.
- When REST has no endpoint for something — meter readings, gas meter units, resolving an account number from a bare API key — check GraphQL before concluding the data is unavailable.
