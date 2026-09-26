# AI-related investment's contribution to GDP growth

Status: built in R from BEA data fetched on 2026-09-26, through 2026 Q2. Reproduces the published figure exactly. Title is a draft for review.

## Question

How much is AI-related investment adding to real GDP growth once imported computers are netted out?

## Original analysis

Paul E. Soto, Mason Thieu, and Jeffrey S. Allen, "The AI Buildout and the Economy: Publicly Available Data to Assess AI's Impact," FEDS Notes, Federal Reserve Board, July 17, 2026.
https://www.federalreserve.gov/econres/notes/feds-notes/the-ai-buildout-and-the-economy-publicly-available-data-to-assess-ais-impact-20260717.html

Figure 7, "Contributions to GDP Growth from Software, Data Centers, and IT Equipment," 2022 Q1 to 2026 Q1. Figure data are published with the note and saved in `data/feds_ai_buildout_figure_data.xlsx`.

Related work, with different methods and results:

- Hannah Rubinton and Bontu Ankit Patro, "Tracking AI's Contribution to GDP Growth," On the Economy, St. Louis Fed, January 12, 2026. Includes software, research and development, information processing equipment, and data centers, with no import adjustment. Finds 0.97 point over the first three quarters of 2025. The same quarters under this chart's method average 0.81 gross and 0.64 net.
- ING THINK, "How much is AI contributing to US economic growth?", August 2026. Subtracts net imports of semiconductors as well as computers.

The size of the import offset depends mostly on how much of computer imports is assumed to go into investment. This chart follows the FEDS Note.

## Sources

All from BEA's NIPA flat files (`https://apps.bea.gov/national/Release/TXT/`), read with `tidyusmacro::getNIPAFiles()` through `fetch_bea_nipa()`.

| Series | Nominal | Real (chained dollars) | Table |
|--------|---------|------------------------|-------|
| GDP | A191RC | A191RX | 1.1.5, 1.1.6 |
| Software | B985RC | B985RX | 5.3.5, 5.3.6 |
| Computers and peripheral equipment | B935RC | B935RX | 5.5.5, 5.5.6 |
| Data centers | LA001282 | LB001282 | 5.4.5 line 5, 5.4.6 |
| Power (structures) | W028RC | W028RX | 5.4.5 line 18, 5.4.6 |
| Exports of computers, peripherals, and parts | B850RC | B850RX | 4.2.5B, 4.2.6B |
| Imports of computers, peripherals, and parts | B852RC | B852RX | 4.2.5B, 4.2.6B |
| Exports of capital goods, except automotive | A640RC | | 4.2.5B line 22 |
| Exports of consumer goods, except food and automotive | A642RC | | 4.2.5B line 42 |
| Imports of capital goods, except automotive | A650RC | | 4.2.5B line 114 |
| Imports of consumer goods, except food and automotive | A652RC | | 4.2.5B line 134 |

## Transformations

For each component, the contribution to annualized real GDP growth is

`s_{t-1} * 400 * (R_t / R_{t-1} - 1) + (N_t / GDP_t) * [100 * ((Y_t / Y_{t-1})^4 - 1) - 400 * (Y_t / Y_{t-1} - 1)]`

where `s` is the component's nominal share of GDP, `R` its real value, `N` its nominal value, and `Y` real GDP. The second term converts a simple annualized rate to a compound one and is under 0.01 point here.

For computer trade, the lagged share is multiplied by the capital goods share of trade, `CG / (CG + CS)`, computed separately for exports and imports and lagged one quarter along with the share it scales. The FEDS Note text writes the weight as `w_t`. Only the lagged weight reproduces the published figure.

Net contribution = software + computers + data centers + power + net exports of computers.

The chart combines data centers and power into one bar. The CSV keeps them separate.

## Vintages

BEA's flat files carry no release date, so each fetch is saved as `data/bea_nipa_<fetch date>.csv`. The 2026-09-26 fetch runs through 2026 Q2 and matches the FEDS Note's figure data for every quarter from 2022 Q1 to 2026 Q1, so those quarters have not been revised since the note's data were pulled. BEA's annual update, usually published around late September, may revise them.

## Reproduction status

`reproduce.R` compares our five components with the published Figure 7 data. All 17 quarters match to two decimals for every component.

## Census crosswalk

Work in progress, to test the capital goods weight on computer trade.

- BEA's exports and imports of "computers, peripherals, and parts" (B850RC, B852RC) match Census end-use categories 21300 (computers) plus 21301 (computer accessories) within 1 to 3 percent in every quarter from 2022 Q1 to 2026 Q2. Compare Census's seasonally adjusted end-use series, summed to quarters and multiplied by four, with BEA's annual rates.
- Census publishes those seasonally adjusted end-use series monthly back to 1994, with no API key: `https://www.census.gov/foreign-trade/statistics/historical/imports_enduse.xlsx` and `exports_enduse.xlsx`.
- Detail below end-use, such as HS codes that separate servers from laptops, and trade by country, is not seasonally adjusted. Seasonal patterns mostly cancel in shares, so the plan is to take the composition from unadjusted HS data and apply it to BEA's adjusted totals, rather than adding unadjusted HS values to adjusted ones.
- The Census trade API now requires a free key. It is read from the `CENSUS_API_KEY` environment variable and never committed.

## Known breaks and caveats

- There is no AI line in the national accounts. Software, computers, and power facilities include non-AI spending. Power covers all electric and other power structures.
- The capital goods weight assumes computer imports go to investment in the same proportion as goods trade overall goes to capital goods. That is the key assumption behind the size of the offset.
- Semiconductors and communication equipment are excluded, following the FEDS Note.

## Decision log

- 2026-09-26: Follow the FEDS Note method because it publishes figure data that can be reproduced exactly. Credit it as the source of the method.
- 2026-09-26: Show quarterly contributions, as the note does. Put the four-quarter averages behind the title in a note, computed from the data so they update on refresh.
- 2026-09-26: Title: "Computer imports offset about a third of the AI buildout's boost to growth." Over the four quarters through 2026 Q2, 0.66 point gross and 0.45 net, an offset of 31%.
