#' Detect Discreteness or Point Masses in Data
#'
#' Applies the heuristic from Section 2.2 of Sailynoja et al. (2025): if any
#' value has a relative frequency greater than `threshold`, the data is flagged
#' as potentially discrete or containing point masses (e.g., zero-inflation).
#'
#' @param y Numeric vector of observed data.
#' @param threshold Relative frequency threshold (default 0.02 = 2%). Any value
#'   appearing more than this fraction of the time is flagged.
#'
#' @return An S3 object of class `"discrete_check"` with components:
#'   \describe{
#'     \item{`is_discrete`}{Logical. TRUE if any value exceeds `threshold`.}
#'     \item{`is_mixed`}{Logical. TRUE if data appears to be a mixture of
#'       continuous bulk and discrete point masses (some values flagged but
#'       many unique values exist).}
#'     \item{`n_unique`}{Number of unique values.}
#'     \item{`n`}{Total number of observations.}
#'     \item{`unique_ratio`}{Ratio of unique values to total observations.}
#'     \item{`flagged_values`}{Named numeric vector of values exceeding
#'       `threshold`, with their relative frequencies as values.}
#'   }
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' # Continuous data — should not flag anything
#' detect_discrete(rnorm(200))
#'
#' # Discrete counts
#' detect_discrete(rpois(200, lambda = 3))
#'
#' # Zero-inflated: mixture of zeros and continuous values
#' y_mixed <- c(rep(0, 60), rnorm(140, mean = 2))
#' detect_discrete(y_mixed)
#'
#' @export
detect_discrete <- function(y, threshold = 0.02) {
  y <- .validate_y(y)
  n <- length(y)

  tab <- table(y)
  rel_freq <- as.numeric(tab) / n
  names(rel_freq) <- names(tab)

  flagged_mask <- rel_freq > threshold
  flagged_values <- rel_freq[flagged_mask]

  n_unique <- length(tab)
  unique_ratio <- n_unique / n

  is_discrete <- length(flagged_values) > 0

  is_mixed <- is_discrete && (unique_ratio > 0.1) && (n_unique > 10)

  structure(
    list(
      is_discrete    = is_discrete,
      is_mixed       = is_mixed,
      n_unique       = n_unique,
      n              = n,
      unique_ratio   = unique_ratio,
      flagged_values = flagged_values,
      threshold      = threshold
    ),
    class = "discrete_check"
  )
}

#' @export
print.discrete_check <- function(x, ...) {
  cat("Discreteness / point-mass check\n")
  cat("--------------------------------\n")
  cat(sprintf("  Observations : %d\n", x$n))
  cat(sprintf("  Unique values: %d (ratio %.3f)\n", x$n_unique, x$unique_ratio))
  cat(sprintf("  Threshold    : %.1f%%\n\n", x$threshold * 100))

  if (!x$is_discrete) {
    cat("  Result: No point masses detected. Data appears continuous.\n")
  } else if (x$is_mixed) {
    cat("  Result: MIXED / ZERO-INFLATED data detected.\n")
    cat("  Point masses with relative frequency > threshold:\n")
    for (nm in names(x$flagged_values)) {
      cat(sprintf("    value = %s  (freq = %.1f%%)\n",
                  nm, x$flagged_values[[nm]] * 100))
    }
    cat("  Recommendation: Separate discrete/continuous components;\n")
    cat("  consider ppc_rootogram() or a hurdle/mixture model check.\n")
  } else {
    cat("  Result: DISCRETE data detected.\n")
    cat("  Values with relative frequency > threshold:\n")
    for (nm in names(x$flagged_values)) {
      cat(sprintf("    value = %s  (freq = %.1f%%)\n",
                  nm, x$flagged_values[[nm]] * 100))
    }
    cat("  Recommendation: Use ppc_rootogram() or ppc_bars();\n")
    cat("  avoid KDE-based plots.\n")
  }

  invisible(x)
}


