library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)
library(ggplot2)
library(purrr)

source("R/fetch_census.R")
source("R/chart_style.R")

chart_dir <- "charts/goods-balance"
from <- ymd("2017-01-01")
store <- "https://github.com/nbaulch/econ-charts/releases/download/census-trade-data"

# Census end-use categories, except gold. Census files gold bars under 7115
# ("articles of precious metal") in finished metal shapes, not nonmonetary
# gold, so gold is taken from the product codes and their descriptions.
categories <- c(
  computers = "Computers and parts",
  chips_telecom = "Semiconductors and telecom equipment",
  pharmaceuticals = "Pharmaceuticals",
  gold = "Gold",
  other = "All other goods"
)

category_of <- function(commodity, description, end_use) {
  case_when(
    str_starts(commodity, "7108") | (str_starts(commodity, "7115") & str_detect(description, "GOLD")) ~ "gold",
    end_use %in% c("21300", "21301") ~ "computers",
    end_use %in% c("21320", "21400") ~ "chips_telecom",
    end_use == "40100" ~ "pharmaceuticals",
    .default = "other"
  )
}

# Codes change each January, so each year is classified with its own list.
product_categories <- expand_grid(flow = c("imports", "exports"), year = year(from):year(today())) |>
  pmap(\(flow, year) {
    read_csv(str_glue("{store}/{flow}-codes-{year}.csv"), col_types = cols(.default = "c")) |>
      transmute(flow, year, commodity, category = category_of(commodity, description, end_use))
  }) |>
  list_rbind()

# General imports and total exports, the Census basis of the monthly trade
# release.
trade_by_product <- list(imports = "gen_val", exports = "all_val") |>
  imap(\(value, flow) {
    read_census_trade(flow, from) |>
      select(date, commodity, value = all_of(value)) |>
      summarise(value = sum(value), .by = c(date, commodity)) |>
      collect() |>
      mutate(flow, year = year(date))
  }) |>
  list_rbind()

trade_by_category <- trade_by_product |>
  left_join(product_categories, by = c("flow", "year", "commodity")) |>
  summarise(value = sum(value) / 1e9, .by = c(date, flow, category)) |>
  arrange(date, flow, category)

latest_month <- max(trade_by_category$date)
write_csv(trade_by_category, file.path(chart_dir, "data", str_glue("census_trade_by_category_{latest_month}.csv")))

balance_by_category <- trade_by_category |>
  pivot_wider(names_from = flow, values_from = value, values_fill = 0) |>
  transmute(date, category, balance = exports - imports) |>
  pivot_wider(names_from = category, values_from = balance) |>
  select(date, all_of(names(categories))) |>
  mutate(total = rowSums(pick(-date)))

balance_by_category |>
  mutate(across(-date, \(x) round(x, 3))) |>
  write_csv(file.path(chart_dir, "output", "goods-balance.csv"))

month_label <- format(latest_month, "%B %Y")

write_chart_notes(
  notes = c(
    "**Computers and parts:** Computers, and their accessories and parts, as Census classifies them by end use.",
    "**Semiconductors and telecom equipment:** Semiconductors, and telecommunications equipment such as network switches.",
    "**Pharmaceuticals:** Medicines, vaccines and blood products, and hormones in bulk, such as insulin and the active ingredients of weight-loss drugs.",
    "**Gold:** Nonmonetary gold, including gold bars classed as articles of precious metal.",
    "**All other goods:** Everything else."
  ),
  source = str_glue(
    "Source: Census Bureau, U.S. imports and exports of merchandise by product, through {month_label}, not ",
    "seasonally adjusted. Exports less general imports."
  ),
  csv_path = file.path(chart_dir, "output", "goods-balance.csv"),
  path = file.path(chart_dir, "output", "goods-balance-notes.md")
)

balance_chart_data <- balance_by_category |>
  filter(date >= ymd("2019-01-01"))

balance_chart <- balance_chart_data |>
  pivot_longer(all_of(names(categories)), names_to = "category", values_to = "balance") |>
  mutate(category = factor(categories[category], levels = categories)) |>
  ggplot(aes(date, balance)) +
  # The named products sit next to zero, where their bars share a baseline.
  geom_col(aes(fill = category), width = 25, position = position_stack(reverse = TRUE)) +
  geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  geom_point(data = balance_chart_data, aes(y = total), size = 0.9, colour = chart_greys[["title"]]) +
  scale_fill_manual(values = unname(chart_colors[c("blue", "teal", "orange", "gold", "grey")])) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(breaks = scales::breaks_width(50)) +
  theme_chart()

title <- "U.S. goods trade balance by product"
subtitle <- "Exports less imports, billions of dollars a month; dots show the total"
source_line <- "Source: Census Bureau."

save_chart(
  balance_chart + chart_labels(title, subtitle, source_line, width = 8) + guides(fill = guide_legend(nrow = 2)),
  file.path(chart_dir, "output", "goods-balance.png"),
  width = 8,
  height = 5.5
)

save_chart(
  balance_chart + chart_labels(title, subtitle, source_line, width = 4.2) + guides(fill = guide_legend(ncol = 1)),
  file.path(chart_dir, "output", "goods-balance-narrow.png"),
  width = 4.2,
  height = 6
)
