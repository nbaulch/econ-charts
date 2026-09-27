# Effective tariff rate

Status: in development. Built in R from the Census trade store.

## Question

What rate are U.S. imports paying in tariffs, and how much of that rate reflects the current mix of products and source countries rather than the rates themselves?

## Related work

- Sydney Eck, Trang Hoang, Carter Mix, and Madeleine Ray, "Mind the Gap: Announced versus Implied Tariff Rates in Recent Trade Policy Episodes," FEDS Notes, April 8, 2026. https://www.federalreserve.gov/econres/notes/feds-notes/mind-the-gap-announced-versus-implied-tariff-rates-in-recent-trade-policy-episodes-20260408.html. Calls the collected rate the realized effective tariff rate: calculated duties over the customs value of general imports, by country and 10-digit product. Compares it with an announced rate at 2017 or 2024 import weights and splits the gap into composition and rate discrepancy. Reports, for December 2025, an announced rate of 14.7 percent, 12.37 points above 2024, and a gap of 5.43 points; for December 2018, an announced rate up 1.93 points from 2017 and a collected rate up 1.49. No data file.
- Penn Wharton Budget Model, "Effective Tariff Rates and Revenues," updated September 9, 2026. https://budgetmodel.wharton.upenn.edu/p/2026-09-09-effective-tariff-rates-and-revenues-updated-september-9-2026/. Customs duties as a percent of imports, from USITC DataWeb: 2.3 percent in January 2025, 6.7 percent in July 2026, and 22.8 percent on imports from China in July 2026.
- Yale Budget Lab, Tariff Rate Tracker. https://github.com/Budget-Lab-Yale/tariff-rate-tracker. Computes collected rates as `cal_dut_mo / con_val_mo` by 10-digit product, country, and month.

## Sources

| Data | Provider | Fetch | Fields |
|---|---|---|---|
| Imports by 10-digit product, country, and rate provision, monthly | Census Bureau, IMDB bulk files, via the trade store | `read_census_trade("imports", ...)` | `con_val` (customs value, imports for consumption), `gen_val` (customs value, general imports), `dut_val` (dutiable value), `cal_dut` (calculated duty) |

## Transformations

- Collected rate = calculated duty over the customs value of imports for consumption, summed over all products and countries.
- Rate at the base-year mix = the average of each product and country's collected rate that month, weighted by its imports for consumption in 2024. Products are 10-digit tariff codes. A product and country with no imports that month drops out, and the remaining weights are rescaled; `base_mix_coverage` in the CSV records the share of 2024 value still covered.
- Dutiable share = dutiable value over customs value, in the CSV only.

## Vintages

- The trade store holds the latest Census release of each month and re-pulls months Census revises, as it does each June. `data/census_imports_by_country_<last month>.csv` keeps monthly totals by country from the build.

## Reproduction status

To be filled in.

## Known breaks and caveats

- Calculated duty is the duty assessed when goods enter. It does not reflect later refunds, such as those after the Supreme Court's February 20, 2026 ruling on tariffs imposed under the International Emergency Economic Powers Act, or duties collected on goods withdrawn later from bonded warehouses.
- Tariff codes change each January. A product whose code changes after 2024 drops out of the base-year mix.

## Decision log

- 2026-09-27: Imports for consumption, not general imports, as the denominator, since duty is assessed on imports for consumption. The Federal Reserve Board note uses general imports; `reproduce.R` checks both.
