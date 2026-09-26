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

# Wraps the title, subtitle, and short source line to fit a chart `width`
# inches wide. The characters per inch match the text sizes in theme_chart().
# Definitions and the full source go on the page instead; see write_chart_notes().
chart_labels <- function(title, subtitle, source, width) {
  text_width <- width - 0.4
  labs(
    title = stringr::str_wrap(title, floor(text_width * 8.5)),
    subtitle = stringr::str_wrap(subtitle, floor(text_width * 12)),
    caption = stringr::str_wrap(source, floor(text_width * 14.5))
  )
}

# Notes shown as text under the chart on the site, where they stay readable at
# any screen size. `notes` is a vector of Markdown paragraphs; the topic page
# includes the file.
write_chart_notes <- function(notes, path) {
  writeLines(c("::: {.chart-notes}", "", stringr::str_c(notes, collapse = "\n\n"), "", ":::"), path)
}

save_chart <- function(plot, path, width, height) {
  ggsave(path, plot, device = ragg::agg_png, width = width, height = height, dpi = 200)
}
