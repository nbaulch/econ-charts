library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(stringr)
library(lubridate)
library(ggplot2)

source("R/fetch_nyfed.R")
source("R/fetch_philfed.R")
source("R/chart_style.R")

chart_dir <- "charts/term-premium"

# Each model's 10-year fitted yield splits exactly into a term premium and the
# average short rate the model expects over the next 10 years.
acm <- fetch_nyfed_acm() |>
  transmute(date, model = "acm", yield = acmy10, term_premium = acmtp10)

kim_wright <- tidyusmacro::getFRED(yield = "THREEFY10", term_premium = "THREEFYTP10") |>
  filter(!is.na(term_premium)) |>
  mutate(model = "kim_wright")

decompositions <- bind_rows(acm, kim_wright) |>
  mutate(expected_short_rates = yield - term_premium) |>
  select(date, model, yield, expected_short_rates, term_premium) |>
  arrange(model, date)

# Neither source dates its releases, so the snapshot is named by the fetch date.
write_csv(
  filter(decompositions, year(date) >= 1990),
  file.path(chart_dir, "data", str_glue("term_premium_models_{today()}.csv"))
)

# Kim-Wright is posted with a lag of a week or so; compare both models on the
# latest date they share, against the same date one and two years earlier.
latest_date <- decompositions |>
  summarise(latest = max(date), .by = model) |>
  pull(latest) |>
  min()

value_on <- \(target) decompositions |>
  filter(date <= target) |>
  slice_max(date, by = model)

periods <- tribble(
  ~period, ~start,
  "past_year", latest_date - years(1),
  "past_two_years", latest_date - years(2)
)

changes <- periods |>
  rowwise() |>
  reframe(period, start, value_on(start)) |>
  pivot_longer(c(yield, expected_short_rates, term_premium), names_to = "part", values_to = "start_value") |>
  select(-date) |>
  inner_join(
    value_on(latest_date) |>
      pivot_longer(c(yield, expected_short_rates, term_premium), names_to = "part", values_to = "latest_value") |>
      select(-date),
    by = c("model", "part")
  ) |>
  mutate(change = latest_value - start_value)

decompositions |>
  pivot_wider(names_from = model, values_from = c(yield, expected_short_rates, term_premium)) |>
  filter(year(date) >= 1990) |>
  arrange(date) |>
  mutate(across(-date, \(x) round(x, 3))) |>
  write_csv(file.path(chart_dir, "output", "term-premium.csv"), na = "")

# Forecasters are asked about the next 10 years only in first-quarter surveys.
bill_rate_forecasts <- fetch_philfed_spf_median("BILL10") |>
  filter(!is.na(median))

write_csv(bill_rate_forecasts, file.path(chart_dir, "data", str_glue("philfed_spf_bill10_{today()}.csv")))

latest_forecasts <- slice_tail(bill_rate_forecasts, n = 2)

change_in <- \(which_model, which_period, which_part) changes |>
  filter(model == which_model, period == which_period, part == which_part) |>
  pull(change)

points <- \(x) format(round(x, 2), nsmall = 2)

market_yield <- tidyusmacro::getFRED(yield = "DGS10") |>
  filter(!is.na(yield))

value_on_market <- \(target) market_yield |>
  filter(date <= target) |>
  slice_max(date) |>
  pull(yield)

two_year_term_premium <- c(
  change_in("acm", "past_two_years", "term_premium"),
  change_in("kim_wright", "past_two_years", "term_premium")
)

models <- c(acm = "New York Fed", kim_wright = "Fed Board")
parts <- tribble(
  ~part, ~label, ~colour,
  "term_premium", "Term premium", chart_colors[["orange"]],
  "expected_short_rates", "Expected short-term rates", chart_colors[["blue"]]
)

latest_label <- format(latest_date, "%B %-d, %Y")
year_ago_label <- format(latest_date - years(1), "%B %Y")
two_years_ago_label <- format(latest_date - years(2), "%B %Y")

