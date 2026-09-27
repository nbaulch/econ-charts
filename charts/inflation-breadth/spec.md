# Breadth of price increases

Status: built in R from BEA's monthly NIPA files (fetched September 27, 2026, through July 2026) and the Dallas Fed's list of trimmed-mean categories. `reproduce.R` checks Warsh's numbers. Title is a draft for review.

## Question

Are price increases concentrated in a few categories, or spread across most of the consumer basket?

## Related work

- Kevin Warsh, Jackson Hole keynote, August 28, 2026. https://www.federalreserve.gov/newsevents/speech/warsh20260828a.htm. Reports that 54 percent of PCE categories had prices up more than 3 percent over the 12 months to July, against a 2000 to 2019 average of 32 percent and a 2022 peak of 77, and 49 percent over six months at an annual rate. No written method beyond that.

## Sources

| Data | Provider | Fetch | Series |
|---|---|---|---|
| Prices by category | BEA, NIPA table 2.4.4U, monthly flat file | `fetch_bea_nipa_tables("U20404")` | Lines 1 to 369, matched to the Dallas Fed's categories by name |
| Category list | Dallas Fed, trimmed mean PCE detail | `fetch_dallasfed_trimmed_mean_components()` | 177 categories, by BEA name |

## Transformations

- Categories are the 177 the Dallas Fed uses for its trimmed mean: the most detailed PCE categories BEA publishes. They are matched to table 2.4.4U by name, after dropping BEA's footnote numbers, such as "Electricity (27)", and punctuation. All 177 match. Three nonprofit categories appear twice in the table; the lowest line number is the category itself.
- 12-month change = price index over its value 12 months earlier. Six-month change, annualized = (index over its value six months earlier) squared, minus one.
- Share = the percent of categories whose change is above 3 percent. Each category counts equally.

## Vintages

- `data/bea_pce_prices_<last month>.csv`: price indexes for the 177 categories since 1999, one column per BEA series code. `data/dallasfed_components_<last month>.csv`: the Dallas Fed list, with that month's weights and trims. Neither download carries a release date, so each is named by the last month it covers.
- BEA's annual update, due with the next PCE release, revises category detail. Rerun and report how much the share moves.

## Reproduction status, July 2026

| Check | Warsh | Ours |
|---|---|---|
| Share above 3 percent, 12 months | 54 | 54.2 |
| Same, 2000 to 2019 average | 32 | 31.9 |
| Same, 2022 peak | 77 | 77.4 |
| Share above 3 percent, 6 months annualized | 49 | 50.8 |

The 12-month figures match. The six-month figure is about 2 points higher, perhaps from a different annualization or seasonal adjustment of short changes; the chart doesn't show it.

Weighting categories by their spending share doesn't match Warsh: it gives 63 percent in July 2026 and 34 percent on average from 2000 to 2019. His measure counts categories equally.

## Findings, July 2026

- 54 percent of categories are up more than 3 percent over 12 months, up from 36 percent in January 2025, the low since 2024.
- That is above every month from 2000 to 2020; the high before 2021 was 53 percent in 2008. The 2004 to 2007 range was 33 to 51 percent.
- Similar breadth in 2004 to 2007 came with core PCE inflation averaging 2.2 percent, against 3.3 percent now, so breadth alone doesn't pin down the level of inflation. Not in the text, since the chart doesn't show core inflation.

## Known breaks and caveats

- The 3 percent threshold is Warsh's. The share is sensitive to it: many categories cluster near 2 to 4 percent.
- Equal weights give small categories, such as specific food items, the same say as rent.
- The Dallas Fed list is current; categories BEA added or dropped over time may make early years slightly different from what the Dallas Fed used then.

## Decision log

- 2026-09-27: Reproduces Warsh with the Dallas Fed's 177 categories, unweighted. The six-month line was dropped from the chart: it is noisier and doesn't change the story.
- 2026-09-27: Title: "More than half of prices are rising faster than 3 percent, more than at any time before 2021." Check on each refresh that the share is above 50 percent and above the pre-2021 high of 53.
