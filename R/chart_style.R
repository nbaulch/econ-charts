# House chart style. STYLE.md explains the choices.

chart_colors <- c(
  blue = "#1f6fb2",
  orange = "#d9731f",
  teal = "#1a9a8a",
  red = "#c8453c",
  purple = "#7b5ea7",
  gold = "#d4a62a",
  grey = "#b8b6b0"
)

chart_greys <- c(
  title = "#222220",
  text = "#4a4a47",
  muted = "#75746f",
  baseline = "#3a3a38",
  grid = "#e6e5e1"
)

# Bundled so charts render the same on any machine without installing fonts.
# Registered under its own name so it can't clash with an installed Roboto.
systemfonts::register_font(
  "Roboto Chart",
  plain = "fonts/Roboto-Regular.ttf",
  bold = "fonts/Roboto-Bold.ttf"
)

theme_chart <- function(base_size = 12) {
  theme_minimal(base_size = base_size, base_family = "Roboto Chart") +
    theme(
      text = element_text(colour = chart_greys[["text"]]),
      plot.title = element_text(
        face = "bold",
        size = rel(1.45),
        colour = chart_greys[["title"]],
        margin = margin(b = 6)
      ),
      plot.subtitle = element_text(size = rel(1.05), margin = margin(b = 14)),
      plot.caption = element_text(
        size = rel(0.85),
        colour = chart_greys[["muted"]],
        hjust = 0,
        lineheight = 1.3,
        margin = margin(t = 16)
      ),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      axis.title = element_blank(),
      axis.text = element_text(size = rel(0.9), colour = chart_greys[["muted"]]),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_line(colour = chart_greys[["grid"]], linewidth = 0.35),
      legend.position = "top",
      legend.location = "plot",
      legend.justification = "left",
      legend.title = element_blank(),
      legend.text = element_text(size = rel(0.9)),
      legend.key.size = unit(0.9, "lines"),
      legend.margin = margin(b = 4),
      plot.margin = margin(18, 18, 12, 18),
      plot.background = element_rect(fill = "white", colour = NA)
    )
}

save_chart <- function(plot, path, width = 8, height = 6) {
  ggsave(path, plot, device = ragg::agg_png, width = width, height = height, dpi = 200)
}