#' Detect Natural Bounds in Data
#'
#' Checks whether continuous data has natural lower and/or upper bounds by
#' examining the minimum and maximum values and the density near those extremes.
#' A sharp density cutoff near the data range suggests a hard boundary.
#'
#' @param y Numeric vector of observed data.
#' @param tol Relative tolerance for boundary detection (default 0.01). Controls
#'   how much "room" must exist between the data range and the detected boundary.
#'
#' @return An S3 object of class `"bounds_check"` with components:
#'   \describe{
#'     \item{`lower`}{Detected lower bound (numeric), or `NULL` if none found.}
#'     \item{`upper`}{Detected upper bound (numeric), or `NULL` if none found.}
#'     \item{`likely_non_negative`}{Logical. TRUE if data is all non-negative
#'       and a lower bound near 0 is detected.}
#'     \item{`likely_proportion`}{Logical. TRUE if data appears bounded to
#'       \eqn{[0, 1]}.}
#'   }
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' # Unbounded continuous data
#' detect_bounds(rnorm(300))
#'
#' # Non-negative data (e.g., exponential)
#' detect_bounds(rexp(300))
#'
#' # Proportion data bounded to [0, 1]
#' detect_bounds(rbeta(300, 2, 5))
#'
#' @export
detect_bounds <- function(y, tol = 0.01) {
  y <- .validate_y(y)

  rng <- range(y)
  span <- diff(rng)

  lower <- NULL
  upper <- NULL

  if (all(y >= 0) && all(y <= 1) && rng[1] <= 0.15) {
    lower <- 0
    upper <- 1

    likely_non_negative <- TRUE
    likely_proportion   <- TRUE

    return(structure(
      list(
        lower               = lower,
        upper               = upper,
        likely_non_negative = likely_non_negative,
        likely_proportion   = likely_proportion,
        y_range             = rng
      ),
      class = "bounds_check"
    ))
  }

  kde <- stats::density(y, n = 512)
  kde_fun <- stats::approxfun(kde$x, kde$y, rule = 2)

  d_at_min  <- kde_fun(rng[1])
  d_at_10pct <- kde_fun(rng[1] + 0.1 * span)

  lower_sharp <- (d_at_min > 0.5 * d_at_10pct) && (d_at_min > 0)

  if (all(y >= 0) && rng[1] <= tol * span) {
    lower <- 0
  } else if (lower_sharp && rng[1] >= 0) {
    lower <- rng[1]
  }

  d_at_max   <- kde_fun(rng[2])
  d_at_90pct <- kde_fun(rng[2] - 0.1 * span)

  upper_sharp <- (d_at_max > 0.5 * d_at_90pct) && (d_at_max > 0)

  if (upper_sharp) {
    upper <- rng[2]
  }

  likely_non_negative <- !is.null(lower) && lower == 0
  likely_proportion   <- likely_non_negative && !is.null(upper) && upper == 1

  structure(
    list(
      lower               = lower,
      upper               = upper,
      likely_non_negative = likely_non_negative,
      likely_proportion   = likely_proportion,
      y_range             = rng
    ),
    class = "bounds_check"
  )
}

#' @export
print.bounds_check <- function(x, ...) {
  cat("Boundary detection check\n")
  cat("------------------------\n")
  cat(sprintf("  Data range: [%.4g, %.4g]\n\n", x$y_range[1], x$y_range[2]))

  lb_str <- if (is.null(x$lower)) "none detected"
            else sprintf("%.4g", x$lower)
  ub_str <- if (is.null(x$upper)) "none detected"
            else sprintf("%.4g", x$upper)

  cat(sprintf("  Lower bound: %s\n", lb_str))
  cat(sprintf("  Upper bound: %s\n\n", ub_str))

  if (x$likely_proportion) {
    cat("  Result: Data appears to be PROPORTIONS bounded to [0, 1].\n")
    cat("  Recommendation: Use ppc_dens_overlay(bounds = c(0, 1)) or\n")
    cat("  ppc_ecdf_overlay() to avoid boundary bias in KDE.\n")
  } else if (x$likely_non_negative) {
    cat("  Result: Data appears NON-NEGATIVE (lower bound = 0).\n")
    cat("  Recommendation: Use ppc_dens_overlay(bounds = c(0, Inf)) or\n")
    cat("  ppc_ecdf_overlay().\n")
  } else if (!is.null(x$lower) || !is.null(x$upper)) {
    cat("  Result: Data appears to have a CUSTOM BOUNDARY.\n")
    bounds_str <- sprintf(
      "c(%s, %s)",
      if (is.null(x$lower)) "-Inf" else sprintf("%.4g", x$lower),
      if (is.null(x$upper)) "Inf"  else sprintf("%.4g", x$upper)
    )
    cat(sprintf("  Recommendation: Use ppc_dens_overlay(bounds = %s).\n", bounds_str))
  } else {
    cat("  Result: No natural boundaries detected. Data appears UNBOUNDED.\n")
    cat("  Recommendation: Standard ppc_dens_overlay() should be appropriate.\n")
  }

  invisible(x)
}


.validate_y <- function(y, min_n = 3L) {
  if (!is.numeric(y)) {
    rlang::abort("`y` must be a numeric vector.")
  }
  n_na <- sum(is.na(y))
  if (n_na > 0L) {
    rlang::warn(sprintf("Removed %d NA value(s) from `y`.", n_na))
    y <- y[!is.na(y)]
  }
  if (length(y) < min_n) {
    rlang::abort(sprintf("`y` must have at least %d non-NA values.", min_n))
  }
  y
}
