# The Federal Reserve's System Open Market Account holdings of Treasury
# securities by CUSIP, on each Wednesday in `dates` (as listed by
# fetch_nyfed_soma_dates()). Par values are in millions of dollars;
# inflation-protected holdings include their inflation compensation. Past
# holdings don't change, so each week's download is kept in `cache_dir`.
# https://markets.newyorkfed.org/static/docs/markets-api.html
fetch_nyfed_soma_treasury <- function(dates, cache_dir = "cache/nyfed_soma") {
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  map(dates, \(as_of) {
    path <- file.path(cache_dir, str_glue("{as_of}.json"))
    if (!file.exists(path)) {
      response <- httr::RETRY("GET", str_glue("https://markets.newyorkfed.org/api/soma/tsy/get/asof/{as_of}.json"))
      httr::stop_for_status(response)
      writeLines(httr::content(response, as = "text", encoding = "UTF-8"), path)
    }
    jsonlite::fromJSON(path)$soma$holdings
  }) |>
    list_rbind() |>
    as_tibble() |>
    transmute(
      as_of = ymd(asOfDate),
      cusip,
      held = (as.numeric(parValue) + coalesce(suppressWarnings(as.numeric(inflationCompensation)), 0)) / 1e6
    )
}

fetch_nyfed_soma_dates <- function() {
  ymd(jsonlite::fromJSON("https://markets.newyorkfed.org/api/soma/asofdates/list.json")$soma$asOfDates)
}
