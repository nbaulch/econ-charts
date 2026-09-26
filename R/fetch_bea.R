# Quarterly NIPA series from BEA's flat files, by series code. The full file
# is large, so only the requested series are kept, one column each, named by
# the names of `series`.
fetch_bea_nipa <- function(series) {
  tidyusmacro::getNIPAFiles(type = "Q") |>
    filter(SeriesCode %in% series) |>
    distinct(SeriesCode, date, Value) |>
    mutate(name = names(series)[match(SeriesCode, series)]) |>
    select(date, name, Value) |>
    pivot_wider(names_from = name, values_from = Value) |>
    arrange(date)
}