write_chart_lead(
  str_glue(
    "From {year_ago_label} to {latest_label}, the 10-year Treasury yield rose from ",
    "{format(value_on_market(latest_date - years(1)), nsmall = 2)} to {format(value_on_market(latest_date), nsmall = 2)} ",
    "percent. The New York Fed's model attributes {points(change_in('acm', 'past_year', 'expected_short_rates'))} ",
    "point of the rise to higher expected short-term rates and {points(change_in('acm', 'past_year', 'term_premium'))} ",
    "to the term premium. The Fed Board's model attributes ",
    "{points(change_in('kim_wright', 'past_year', 'expected_short_rates'))} to expected rates and ",
    "{points(change_in('kim_wright', 'past_year', 'term_premium'))} to the term premium. Over two years, the models ",
    "agree that the term premium rose {points(min(two_year_term_premium))} to {points(max(two_year_term_premium))} point."
  ),
  file.path(chart_dir, "output", "term-premium-lead.md")
)

write_chart_notes(
  notes = c(
    str_c(
      "**Expected short-term rates:** The average short-term interest rate over the next 10 years that the model ",
      "infers investors expect. Mostly expected Federal Reserve policy."
    ),
    str_c(
      "**Term premium:** The extra yield investors require to hold a 10-year bond rather than roll over short-term ",
      "bills. It rises with uncertainty and with how much debt investors have to absorb. It can't be observed; each ",
      "model estimates it as what is left after its estimate of expected rates."
    ),
    str_glue(
      "**New York Fed model:** Adrian, Crump, and Moench, estimated from Treasury yields alone. ",
      "**Fed Board model:** Kim and Wright, which also uses professional forecasters' predictions of short-term ",
      "rates. Forecasters' expected average Treasury bill rate over the next 10 years went from ",
      "{format(round(latest_forecasts$median[1], 1), nsmall = 1)} percent in early {year(latest_forecasts$survey[1])} to ",
      "{format(round(latest_forecasts$median[2], 1), nsmall = 1)} percent in early {year(latest_forecasts$survey[2])}, so a ",
      "model that follows them assigns more of a rise in yields to the term premium."
    ),
    "The bars for each model add up to the change in its fitted 10-year yield, which is close to the market yield."
  ),
  source = str_glue(
    "Sources: Federal Reserve Bank of New York, [Treasury term premia]",
    "(https://www.newyorkfed.org/research/data_indicators/term-premia-tabs) (Tobias Adrian, Richard Crump, and ",
    "Emanuel Moench); Federal Reserve Board, three-factor term structure model (Don Kim and Jonathan Wright), and ",
    "10-year Treasury yield, from FRED; Federal Reserve Bank of Philadelphia, Survey of Professional Forecasters. ",
    "Data through {latest_label}."
  ),
  csv_path = file.path(chart_dir, "output", "term-premium.csv"),
  path = file.path(chart_dir, "output", "term-premium-notes.md")
)

period_labels <- c(past_year = "Past year", past_two_years = "Past two years")

bars <- changes |>
  filter(part != "yield") |>
  mutate(
    model = factor(models[model], levels = models),
    period = factor(period_labels[period], levels = period_labels),
    part = factor(part, levels = parts$part)
  )

term_premium_chart <- ggplot(bars, aes(model, change)) +
  geom_col(aes(fill = part), width = 0.6, colour = "white", linewidth = 0.4) +
  geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  facet_wrap(vars(period)) +
  scale_fill_manual(values = setNames(parts$colour, parts$part), labels = setNames(parts$label, parts$part)) +
  scale_y_continuous(breaks = scales::breaks_width(0.25)) +
  theme_chart() +
  theme(
    strip.text = element_text(hjust = 0, size = rel(0.95), colour = chart_greys[["text"]])
  )

title <- "Two Fed models disagree on why long-term yields rose this year"
subtitle <- str_glue("Change in the 10-year Treasury yield and its parts to {format(latest_date, '%B %Y')}, by model, percentage points")
source_line <- str_glue(
  "Sources: Federal Reserve Bank of New York (Adrian, Crump, and Moench); Federal Reserve Board (Kim and Wright). ",
  "Data through {latest_label}."
)

save_chart(
  term_premium_chart + chart_labels(title, subtitle, source_line, width = 8),
  file.path(chart_dir, "output", "term-premium.png"),
  width = 8,
  height = 5
)

save_chart(
  term_premium_chart +
    chart_labels(title, subtitle, source_line, width = 4.2) +
    guides(fill = guide_legend(ncol = 1)) +
    theme(axis.text.x = element_text(size = rel(0.85))),
  file.path(chart_dir, "output", "term-premium-narrow.png"),
  width = 4.2,
  height = 6.4
)
