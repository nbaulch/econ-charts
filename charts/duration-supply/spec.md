# Duration supplied to private investors by Treasury and big tech bonds

Status: built in R from data through August 2026 (fetched September 26, 2026). Original chart, prompted by Alex Etra's; it doesn't reproduce his numbers (see below). Title is a draft for review.

## Question

How much interest rate risk are Treasury and the largest AI borrowers handing to private investors, and is Treasury's share rising, as the fiscal explanation of higher yields would suggest?

## Related work

- Alex Etra, Exante Data, "Net duration supplied to the US private market," chart on X, September 2026, shared by Brad Setser. Change in the stock of 10-year equivalents over 12 months, monthly: Treasury net of Fed holdings and buybacks, hyperscalers, other nonfinancial corporates, and financials. Sources on the chart: TreasuryDirect auction history, New York Fed holdings, Fiscal Data buybacks, and Bloomberg for corporate bonds. His methods note is referenced but not public, and the corporate data are proprietary, so the chart is credited as related work, not reproduced.
- Hugo De Vere, Srini Ramaswamy, and Seth Searls, "How AI debt financing impacts duration supply and interest rates," Federal Reserve Bank of Dallas, February 10, 2026. https://www.dallasfed.org/research/economics/2026/0210-searls-aifinancing. About $300 billion of AI-related investment-grade issuance in 2026, about $360 billion in 10-year equivalents, "an eighth of the duration supply from U.S. Treasury issuance." That compares with gross Treasury issuance; this chart is net.
- Toby Nangle on hyperscaler duration supply, recommended by Brad Setser, September 2026. Not yet read.

## Sources

| Data | Provider | Fetch |
|---|---|---|
| Marketable Treasury securities outstanding by CUSIP, month end, net of buybacks | Treasury, Monthly Statement of the Public Debt, Fiscal Data API | `fetch_treasury_mspd_marketable()` |
| Fed holdings by CUSIP, weekly | New York Fed, System Open Market Account API | `fetch_nyfed_soma_treasury()`, `fetch_nyfed_soma_dates()` |
| Big tech bonds: amount and title of each tranche | SEC EDGAR, filing fee exhibits of 424B2 and 424B5 prospectuses | `fetch_sec_filings()`, `fetch_sec_fee_offerings()` |
| Nominal and real Treasury yield curves | Fed Board H.15, from FRED | `tidyusmacro::getFRED()`: DGS1MO to DGS30, DFII5 to DFII30 |

- EDGAR requires a user agent with a contact email, read from the `SEC_USER_AGENT` environment variable and never committed.
- Downloads that don't change are cached in `cache/` (not committed): weekly Fed holdings and SEC filings.
- Companies: Alphabet (CIK 1652044), Amazon (1018724), Meta (1326801), Microsoft (789019), Oracle (1341439). Microsoft has registered no bonds since 2022.

## Transformations

- Treasury held privately = amount outstanding minus Fed holdings on the last Wednesday on or before the month end. Buybacks are already netted out of amounts outstanding.
- Big tech bonds outstanding at a month end = dollar tranches filed on or before it and not yet matured. The currency is read from the prospectus cover; euro, sterling, and yen tranches are excluded. The maturity day is taken as the issue's month and day in the maturity year given in the title.
- Modified duration of each security from its coupon and remaining maturity, priced on the latest month-end yield curve for every month. Bills are zero-coupon, floating rate notes count as zero duration, inflation-protected securities are priced on real yields, and corporate bonds on the Treasury curve without a credit spread.
- 10-year equivalents = amount times duration divided by the duration of a new 10-year note on the same curve.
- The chart plots the 12-month change in each stock. It includes new issuance, maturities, buybacks, changes in Fed holdings, and bonds aging toward maturity.

## Vintages

- `data/treasury_held_privately_<latest month end>.csv`: privately held amounts by month and security type. Security-level data, about 100,000 rows, are rebuilt from the sources on each run.
- `data/sec_hyperscaler_bonds_<fetch date>.csv`: every big tech dollar tranche used, with filing date and accession number.
- Because every month is priced on the latest curve, the whole history shifts slightly on each refresh.

## Comparison with Etra

12-month change in Treasury held privately, billions of 10-year equivalents:

| | Ours | Etra (read off his chart) |
|---|---|---|
| 2016 to 2019 | 430 to 700 | about 500 |
| Mid-2020 | about -400 | about 0 |
| 2021 to 2022 peak | about 1,650 | about 1,300 |
| August 2025 | 1,004 | about 1,050 |
| August 2026 | 980 | about 800 |

Big tech, August 2026: ours 284, his about 400. His Bloomberg data likely include private placements (such as the roughly $27 billion Meta Hyperion financing) and possibly other issuers.

Valuation choice: priced at each month's own yields, our Treasury series swings with rates (620 in February 2026, 1,153 in August 2026). The fixed curve removes that.

## Findings, August 2026

- Treasury added $980 billion of 10-year equivalents to private holdings over 12 months, against $1,004 billion a year earlier and about $1,200 billion in early 2025. Treasury has kept coupon auction sizes unchanged and funded deficits with bills.
- Big tech dollar bonds added $284 billion, 29 percent as much as Treasury. Their USD issuance over the 12 months was about $254 billion, concentrated in long maturities.
- Gross Treasury issuance adds about $2.7 to 3.0 trillion a year in 10-year equivalents, consistent with the Dallas Fed; the net figure is much smaller because bonds age and mature.

## Known breaks and caveats

- Big tech coverage starts in August 2024, when filing fee exhibits became structured; 12-month changes are complete from August 2025. Earlier big tech bonds' aging isn't subtracted, which overstates the big tech figure by roughly $20 billion a year.
- Private placements, other AI borrowers (such as data center developers and chip makers), and foreign-currency bonds are excluded.
- Other corporate and financial bonds, which Etra includes, aren't covered: no free source gives their maturities.
- Mid-2020: the Fed's purchases exceeded Treasury's net issuance of duration, so the series turns negative; Etra's doesn't. Unresolved.

## Decision log

- 2026-09-26: Build from public data; credit Etra and the Dallas Fed as related work rather than reproducing Etra, whose method and corporate data aren't public.
- 2026-09-26: Value every month on the latest yield curve, so the series reflects what was issued rather than yield swings.
- 2026-09-26: Dollar bonds only, since the question is the U.S. market.
- 2026-09-26: Title: "Big tech bond sales now add more than a quarter as much interest rate risk as Treasury." The ratio is 29 percent in August 2026; revisit on refresh.
