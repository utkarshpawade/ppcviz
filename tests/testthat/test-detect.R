test_that("detect_discrete: continuous normal not flagged", {
  res <- detect_discrete(y_normal)
  expect_s3_class(res, "discrete_check")
  expect_false(res$is_discrete)
  expect_false(res$is_mixed)
  expect_equal(res$n, length(y_normal))
})

test_that("detect_discrete: Poisson counts flagged as discrete", {
  res <- detect_discrete(y_poisson)
  expect_s3_class(res, "discrete_check")
  expect_true(res$is_discrete)
  # Poisson(5) has several values repeating > 2% of the time
  expect_gt(length(res$flagged_values), 0)
})

test_that("detect_discrete: zero-inflated detected as mixed", {
  res <- detect_discrete(y_zeroinf)
  expect_s3_class(res, "discrete_check")
  expect_true(res$is_discrete)
  expect_true(res$is_mixed)
  expect_true("0" %in% names(res$flagged_values))
})

test_that("detect_discrete: binary flagged as discrete (2 unique values)", {
  res <- detect_discrete(y_binary)
  expect_s3_class(res, "discrete_check")
  expect_true(res$is_discrete)
})

test_that("detect_discrete: print method runs without error", {
  res <- detect_discrete(y_normal)
  expect_output(print(res), "Discreteness")
})

test_that("detect_discrete: errors on non-numeric input", {
  expect_error(detect_discrete(letters), "numeric")
})

test_that("detect_discrete: errors on too-short input", {
  expect_error(detect_discrete(c(1, 2)), regexp = "at least")
})

test_that("detect_discrete: custom threshold works", {
  # Very high threshold should flag nothing for continuous data
  res <- detect_discrete(y_normal, threshold = 0.99)
  expect_false(res$is_discrete)
})

# ---- detect_bounds ----------------------------------------------------------

test_that("detect_bounds: normal data has no bounds", {
  res <- detect_bounds(y_normal)
  expect_s3_class(res, "bounds_check")
  expect_false(res$likely_non_negative)
  expect_false(res$likely_proportion)
})

test_that("detect_bounds: beta data flagged as proportion", {
  res <- detect_bounds(y_beta)
  expect_s3_class(res, "bounds_check")
  expect_true(res$likely_proportion)
  expect_equal(res$lower, 0)
  expect_equal(res$upper, 1)
})

test_that("detect_bounds: exponential data flagged as non-negative", {
  res <- detect_bounds(rexp(300))
  expect_s3_class(res, "bounds_check")
  expect_true(res$likely_non_negative)
  expect_equal(res$lower, 0)
})

test_that("detect_bounds: print method runs without error", {
  res <- detect_bounds(y_normal)
  expect_output(print(res), "Boundary detection")
})

test_that("detect_bounds: print outputs 'proportion' for beta data", {
  res <- detect_bounds(y_beta)
  expect_output(print(res), "PROPORTION|proportion", ignore.case = TRUE)
})
