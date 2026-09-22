# Account response

`GET /v1/accounts/{account_number}/`, authenticated. One account holds many properties (one per address you have occupied), each holding electricity and gas meter points.

```json
{
  "number": "A-AAAA1111",
  "properties": [
    {
      "id": 1234567,
      "moved_in_at": "2020-11-30T00:00:00Z",
      "moved_out_at": null,
      "address_line_1": "10 Downing Street",
      "address_line_2": "",
      "address_line_3": "",
      "town": "LONDON",
      "county": "",
      "postcode": "W1 1AA",
      "electricity_meter_points": [
        {
          "mpan": "1000000000000",
          "profile_class": 1,
          "consumption_standard": 2560,
          "meters": [
            {
              "serial_number": "1111111111",
              "registers": [
                { "identifier": "1", "rate": "STANDARD", "is_settlement_register": true }
              ]
            },
            { "serial_number": "2222222222", "registers": [ ... ] }
          ],
          "agreements": [
            { "tariff_code": "E-1R-VAR-20-09-22-N", "valid_from": "2020-12-17T00:00:00Z", "valid_to": "2021-12-17T00:00:00Z" },
            { "tariff_code": "E-1R-VAR-22-11-01-N", "valid_from": "2023-04-01T00:00:00+01:00", "valid_to": null }
          ],
          "is_export": false
        }
      ],
      "gas_meter_points": [
        {
          "mprn": "1234567890",
          "consumption_standard": 3448,
          "meters": [ { "serial_number": "12345678901234" } ],
          "agreements": [
            { "tariff_code": "G-1R-VAR-22-11-01-N", "valid_from": "2023-04-01T00:00:00+01:00", "valid_to": null }
          ]
        }
      ]
    }
  ]
}
```

## Properties

Filter on `moved_out_at: null` for the address currently occupied. Historic properties stay in the response indefinitely, complete with their meter points — a costing that sums across all properties double-counts any period where an old and a new address overlap.

## Meters and serials

`meters[]` is the full history for that meter point, not the live meter. A meter swap leaves the old serial in the list forever, and the consumption endpoint answers for a decommissioned serial with an empty list rather than an error. Nothing in the payload marks which serial is current: identify it by querying each for a recent range and keeping the one that returns rows.

Gas meters carry no `registers` array; electricity meters do.

## Registers

`registers[]` describes how the meter splits its readings:

- One entry with `rate: "STANDARD"` — a single-rate meter, matching an `E-1R-` tariff code.
- Two entries, `DAY` and `NIGHT` — Economy 7, matching `E-2R-`. Both registers roll up into the same half-hourly consumption series; the day/night split lives in the tariff's separate rate endpoints, not in the consumption payload.

`is_settlement_register: true` marks the register used for industry settlement — the one that bills.

## Agreements

Each entry is a contiguous period on one tariff, ordered oldest first, with `valid_to: null` on the live one. Rules that catch costings out:

- **Boundaries are exact instants, not dates.** `valid_to` of one agreement equals `valid_from` of the next, and both flip offset across a clock change (`00:00:00Z` in winter, `00:00:00+01:00` in summer). Compare as offset-aware datetimes.
- **A range can span several agreements.** Any window longer than a fixed term crosses a boundary, and each side needs its own unit rate and standing charge. Match each half-hour to the agreement containing its `interval_start`.
- **Variable tariffs auto-extend**; fixed tariffs end and drop the account onto the variable tariff, appearing as a new agreement.

## Export meter points

An `is_export: true` electricity meter point is a separate MPAN with its own serials and its own agreements (an outgoing tariff). Its consumption endpoint reports exported energy under the `consumption` key — the same field name and the same units as import, with the opposite sign of meaning. Summing import and export MPANs together produces a meaningless number.

## Other fields

- `profile_class` — industry consumption profile; `1` is domestic unrestricted, `2` domestic Economy 7.
- `consumption_standard` — the estimated annual consumption (EAC) used for quotes, not a measurement. Never use it for billing.

## Meter point lookup without the account

`GET /v1/electricity-meter-points/{mpan}/` returns `{"gsp", "mpan", "profile_class"}`. It 404s on an unknown MPAN, which makes it the cheapest way to check an identifier before blaming a consumption query. `gsp` comes back as `_A`–`_P` and gives you the region letter that terminates every tariff code for that meter.
