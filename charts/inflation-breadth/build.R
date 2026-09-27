library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(stringr)
library(lubridate)
library(ggplot2)

source("R/fetch_bea.R")
source("R/fetch_dallasfed.R")
source("R/chart_style.R")

chart_dir <- "charts/inflation-breadth"
threshold <- 3

# PCE prices by category, NIPA table 2.4.4U. Lines past 369 repeat categories
# in other groupings.
prices <- fetch_bea_nipa_tables("U20404") |>
  filter(line <= 369)
components <- fetch_dallasfed_trimmed_mean_components()

# BEA labels carry footnote numbers, such as "Electricity (27)", that the Dallas
# Fed's names drop.
match_key <- \(label) label |>
  str_remove("\\s*\\([^)]*\\)\\s*$") |>
  str_remove_all("[^A-Za-z0-9 ,]") |>
  str_squish() |>
  str_to_lower()

# Three nonprofit categories appear twice in the table; the first is the
# category itself.
component_lines <- components |>
  mutate(key = match_key(category)) |>
  inner_join(distinct(prices, line, code, label) |> mutate(key = match_key(label)), by = "key") |>
  slice_min(line, by = category, with_ties = FALSE) |>
  select(category, line, code)

component_prices <- prices |>
  semi_join(component_lines, by = "line") |>
  select(code, date, price = value)

latest_month <- max(component_prices$date)
list(
  bea_pce_prices = component_prices |>
    filter(date >= ymd("1999-01-01")) |>
    pivot_wider(names_from = code, values_from = price),
  dallasfed_components = components
) |>
  purrr::iwalk(\(data, name) write_csv(data, file.path(chart_dir, "data", str_glue("{name}_{latest_month}.csv"))))

# Warsh's measure counts categories equally, whatever their share of spending.
breadth <- component_prices |>
  arrange(date) |>
  mutate(
    twelve_month = 100 * (price / lag(price, 12) - 1),
    six_month = 100 * ((price / lag(price, 6))^2 - 1),
    .by = code
  ) |>
  filter(!is.na(twelve_month)) |>
  summarise(
    twelve_month = 100 * mean(twelve_month > threshold),
    six_month = 100 * mean(six_month > threshold),
    categories = n(),
    .by = date
  )

breadth |>
  filter(date >= ymd("2000-01-01")) |>
  mutate(across(c(twelve_month, six_month), \(x) round(x, 1))) |>
  write_csv(file.path(chart_dir, "output", "inflation-breadth.csv"))

latest <- filter(breadth, date == latest_month)
before_pandemic <- breadth |>
  filter(between(year(date), 2000, 2019)) |>
  summarise(mean(twelve_month)) |>
  pull()
high_before_2021 <- slice_max(filter(breadth, between(year(date), 2000, 2020)), twelve_month, n = 1)
peak <- slice_max(filter(breadth, year(date) >= 2021), twelve_month, n = 1)
low_since_2024 <- slice_min(filter(breadth, year(date) >= 2024), twelve_month, n = 1)
month_label <- format(latest_month, "%B %Y")
whole <- \(x) round(x)

write_chart_lead(
  str_glue(
    "Price increases have broadened since early 2025. In {month_label}, prices of ",
    "{whole(latest$twelve_month)} percent of the {latest$categories} categories of consumer spending were up more ",
    "than {threshold} percent from a year earlier, compared with {whole(low_since_2024$twelve_month)} percent in ",
    "{format(low_since_2024$date, '%B %Y')}. That is more than in any month from 2000 to 2020, when the high was ",
    "{whole(high_before_2021$twelve_month)} percent in {year(high_before_2021$date)}, though well below the ",
    "{whole(peak$twelve_month)} percent reached in {format(peak$date, '%B %Y')}. Kevin Warsh ",
    "[pointed to this measure](https://www.federalreserve.gov/newsevents/speech/warsh20260828a.htm) at Jackson ",
    "Hole in August."
  ),
  file.path(chart_dir, "output", "inflation-breadth-lead.md")
)

write_chart_notes(
  notes = c(
    str_glue(
      "**Share of categories:** The share of the {latest$categories} categories of consumer spending in the Dallas ",
      "Fed's trimmed mean whose prices rose more than {threshold} percent over the past 12 months. Each category ",
      "counts equally, whatever its share of spending."
    ),
    "**Dashed line:** The average from 2000 to 2019."
  ),
  source = str_glue(
    "Source: Bureau of Economic Analysis, PCE prices by category, through {month_label}; categories from the ",
    "Federal Reserve Bank of Dallas, [trimmed mean PCE](https://www.dallasfed.org/research/pce). The measure follows ",
    "Kevin Warsh, [\"Remarks\"](https://www.federalreserve.gov/newsevents/speech/warsh20260828a.htm), Jackson Hole, ",
    "August 28, 2026."
  ),
  csv_path = file.path(chart_dir, "output", "inflation-breadth.csv"),
  path = file.path(chart_dir, "output", "inflation-breadth-notes.md")
)

breadth_chart <- ggplot(filter(breadth, date >= ymd("2000-01-01")), aes(date, twelve_month)) +
  geom_hline(yintercept = before_pandemic, colour = chart_greys[["muted"]], linetype = "dashed", linewidth = 0.4) +
  # Placed over the mid-2010s, when the share ran below the average.
  annotate(
    "text",
    x = ymd("2012-09-01"), y = before_pandemic + 1.5, label = "2000 to 2019 average",
    hjust = 0, vjust = 0, size = 3.2, colour = chart_greys[["muted"]], family = "Roboto Chart"
  ) +
  geom_line(colour = chart_colors[["blue"]], linewidth = 0.9) +
  scale_x_date(date_breaks = "4 years", date_labels = "%Y") +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20), expand = expansion(mult = c(0, 0.02))) +
  theme_chart()

title <- str_glue("More than half of prices are rising faster than {threshold} percent, more than at any time before 2021")
subtitle <- str_glue("Share of consumer spending categories with prices up more than {threshold} percent over 12 months, percent")
source_line <- "Source: Bureau of Economic Analysis, with categories from the Federal Reserve Bank of Dallas."

save_chart(
  breadth_chart + chart_labels(title, subtitle, source_line, width = 8),
  file.path(chart_dir, "output", "inflation-breadth.png"),
  width = 8,
  height = 5
)

save_chart(
  breadth_chart + chart_labels(title, subtitle, source_line, width = 4.2),
  file.path(chart_dir, "output", "inflation-breadth-narrow.png"),
  width = 4.2,
  height = 5.5
)
