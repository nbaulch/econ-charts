# Net duration supplied to private investors (work in progress)

Status: draft, not on the site. Treasury series built from public data; not yet matched to the chart that prompted it. Decisions pending, listed at the end.

## Question

How much interest rate risk, in 10-year equivalents, are Treasury and AI-related corporate borrowers handing to private investors, net of Fed holdings?

## Related work

- Alex Etra (Exante Data), "Net duration supplied to the US private market," chart on X, September 2026, shared by Brad Setser. Change in the stock of 10-year equivalents over 12 months, monthly, Treasury net of Fed holdings and buybacks, plus hyperscaler, other corporate, and financial issuance. Sources on the chart: TreasuryDirect auction history, New York Fed holdings, Fiscal Data buybacks, Bloomberg. Methods note referenced but not found publicly.
- Hugo De Vere, Srini Ramaswamy, and Seth Searls, "How AI debt financing impacts duration supply and interest rates," Dallas Fed, February 10, 2026. About $300 billion of AI-related investment-grade issuance in 2026, about $360 billion in 10-year equivalents, "an eighth of the duration supply from U.S. Treasury issuance" (a gross measure). https://www.dallasfed.org/research/economics/2026/0210-searls-aifinancing
- Toby Nangle on hyperscaler duration supply, recommended by Brad Setser, September 2026. Not yet read.

## Sources

| Data | Provider | Fetch |
|---|---|---|
| Marketable Treasury securities outstanding by CUSIP, month end, net of buybacks | Treasury, Monthly Statement of the Public Debt, Fiscal Data API | `fetch_treasury_mspd_marketable()` |
| Fed holdings by CUSIP, weekly | New York Fed, SOMA API | `fetch_nyfed_soma_treasury()`, `fetch_nyfed_soma_dates()` |
| Nominal and inflation-protected yield curves | Fed Board H.15, from FRED | `tidyusmacro::getFRED()` |

Weekly Fed holdings are cached in `cache/nyfed_soma/` (not committed); past weeks don't change.

## Method so far

- Private holdings of each security = amount outstanding minus Fed holdings on the last Wednesday on or before the month end.
- Modified duration from the security's coupon and remaining maturity, priced on the month-end curve at its remaining maturity. Bills are zero-coupon. Floating rate notes count as zero duration. Inflation-protected securities are priced on real yields.
- 10-year equivalents = holdings times the security's duration divided by the duration of a new 10-year note.
- Stock of 10-year equivalents held privately, and its 12-month change.

## Findings so far

- Gross: new Treasury debt adds about $2.7 to 3.0 trillion a year in 10-year equivalents, consistent with the Dallas Fed's figure.
- Net stock change: about $0.6 to 1.2 trillion a year since mid-2024, the same range as Etra's Treasury series.
- Priced at each month's yields, the 12-month change swings with yield changes (620 in February 2026, 1,153 in August 2026). Priced on one fixed curve, it falls from about 1,200 in early 2025 to about 900 to 990 in 2026, closer to Etra's decline to about 800.
- History broadly matches Etra except around 2020 (ours falls to -475 in mid-2020; his Treasury series stays near zero) and the 2021 to 2022 peak (ours about 1,700, his about 1,300).

## Decisions pending

- Price on each month's curve or on a fixed curve.
- Present as our own series crediting Etra, or try to obtain his method first.
- Hyperscaler bonds from SEC filings, which needs a contact email in an environment variable, or Treasury only.
