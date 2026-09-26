# Splits business sector labor productivity growth into the parts identified in
# Fernald's data. The three components sum to dLP each quarter.
labor_productivity_contributions <- function(tfp) {
  tfp |>
    transmute(
      date,
      labor_productivity = dLP,
      deepening = alpha * (dk - dhours) + (1 - alpha) * dLQ,
      tfp_util_adjusted = dtfp_util,
      utilization = dutil
    ) |>
    pivot_longer(-date, names_to = "series", values_to = "growth") |>
    arrange(series, date) |>
    mutate(
      four_quarter_mean = slide_dbl(growth, mean, .before = 3, .complete = TRUE),
      .by = series
    ) |>
    select(-growth)
}
