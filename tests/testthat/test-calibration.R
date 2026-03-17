test_that("ppc_calibration: returns a ggplot for binary y", {
  skip_if_not_installed("ggplot2")
  p <- ppc_calibration(y_binary, yrep_bin, n_boot = 50L)
  expect_s3_class(p, "gg")
})

test_that("ppc_calibration: errors on non-binary y", {
  expect_error(ppc_calibration(y_poisson, yrep_bin), "0 and 1")
})

test_that("ppc_calibration: errors on wrong yrep dimensions", {
  bad_yrep <- matrix(0, nrow = 10, ncol = 50)  # should be 200 cols
  expect_error(ppc_calibration(y_binary, bad_yrep), "columns")
})

test_that("ppc_calibration: works with small n_quantiles", {
  skip_if_not_installed("ggplot2")
  p <- ppc_calibration(y_binary, yrep_bin, n_quantiles = 4L, n_boot = 20L)
  expect_s3_class(p, "gg")
})

# ---- ppc_calibration_residual -----------------------------------------------

test_that("ppc_calibration_residual: returns ggplot", {
  skip_if_not_installed("ggplot2")
  p <- ppc_calibration_residual(y_binary, yrep_bin, n_boot = 50L)
  expect_s3_class(p, "gg")
})

test_that("ppc_calibration_residual: covariate x supported", {
  skip_if_not_installed("ggplot2")
  x_cov <- rnorm(200)
  p <- ppc_calibration_residual(y_binary, yrep_bin, x = x_cov, n_boot = 50L)
  expect_s3_class(p, "gg")
})

test_that("ppc_calibration_residual: errors on wrong x length", {
  expect_error(
    ppc_calibration_residual(y_binary, yrep_bin, x = rnorm(50)),
    "same length"
  )
})

# ---- ppc_calibration_discrete -----------------------------------------------

test_that("ppc_calibration_discrete: works for ordinal 0/1/2 outcome", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  n  <- 150
  y3 <- sample(0:2, n, replace = TRUE)
  yrep3 <- do.call(rbind, lapply(seq_len(50), function(i) {
    sample(0:2, n, replace = TRUE)
  }))
  p <- ppc_calibration_discrete(y3, yrep3, n_boot = 20L)
  expect_s3_class(p, "gg")
})

test_that("ppc_calibration_discrete: errors on single-category y", {
  y_single <- rep(1L, 50)
  yrep_s   <- matrix(1L, nrow = 20, ncol = 50)
  expect_error(ppc_calibration_discrete(y_single, yrep_s), "unique values")
})
