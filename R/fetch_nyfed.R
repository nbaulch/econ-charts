# Daily Treasury yields, term premiums, and risk-neutral (expected short rate)
# yields from the Adrian, Crump, and Moench model, maturities of 1 to 10 years,
# in percent. Each fitted yield is its term premium plus its risk-neutral yield.
# https://www.newyorkfed.org/research/data_indicators/term-premia-tabs
fetch_nyfed_acm <- function() {
  download <- tempfile(fileext = ".xls")
  download.file(
    "https://www.newyorkfed.org/medialibrary/media/research/data_indicators/ACMTermPremium.xls",
    download,
    mode = "wb",
    quiet = TRUE
  )

  read_excel(download, sheet = "ACM Daily") |>
    mutate(date = dmy(DATE), .keep = "unused", .before = 1) |>
    rename_with(str_to_lower, -date)
}
