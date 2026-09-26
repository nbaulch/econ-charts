# The 10-year Treasury yield split by two term premium models

Status: built in R from the ACM and Kim-Wright estimates through September 18, 2026 (fetched September 26, 2026). Original chart. Title is a draft for review.

## Question

Did long-term yields rise over the past year because investors expect higher short-term rates, or because they demand more compensation for holding long bonds? And how much does the answer depend on the model?

## Related work and debate

The models' authors are credited on the chart: Tobias Adrian, Richard Crump, and Emanuel Moench (New York Fed), and Don Kim and Jonathan Wright (Fed Board). The chart doesn't maintain anyone's analysis, so there is no `reproduce.R`; the model outputs are used as published.

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
| ACM 10-year fitted yield, term premium, risk-neutral yield, daily | New York Fed | `fetch_nyfed_acm()` | `ACMTermPremium.xls`, sheet "ACM Daily": `ACMY10`, `ACMTP10`, `ACMRNY10` |
| Kim-Wright 10-year fitted yield and term premium, daily | Fed Board, from FRED | `tidyusmacro::getFRED()` | `THREEFY10`, `THREEFYTP10` |
| 10-year Treasury yield, constant maturity | Fed Board H.15, from FRED | `tidyusmacro::getFRED()` | `DGS10` |
| Forecasters' average 3-month bill rate over the next 10 years, median | Philadelphia Fed, Survey of Professional Forecasters | `fetch_philfed_spf_median("BILL10")` | `median_bill10_level.xlsx` |

## Transformations

- Expected short-term rates = fitted yield minus term premium, for each model. For ACM this equals the published risk-neutral yield.
- Changes are from the latest date both models share to the same calendar date one and two years earlier, using the last observation on or before each date. Kim-Wright is posted on FRED about a week after ACM, so the latest shared date lags ACM.
- The bars for each model sum to the change in its fitted 10-year yield. The lead text quotes the market yield (`DGS10`) for the level.
- The survey is asked about the next 10 years only in first-quarter surveys, so it gives one reading a year. It is quoted in the notes to explain the models' disagreement, not plotted.

## Vintages

- `data/term_premium_models_<fetch date>.csv`: both models' daily fitted yield, expected short rates, and term premium since 1990. The models are re-estimated as data arrive, so past values can change between vintages; the git diff of the snapshot shows by how much.
- `data/philfed_spf_bill10_<fetch date>.csv`: the survey medians.

## Findings, September 18, 2026

| | ACM | Kim-Wright |
|---|---|---|
| Change in fitted yield, past year | +0.82 | +0.85 |
| of which expected short rates | +0.80 | +0.35 |
| of which term premium | +0.02 | +0.50 |
| Change in term premium, past two years | +0.83 | +0.87 |

- The market 10-year yield rose from 4.11 to 5.01 percent over the year. The 2-year rose more, to 4.76 percent on September 18, with markets pricing Fed hikes.
- The rise was all in real yields: the 10-year inflation-protected yield rose about 1 point while 10-year breakeven inflation was little changed. That is model-free and is the natural second chart for this page.
- Forecasters lowered their expected 10-year average bill rate from 3.2 to 3.0 percent between early 2025 and early 2026, while market yields rose. A model anchored to forecasters therefore puts the rise in the term premium; a model that reads expectations from the yield curve puts it in expected rates.

## Known breaks and caveats

- Both decompositions are model estimates, not observations. Other models (for example D'Amico, Kim, and Wei, which uses inflation-protected yields) give other splits.
- A decomposition separates expectations from compensation. It doesn't identify why either moved. Fiscal risk, Treasury supply, AI-related corporate borrowing, and foreign demand would all show up in the term premium together.
- Past-year numbers move a lot with the end date because yields are volatile. The chart is recomputed on each build.

## Decision log

- 2026-09-26: Start the interest rates topic with this chart, since the disagreement between the models is the source of the confident but conflicting claims.
- 2026-09-26: Stacked bars of the change over one and two years, one bar per model. The two-year panel shows where the models agree.
- 2026-09-26: Title: "Two Fed models disagree on why long-term yields rose this year."
