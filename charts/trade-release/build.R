library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)
library(ggplot2)
library(purrr)

source("R/fetch_census.R")
source("R/chart_style.R")

chart_dir <- "charts/trade-release"

# The seasonally adjusted figures come from the latest FT-900; the rest are not
# seasonally adjusted, from the Census API and the trade store. Seasonal factors
# have been harder to estimate since 2020, so each section shows both views
# where the data allow.
headline <- fetch_census_ft900_exhibit(1, c(
  "balance_total", "balance_goods", "balance_services",
  "exports_total", "exports_goods", "exports_services",
  "imports_total", "imports_goods", "imports_services"
))
end_use_adjusted <- fetch_census_ft900_exhibit(6, c(
  "total_bop", "net_adjustments", "total_census",
  "0", "1", "2", "3", "4", "5"
))

latest_month <- max(headline$date)
previous_month <- latest_month - months(1)
year_earlier <- latest_month - years(1)
schedule <- fetch_census_trade_schedule()
released <- schedule$released[schedule$month == latest_month]
next_release <- slice_min(filter(schedule, month > latest_month), month)

store_latest <- max(filter(read_census_trade_manifest(), flow == "imports")$date)
if (store_latest != latest_month) {
  stop("The trade store runs through ", store_latest, " but the FT-900 covers ", latest_month, "; update the store first.")
}

end_use <- c("imports", "exports") |>
  map(\(flow) fetch_census_trade_end_use(flow, latest_month - months(25))) |>
  list_rbind()

list(
  census_ft900 = bind_rows(exhibit_1 = headline, exhibit_6 = end_use_adjusted, .id = "exhibit"),
  census_end_use = end_use
) |>
  iwalk(\(data, name) write_csv(data, file.path(chart_dir, "data", str_glue("{name}_{released}.csv"))))

billions <- \(x) sprintf("%.1f", x / 1e3)
change <- \(x) if_else(round(x, 1) == 0, "0", sprintf("%+.1f", x))
month_short <- \(date) format(date, "%b %Y")

markdown_table <- function(table, path) {
  header <- str_c("| ", str_c(c("", names(table)[-1]), collapse = " | "), " |")
  alignment <- str_c("|", str_c(c(":--", rep("--:", ncol(table) - 1)), collapse = "|"), "|")
  rows <- pmap_chr(table, \(...) str_c("| ", str_c(c(...), collapse = " | "), " |"))
  write_lines(c(header, alignment, rows), path)
}

write_lines(
  str_glue(
    "Data for {format(latest_month, '%B %Y')}, released {format(released, '%B %-d, %Y')}. ",
    "Next release: {format(next_release$month, '%B %Y')} data, ",
    "{if (is.na(next_release$released)) 'date not yet set' else format(next_release$released, '%B %-d, %Y')}."
  ),
  file.path(chart_dir, "output", "release.md")
)

# Headline --------------------------------------------------------------------

headline_rows <- c(
  balance_total = "Goods and services balance",
  balance_goods = "Goods balance",
  balance_services = "Services balance",
  exports_total = "Exports",
  imports_total = "Imports"
)

headline |>
  filter(series %in% names(headline_rows), date %in% c(latest_month, previous_month)) |>
  select(series, date, value) |>
  pivot_wider(names_from = date, values_from = value) |>
  transmute(
    series = headline_rows[series],
    "{month_short(latest_month)}" := billions(.data[[as.character(latest_month)]]),
    "{month_short(previous_month)}" := billions(.data[[as.character(previous_month)]]),
    Change = change((.data[[as.character(latest_month)]] - .data[[as.character(previous_month)]]) / 1e3)
  ) |>
  arrange(match(series, headline_rows)) |>
  markdown_table(file.path(chart_dir, "output", "headline.md"))

goods_balance <- bind_rows(
  "Seasonally adjusted" = end_use_adjusted |>
    filter(series == "total_census") |>
    summarise(balance = value[block == "exports"] - value[block == "imports"], .by = date) |>
    mutate(balance = balance / 1e3),
  "Not seasonally adjusted" = end_use |>
    filter(level == "EU1") |>
    summarise(value = sum(value), .by = c(date, flow)) |>
    pivot_wider(names_from = flow, values_from = value) |>
    transmute(date, balance = (exports - imports) / 1e9),
  .id = "adjustment"
) |>
  filter(date >= min(end_use_adjusted$date)) |>
  arrange(adjustment, date)

