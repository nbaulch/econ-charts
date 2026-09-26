# Contributions to U.S. labor productivity growth

Status: draft. Sources and identities confirmed against the September 3, 2026 release of the Fernald data. Not yet reproduced in R.

## Question

Is the recent acceleration in U.S. labor productivity coming from technology and efficiency (utilization-adjusted TFP), or from firms running existing capital and labor harder (utilization)?

## Original analysis

Ernie Tedeschi, "AI and Productivity," Stripe Economics, July 23, 2026.
https://www.stripeeconomics.com/p/ai-and-productivity

Published chart: "Contributions to US labor productivity growth," subtitle "Percentage points, four-quarter annualized average," 2022 Q1 to 2026 Q1. Stacked bars with three components: labor and capital deepening, utilization-adjusted TFP, and utilization. Chart note: "Contributions sum to four-quarter US business sector productivity growth." Sources: BLS, Federal Reserve Bank of San Francisco, Stripe analysis.

Related work to credit:
- John Fernald, the quarterly utilization-adjusted TFP series, maintained by the San Francisco Fed.
- Boyle, Fernald, and Li (2026), "Higher utilisation explains recent surge in productivity growth," VoxEU. https://cepr.org/voxeu/columns/higher-utilisation-explains-recent-surge-productivity-growth

Approximate readings from the published chart, in percentage points:

| Quarter | Deepening | Utilization-adjusted TFP | Utilization |
|---------|-----------|--------------------------|-------------|
| 2022 Q1 | -1.4 | 0.9 | -0.1 |
| 2023 Q4 | 1.55 | 2.65 | -0.95 |
| 2025 Q4 | 1.25 | 0.3 | 1.05 |
| 2026 Q1 | 1.0 | 0.1 | 1.4 |

## Source

| Data | Provider | Fetch | Identifier |
|------|----------|-------|------------|
| Quarterly TFP and its components, U.S. business sector | San Francisco Fed (Fernald) | `fetch_sffed_tfp()` | `quarterly_tfp.xlsx`, sheet "quarterly" |

Data URL: https://www.frbsf.org/wp-content/uploads/quarterly_tfp.xlsx

Columns used: `dLP`, `dk`, `dhours`, `dLQ`, `alpha`, `dtfp`, `dutil`, `dtfp_util`. All are quarterly log changes at an annual rate (400 times the log difference).

`dLP` is output growth minus hours growth, where output averages the expenditure and income sides. The BLS productivity release uses the expenditure side only, so `dLP` will not match the BLS headline exactly.

## Transformations

1. Components, each quarter. These identities hold exactly in the data:
   - Capital deepening: `alpha * (dk - dhours)`
   - Labor composition: `(1 - alpha) * dLQ`
   - Utilization: `dutil`
   - Utilization-adjusted TFP: `dtfp_util`
   - The four sum to `dLP`.
2. Tedeschi combines capital deepening and labor composition into one "labor and capital deepening" bar.
3. Four-quarter trailing mean of each component. This matches "four-quarter annualized average" and keeps the sum equal to the four-quarter mean of `dLP`.

## Vintages

Fernald does not publish past vintages. Each fetch should save a dated snapshot, because revisions are large relative to the components.

- The September 3, 2026 release changed the labor composition series. The `labor composition` sheet has both versions: `dLC_current` and `dLC_through_2026.08`. Tedeschi's July chart used the earlier one.
- The change shifts capital-plus-labor deepening by up to 0.9 percentage points in some quarters. Example: 2023 Q1 is 0.60 under the current series and 1.48 under the earlier one. TFP absorbs the difference.

## Reproduction status

The current release does not reproduce the published chart exactly, which is expected given the revisions above.

- Using the earlier labor composition series, the 2023 Q4 bars match the readings to within 0.05 point and 2022 Q1 to within about 0.15.
- 2025 Q4 is within about 0.1 point. 2026 Q1 differs by 0.2 points on TFP and utilization: 0.31 and 1.30 against about 0.1 and 1.4. That is most likely routine revision between the July and September releases.

The July vintage is not public. The fix is to ask Fernald's team for the release Tedeschi used, or to accept the match as close enough.

## Known breaks and caveats

- Utilization is not observed. It is inferred from hours per worker, following Basu, Fernald, Fisher, and Kimball. The chart's argument depends on that method.
- Capital deepening is where AI investment in data centers and computers shows up. Folding it into one bar with labor composition hides that channel. The capital detail sheet splits capital input by asset type, including information processing equipment and software, so a separate AI-related capital bar is possible.

## Decision log

Record decisions here with a date and the reason.

- 2026-09-26: Chose this chart over the industry AI adoption scatter. The question is macro: is productivity growth coming from TFP or from utilization. The scatter answers a narrower cross-sectional question.
- 2026-09-26: Fernald release of 2026-09-03 inspected. Data run through 2026 Q2. Component identities verified.
