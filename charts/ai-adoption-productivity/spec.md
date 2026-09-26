# Industry AI adoption and labor productivity growth

Status: draft. The original analysis is documented from the published post. Series identifiers and exact transformations are not yet confirmed against the data.

## Question

Did industries that adopted AI more see faster labor productivity growth, once each industry's pre-pandemic growth is taken into account?

## Original analysis

Ernie Tedeschi, "AI and Productivity," Stripe Economics, July 23, 2026.
https://www.stripeeconomics.com/p/ai-and-productivity

Published chart: "US sectoral productivity growth vs. AI adoption," three stacked scatter panels. The x-axis in every panel is the AI adoption rate, 2026 H1. Each panel has an OLS fit line.

| Panel | y-axis | R² |
|-------|--------|----|
| Latest | Annualized productivity growth, 2022 Q4 to 2025 Q4 | 0.18 |
| Pre-pandemic | Annualized productivity growth, 2016 Q4 to 2019 Q4 | 0.21 |
| Latest minus pre-pandemic | Difference of the two | 0.00 |

Chart note: "Mining (NAICS 21) excluded." Sources listed: Census Bureau, Bureau of Labor Statistics, Federal Reserve Bank of Chicago, Stripe analysis.

The post says the Chicago Fed series was extended two quarters "using its methodology." That extension is where BLS enters.

No underlying data or code is published. Reproduction targets are the three R² values and point positions read off the chart. Approximate readings:

| Sector | AI adoption | Latest | Pre-pandemic |
|--------|-------------|--------|--------------|
| Information | 38% | 9.1% | 6.4% |
| Management of companies | 42% | 1.9% | 4.8% |
| Professional, scientific, and technical | 35% | 4.1% | 3.1% |
| Retail trade | 13% | 6.7% | 4.6% |
| Real estate | 25% | 7.1% | 2.2% |
| Transportation and warehousing | 8% | 3.0% | -2.0% |

## Sample

17 NAICS sectors: the nonfarm private sectors, less mining. Agriculture is also absent from the chart, which the note does not mention. To confirm why.

## Sources

| Data | Provider | Fetch | Identifier |
|------|----------|-------|------------|
| AI use rate by sector | Census Business Trends and Outlook Survey | `fetch_census_btos()` | To confirm: question ID, firm share or employment-weighted, which 2026 H1 waves and how they are averaged |
| Labor productivity by industry, through 2025 Q2 | Chicago Fed, Quarterly Industry-Level Labor Productivity (Hobijn, Mestieri, Werquin, Zhang, Economic Perspectives 2025 No. 1) | `fetch_chicagofed_qilp()` | `qilp.xlsx`, sheet "Labor Productivity": real value added per hour, index 2017 = 100 |
| Real value added by industry, for the extension | BEA GDP by Industry | To confirm: `tidyusmacro` does not cover GDP by Industry | To confirm |
| Hours by industry, for the extension | BLS Current Employment Statistics, plus CPS self-employment | `tidyusmacro::getBLSFiles("ces")` | To confirm |

Data URL for the Chicago Fed file: https://www.chicagofed.org/-/media/others/people/research-resources/hobijin-bart/qilp.xlsx

## Transformations

1. Extend Chicago Fed productivity to 2025 Q4 with its published method: quarterly growth is the log change in real value added minus the log change in total hours.
2. Annualized growth for each sector over 2022 Q4 to 2025 Q4 and over 2016 Q4 to 2019 Q4. To confirm: compound or log annualization.
3. Difference: latest minus pre-pandemic.
4. Regress each on the sector AI adoption rate. Report slope and R².

## Vintages

To decide. See the open question in `CLAUDE.md`. Relevant facts:

- The Chicago Fed file has a version sheet. The copy downloaded on 2026-09-26 is dated 2025-10-07 and runs through 2025 Q2. It has not been updated in almost a year.
- Chicago Fed hours are revised with each annual CES benchmark, per the version notes.

## Known breaks and risks

- The Business Trends and Outlook Survey changed its AI question wording in November 2025. The 2026 H1 adoption rate is entirely after the change, so it is internally consistent, but it is not comparable to earlier waves.
- The Chicago Fed file looks unmaintained. Keeping this chart current means computing the productivity series ourselves from BEA and BLS data, not just extending it two quarters. That is the main cost of this chart.

## Decision log

Record decisions here with a date and the reason.

- 2026-09-26: Chart method documented from the published post and chart. Chicago Fed file inspected: version 2025-10-07, data through 2025 Q2.
