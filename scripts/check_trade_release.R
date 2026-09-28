library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(lubridate)

source("R/fetch_census.R")

# Whether the trade release page needs a rebuild: "new" when the latest FT-900
# has not been built and the trade store holds its month, "waiting" when the
# store does not yet, and "current" when it has been built. Written as GitHub
# Actions step outputs for .github/workflows/trade-release.yml.
headline_series <- str_c(rep(c("balance", "exports", "imports"), each = 3), rep(c("_total", "_goods", "_services"), times = 3))
latest_month <- fetch_census_ft900_exhibit(1, headline_series) |>
  pull(date) |>
  max()
schedule <- fetch_census_trade_schedule()
released <- schedule$released[schedule$month == latest_month]
store_latest <- max(filter(read_census_trade_manifest(), flow == "imports")$date)

status <- case_when(
  file.exists(str_glue("charts/trade-release/data/census_ft900_{released}.csv")) ~ "current",
  store_latest < latest_month ~ "waiting",
  .default = "new"
)

# Outside GitHub Actions, GITHUB_OUTPUT is unset and cat() prints instead.
cat(
  str_glue("status={status}"),
  str_glue("released={released}"),
  str_glue("month={format(latest_month, '%B %Y')}"),
  sep = "\n",
  file = Sys.getenv("GITHUB_OUTPUT"),
  append = TRUE
)
