# NIPA series from BEA's flat files, by series code, quarterly ("Q") or monthly
# ("M"). The monthly file includes the underlying detail tables, such as PCE
# prices (2.4.4U) and spending (2.4.5U) by category. The full file is large, so
# only the requested series are kept, one column each, named by the names of
# `series`.
fetch_bea_nipa <- function(series, frequency = "Q") {
  tidyusmacro::getNIPAFiles(type = frequency) |>
    filter(SeriesCode %in% series) |>
    distinct(SeriesCode, date, Value) |>
    mutate(name = names(series)[match(SeriesCode, series)]) |>
    select(date, name, Value) |>
    pivot_wider(names_from = name, values_from = Value) |>
    arrange(date)
}
