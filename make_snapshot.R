# =============================================================================
# make_snapshot.R
#
# Fetches historical stock price data from Yahoo Finance via quantmod,
# converts to daily log returns, and writes stock_data_snapshot.csv into the
# current working directory.
#
# Run this ONCE to produce the snapshot used by model_engine.R and the app.
# All team members should share the same snapshot file for reproducibility.
#
# USAGE:
#   setwd("<folder containing this file>")
#   source("make_snapshot.R")
#
# OUTPUT:
#   stock_data_snapshot.csv  (in the current working directory)
#     Columns: date, AAPL, SPY, QQQ, XLK
#     Values : daily log returns
# =============================================================================

library(quantmod)

# ---- Configure ---------------------------------------------------------------
target     <- "AAPL"
predictors <- c("SPY", "QQQ", "XLK")
start_date <- "2023-09-01"
end_date   <- Sys.Date()          # today

output_file <- "stock_data_snapshot.csv"

# ---- Fetch -------------------------------------------------------------------
all_tickers <- c(target, predictors)
cat("Downloading", length(all_tickers), "tickers from Yahoo Finance...\n")

price_list <- lapply(all_tickers, function(tk) {
  cat("  fetching", tk, "... ")
  t0 <- Sys.time()
  px <- getSymbols(tk, src = "yahoo",
                   from = start_date, to = end_date,
                   auto.assign = FALSE)
  cat("done in", round(as.numeric(Sys.time() - t0), 1), "s\n")
  series <- Ad(px)                # adjusted close price
  colnames(series) <- tk
  series
})

# Merge into one aligned time series and drop rows with any missing values
prices <- Reduce(merge, price_list)
prices <- na.omit(prices)
cat("Aligned price rows after dropping NAs:", nrow(prices), "\n")

# ---- Convert to log returns --------------------------------------------------
returns_xts <- diff(log(prices))
returns_xts <- na.omit(returns_xts)   # first row is NA after diff

returns <- data.frame(
  date = zoo::index(returns_xts),
  zoo::coredata(returns_xts)
)

# ---- Save --------------------------------------------------------------------
write.csv(returns, output_file, row.names = FALSE)
cat("\nSaved:", normalizePath(output_file), "\n")

# ---- Sanity output -----------------------------------------------------------
cat("\nDate range: ",
    format(min(returns$date)), "to", format(max(returns$date)),
    "(", nrow(returns), "trading days )\n\n")

cat("First rows:\n"); print(head(returns, 3))
cat("\nDaily return summary:\n"); print(round(sapply(returns[-1], summary), 4))
cat("\nCorrelation matrix:\n"); print(round(cor(returns[-1]), 3))