# Checks the collected tariff rate against published figures. Run build.R
# first; this reads the totals by country it saves.

library(dplyr)
library(readr)
library(lubridate)

chart_dir <- "charts/effective-tariff-rate"
china <- "5700"

totals_by_country <- list.files(file.path(chart_dir, "data"), "^census_imports_by_country_", full.names = TRUE) |>
  max() |>
  read_csv(col_types = cols(country_code = "c"))

# The Federal Reserve Board note divides by general imports, the NIPA concept;
# the chart divides by imports for consumption, as the Yale Budget Lab does.
collected_rate <- function(totals) {
  summarise(
    totals,
    consumption = 100 * sum(cal_dut) / sum(con_val),
    general = 100 * sum(cal_dut) / sum(gen_val)
  )
}

rate_in <- function(months, countries = unique(totals_by_country$country_code)) {
  totals_by_country |>
    filter(date %in% months, country_code %in% countries) |>
    collected_rate()
}

months_of <- \(year) seq(make_date(year), make_date(year, 12), by = "month")

rise_from <- function(month, base_year) {
  rate_in(month) - rate_in(months_of(base_year))
}

bind_rows(
  "Fed Board: collected rate, December 2025 (14.7 announced less 5.43 gap)" =
    tibble(published = 14.7 - 5.43, rate_in(ymd("2025-12-01"))),
  "Fed Board: rise in collected rate, 2024 to December 2025 (12.37 less 5.43)" =
    tibble(published = 12.37 - 5.43, rise_from(ymd("2025-12-01"), 2024)),
  "Fed Board: rise in collected rate, 2017 to December 2018" =
    tibble(published = 1.49, rise_from(ymd("2018-12-01"), 2017)),
  "Penn Wharton: January 2025" =
    tibble(published = 2.3, rate_in(ymd("2025-01-01"))),
  "Penn Wharton: July 2026" =
    tibble(published = 6.7, rate_in(ymd("2026-07-01"))),
  "Penn Wharton: China, July 2026" =
    tibble(published = 22.8, rate_in(ymd("2026-07-01"), china)),
  .id = "check"
) |>
  mutate(across(where(is.numeric), \(x) round(x, 2))) |>
  print(width = Inf)
