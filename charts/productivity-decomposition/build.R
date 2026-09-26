library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(stringr)
library(lubridate)
library(slider)
library(ggplot2)

source("R/fetch_sffed.R")
source("charts/productivity-decomposition/contributions.R")

chart_dir <- "charts/productivity-decomposition"

tfp_path <- fetch_sffed_tfp(file.path(chart_dir, "data"))
release_date <- read_sffed_release_date(tfp_path)

contributions <- tfp_path |>
  read_sffed_tfp() |>
  labor_productivity_contributions() |>
  filter(!is.na(four_quarter_mean))

write_csv(contributions, file.path(chart_dir, "output", "contributions.csv"))

component_labels <- c(
  deepening = "Capital deepening and labor composition",
  tfp_util_adjusted = "Utilization-adjusted TFP",
  utilization = "Utilization"
)
component_colors <- c(
  deepening = "#1baf7a",
  tfp_util_adjusted = "#2a78d6",
  utilization = "#eb6834"
)

recent <- filter(contributions, date >= ymd("2022-01-01"))

productivity_chart <- ggplot(recent, aes(date, four_quarter_mean)) +
  geom_col(
    data = filter(recent, series != "labor_productivity"),
    aes(fill = series),
    width = 75,
    colour = "white",
    linewidth = 0.4
  ) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_point(
    data = filter(recent, series == "labor_productivity"),
    aes(colour = "Labor productivity growth"),
    size = 2.5
  ) +
  scale_fill_manual(
    values = component_colors,
    labels = component_labels,
    breaks = names(component_labels)
  ) +
  scale_colour_manual(values = "black") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  guides(fill = guide_legend(order = 1, ncol = 1)) +
  labs(
    title = "Most recent labor productivity growth comes from higher utilization, not TFP",
    subtitle = "Contributions to U.S. business sector labor productivity growth, four-quarter average, percentage points",
    caption = str_glue(
      "Source: Federal Reserve Bank of San Francisco, Fernald quarterly utilization-adjusted TFP, release of {format(release_date, '%B %-d, %Y')}.\n",
      "Series: dLP, dk, dhours, dLQ, alpha, dutil, dtfp_util. Deepening is alpha * (dk - dhours) + (1 - alpha) * dLQ.\n",
      "Based on Ernie Tedeschi, \"AI and Productivity,\" Stripe Economics, July 2026."
    ),
    x = NULL,
    y = NULL,
    fill = NULL,
    colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, colour = "grey30", size = 8),
    plot.title = element_text(face = "bold")
  )

ggsave(
  file.path(chart_dir, "output", "productivity-decomposition.png"),
  productivity_chart,
  device = ragg::agg_png,
  width = 9,
  height = 6,
  dpi = 200,
  bg = "white"
)
