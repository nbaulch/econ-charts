library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(stringr)
library(lubridate)
library(slider)
library(ggplot2)

source("R/fetch_sffed.R")
source("R/chart_style.R")
source("charts/productivity-decomposition/contributions.R")

chart_dir <- "charts/productivity-decomposition"

tfp_path <- fetch_sffed_tfp(file.path(chart_dir, "data"))
release_date <- read_sffed_release_date(tfp_path)

contributions <- labor_productivity_contributions(
  read_sffed_tfp(tfp_path),
  read_sffed_capital(tfp_path)
) |>
  filter(!is.na(four_quarter_mean))

write_csv(contributions, file.path(chart_dir, "output", "contributions.csv"))

# Listed in stacking order, top to bottom, so the legend reads like the bars.
three_components <- tribble(
  ~series,             ~label,                                          ~colour,
  "deepening",         "Capital deepening and labor composition",       chart_colors[["grey"]],
  "tfp_util_adjusted", "Total factor productivity, utilization-adjusted", chart_colors[["blue"]],
  "utilization",       "Utilization",                                   chart_colors[["orange"]]
)

four_components <- tribble(
  ~series,                ~label,                                          ~colour,
  "other_deepening",      "Other capital deepening and labor composition", chart_colors[["grey"]],
  "it_capital_deepening", "Computer and software capital deepening",       chart_colors[["teal"]],
  "tfp_util_adjusted",    "Total factor productivity, utilization-adjusted", chart_colors[["blue"]],
  "utilization",          "Utilization",                                   chart_colors[["orange"]]
)

definitions <- c(
  utilization = "Utilization is how intensively businesses use the workers and equipment they already have, such as longer workweeks or machines running more hours. It is estimated from hours per worker.",
  tfp = "Total factor productivity, utilization-adjusted, is growth in output that more capital, more skilled labor, and more intensive use of both do not explain. It is the closest measure to technology and efficiency gains.",
  deepening = "Capital deepening is growth in equipment, software, and buildings per hour worked. Labor composition is the shift toward more educated and experienced workers.",
  it_capital = "Computer and software capital deepening covers information processing equipment and software. It includes AI investment but is not limited to it."
)

source_note <- str_glue(
  "Source: John Fernald, Quarterly Utilization-Adjusted Series on Total Factor Productivity, ",
  "Federal Reserve Bank of San Francisco, release of {format(release_date, '%B %-d, %Y')}. ",
  "Chart adapted from Ernie Tedeschi, \"AI and Productivity,\" Stripe Economics, July 2026."
)

caption <- function(notes) {
  c(notes, source_note) |>
    str_wrap(width = 160) |>
    str_c(collapse = "\n")
}

plot_contributions <- function(contributions, components, title, notes) {
  recent <- filter(contributions, date >= ymd("2022-01-01"))

  bars <- recent |>
    filter(series %in% components$series) |>
    mutate(series = factor(series, levels = components$series))

  ggplot(bars, aes(date, four_quarter_mean)) +
    geom_col(aes(fill = series), width = 75, colour = "white", linewidth = 0.4) +
    geom_hline(yintercept = 0, colour = chart_greys[["baseline"]], linewidth = 0.4) +
    geom_point(
      data = filter(recent, series == "labor_productivity"),
      aes(shape = "Labor productivity growth"),
      colour = chart_greys[["title"]],
      size = 2.3
    ) +
    scale_fill_manual(
      values = setNames(components$colour, components$series),
      labels = setNames(components$label, components$series)
    ) +
    scale_shape_manual(values = 16) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    scale_y_continuous(breaks = scales::breaks_width(1)) +
    guides(fill = guide_legend(ncol = 2, byrow = TRUE, order = 1)) +
    labs(
      title = str_wrap(title, width = 75),
      subtitle = "Contributions to growth in U.S. business sector labor productivity, four-quarter average, percentage points",
      caption = caption(notes)
    ) +
    theme_chart()
}

three_bar_chart <- plot_contributions(
  contributions,
  three_components,
  title = "Recent productivity growth comes mostly from working existing equipment and workers harder",
  notes = definitions[c("utilization", "tfp", "deepening")]
)

four_bar_chart <- plot_contributions(
  contributions,
  four_components,
  title = "Recent productivity growth comes from working existing equipment and workers harder and from computer investment, not efficiency gains",
  notes = definitions[c("utilization", "tfp", "deepening", "it_capital")]
)

save_chart(three_bar_chart, file.path(chart_dir, "output", "productivity-decomposition.png"), width = 10, height = 6.8)
save_chart(four_bar_chart, file.path(chart_dir, "output", "productivity-decomposition-it-capital.png"), width = 10, height = 7.2)
