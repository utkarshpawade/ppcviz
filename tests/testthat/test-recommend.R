test_that("recommend_ppc: returns ppc_recommendation for normal data", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_normal)))
  expect_s3_class(res, "ppc_recommendation")
  expect_equal(res$data_type, "continuous")
  expect_true(length(res$recommended) > 0)
})

test_that("recommend_ppc: Poisson data classified as discrete", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_poisson)))
  expect_equal(res$data_type, "discrete")
  expect_true(any(grepl("rootogram|bars", res$recommended, ignore.case = TRUE)))
})

test_that("recommend_ppc: beta data classified as continuous proportion", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_beta)))
  expect_equal(res$data_type, "continuous")
  # Should recommend bounds-corrected KDE
  expect_true(any(grepl("bounds", res$recommended, ignore.case = TRUE)))
})

test_that("recommend_ppc: zero-inflated classified as mixed", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_zeroinf)))
  expect_equal(res$data_type, "mixed")
  expect_true(any(grepl("rootogram", res$recommended, ignore.case = TRUE)))
})

test_that("recommend_ppc: binary classified as binary", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_binary)))
  expect_equal(res$data_type, "binary")
  expect_true(any(grepl("calibration", res$recommended, ignore.case = TRUE)))
})

test_that("recommend_ppc: print method runs without error", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_normal)))
  expect_output(print(res), "recommendation|RECOMMENDED", ignore.case = TRUE)
})

test_that("recommend_ppc: returns invisibly", {
  res <- suppressMessages(suppressWarnings(
    withVisible(recommend_ppc(y_normal))
  ))
  expect_false(res$visible)
})

test_that("recommend_ppc: yrep triggers kde_gof computation", {
  n_obs  <- 200
  y_cont <- rnorm(n_obs)
  yrep   <- matrix(rnorm(100 * n_obs), nrow = 100, ncol = n_obs)
  res    <- suppressMessages(suppressWarnings(recommend_ppc(y_cont, yrep = yrep)))
  expect_s3_class(res, "ppc_recommendation")
  # kde_gof should be populated
  expect_s3_class(res$kde_gof, "viz_gof")
})

test_that("recommend_ppc: contains bounds and discrete sub-results", {
  res <- suppressMessages(suppressWarnings(recommend_ppc(y_normal)))
  expect_s3_class(res$bounds, "bounds_check")
  expect_s3_class(res$discrete, "discrete_check")
})
