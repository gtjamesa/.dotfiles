# Tariffs and prices

Everything here is public — no API key needed. The account's `agreements[].tariff_code` is the only authenticated input, and it encodes the rest.

## Decoding a tariff code

```
E-1R-VAR-22-11-01-N
│ │  │            └── GSP region letter (A–P, no I or O)
│ │  └─────────────── product code
│ └────────────────── register count
└──────────────────── fuel
```

| Segment | Values |
|---|---|
| Fuel | `E` electricity, `G` gas |
| Registers | `1R` single rate, `2R` dual rate (Economy 7). Only these two appear in practice — four-rate EV tariffs still carry `E-1R-`. |
| Product code | Everything between the second and last hyphen — `VAR-22-11-01`, `AGILE-24-10-01`, `GO-VAR-22-10-14` |
| Region | The trailing letter, matching the meter point's `gsp` minus its underscore |

Splitting on `-` breaks: product codes contain hyphens. Take the fuel and register from the first two segments and the region from the last, and rejoin what remains as the product code.

## Rate endpoints

```
GET /v1/products/{product_code}/electricity-tariffs/{tariff_code}/standard-unit-rates/
GET /v1/products/{product_code}/electricity-tariffs/{tariff_code}/standing-charges/
GET /v1/products/{product_code}/electricity-tariffs/{tariff_code}/day-unit-rates/
GET /v1/products/{product_code}/electricity-tariffs/{tariff_code}/night-unit-rates/
GET /v1/products/{product_code}/electricity-tariffs/{tariff_code}/ev-device-peak-unit-rates/
GET /v1/products/{product_code}/electricity-tariffs/{tariff_code}/ev-device-off-peak-unit-rates/
GET /v1/products/{product_code}/gas-tariffs/{tariff_code}/standing-charges/
GET /v1/products/{product_code}/gas-tariffs/{tariff_code}/standard-unit-rates/
```

A tariff answers on only some of these, by type — see *Rate shape per tariff type* below before choosing one.

Params: `period_from` (inclusive), `period_to` (exclusive), `page`, `page_size` (default 100, **max 1500**, silently clamped above that). No `order_by` and no `group_by` here — results always come newest first, so reverse them yourself.

```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    { "value_exc_vat": 23.4, "value_inc_vat": 24.57, "valid_from": "2023-03-26T01:00:00Z", "valid_to": "2023-03-26T01:30:00Z", "payment_method": null }
  ]
}
```

- Values are **pence** — per kWh for unit rates, per day for standing charges.
- `value_inc_vat` carries domestic VAT at 5%.
- `valid_to: null` means the rate is still live.
- **Prices stay in UTC throughout**, including across a clock change — unlike the consumption endpoint, whose offsets shift mid-response. Anything joining the two must normalise before comparing.
- Omitting `period_from`/`period_to` returns the price *history* rather than the current price.

### payment_method

`null` on tariffs with one price. On tariffs that price by payment method, the same period appears **twice** — once as `DIRECT_DEBIT` and once as `NON_DIRECT_DEBIT`. Filtering to the account's method is not optional; keeping both double-counts every unit.

## Rate shape per tariff type

| Tariff | Where the rates live, and their shape |
|---|---|
| Agile (`AGILE-*`) | `standard-unit-rates`, one record per half-hour, published for the next day in the late afternoon. A month is ~1440 records, just under the 1500 page ceiling. |
| Go (`GO-*`) | `standard-unit-rates`, sparse — one record per contiguous run at a price, so an off-peak window is a single row spanning several hours. |
| Fixed / variable (`VAR-*`, `FIX-*`) | `standard-unit-rates`, one record per price change, often unchanged for months. |
| Economy 7 (`E-2R-*`) | `day-unit-rates` and `night-unit-rates`. `standard-unit-rates` **400s** here — `{"detail": "This tariff has day and night rates, not standard."}` |
| Intelligent Octopus Go (`IOG-*`) | `ev-device-peak-unit-rates` and `ev-device-off-peak-unit-rates`, despite the `E-1R-` code. `standard-unit-rates` returns an empty list at `200` — silent, unlike the Economy 7 case. |
| Export (`OUTGOING-*`, `*-EXPORT-*`, `*SEG*`) | `standard-unit-rates`, with a standing charge of `0`. These price an export MPAN's "consumption". |

A tariff that returns an empty rate list is usually the wrong endpoint for its type, not a tariff without prices. Check the table before concluding there is no data.

Sparse rates are why matching must be **interval containment, not equality**: find the record whose `[valid_from, valid_to)` contains each half-hour's `interval_start`. Joining on equal timestamps silently drops every half-hour of a Go or fixed tariff.

## Product discovery

```
GET /v1/products/                    # ~39 active products; ignores page_size, returns all
GET /v1/products/{product_code}/     # every tariff for that product, by region and payment method
```

Filters on the list endpoint: `brand=OCTOPUS_ENERGY`, `is_variable`, `is_business`, `is_green`, `is_prepay`, `available_at=2019-01-01T00:00Z`. On the detail endpoint, `tariffs_active_at=2019-01-01T00:00Z` returns rates as of a past date.

Product codes are dated and superseded regularly (`AGILE-FLEX-22-11-25` → `AGILE-24-10-01` → …). Resolve the current one from `/v1/products/` rather than hard-coding it; hard-coded codes keep returning `200` with stale prices long after they stop being the live tariff.

The detail response nests tariffs as `single_register_electricity_tariffs → {region} → {payment_method} → {code, standing_charge_exc_vat, standing_charge_inc_vat, links[]}`, alongside `dual_register_electricity_tariffs`, `four_rate_ev_electricity_tariffs`, and `single_register_gas_tariffs`. The `{payment_method}` key varies by product — `varying`, `direct_debit_monthly`, and others — so read it rather than assuming a name. Each entry's `links[]` gives the `standing_charges` and `standard_unit_rates` URLs directly — follow them instead of assembling paths by hand.

## Costing a range

1. From the account, take every agreement overlapping the range; a long range crosses tariff boundaries and each side prices separately.
2. For each agreement, fetch unit rates and standing charges over its slice of the range, filtered to the account's `payment_method`.
3. Fetch consumption for the same slice with `order_by=period`.
4. Round each half-hour's kWh to 0.01 **half-to-even**, then multiply by the rate whose validity window contains its `interval_start`.
5. Add one standing charge per **local** day in the range, partial days at either end included.
6. Sum in pence and convert once at the end — converting per row accumulates float error across ~17500 rows a year.

Reconcile against a real bill before trusting the number. A mismatch usually traces to VAT (`exc` vs `inc`), a duplicated `payment_method`, a missing standing charge day, or rounding at the wrong step.

## Agile prices from wholesale

To derive VAT-exclusive Agile prices from wholesale: divide the wholesale price by 10 (converting $/MWh to p/kWh), multiply by the region multiplier, and add the peak adder for periods between 16:00 and 19:00.

| Region | A | B | C | D | E | F | G | H | J | K | L | M | N | P |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Multiplier | 2.1 | 2.0 | 2.0 | 2.2 | 2.1 | 2.1 | 2.1 | 2.1 | 2.2 | 2.2 | 2.3 | 2.2 | 2.1 | 2.4 |
| Peak adder | 13 | 14 | 12 | 13 | 12 | 12 | 12 | 12 | 12 | 12 | 11 | 13 | 13 | 12 |

To convert a region C price to another region: subtract 12 if peak, divide by 2, multiply by the new region's multiplier, then add its peak adder if peak.
