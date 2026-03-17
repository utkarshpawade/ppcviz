test_that("viz_gof: returns correct S3 class and components", {
  pit    <- pit_kde(y_normal)
  result <- viz_gof(pit, n_sim = 200L)
  expect_s3_class(result, "viz_gof")
  expect_named(result, c("pit", "passes", "K", "prob", "ecdf_values",
                          "z", "lower", "upper", "max_deviation", "gamma"))
  expect_length(result$z, result$K)
  expect_length(result$ecdf_values, result$K)
  expect_length(result$lower, result$K)
  expect_length(result$upper, result$K)
})

test_that("viz_gof: normal KDE pit mostly passes at 95%", {
  # Average over replications since this is probabilistic
  pass_count <- 0L
  for (s in seq_len(10L)) {
    set.seed(s * 7L)
    y   <- rnorm(300)
    pit <- pit_kde(y)
    res <- viz_gof(pit, n_sim = 200L)
    if (res$passes) pass_count <- pass_count + 1L
  }
  # Should pass most of the time (>=7/10) for a well-calibrated KDE
  expect_gte(pass_count, 7L)
})

test_that("viz_gof: max_deviation is non-negative", {
  pit    <- pit_kde(y_normal)
  result <- viz_gof(pit, n_sim = 200L)
  expect_gte(result$max_deviation, 0)
})

test_that("viz_gof: band respects prob argument", {
  pit   <- pit_kde(y_normal)
  r90   <- viz_gof(pit, prob = 0.90, n_sim = 200L)
  r99   <- viz_gof(pit, prob = 0.99, n_sim = 200L)
  # Wider band at higher probability
  width90 <- mean(r90$upper - r90$lower)
  width99 <- mean(r99$upper - r99$lower)
  expect_gt(width99, width90)
})

test_that("viz_gof: errors on out-of-range pit values", {
  expect_error(viz_gof(c(0.5, 1.5)), "\\[0, 1\\]")
})

test_that("viz_gof: errors on NA in pit", {
  expect_error(viz_gof(c(0.1, NA, 0.5)), "NA")
})

test_that("print.viz_gof: runs without error", {
  pit <- pit_kde(y_normal)
  res <- viz_gof(pit, n_sim = 200L)
  expect_output(print(res), "GoF test")
})

test_that("plot.viz_gof: returns a ggplot object", {
  skip_if_not_installed("ggplot2")
  pit <- pit_kde(y_normal)
  res <- viz_gof(pit, n_sim = 200L)
  p   <- plot(res)
  expect_s3_class(p, "gg")
})

# ---- check_viz --------------------------------------------------------------

test_that("check_viz: kde method runs without error", {
  expect_no_error(
    suppressMessages(suppressWarnings(check_viz(y_normal, method = "kde")))
  )
})

test_that("check_viz: histogram method returns viz_gof invisibly", {
  result <- suppressMessages(suppressWarnings(
    check_viz(y_normal, method = "histogram")
  ))
  expect_s3_class(result, "viz_gof")
})

test_that("check_viz: invalid method errors", {
  expect_error(check_viz(y_normal, method = "invalid"), "should be one of")
})
