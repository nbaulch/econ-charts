# Monthly U.S. goods trade by HS code and country from the Census
# international trade API, not seasonally adjusted, in dollars. `flow` is
# "imports" (general imports) or "exports" (total exports). The API needs a free
# key, read from the CENSUS_API_KEY environment variable. Returns countries
# only, without the all-country total the API adds.
# https://www.census.gov/data/developers/data-sets/international-trade.html
fetch_census_trade <- function(flow, hs_codes, from) {
  map(hs_codes, \(hs_code) fetch_census_trade_hs(flow, hs_code, from)) |>
    list_rbind()
}

fetch_census_trade_hs <- function(flow, hs_code, from) {
  commodity <- if (flow == "imports") "I_COMMODITY" else "E_COMMODITY"
  value <- if (flow == "imports") "GEN_VAL_MO" else "ALL_VAL_MO"

  query <- list(
    get = str_glue("{value},CTY_CODE,CTY_NAME"),
    COMM_LVL = str_glue("HS{nchar(hs_code)}"),
    SUMMARY_LVL = "DET",
    time = str_glue("from {format(from, '%Y-%m')}"),
    key = Sys.getenv("CENSUS_API_KEY")
  )
  query[[commodity]] <- hs_code

  response <- httr::GET(
    str_glue("https://api.census.gov/data/timeseries/intltrade/{flow}/hs"),
    query = query
  )
  httr::stop_for_status(response)

  # No content means no trade under that code in the period, as for codes
  # retired in an HS revision.
  if (httr::status_code(response) == 204) {
    return(NULL)
  }

  rows <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"))

  rows[-1, ] |>
    as_tibble(.name_repair = \(x) make.unique(rows[1, ])) |>
    filter(CTY_CODE != "-") |>
    transmute(
      date = ym(time),
      flow,
      hs_code,
      country_code = CTY_CODE,
      country = str_to_title(CTY_NAME),
      value = as.numeric(.data[[value]])
    )
}

# One sheet of a Business Trends and Outlook Survey download, such as
# "National.xlsx", in long form: one row per question, answer, and survey
# period, with estimates in percent. Suppressed estimates, shown as ".", are NA.
# https://www.census.gov/hfp/btos/data_downloads
fetch_census_btos <- function(file, sheet) {
  download <- tempfile(fileext = ".xlsx")
  download.file(
    str_glue("https://www.census.gov/hfp/btos/downloads/{URLencode(file)}"),
    download,
    mode = "wb",
    quiet = TRUE
  )

  read_excel(download, sheet = sheet, col_types = "text") |>
    rename_with(\(name) str_to_lower(str_replace_all(name, " ", "_"))) |>
    filter(str_detect(question_id, "^\\d+$")) |>
    pivot_longer(matches("^\\d{6}$"), names_to = "period", values_to = "estimate") |>
    mutate(estimate = suppressWarnings(parse_number(estimate)))
}

# Survey periods of the Business Trends and Outlook Survey, with the two-week
# reference period each asks about and its publication date.
fetch_census_btos_periods <- function() {
  download <- tempfile(fileext = ".xlsx")
  download.file(
    "https://www.census.gov/hfp/btos/downloads/National.xlsx",
    download,
    mode = "wb",
    quiet = TRUE
  )

  read_excel(download, sheet = "Collection and Reference Dates", .name_repair = "unique_quiet") |>
    filter(!is.na(Smpdt)) |>
    transmute(
      period = as.character(Smpdt),
      reference_start = as_date(`Reference Period Start`),
      reference_end = as_date(`Ref End`),
      published = as_date(`Publication Date`)
    )
}

# Firms and employment by enterprise size for the whole U.S. economy, from the
# Statistics of U.S. Businesses detailed-size table for one year. Size codes
# and labels are as published, such as "02" and "02: <5".
# https://www.census.gov/programs-surveys/susb.html
fetch_census_susb <- function(year, cache_dir = "cache/census_susb") {
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(cache_dir, str_glue("us_state_naics_detailedsizes_{year}.txt"))
  if (!file.exists(path)) {
    download.file(
      str_glue("https://www2.census.gov/programs-surveys/susb/tables/{year}/us_state_naics_detailedsizes_{year}.txt"),
      path,
      mode = "wb",
      quiet = TRUE
    )
  }

  read_csv(path, col_types = cols(.default = "c")) |>
    filter(STATE == "00", NAICS == "--") |>
    transmute(size_code = ENTRSIZE, size_label = ENTRSIZEDSCR, firms = as.numeric(FIRM), employment = as.numeric(EMPL))
}
