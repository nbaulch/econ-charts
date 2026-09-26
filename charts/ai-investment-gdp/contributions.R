# Contribution of one component to annualized real GDP growth, following
# Soto, Thieu, and Allen (2026). The first term is the component's lagged share
# of nominal GDP times its annualized real growth. The second converts the
# simple annualized rate to a compound one; it is under 0.01 point here.
# `share_weight` scales the lagged share, which the authors use to count only
# the capital goods part of trade.
gdp_contribution <- function(nominal, real, gdp_nominal, gdp_real, share_weight = 1) {
  gdp_ratio <- gdp_real / lag(gdp_real)
  compounding <- 100 * (gdp_ratio^4 - 1) - 400 * (gdp_ratio - 1)

  share_weight * lag(nominal) / lag(gdp_nominal) * 400 * (real / lag(real) - 1) +
    nominal / gdp_nominal * compounding
}

ai_investment_contributions <- function(nipa) {
  nipa |>
    arrange(date) |>
    mutate(
      # Share of capital goods in goods trade other than food and autos, lagged
      # a quarter along with the trade share it scales.
      export_weight = lag(capital_goods_exports / (capital_goods_exports + consumer_goods_exports)),
      import_weight = lag(capital_goods_imports / (capital_goods_imports + consumer_goods_imports)),
      software = gdp_contribution(software_nominal, software_real, gdp_nominal, gdp_real),
      computers = gdp_contribution(computers_nominal, computers_real, gdp_nominal, gdp_real),
      data_centers = gdp_contribution(data_centers_nominal, data_centers_real, gdp_nominal, gdp_real),
      power = gdp_contribution(power_nominal, power_real, gdp_nominal, gdp_real),
      computer_net_exports =
        gdp_contribution(computer_exports_nominal, computer_exports_real, gdp_nominal, gdp_real, export_weight) -
        gdp_contribution(computer_imports_nominal, computer_imports_real, gdp_nominal, gdp_real, import_weight),
      gross = software + computers + data_centers + power,
      net = gross + computer_net_exports
    ) |>
    select(date, software, computers, data_centers, power, computer_net_exports, gross, net)
}
