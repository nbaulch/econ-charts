# The SEC asks every request to name the requester. SEC_USER_AGENT holds a
# name and contact email, set in the environment and never committed.
sec_get <- function(url, path) {
  if (!file.exists(path)) {
    response <- httr::RETRY("GET", url, httr::user_agent(Sys.getenv("SEC_USER_AGENT")))
    httr::stop_for_status(response)
    writeBin(httr::content(response, as = "raw"), path)
    # The SEC allows at most 10 requests a second.
    Sys.sleep(0.15)
  }
  path
}

# Every filing by a company, from EDGAR's submissions index. `cik` is the
# company's central index key.
fetch_sec_filings <- function(cik, cache_dir = "cache/sec") {
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  index_url <- \(file) str_glue("https://data.sec.gov/submissions/{file}")
  as_filings <- \(block) as_tibble(block[c("form", "filingDate", "accessionNumber")])

  # The index is refetched each run, since new filings arrive.
  index_path <- file.path(cache_dir, str_glue("CIK{str_pad(cik, 10, pad = '0')}.json"))
  unlink(index_path)
  submissions <- jsonlite::fromJSON(sec_get(index_url(basename(index_path)), index_path))

  older <- map(submissions$filings$files$name, \(file) {
    jsonlite::fromJSON(sec_get(index_url(file), file.path(cache_dir, file))) |> as_filings()
  })

  bind_rows(as_filings(submissions$filings$recent), older) |>
    transmute(cik, form, filed = ymd(filingDate), accession = accessionNumber)
}

# The securities offered in one filing, from its filing fee exhibit, which the
# SEC has required in structured form since 2022. One row per security, with the
# amount registered and its currency. Filings are never changed, so each is
# cached.
fetch_sec_fee_offerings <- function(cik, accession, cache_dir = "cache/sec") {
  folder <- str_glue("https://www.sec.gov/Archives/edgar/data/{cik}/{str_remove_all(accession, '-')}")
  files <- jsonlite::fromJSON(sec_get(str_glue("{folder}/index.json"), file.path(cache_dir, str_glue("{accession}.json"))))
  exhibit <- str_subset(files$directory$item$name, "filingfees.*\\.xml$")

  if (length(exhibit) == 0) {
    return(NULL)
  }

  deal_currency <- prospectus_currency(folder, files, accession, cache_dir)

  facts <- sec_get(str_glue("{folder}/{exhibit[1]}"), file.path(cache_dir, str_glue("{accession}.xml"))) |>
    xml2::read_xml() |>
    xml2::xml_ns_strip() |>
    xml2::xml_find_all("//*[@contextRef]")

  tibble(
    offering = xml2::xml_attr(facts, "contextRef"),
    field = xml2::xml_name(facts),
    value = xml2::xml_text(facts)
  ) |>
    filter(field %in% c("OfferingSctyTp", "OfferingSctyTitl", "AmtSctiesRegd", "MaxAggtOfferingPric")) |>
    summarise(
      type = value[field == "OfferingSctyTp"][1],
      title = value[field == "OfferingSctyTitl"][1],
      # Some exhibits give only the offering price, in dollars, not the face amount.
      amount = coalesce(
        as.numeric(value[field == "AmtSctiesRegd"][1]),
        as.numeric(value[field == "MaxAggtOfferingPric"][1])
      ),
      .by = offering
    ) |>
    filter(type == "Debt") |>
    transmute(cik, accession, title, amount, currency = deal_currency)
}

# The exhibit doesn't say which currency the notes are in, so read it from the
# prospectus cover: the symbol in front of the first amount after
# "PROSPECTUS SUPPLEMENT". Covers write symbols in several encodings.
prospectus_currency <- function(folder, files, accession, cache_dir) {
  prospectus <- str_subset(files$directory$item$name, "424b[25]\\.htm$")
  symbol <- sec_get(str_glue("{folder}/{prospectus[1]}"), file.path(cache_dir, str_glue("{accession}.htm"))) |>
    read_file() |>
    str_remove_all("<[^>]+>") |>
    str_extract(
      "(?is)prospectus supplement.{0,600}?(\\$|\u20ac|&#8364;|&#128;|&euro;|\u00a3|&#163;|&pound;|CHF|\u00a5|&#165;|&yen;)\\s?\\d{1,3}(,\\d{3}){2,}",
      group = 1
    )

  case_when(
    str_detect(symbol, "\\$") ~ "USD",
    str_detect(symbol, "\u20ac|&#8364;|&#128;|&euro;") ~ "EUR",
    str_detect(symbol, "\u00a3|&#163;|&pound;") ~ "GBP",
    str_detect(symbol, "CHF") ~ "CHF",
    str_detect(symbol, "\u00a5|&#165;|&yen;") ~ "JPY"
  )
}
