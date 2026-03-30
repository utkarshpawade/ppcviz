# Shared test fixtures — sourced automatically by testthat

set.seed(2025L)

y_normal <- rnorm(300)

y_beta <- rbeta(300, 2, 5)

y_poisson <- rpois(300, lambda = 5)

y_zeroinf <- c(rep(0, 70), rnorm(230, mean = 2, sd = 0.5))

y_binary <- sample(c(0L, 1L), 200, replace = TRUE,
                   prob = c(0.4, 0.6))

true_p   <- rep(0.6, 200)
yrep_bin <- do.call(rbind, lapply(seq_len(100), function(i) {
  stats::rbinom(200, 1, true_p)
}))