goods_balance |>
  mutate(balance = round(balance, 3)) |>
  pivot_wider(names_from = adjustment, values_from = balance) |>
  write_csv(file.path(chart_dir, "output", "goods-balance.csv"))

goods_balance_chart <- goods_balance |>
  mutate(adjustment = factor(adjustment, levels = c("Seasonally adjusted", "Not seasonally adjusted"))) |>
  ggplot(aes(date, balance, colour = adjustment)) +
  geom_line(linewidth = 0.9) +
  geom_point(data = \(data) filter(data, date == latest_month), size = 2.2) +
  scale_colour_manual(values = unname(chart_colors[c("blue", "orange")])) +
  scale_x_date(date_breaks = "3 months", date_labels = "%b\n%Y") +
  theme_chart()

# What moved -------------------------------------------------------------------

end_use_labels <- c(
  "0" = "Foods, feeds, and beverages",
  "1" = "Industrial supplies",
  "2" = "Capital goods",
  "3" = "Autos and parts",
  "4" = "Consumer goods",
  "5" = "Other goods"
)
view_labels <- c(
  adjusted = str_glue("From {format(previous_month, '%B')}, seasonally adjusted"),
  unadjusted = str_glue("From {format(year_earlier, '%B %Y')}, not seasonally adjusted")
)

end_use_changes <- bind_rows(
  adjusted = end_use_adjusted |>
    filter(series %in% names(end_use_labels), date %in% c(latest_month, previous_month)) |>
    summarise(change = (value[date == latest_month] - value[date == previous_month]) / 1e3, .by = c(block, series)),
  # Exports n.e.c. and reexports (code 6) are part of other goods in the FT-900.
  unadjusted = end_use |>
    filter(level == "EU1", date %in% c(latest_month, year_earlier)) |>
    mutate(code = if_else(code == "6", "5", code)) |>
    summarise(change = (sum(value[date == latest_month]) - sum(value[date == year_earlier])) / 1e9, .by = c(flow, code)) |>
    rename(block = flow, series = code),
  .id = "view"
)

end_use_changes |>
  transmute(view = view_labels[view], flow = block, category = end_use_labels[series], change = round(change, 3)) |>
  write_csv(file.path(chart_dir, "output", "end-use-changes.csv"))

end_use_chart <- end_use_changes |>
  mutate(
    view = factor(view_labels[view], levels = view_labels),
    flow = factor(str_to_sentence(block), levels = c("Imports", "Exports")),
    category = factor(end_use_labels[series], levels = rev(end_use_labels))
  ) |>
  ggplot(aes(change, category, fill = flow)) +
  geom_vline(xintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  geom_col(position = position_dodge(width = 0.75, reverse = TRUE), width = 0.7) +
  facet_wrap(vars(view), scales = "free_x") +
  scale_fill_manual(values = unname(chart_colors[c("blue", "orange")])) +
  scale_x_continuous(labels = \(x) str_c("$", x)) +
  theme_chart() +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(colour = chart_greys[["grid"]], linewidth = 0.35),
    strip.text = element_text(hjust = 0, size = rel(0.9), colour = chart_greys[["text"]]),
    panel.spacing.x = unit(1.5, "lines")
  )

# Largest changes by product ------------------------------------------------------

# The ten detailed end-use categories with the largest change in dollars from a
# year earlier, for imports and for exports.
product_changes <- end_use |>
  filter(level == "EU5", date %in% c(latest_month, year_earlier)) |>
  summarise(change = (sum(value[date == latest_month]) - sum(value[date == year_earlier])) / 1e9, .by = c(flow, code, description)) |>
  slice_max(abs(change), n = 10, by = flow, with_ties = FALSE) |>
  arrange(flow, change)

product_changes |>
  mutate(change = round(change, 3)) |>
  write_csv(file.path(chart_dir, "output", "product-changes.csv"))

