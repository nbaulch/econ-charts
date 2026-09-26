library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)
library(ggplot2)

source("R/fetch_bea.R")
source("R/chart_style.R")
source("charts/ai-investment-gdp/contributions.R")

chart_dir <- "charts/ai-investment-gdp"

# NIPA series codes. Investment is from tables 5.3.5, 5.4.5, and 5.5.5 and their
# chained-dollar versions; trade is from tables 4.2.5B and 4.2.6B. Consumer
# spending on computers (2.4.5U) and final sales of computers (1.2.5) are for
# a second trade weight, reported in the notes. Semiconductor trade is for
# `semiconductors.R`.
nipa_series <- c(
  gdp_nominal = "A191RC",
  gdp_real = "A191RX",
  software_nominal = "B985RC",
  software_real = "B985RX",
  computers_nominal = "B935RC",
  computers_real = "B935RX",
  data_centers_nominal = "LA001282",
  data_centers_real = "LB001282",
  power_nominal = "W028RC",
  power_real = "W028RX",
  computer_exports_nominal = "B850RC",
  computer_exports_real = "B850RX",
  computer_imports_nominal = "B852RC",
  computer_imports_real = "B852RX",
  capital_goods_exports = "A640RC",
  consumer_goods_exports = "A642RC",
  capital_goods_imports = "A650RC",
  consumer_goods_imports = "A652RC",
  consumer_computers = "DCPPRC",
  computer_final_sales = "BB01RC",
  semiconductor_exports_nominal = "LA001105",
  semiconductor_exports_real = "LB001105",
  semiconductor_imports_nominal = "LA001145",
  semiconductor_imports_real = "LB001145",
  gdp_growth = "A191RL"
)

nipa <- fetch_bea_nipa(nipa_series)

# BEA's flat files don't carry a release date, so the snapshot is named by the
# fetch date and records the latest quarter it covers.
write_csv(nipa, file.path(chart_dir, "data", str_glue("bea_nipa_{today()}.csv")))

# The two alternatives to the FEDS Note's method, for the range on the chart:
# a trade weight specific to computers, and computer trade priced like business
# investment in computers.
contributions_by_method <- bind_rows(
  fed = ai_investment_contributions(nipa),
  computer_weight = ai_investment_contributions(nipa, domestic_use_weights(nipa)),
  investment_price = ai_investment_contributions(deflate_trade_with_investment_price(nipa)),
  .id = "method"
) |>
  filter(!is.na(net))

# Quarterly contributions swing widely, so the chart averages over four quarters.
four_quarter_average <- \(x) (x + lag(x) + lag(x, 2) + lag(x, 3)) / 4

averages <- contributions_by_method |>
  mutate(across(software:net, four_quarter_average), .by = method) |>
  filter(date >= ymd("2022-03-01"))

contributions <- averages |>
  filter(method == "fed") |>
  inner_join(
    summarise(averages, net_low = min(net), net_high = max(net), .by = date),
    by = "date"
  )

latest_quarter <- max(contributions$date)
quarter_label <- str_glue("{year(latest_quarter)} Q{quarter(latest_quarter)}")

latest <- filter(contributions, date == latest_quarter)
before_the_boom <- filter(contributions, date == ymd("2023-12-01"))
gdp_growth <- nipa |>
  filter(date > latest_quarter %m-% months(12), date <= latest_quarter) |>
  pull(gdp_growth) |>
  mean()

contributions |>
  transmute(
    quarter_end = date,
    software,
    computers,
    data_centers,
    power,
    computer_net_exports,
    total = gross,
    total_net_of_computer_trade = net,
    net_lowest = net_low,
    net_highest = net_high
  ) |>
  mutate(across(-quarter_end, \(x) round(x, 3))) |>
  write_csv(file.path(chart_dir, "output", "ai-investment-gdp.csv"))

# The four components carry the AI buildout but aren't all AI, so the text names
# them rather than calling the total AI investment.
write_chart_lead(
  str_glue(
    "Investment in software, computers, data centers, and power\u2014the spending that carries the AI buildout\u2014has ",
    "lifted real GDP growth since early 2025, but by less than headline figures suggest because many of the ",
    "computers are imported. Over the past four quarters, this investment added {round(latest$gross, 2)} percentage ",
    "point to real GDP growth of {format(round(gdp_growth, 1), nsmall = 1)} percent. Net of imported computers and ",
    "parts, it added {round(latest$net, 2)} point, and as little as {round(latest$net_low, 2)} under other reasonable ",
    "assumptions. In 2023, before the buildout, it added about {round(before_the_boom$gross, 1)} point with or ",
    "without imports."
  ),
  file.path(chart_dir, "output", "ai-investment-gdp-lead.md")
)

lines <- tribble(
  ~series, ~label, ~colour, ~definition,
  "gross", "Before netting imports", chart_greys[["muted"]],
  "Business investment in software, computers, data centers, and power.",
  "net", "Net of imported computers", chart_colors[["blue"]],
  "Subtracts computer imports minus exports, counting only the share that goes to business.",
  "range", "Range under other assumptions", chart_colors[["blue"]],
  "Estimates that share from U.S. computer spending, or prices imports like the computers businesses buy."
)

write_chart_notes(
  notes = str_glue("**{lines$label}:** {lines$definition}"),
  source = str_glue(
    "Source: Bureau of Economic Analysis, through {quarter_label}. Method from Soto, Thieu, and Allen, ",
    "[\"The AI Buildout and the Economy\"]",
    "(https://www.federalreserve.gov/econres/notes/feds-notes/the-ai-buildout-and-the-economy-publicly-available-data-to-assess-ais-impact-20260717.html), ",
    "FEDS Notes, July 2026."
  ),
  csv_path = file.path(chart_dir, "output", "ai-investment-gdp.csv"),
  path = file.path(chart_dir, "output", "ai-investment-gdp-notes.md")
)

investment_chart <- ggplot(contributions, aes(date)) +
  geom_ribbon(aes(ymin = net_low, ymax = net_high, fill = "range"), alpha = 0.25) +
  geom_line(aes(y = gross, colour = "gross"), linewidth = 0.9) +
  geom_line(aes(y = net, colour = "net"), linewidth = 0.9) +
  geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  scale_colour_manual(
    values = setNames(lines$colour[1:2], lines$series[1:2]),
    labels = setNames(lines$label[1:2], lines$series[1:2])
  ) +
  scale_fill_manual(values = c(range = chart_colors[["blue"]]), labels = c(range = lines$label[3])) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(limits = c(0, NA), breaks = scales::breaks_width(0.2), expand = expansion(mult = c(0, 0.05))) +
  guides(colour = guide_legend(order = 1), fill = guide_legend(order = 2)) +
  theme_chart()

title <- "Computer imports offset a third to a half of the AI buildout's boost to growth"
subtitle <- "Contribution to real GDP growth, average over four quarters, percentage points"
source_line <- str_glue(
  "Source: Bureau of Economic Analysis, data through {quarter_label}. ",
  "Method from Soto, Thieu, and Allen, FEDS Notes, July 2026."
)

save_chart(
  investment_chart + chart_labels(title, subtitle, source_line, width = 8),
  file.path(chart_dir, "output", "ai-investment-gdp.png"),
  width = 8,
  height = 5
)

save_chart(
  investment_chart +
    chart_labels(title, subtitle, source_line, width = 4.2) +
    guides(colour = guide_legend(ncol = 1, order = 1)) +
    theme(legend.box = "vertical", legend.spacing.y = unit(2, "pt")),
  file.path(chart_dir, "output", "ai-investment-gdp-narrow.png"),
  width = 4.2,
  height = 6.8
)
