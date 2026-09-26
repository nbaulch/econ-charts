# The 10-year Treasury yield since 2021, split into expected rates and risk premiums

Status: built in R from the Fed Board's D'Amico, Kim, and Wei (DKW) estimates through August 31, 2026 (fetched September 26, 2026). Original chart in the style of decompositions by Ernie Tedeschi and Moody's Analytics. Title is a draft for review.

## Question

Why is the 10-year yield higher than before the Fed began raising rates, and how has the reason changed? This is the context chart; `charts/yield-rise-by-model/` covers this year's rise.

## Related work and debate

The model's authors are credited on the chart. The chart doesn't maintain anyone's analysis, so there is no `reproduce.R`; the model output is used as published.

Charts in the same style: Ernie Tedeschi, decomposition of the 30-year yield since December 31, 2025 from an ACM-type model with four parts (real policy rate, real term premium, expected inflation, inflation risk premium), on X, August 2026; Moody's Analytics (Mark Zandi), decomposition of the 10-year yield since the start of the Iran war, from Federal Reserve data, on X, July 2026.

Commentary, September 2026, for context:

- Anna Wong, Bloomberg Economics, on X, September 23, 2026: the ACM model says the rise is "all real yields/growth/ppl expect Fed to hike," the Kim-Wright model says "it is term premium," and Warsh and the FOMC picked the first reading.
- Kevin Warsh, Fed chair, press conference September 16, 2026: higher 10-year yields reflect economic strength, competition for capital, and geopolitics (as reported by CNBC).
- Matthew Klein, The Overshoot: "the Fed is starting to hike for the right reason: The economy has been running hot for years" (Fortune, September 25, 2026).
- Robin Brooks, Brookings: the U.S. convenience yield has disappeared as debt rises faster than elsewhere, and the 10-year rate 10 years forward is at a 20-year high.
- PIMCO, on AI debt: individual AI bond deals leave little statistically significant footprint on 10-year yields, term premia, or swap spreads.
- Why the models differ: Federal Reserve Board, "Robustness of Long-Maturity Term Premium Estimates," FEDS Notes, April 3, 2017. Most of the gap comes from Kim-Wright's use of survey forecasts of short rates; ACM with the same surveys gives similar estimates.

## Sources

| Data | Provider | Fetch | Series |
|---|---|---|---|
| 10-year yield decomposition, daily | Fed Board staff, DKW model, updated monthly | `fetch_frb_dkw()` | `DKW_updates.csv`: `nominal.yield.fitted.10`, `exp.real.short.rate.10`, `real.term.prem.10`, `exp.inflation.10`, `inflation.risk.prem.10` |

## Transformations

- The four parts sum to the fitted 10-year zero-coupon yield. The TIPS liquidity premium, also in the file, is part of inflation compensation measured from inflation-protected securities, not of the nominal yield, and is not used.
- Monthly averages of daily values, then the change from the December 2023 average, the last month before the term premium's rise. The text's rise since before the Fed began hiking uses the December 2021 average.
- Term premium in the text = real term premium plus inflation risk premium. Expected rates = expected real short-term rates plus expected inflation.
- The CSV has monthly levels since 1983 and changes since December 2023.

## Vintages

- `data/frb_dkw_10_year_<last date>.csv`: daily 10-year parts since 2015, named by the file's last observation, since it has no release date. The model is re-estimated from time to time (the current file uses data through November 12, 2025), which revises history; the git diff of the snapshot shows by how much.
- Updates come about the fourth business day of each month, so the chart runs through the end of the previous month.

## Findings, August 2026 (monthly averages)

| Change in | Since December 2023 | Past year |
|---|---|---|
| Fitted 10-year yield | +0.72 | +0.45 |
| Expected real short-term rates | -0.02 | +0.13 |
| Real term premium | +0.44 | +0.18 |
| Expected inflation | +0.18 | +0.09 |
| Inflation risk premium | +0.12 | +0.05 |

- Since December 2023 the term premium accounts for about three quarters of the rise. Expected real short-term rates fell through 2025 and have since come back to about where they started.
- Over the past year, expected rates and the term premium each added about 0.22 point.
- Other models split the past year differently. The New York Fed's ACM model puts nearly all of it in expected rates; Kim-Wright puts about 0.5 point in the term premium (September 18, 2026). Model-free, the 10-year inflation-protected yield rose about 1 point over the year while breakeven inflation was little changed, a smaller inflation share than DKW gives.

## Known breaks and caveats

- The decomposition is a model estimate, not an observation, and uses survey forecasts of inflation and bill rates.
- The fitted zero-coupon yield differs from the market 10-year note yield by a few basis points, and monthly averages differ from end-of-period values.
- A decomposition separates expectations from compensation. It doesn't identify why either moved. Fiscal risk, Treasury supply, AI-related corporate borrowing, and foreign demand would all show up in the term premium together.

## Decision log

- 2026-09-26: Start the interest rates topic with a term premium chart.
- 2026-09-26: Replace the two-model bar chart (ACM against Kim-Wright, change over one and two years) with a monthly decomposition of the change since December 2023 from DKW, following how Tedeschi and Moody's chart it. Time series of levels and of 12-month changes were tried and dropped as hard to read. DKW is the one public model that also splits real rates from inflation, which the storyline asks about.
- 2026-09-26: Title: "The 10-year yield's rise since 2023 has come mostly from the term premium." Check on each refresh that the term premium is still the largest part.
- 2026-09-26: Measure from December 2021 so the chart gives context back to the start of the hiking cycle, and add a second chart, `charts/yield-rise-by-model/`, for this year's rise with both models. Renamed from `charts/term-premium/`. Title: "The 10-year yield rose first on expected rates, then on the term premium." Change since December 2021 through August 2026: yield +3.25, expected real short-term rates +1.55, real term premium +0.81, expected inflation +0.74, inflation risk premium +0.14. The text says the term premium accounted for "most of the further rise" since 2023 (0.56 of 0.72); check on each refresh.
- 2026-09-26: Back to measuring from December 2023. From 2021, the hiking cycle's 2.5-point rise in expected rates set the scale and shrank the term premium, which the debate is about; the text gives the rise since 2021 in one sentence. Title: "The 10-year yield's rise since 2023 has come mostly from the term premium."
