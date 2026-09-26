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
