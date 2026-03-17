# Shared test fixtures — sourced automatically by testthat

set.seed(2025L)

# Standard normal (continuous, unbounded) — should pass KDE GoF
y_normal <- rnorm(300)

# Beta(2,5) (continuous, bounded [0,1]) — should detect bounds
y_beta <- rbeta(300, 2, 5)

# Poisson(5) counts (discrete) — should detect discrete
y_poisson <- rpois(300, lambda = 5)

# Zero-inflated normal (mixed) — should detect point mass at 0
y_zeroinf <- c(rep(0, 70), rnorm(230, mean = 2, sd = 0.5))

# Binary 0/1
y_binary <- sample(c(0L, 1L), 200, replace = TRUE,
                   prob = c(0.4, 0.6))

# Simple yrep for binary calibration (200 obs, 100 draws)
true_p   <- rep(0.6, 200)
yrep_bin <- do.call(rbind, lapply(seq_len(100), function(i) {
  stats::rbinom(200, 1, true_p)
}))
