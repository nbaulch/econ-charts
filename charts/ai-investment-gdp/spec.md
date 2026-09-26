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
| Consumer spending on personal computers, tablets, and peripherals | DCPPRC | | 2.4.5U line 49 |
| Final sales of computers | BB01RC | | 1.2.5 line 17 |

The last two build the trade weight based on domestic spending on computers, used in the chart notes and in `trade_weights.R`.

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

Tests the capital goods weight on computer trade. `trade_weights.R` fetches the Census detail, saves the snapshot, and prints the comparison below. It does not change the chart.

- BEA's exports and imports of "computers, peripherals, and parts" (B850RC, B852RC) match Census end-use categories 21300 (computers) plus 21301 (computer accessories) within 1 to 3 percent in every quarter from 2022 Q1 to 2026 Q2. Compare Census's seasonally adjusted end-use series, summed to quarters and multiplied by four, with BEA's annual rates.
- Census publishes those seasonally adjusted end-use series monthly back to 1994, with no API key: `https://www.census.gov/foreign-trade/statistics/historical/imports_enduse.xlsx` and `exports_enduse.xlsx`.
- HS detail comes from the Census international trade API (`timeseries/intltrade/imports/hs` and `exports/hs`) through `fetch_census_trade()`: general imports (`GEN_VAL_MO`) and total exports (`ALL_VAL_MO`), monthly, by country, not seasonally adjusted. The API needs a free key, read from the `CENSUS_API_KEY` environment variable and never committed.
- Codes: all of HS 8471 at six digits (847130 laptops, 847141 and 847149 desktops and systems, 847150 processing units, which are mostly servers, 847160 input and output units, 847170 storage, 847180 other units, 847190 other) plus 847330, parts of 8471 machines. Together they are 86% of end-use 21300 plus 21301 imports in 2022, rising to 96% in 2026, and they carry nearly all the growth.
- Not covered, because they are outside BEA's computer line: GPUs and other chips shipped on their own (HS 8542), network switches and routers (8517.62), and power and cooling equipment for data centers.
- Snapshot: `data/census_trade_<fetch date>.csv`, monthly by HS code and partner, with partners grouped as Mexico, Taiwan, and all others. The full country detail is about 5 MB a pull, too large to commit on every refresh.

### Findings, data through 2026 Q2 (Census through July 2026)

Composition of computer imports:

| | 2022 | 2026 H1 |
|---|---|---|
| Processing units, mostly servers | 24–29% | 52–55% |
| Parts | 19–24% | 26–27% |
| Laptops | 33–36% | 9–10% |
| Desktops and systems | 2–4% | 1–2% |
| Storage and other units | 13–15% | 8–9% |

Import weights and the offset, averaged over the four quarters through 2026 Q2. Gross contribution is 0.66 point in every case.

| Weight on computer trade | Export weight | Import weight | Net contribution | Offset |
|---|---|---|---|---|
| Capital goods share (FEDS Note, current chart) | 0.73 | 0.63 | 0.45 | 31% |
| Capital goods share of imports, on both sides | 0.63 | 0.63 | 0.44 | 33% |
| Business share of domestic spending on computers (BEA) | 0.69 | 0.69 | 0.41 | 37% |
| Product mix from Census HS detail | 0.97 | 0.95 | 0.32 | 52% |
| No weight | 1 | 1 | 0.30 | 55% |

The BEA weight is business investment in computers as a share of domestic spending on computers by businesses, consumers, and government, lagged a quarter and applied to exports and imports alike. That spreads net imports across domestic uses in proportion to their size, the assumption BEA uses in its input-output tables. Government spending on computers isn't published, so it is the residual in final sales of computers (consumer + business + government + exports - imports). The residual rose from $13 billion a year in 2019 and $17 billion in 2024 Q1 to $46 billion in 2026 Q2. That rise is unverified; if it were $18 billion, the weight in 2026 Q2 would be 0.75 rather than 0.72. The business share rose from about 0.60 before 2025 to 0.72 in 2026 as server purchases grew.

The product mix weight counts servers, storage, other units, and parts fully as capital goods and gives laptops and desktops the FEDS weight, since households buy them too. Because laptops and desktops are now about a tenth of computer trade, it lands close to no weight. The level of the import weight drives the gap; weighting exports more heavily than imports accounts for only about 2 points of it.

Domestic content check. A weight is too high if the net computer imports it counts exceed business investment in computers. Counted net imports as a share of that investment, 2025 Q3 to 2026 Q2: FEDS weight 0.45 to 0.72, BEA weight 0.57 to 0.79, product mix 0.79 to 1.06, no weight 0.87 to 1.10. The product mix weight and no weight fail in 2026. The BEA weight passes by construction, since it is built from final sales, so the check rules out the high weights but cannot choose between the FEDS and BEA weights.

