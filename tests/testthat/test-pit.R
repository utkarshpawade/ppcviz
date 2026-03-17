test_that("pit_kde: returns values in [0,1] for normal data", {
  pit <- pit_kde(y_normal)
  expect_length(pit, length(y_normal))
  expect_true(all(pit >= 0 & pit <= 1))
})

test_that("pit_kde: PIT of normal data is approximately uniform", {
  pit <- pit_kde(y_normal)
  # KS test against uniform — should not reject at alpha=0.01 with n=300
  ks <- ks.test(pit, "punif")
  expect_gt(ks$p.value, 0.01)
})

test_that("pit_kde: bounded beta data with correct bounds ~ uniform", {
  pit <- pit_kde(y_beta, bounds = c(0, 1))
  ks <- ks.test(pit, "punif")
  expect_gt(ks$p.value, 0.01)
})

test_that("pit_kde: errors on non-numeric y", {
  expect_error(pit_kde(letters), "numeric")
})

test_that("pit_kde: errors on wrong bounds length", {
  expect_error(pit_kde(y_normal, bounds = c(0, 1, 2)), "length-2")
})

test_that("pit_kde: one-sided bound works (lower = 0 for exponential)", {
  y_exp <- rexp(200)
  pit   <- pit_kde(y_exp, bounds = c(0, NA))
  expect_length(pit, length(y_exp))
  expect_true(all(pit >= 0 & pit <= 1))
})

# ---- pit_histogram ----------------------------------------------------------

test_that("pit_histogram: returns values in [0,1] for normal data", {
  pit <- pit_histogram(y_normal)
  expect_length(pit, length(y_normal))
  expect_true(all(pit >= 0 & pit <= 1))
})

test_that("pit_histogram: PIT of normal data is approximately uniform", {
  pit <- pit_histogram(y_normal)
  ks <- ks.test(pit, "punif")
  expect_gt(ks$p.value, 0.01)
})

test_that("pit_histogram: numeric breaks argument works", {
  pit <- pit_histogram(y_normal, breaks = 30)
  expect_length(pit, length(y_normal))
  expect_true(all(pit >= 0 & pit <= 1))
})

test_that("pit_histogram: errors on non-numeric y", {
  expect_error(pit_histogram(letters), "numeric")
})

# ---- pit_qdotplot -----------------------------------------------------------

test_that("pit_qdotplot: returns values in [0,1]", {
  pit <- pit_qdotplot(y_normal, n_quantiles = 50L)
  expect_length(pit, length(y_normal))
  expect_true(all(pit >= 0 & pit <= 1))
})

test_that("pit_qdotplot: errors on n_quantiles < 2", {
  expect_error(pit_qdotplot(y_normal, n_quantiles = 1L), "n_quantiles")
})

test_that("pit_qdotplot: custom bw accepted", {
  pit <- pit_qdotplot(y_normal, n_quantiles = 50L, bw = 0.1)
  expect_true(all(pit >= 0 & pit <= 1))
})

test_that("pit_qdotplot: values vary (not all identical)", {
  pit <- pit_qdotplot(y_normal, n_quantiles = 50L)
  expect_gt(var(pit), 0)
})
