# Median forecasts from the Survey of Professional Forecasters for one
# variable, such as "BILL10", the average 3-month Treasury bill rate over the
# next 10 years. Surveys that didn't ask the question are NA.
# https://www.philadelphiafed.org/surveys-and-data/real-time-data-research/survey-of-professional-forecasters
fetch_philfed_spf_median <- function(variable) {
  download <- tempfile(fileext = ".xlsx")
  download.file(
    str_glue(
      "https://www.philadelphiafed.org/-/media/frbp/assets/surveys-and-data/survey-of-professional-forecasters/",
      "data-files/files/median_{str_to_lower(variable)}_level.xlsx"
    ),
    download,
    mode = "wb",
    quiet = TRUE
  )

  read_excel(download, col_types = "text") |>
    transmute(
      survey = make_date(as.integer(YEAR), 3 * as.integer(QUARTER) - 2),
      median = suppressWarnings(as.numeric(.data[[variable]]))
    )
}
