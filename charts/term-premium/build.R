library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)
library(ggplot2)

source("R/fetch_frb.R")
source("R/chart_style.R")

chart_dir <- "charts/term-premium"

# The model splits the fitted 10-year zero-coupon yield into four parts that add
# up to it. The TIPS liquidity premium belongs to inflation compensation, not
# the nominal yield, so it is left out.
dkw <- fetch_frb_dkw() |>
  transmute(
    date,
    yield = nominal_yield_fitted_10,
    real_rate = exp_real_short_rate_10,
    real_term_premium = real_term_prem_10,
    expected_inflation = exp_inflation_10,
    inflation_risk_premium = inflation_risk_prem_10
  ) |>
  filter(!is.na(yield))

# The file carries no release date, so the snapshot is named by its last day.
write_csv(
  filter(dkw, year(date) >= 2015),
  file.path(chart_dir, "data", str_glue("frb_dkw_10_year_{max(dkw$date)}.csv"))
)

# Daily estimates are noisy, so the chart uses monthly averages, measured from
# December 2023, the last month before the term premium's rise.
base_month <- ymd("2023-12-01")

monthly <- dkw |>
  mutate(date = floor_date(date, "month")) |>
  summarise(across(everything(), mean), .by = date)

changes <- monthly |>
  filter(date >= base_month) |>
  mutate(across(-date, \(x) x - x[date == base_month]))

monthly |>
  left_join(changes, by = "date", suffix = c("", "_change_since_december_2023")) |>
  mutate(across(-date, \(x) round(x, 3))) |>
  write_csv(file.path(chart_dir, "output", "term-premium.csv"), na = "")

parts <- tribble(
  ~part, ~label, ~colour, ~definition,
  "real_rate", "Expected real short-term rates", chart_colors[["blue"]],
  "The average short-term interest rate, net of inflation, that investors expect over 10 years.",
  "real_term_premium", "Real term premium", chart_colors[["orange"]],
  "The extra return investors require for the risk that real interest rates change while they hold the bond.",
  "expected_inflation", "Expected inflation", chart_colors[["teal"]],
  "Average inflation investors expect over 10 years.",
  "inflation_risk_premium", "Inflation risk premium", chart_colors[["red"]],
  "The extra return investors require for the risk that inflation turns out different from what they expect. With the real term premium, it makes up the term premium."
)

latest <- slice_max(changes, date)
year_earlier <- monthly |>
  filter(date == latest$date %m-% months(12))
past_year <- slice_max(monthly, date) |>
  mutate(across(-date, \(x) x - year_earlier[[cur_column()]]))

latest_month <- format(latest$date, "%B %Y")
points <- \(x) format(round(x, 2), nsmall = 2)

write_chart_lead(
  str_glue(
    "The 10-year Treasury yield has risen since the end of 2023 mainly because investors want more compensation ",
    "for the risk of holding long-term bonds, rather than because they expect higher interest rates. In the Fed ",
    "Board's ",
    "model, the yield averaged {points(latest$yield)} percentage point more in {latest_month} than in December ",
    "2023. The term premium\u2014the extra return investors require to lock up money for 10 years instead of rolling ",
    "over short-term bills\u2014accounted for {points(latest$real_term_premium + latest$inflation_risk_premium)} point ",
    "of that, and expected inflation {points(latest$expected_inflation)}, while expected real short-term rates ",
    "were little changed. Over the past year, the yield rose {points(past_year$yield)} point: ",
    "{points(past_year$real_rate + past_year$expected_inflation)} from higher expected rates and ",
    "{points(past_year$real_term_premium + past_year$inflation_risk_premium)} from the term premium."
  ),
  file.path(chart_dir, "output", "term-premium-lead.md")
)

write_chart_notes(
  notes = c(
    str_glue("**{parts$label}:** {parts$definition}"),
    "**10-year yield:** The model's estimate of the yield on a 10-year Treasury that pays no coupons."
  ),
  source = str_glue(
    "Source: Federal Reserve Board, D'Amico, Kim, and Wei model, ",
    "[\"Tips from TIPS: Update and Discussions\"]",
    "(https://www.federalreserve.gov/econres/notes/feds-notes/tips-from-tips-update-and-discussions-20190521.html), ",
    "FEDS Notes, updated through {format(max(dkw$date), '%B %-d, %Y')}."
  ),
  csv_path = file.path(chart_dir, "output", "term-premium.csv"),
  path = file.path(chart_dir, "output", "term-premium-notes.md")
)

bars <- changes |>
  select(date, all_of(parts$part)) |>
  pivot_longer(-date, names_to = "part", values_to = "change") |>
  mutate(part = factor(part, levels = parts$part))

term_premium_chart <- ggplot(bars, aes(date, change)) +
  geom_col(aes(fill = part), width = 24, colour = "white", linewidth = 0.2) +
  geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  geom_line(data = changes, aes(y = yield, linetype = "10-year yield"), colour = chart_greys[["title"]], linewidth = 0.8) +
  scale_fill_manual(values = setNames(parts$colour, parts$part), labels = setNames(parts$label, parts$part)) +
  scale_linetype_manual(values = "solid") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(breaks = scales::breaks_width(0.2)) +
  guides(fill = guide_legend(order = 1, nrow = 2), linetype = guide_legend(order = 2)) +
  theme_chart()

title <- "The 10-year yield's rise since 2023 has come mostly from the term premium"
subtitle <- "Change since December 2023 in the 10-year Treasury yield and its parts, monthly average, percentage points"
source_line <- "Source: Federal Reserve Board (D'Amico, Kim, and Wei model)."

save_chart(
  term_premium_chart + chart_labels(title, subtitle, source_line, width = 8),
  file.path(chart_dir, "output", "term-premium.png"),
  width = 8,
  height = 5
)

save_chart(
  term_premium_chart +
    chart_labels(title, subtitle, source_line, width = 4.2) +
    guides(fill = guide_legend(ncol = 1, order = 1)) +
    theme(legend.box = "vertical", legend.spacing.y = unit(2, "pt")),
  file.path(chart_dir, "output", "term-premium-narrow.png"),
  width = 4.2,
  height = 7.2
)