Round trips through Mexico. Exports of parts to Mexico rose from $6 billion to $11 billion a year in 2022 and 2023 to $35 billion in 2026 H1. Server exports to Mexico went from $2 billion (annual rate) in 2025 Q2 to $15 billion in Q3, while server imports from Mexico reached $143 billion in 2026 Q2. The 2025 Q2 rise in exports was mostly servers to other destinations, including Europe and Singapore; Q3's was mostly Mexico. Netting exports against imports handles round trips correctly as long as both sides get the same weight.

## Import price check

`import_prices.R` compares BEA's implied price of computer trade with BLS price indexes, read from FRED and saved as `data/fred_bls_prices_<fetch date>.csv`: import prices for computers, peripherals, and parts (IR213COM), for parts alone (IR21301), and for semiconductors (IR21320), and producer prices for electronic computers (PCU334111334111) and storage devices (PCU334112334112). BLS published no import prices for October 2025, during the government shutdown, so 2025 Q4 averages November and December.

Findings, annualized quarterly price growth:

| | 2025 Q4 | 2026 Q1 | 2026 Q2 |
|---|---|---|---|
| BEA, computer imports | 5% | 23% | 59% |
| BLS import prices, computers, peripherals, and parts | 5% | 17% | 47% |
| BLS import prices, parts only | 10% | 35% | 112% |
| BLS producer prices, storage devices | 19% | 48% | 100% |
| BLS producer prices, electronic computers | -1% | 0% | 1% |
| BEA, business investment in computers | 0% | 15% | 29% |
| BEA, computer exports | -4% | 11% | 14% |

- The jump in BEA's import price is real in the source data. BLS import prices show it, concentrated in parts, and producer prices for storage devices doubled over the same period. That is consistent with the rise in memory prices, though these indexes don't isolate memory. It continues into 2026 Q3: in July and August, import prices for parts averaged 10% above their 2026 Q2 average.
- BEA's investment price for computers rose half as fast as its import price. Real imports therefore fell while nominal imports rose, and the gap between the two price indexes, not fewer imports, is what turns computer trade positive in 2026 Q2.
- Deflating computer trade with the investment price instead changes 2026 Q2 net trade from +0.24 to -0.04 point, the net total from 0.52 to 0.24, and the four-quarter offset from 31% to 48%. Earlier quarters barely move, because the two prices grew at similar rates.
- Which price is right is not clear. BEA's import price follows BLS import prices for the goods actually imported. But much of what is imported ends up in business investment, and producer prices for electronic computers have barely moved, so either domestic makers absorbed the cost or the investment price understates it.

## Open items

As of 2026-09-26. Not yet decided or done.

- **Title and the price gap.** The four-quarter offset is 31% under the FEDS method, 37% with the BEA trade weight, and 48% when computer trade is deflated with the investment price (see Import price check). The positive 2026 Q2 trade bar comes from import prices rising faster than investment prices, not from fewer imports, and 2026 Q3 will likely show the same. Options: keep the title and add a note on the 2026 Q2 price gap; or change the title to a range, such as "a third to a half". Undecided.
- **Semiconductors.** Census end-use semiconductor imports doubled between 2025 Q3 and 2026 Q2, from $67 billion to $138 billion at an annual rate. The FEDS method excludes them; ING includes them.
- **Colors.** Orange means data centers and power here and utilization on the productivity chart, on the same page.

## Known breaks and caveats

- There is no AI line in the national accounts. Software, computers, and power facilities include non-AI spending. Power covers all electric and other power structures.
- The capital goods weight assumes computer imports go to investment in the same proportion as goods trade overall goes to capital goods. That is the key assumption behind the size of the offset.
- Semiconductors and communication equipment are excluded, following the FEDS Note.

## Decision log

- 2026-09-26: Follow the FEDS Note method because it publishes figure data that can be reproduced exactly. Credit it as the source of the method.
- 2026-09-26: Show quarterly contributions, as the note does. Put the four-quarter averages behind the title in a note, computed from the data so they update on refresh.
- 2026-09-26: Title: "Computer imports offset about a third of the AI buildout's boost to growth." Over the four quarters through 2026 Q2, 0.66 point gross and 0.45 net, an offset of 31%.
- 2026-09-26: Pulled Census HS detail for computer trade and compared weights. The chart keeps the FEDS weight until the weight is decided.
- 2026-09-26: Built a weight from BEA's domestic spending on computers. It gives a 37% offset against the FEDS weight's 31%. The product mix weight is ruled out by the domestic content check.
- 2026-09-26: Keep the FEDS weight on the chart, for exact replication. A note gives the offset under the BEA weight, computed from the data so it updates on refresh. Revisit if the two move apart.
- 2026-09-26: Checked the 2026 Q2 jump in computer import prices against BLS. It is real and concentrated in parts; it outpaced BEA's investment price, which is what turns 2026 Q2 computer trade positive.
