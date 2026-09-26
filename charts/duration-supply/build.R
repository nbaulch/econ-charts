library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(readxl)
library(stringr)
library(lubridate)
library(ggplot2)

source("R/fetch_treasury.R")
source("R/fetch_nyfed.R")
source("R/chart_style.R")
source("charts/duration-supply/duration.R")

chart_dir <- "charts/duration-supply"

# A year before the first plotted 12-month change.
first_month_end <- ymd("2009-12-31")

outstanding <- fetch_treasury_mspd_marketable(first_month_end)
month_ends <- sort(unique(outstanding$date))

# The Fed reports holdings each Wednesday; each month end uses the last
# Wednesday on or before it.
soma_dates <- fetch_nyfed_soma_dates()
soma_date_for <- tibble(date = month_ends) |>
  mutate(as_of = map_vec(date, \(d) max(soma_dates[soma_dates <= d])))

fed_holdings <- fetch_nyfed_soma_treasury(unique(soma_date_for$as_of)) |>
  inner_join(soma_date_for, by = "as_of", relationship = "many-to-many") |>
  select(date, cusip, held)

# Month-end yield curves, nominal and inflation-protected, for pricing duration.
curves <- tidyusmacro::getFRED(
  `0.083` = "DGS1MO", `0.25` = "DGS3MO", `0.5` = "DGS6MO", `1` = "DGS1", `2` = "DGS2", `3` = "DGS3",
  `5` = "DGS5", `7` = "DGS7", `10` = "DGS10", `20` = "DGS20", `30` = "DGS30"
) |>
  month_end_curve() |>
  mutate(curve = "nominal") |>
  bind_rows(
    tidyusmacro::getFRED(`5` = "DFII5", `7` = "DFII7", `10` = "DFII10", `20` = "DFII20", `30` = "DFII30") |>
      month_end_curve() |>
      mutate(curve = "real")
  )

private_holdings <- outstanding |>
  left_join(fed_holdings, by = c("date", "cusip")) |>
  mutate(
    held_by_fed = coalesce(held, 0),
    held_privately = outstanding - held_by_fed,
    years_to_maturity = time_length(interval(date, maturity), "years")
  ) |>
  filter(years_to_maturity > 0)

ten_year_equivalents <- private_holdings |>
  add_modified_duration(curves) |>
  mutate(
    across(c(outstanding, held_by_fed, held_privately), \(x) x * modified_duration / ten_year_duration / 1e3,
      .names = "{.col}_10y"
    )
  )

# Snapshot: totals by month and security type. The security-level data, about
# 100,000 rows, are rebuilt from the sources on each run.
monthly_totals <- ten_year_equivalents |>
  summarise(
    across(c(outstanding, held_by_fed, held_privately), \(x) sum(x) / 1e3),
    across(ends_with("_10y"), sum),
    .by = c(date, type)
  ) |>
  arrange(date, type)

write_csv(monthly_totals, file.path(chart_dir, "data", str_glue("treasury_duration_{max(month_ends)}.csv")))
