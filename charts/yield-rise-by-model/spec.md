# This year's rise in the 10-year yield, by model

Status: built in R from the Fed Board's D'Amico, Kim, and Wei (DKW) estimates and the New York Fed's Adrian, Crump, and Moench (ACM) estimates, both through August 31, 2026 (fetched September 26, 2026). Original chart. Title is a draft for review.

## Question

What drove the 10-year yield's rise this year: higher expected short-term rates or a higher term premium? And how much does the answer depend on the model?

## Related work and debate

See `charts/yield-decomposition/spec.md` for the commentary and for the charts by Ernie Tedeschi and Moody's Analytics this follows. The chart doesn't maintain anyone's analysis, so there is no `reproduce.R`.

## Sources

| Data | Provider | Fetch | Series |
|---|---|---|---|
| DKW 10-year decomposition, daily | Fed Board staff, updated monthly | `fetch_frb_dkw()` | `nominal.yield.fitted.10`; expected rates = `exp.real.short.rate.10` + `exp.inflation.10`; term premium = `real.term.prem.10` + `inflation.risk.prem.10` |
| ACM 10-year decomposition, daily | New York Fed | `fetch_nyfed_acm()` | `ACMTermPremium.xls`, sheet "ACM Daily": `ACMY10`, `ACMRNY10` (expected rates), `ACMTP10` |

## Transformations

- The DKW model's four parts are combined into the two ACM has, so the panels compare like with like.
- Weekly averages (weeks starting Monday), then the change from the week of February 23, 2026, the low before this year's rise.
- Both models stop at DKW's last day, since DKW is updated monthly and ACM daily.
- Each model's parts sum to its own fitted zero-coupon yield, so the two yield lines differ slightly.

## Vintages

- `data/frb_dkw_nyfed_acm_10_year_<last date>.csv`: both models' daily yield, expected rates, and term premium from the base week, named by the last day used. Both models are re-estimated from time to time, which revises history.

## Findings, week of February 23 to August 31, 2026

| Change in | Fed Board (DKW) | New York Fed (ACM) |
|---|---|---|
| Fitted 10-year yield | +0.73 | +0.74 |
| Expected short-term rates | +0.46 | +0.59 |
| Term premium | +0.28 | +0.15 |

- Both models put most of this year's rise in expected rates. In ACM the term premium fell below its February level in June and came back in August; in DKW it rose through the year.
- In DKW, the expected-rate part splits into +0.30 expected real rates and +0.16 expected inflation.
- September isn't covered. ACM, which runs through September 24, shows expected rates rising further that month as markets priced in Fed rate increases.

## Known breaks and caveats

- The base week is fixed. A low as the starting point shows the rise at its largest.
- Decompositions are model estimates. They separate expectations from compensation but can't identify why either moved.

## Decision log

- 2026-09-26: Show both models side by side for this year's rise, because the term premium's share is where they differ. Paired with the context chart from 2021 above it.
- 2026-09-26: Title: "Higher expected interest rates drove most of this year's rise in the 10-year yield." True in both models; check on each refresh.
