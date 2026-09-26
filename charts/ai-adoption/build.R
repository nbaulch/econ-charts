library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(stringr)
library(lubridate)
library(ggplot2)

source("R/fetch_census.R")
source("R/fetch_rps.R")
source("R/chart_style.R")

chart_dir <- "charts/ai-adoption"

# Question 7 asks whether the business used AI in the last two weeks. Census
# widened it in November 2025 and publishes the old wording in a separate file.
btos_periods <- fetch_census_btos_periods()

btos_ai_use <- bind_rows(
  old_question = fetch_census_btos("AI Core Questions.xlsx", "National Estimates"),
  new_question = fetch_census_btos("National.xlsx", "Response Estimates"),
  new_question = fetch_census_btos("Employment Size Class.xlsx", "Response Estimates"),
  .id = "wording"
) |>
  filter(question_id == "7", answer == "Yes", !is.na(estimate)) |>
  select(wording, employment_size = empsize, period, estimate)

btos_release <- btos_periods |>
  filter(period == max(btos_ai_use$period)) |>
  pull(published)

write_csv(btos_ai_use, file.path(chart_dir, "data", str_glue("census_btos_ai_{btos_release}.csv")))

genai_use <- fetch_rps_genai()

# The tracker doesn't date its releases, so the snapshot is named by the fetch date.
write_csv(genai_use, file.path(chart_dir, "data", str_glue("rps_genai_{today()}.csv")))

# Each survey period is dated by the end of the two weeks it asks about.
firm_adoption <- btos_ai_use |>
  filter(is.na(employment_size)) |>
  inner_join(btos_periods, by = "period") |>
  select(date = reference_end, wording, estimate)

worker_adoption <- genai_use |>
  filter(sample == "Employed", use == "For Work", frequency == "Share Using GenAI", statistic == "Mean") |>
  select(date, workers = value)

# The Atlanta Fed survey's AI questions were fielded once, in November 2025, and
# its microdata aren't public. The value is as reported by Allen (2026).
jobs_at_adopting_firms <- tibble(date = ymd("2025-11-15"), jobs = 78)

firm_adoption |>
  pivot_wider(names_from = wording, values_from = estimate, names_prefix = "firms_") |>
  full_join(worker_adoption, by = "date") |>
  full_join(jobs_at_adopting_firms, by = "date") |>
  arrange(date) |>
  transmute(
    date,
    firms_old_question = firms_old_question,
    firms = firms_new_question,
    workers,
    jobs_at_firms_using_ai = jobs
  ) |>
  write_csv(file.path(chart_dir, "output", "ai-adoption.csv"), na = "")

adoption_by_size <- btos_ai_use |>
  filter(!is.na(employment_size), period == max(period)) |>
  select(employment_size, estimate)

share_of_size_class <- \(size_class) round(adoption_by_size$estimate[adoption_by_size$employment_size == size_class])

latest_firms <- slice_max(firm_adoption, date)
latest_workers <- slice_max(worker_adoption, date)

measures <- tribble(
  ~series, ~label, ~colour, ~definition,
  "firms", "Firms", chart_colors[["blue"]],
  "Share of businesses using AI in the past two weeks.",
  "workers", "Workers", chart_colors[["orange"]],
  "Share of employed adults using generative AI for their job.",
  "jobs", "Jobs at firms using AI", chart_colors[["teal"]],
  "Share of employment at firms using AI, from one survey in November 2025."
)

# The last old-question period and the first new-question one, either side of the break.
wording_break <- firm_adoption |>
  filter(date == max(date[wording == "old_question"]) | date == min(date[wording == "new_question"])) |>
  select(wording, estimate) |>
  tibble::deframe()

write_chart_lead(
  str_glue(
    "AI use is spreading, but how widespread it looks depends on who is counted and what is asked. About ",
    "{round(latest_firms$estimate)} percent of firms used AI in {format(latest_firms$date, '%B %Y')}, against ",
    "{round(latest_workers$workers)} percent of workers in {format(latest_workers$date, '%B %Y')}, and one survey ",
    "puts {jobs_at_adopting_firms$jobs} percent of jobs at firms that use it. Large firms lead: ",
    "{share_of_size_class('G')} percent of firms with 250 or more employees use it, against ",
    "{share_of_size_class('A')} percent of those with fewer than five. Wording matters too: when the Census Bureau ",
    "broadened its question in November 2025, the firm share jumped from {round(wording_break[['old_question']])} to ",
    "{round(wording_break[['new_question']])} percent."
  ),
  file.path(chart_dir, "output", "ai-adoption-lead.md")
)

write_chart_notes(
  notes = str_glue("**{measures$label}:** {measures$definition}"),
  source = str_glue(
    "Sources: Census Bureau, [Business Trends and Outlook Survey](https://www.census.gov/hfp/btos/); ",
    "[Real-Time Population Survey](https://www.genaiadoptiontracker.com/) (Bick, Blandin, and Deming); Federal ",
    "Reserve Bank of Atlanta. Builds on Allen, [\"Monitoring AI Adoption in the U.S. Economy\"]",
    "(https://www.federalreserve.gov/econres/notes/feds-notes/monitoring-ai-adoption-in-the-u-s-economy-20260403.html), ",
    "FEDS Notes, April 2026."
  ),
  csv_path = file.path(chart_dir, "output", "ai-adoption.csv"),
  path = file.path(chart_dir, "output", "ai-adoption-notes.md")
)

source_line <- str_c(
  "Sources: Census Bureau; Real-Time Population Survey; Federal Reserve Bank of Atlanta. ",
  "Builds on Allen, FEDS Notes, April 2026."
)

adoption_chart <- ggplot(mapping = aes(date)) +
  geom_line(
    data = firm_adoption,
    aes(y = estimate, colour = "firms", group = wording),
    linewidth = 0.9
  ) +
  geom_line(data = worker_adoption, aes(y = workers, colour = "workers"), linewidth = 0.9) +
  geom_point(data = worker_adoption, aes(y = workers, colour = "workers"), size = 1.8) +
  geom_point(data = jobs_at_adopting_firms, aes(y = jobs, colour = "jobs"), size = 3) +
  annotate(
    "text",
    x = ymd("2025-11-01"),
    y = 4,
    label = "Question\nwidened",
    hjust = 0.5,
    size = 3.2,
    lineheight = 0.9,
    colour = chart_greys[["muted"]],
    family = "Roboto Chart"
  ) +
  scale_colour_manual(
    values = setNames(measures$colour, measures$series),
    labels = setNames(measures$label, measures$series),
    breaks = measures$series
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(limits = c(0, 85), breaks = seq(0, 80, 20), expand = expansion(mult = c(0, 0.02))) +
  theme_chart()

title <- "Measured AI use depends on who is counted and what is asked"
subtitle <- "Share using AI, percent"

save_chart(
  adoption_chart + chart_labels(title, subtitle, source_line, width = 8),
  file.path(chart_dir, "output", "ai-adoption.png"),
  width = 8,
  height = 5
)

save_chart(
  adoption_chart +
    chart_labels(title, subtitle, source_line, width = 4.2) +
    guides(colour = guide_legend(ncol = 1)),
  file.path(chart_dir, "output", "ai-adoption-narrow.png"),
  width = 4.2,
  height = 7.2
)