product_chart <- product_changes |>
  mutate(
    flow = factor(str_to_sentence(flow), levels = c("Imports", "Exports")),
    row = factor(str_c(flow, code), levels = str_c(flow, code))
  ) |>
  ggplot(aes(change, row, fill = change > 0)) +
  geom_vline(xintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  geom_col(width = 0.7) +
  facet_wrap(vars(flow), scales = "free_y", ncol = 1) +
  scale_y_discrete(labels = \(x) product_changes$description[match(x, str_c(str_to_sentence(product_changes$flow), product_changes$code))]) +
  scale_fill_manual(values = c(`TRUE` = chart_colors[["blue"]], `FALSE` = chart_colors[["grey"]]), guide = "none") +
  scale_x_continuous(labels = \(x) str_c("$", x)) +
  theme_chart() +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(colour = chart_greys[["grid"]], linewidth = 0.35),
    strip.text = element_text(hjust = 0, face = "bold", size = rel(0.95), colour = chart_greys[["text"]])
  )

# Tariffs -----------------------------------------------------------------------

duties <- read_census_trade("imports", latest_month - months(24), latest_month) |>
  select(date, country_code, con_val, cal_dut) |>
  summarise(across(everything(), sum), .by = c(date, country_code)) |>
  collect()

duties_by_month <- duties |>
  summarise(duties = sum(cal_dut) / 1e9, rate = 100 * sum(cal_dut) / sum(con_val), .by = date) |>
  arrange(date)

duties_by_month |>
  mutate(across(-date, \(x) round(x, 3))) |>
  write_csv(file.path(chart_dir, "output", "duties.csv"))

duties_chart <- duties_by_month |>
  ggplot(aes(date, duties)) +
  geom_col(aes(fill = date == latest_month), width = 25) +
  geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  scale_fill_manual(values = c(`TRUE` = chart_colors[["blue"]], `FALSE` = chart_colors[["grey"]]), guide = "none") +
  scale_x_date(date_breaks = "3 months", date_labels = "%b\n%Y") +
  scale_y_continuous(labels = \(x) str_c("$", x)) +
  theme_chart()

countries <- read_census_trade_countries()

duties |>
  filter(date %in% c(latest_month, year_earlier)) |>
  summarise(
    duties = sum(cal_dut[date == latest_month]) / 1e9,
    duties_year_earlier = sum(cal_dut[date == year_earlier]) / 1e9,
    rate = 100 * sum(cal_dut[date == latest_month]) / sum(con_val[date == latest_month]),
    .by = country_code
  ) |>
  slice_max(duties, n = 10) |>
  left_join(countries, by = "country_code") |>
  transmute(
    country = str_replace(str_to_title(country), "^Korea, South$", "South Korea"),
    "Duties, {month_short(latest_month)}" := sprintf("%.2f", duties),
    "{month_short(year_earlier)}" := sprintf("%.2f", duties_year_earlier),
    "Tariff rate, %" := sprintf("%.1f", rate)
  ) |>
  markdown_table(file.path(chart_dir, "output", "duties-by-country.md"))

# Charts --------------------------------------------------------------------------

source_line <- "Source: Census Bureau."
charts <- list(
  "goods-balance" = list(
    goods_balance_chart,
    "U.S. goods trade balance",
    "Census basis, billions of dollars a month",
    5
  ),
  "end-use-changes" = list(
    end_use_chart,
    "Change in U.S. goods trade by category",
    "Billions of dollars",
    4.5
  ),
  "product-changes" = list(
    product_chart,
    "Largest changes in U.S. goods trade by product",
    str_glue("Change from {format(year_earlier, '%B %Y')}, billions of dollars, not seasonally adjusted"),
    6.5
  ),
  "duties" = list(
    duties_chart,
    "Duties on U.S. imports",
    "Calculated duties, billions of dollars a month, not seasonally adjusted",
    4.5
  )
)

iwalk(charts, \(chart, name) {
  save_chart(
    chart[[1]] + chart_labels(chart[[2]], chart[[3]], source_line, width = 8),
    file.path(chart_dir, "output", str_glue("{name}.png")),
    width = 8,
    height = chart[[4]]
  )
})
