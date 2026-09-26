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
  semiconductor_imports_real = "LB001145"
)

nipa <- fetch_bea_nipa(nipa_series)

# BEA's flat files don't carry a release date, so the snapshot is named by the
# fetch date and records the latest quarter it covers.
write_csv(nipa, file.path(chart_dir, "data", str_glue("bea_nipa_{today()}.csv")))

contributions <- ai_investment_contributions(nipa) |>
  filter(!is.na(net))

contributions |>
  transmute(
    quarter_end = date,
    software,
    computers,
    data_centers,
    power,
    computer_net_exports,
    ai_investment_gross = gross,
    ai_investment_net_of_computer_trade = net
  ) |>
  mutate(across(-quarter_end, \(x) round(x, 3))) |>
  write_csv(file.path(chart_dir, "output", "ai-investment-gdp.csv"))

# In stacking order, top to bottom, so the legend and notes read like the bars.
components <- tribble(
  ~series, ~label, ~colour, ~definition,
  "data_centers_and_power", "Data centers and power", chart_colors[["orange"]],
  "Construction of data centers and of electric power and other power facilities.",
  "software", "Software", chart_colors[["purple"]],
  "Business investment in software, both purchased and developed in house.",
  "computers", "Computers", chart_colors[["teal"]],
  "Business investment in computers and peripheral equipment.",
  "computer_net_exports", "Net trade in computers", chart_colors[["red"]],
  "Exports minus imports of computers and parts, counting only the capital goods share of trade."
)

latest_quarter <- max(contributions$date)
past_year <- slice_tail(contributions, n = 4)
offset_share <- \(past_year) round(100 * (1 - mean(past_year$net) / mean(past_year$gross)))

# The FEDS weight uses goods trade overall; this one is specific to computers.
past_year_computer_weight <- ai_investment_contributions(nipa, domestic_use_weights(nipa)) |>
  semi_join(past_year, by = "date")

past_year_investment_price <- nipa |>
  deflate_trade_with_investment_price() |>
  ai_investment_contributions() |>
  semi_join(past_year, by = "date")

quarter_label <- str_glue("{year(latest_quarter)} Q{quarter(latest_quarter)}")

notes <- c(
  str_glue("**{components$label}:** {components$definition}"),
  str_glue(
    "Over the four quarters through {quarter_label}, AI-related investment added ",
    "{round(mean(past_year$gross), 2)} point a year to growth before computer trade and ",
    "{round(mean(past_year$net), 2)} after, so trade offset {offset_share(past_year)} percent. Counting computer trade ",
    "by businesses' share of U.S. spending on computers puts the offset at {offset_share(past_year_computer_weight)} ",
    "percent, and valuing it at the prices of business investment in computers puts it at ",
    "{offset_share(past_year_investment_price)} percent."
  ),
  # Specific to 2026 Q2; see the import price check in the spec. Revisit on refresh.
  str_c(
    "In 2026 Q2, computer trade added to growth even though spending on imported computers rose, because import ",
    "prices rose about twice as fast as prices of business investment in computers."
  ),
  str_glue(
    "Source: Bureau of Economic Analysis, National Income and Product Accounts, data through {quarter_label}. ",
    "Method from Paul E. Soto, Mason Thieu, and Jeffrey S. Allen, [\"The AI Buildout and the Economy\"]",
    "(https://www.federalreserve.gov/econres/notes/feds-notes/the-ai-buildout-and-the-economy-publicly-available-data-to-assess-ais-impact-20260717.html), ",
    "FEDS Notes, Federal Reserve Board, July 2026."
  )
)

write_chart_notes(notes, file.path(chart_dir, "output", "ai-investment-gdp-notes.md"))

source_line <- str_glue(
  "Source: Bureau of Economic Analysis, data through {quarter_label}. ",
  "Method from Soto, Thieu, and Allen, FEDS Notes, July 2026."
)

recent <- contributions |>
  filter(date >= ymd("2022-01-01")) |>
  mutate(data_centers_and_power = data_centers + power)

bars <- recent |>
  select(date, all_of(components$series)) |>
  pivot_longer(-date, names_to = "series", values_to = "contribution") |>
  mutate(series = factor(series, levels = components$series))

investment_chart <- ggplot(bars, aes(date, contribution)) +
  geom_col(aes(fill = series), width = 75, colour = "white", linewidth = 0.4) +
  geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
  geom_point(
    data = recent,
    aes(y = net, shape = "Total, net of computer trade"),
    colour = chart_greys[["title"]],
    size = 2.3
  ) +
  scale_fill_manual(
    values = setNames(components$colour, components$series),
    labels = setNames(components$label, components$series)
  ) +
  scale_shape_manual(values = 16) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(breaks = scales::breaks_width(0.5)) +
  guides(shape = guide_legend(order = 2)) +
  theme_chart()

title <- "Computer imports offset a third to a half of the AI buildout's boost to growth"
subtitle <- "Contributions of AI-related investment to annualized real GDP growth, percentage points"

save_chart(
  investment_chart +
    chart_labels(title, subtitle, source_line, width = 10) +
    guides(fill = guide_legend(nrow = 1, order = 1)),
  file.path(chart_dir, "output", "ai-investment-gdp.png"),
  width = 10,
  height = 5.4
)

save_chart(
  investment_chart +
    chart_labels(title, subtitle, source_line, width = 4.2) +
    guides(fill = guide_legend(ncol = 1, order = 1)) +
    theme(legend.box = "vertical", legend.spacing.y = unit(2, "pt")),
  file.path(chart_dir, "output", "ai-investment-gdp-narrow.png"),
  width = 4.2,
  height = 7.2
)
