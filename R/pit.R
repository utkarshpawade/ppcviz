#' Compute Visualization PIT Values for KDE
#'
#' Computes probability integral transform (PIT) values of `y` with respect to
#' the kernel density estimate (KDE) fitted to `y` itself. This quantifies how
#' well a KDE density plot represents the empirical distribution of the data.
#'
#' The approach is to: (1) fit a KDE using [stats::density()], (2) numerically
#' integrate the density to get the CDF via cumulative trapezoid integration,
#' and (3) evaluate the CDF at each observation. The resulting PIT values
#' should be uniform on \eqn{[0,1]} if the KDE faithfully represents the data.
#'
#' If `bounds` are provided, the data are reflected at the boundaries before
#' fitting the KDE (the "reflection method"), and the density is then cropped
#' to the bounded region and renormalised.
#'
#' @param y Numeric vector of observed data.
#' @param bw Bandwidth selector passed to [stats::density()]. Default `"SJ"`
#'   (Sheather-Jones). Can also be a numeric value.
#' @param kernel Kernel function passed to [stats::density()]. Default
#'   `"gaussian"`.
#' @param bounds Optional numeric vector of length 2 specifying `c(lower, upper)`
#'   bounds. Use `NA` or `Inf`/`-Inf` for one-sided bounds, e.g.
#'   `c(0, NA)` for non-negative data.
#'
#' @return Numeric vector of PIT values in \eqn{[0,1]}, same length as `y`.
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' set.seed(42)
#' y <- rnorm(200)
#' pit <- pit_kde(y)
#' hist(pit, breaks = 20, main = "PIT values — should be ~uniform")
#'
#' # Bounded data: Beta(2, 5) on [0, 1]
#' y_beta <- rbeta(200, 2, 5)
#' pit_bounded <- pit_kde(y_beta, bounds = c(0, 1))
#' hist(pit_bounded, breaks = 20)
#'
#' @export
pit_kde <- function(y, bw = "SJ", kernel = "gaussian", bounds = NULL) {
  y <- .validate_y(y)

  # Parse bounds
  lb <- NA_real_
  ub <- NA_real_
  if (!is.null(bounds)) {
    if (length(bounds) != 2) {
      rlang::abort("`bounds` must be a length-2 vector c(lower, upper).")
    }
    lb <- bounds[1]
    ub <- bounds[2]
    if (is.infinite(lb) || is.nan(lb)) lb <- NA_real_
    if (is.infinite(ub) || is.nan(ub)) ub <- NA_real_
  }

  has_lower <- !is.na(lb)
  has_upper <- !is.na(ub)

  # Reflection to handle boundaries
  y_fit <- y
  if (has_lower) y_fit <- c(y_fit, 2 * lb - y_fit)
  if (has_upper) y_fit <- c(y_fit, 2 * ub - y_fit)

  # Fit KDE on (possibly reflected) data
  kde <- tryCatch(
    stats::density(y_fit, bw = bw, kernel = kernel, n = 2048),
    error = function(e) {
      rlang::abort(sprintf("stats::density() failed: %s", conditionMessage(e)))
    }
  )

  # Crop to bounded region (or use full range)
  x_grid <- kde$x
  d_grid  <- kde$y

  if (has_lower) {
    keep <- x_grid >= lb
    x_grid <- x_grid[keep]
    d_grid  <- d_grid[keep]
  }
  if (has_upper) {
    keep <- x_grid <= ub
    x_grid <- x_grid[keep]
    d_grid  <- d_grid[keep]
  }

  # Renormalise after cropping
  total_mass <- .cumtrapz(x_grid, d_grid)[length(x_grid)]
  if (total_mass <= 0) {
    rlang::abort("KDE integrates to 0 after cropping to bounds. Check `bounds`.")
  }
  d_grid <- d_grid / total_mass

  # CDF via cumulative trapezoid
  cdf_vals <- .cumtrapz(x_grid, d_grid)

  # Clamp to [0, 1] to handle numerical error
  cdf_vals <- pmin(pmax(cdf_vals, 0), 1)

  # Evaluate CDF at each observation
  cdf_fun <- stats::approxfun(x_grid, cdf_vals, rule = 2)
  pit <- cdf_fun(y)

  # Clamp
  pmin(pmax(pit, 0), 1)
}


#' Compute Visualization PIT Values for a Histogram
#'
#' Computes PIT values of `y` with respect to the piecewise-constant density
#' implied by the histogram of `y`. The histogram is computed using
#' [graphics::hist()], and the CDF is derived from the cumulative bin densities.
#'
#' @param y Numeric vector of observed data.
#' @param breaks Breakpoints specification passed to [graphics::hist()]. Default
#'   `"Freedman-Diaconis"`. Can be a string method name, a number of bins, or
#'   a numeric vector of breakpoints.
#'
#' @return Numeric vector of PIT values in \eqn{[0,1]}, same length as `y`.
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' set.seed(42)
#' y <- rnorm(200)
#' pit <- pit_histogram(y)
#' hist(pit, breaks = 20, main = "Histogram PIT — should be ~uniform")
#'
#' @export
pit_histogram <- function(y, breaks = "Freedman-Diaconis") {
  y <- .validate_y(y)

  h <- tryCatch(
    graphics::hist(y, breaks = breaks, plot = FALSE),
    error = function(e) {
      rlang::abort(sprintf("graphics::hist() failed: %s", conditionMessage(e)))
    }
  )

  bin_breaks  <- h$breaks
  bin_density <- h$density  # density = counts / (n * bin_width)
  bin_width   <- diff(bin_breaks)
  n_bins      <- length(bin_density)

  # Cumulative density (proportion) at each break
  # cum_density[k] = P(Y <= bin_breaks[k+1])
  cum_density <- cumsum(bin_density * bin_width)
  # Prepend 0 for the left boundary
  cdf_at_breaks <- c(0, cum_density)

  # For each observation, find its bin and interpolate
  pit <- vapply(y, function(yi) {
    # Find which bin yi falls into
    bin_idx <- findInterval(yi, bin_breaks, rightmost.closed = TRUE)
    # Clamp to valid range
    bin_idx <- max(1L, min(bin_idx, n_bins))

    # Proportion through the bin
    left_cdf  <- cdf_at_breaks[bin_idx]
    right_cdf <- cdf_at_breaks[bin_idx + 1L]

    left_edge  <- bin_breaks[bin_idx]
    right_edge <- bin_breaks[bin_idx + 1L]

    # Linear interpolation within the bin
    if (right_edge <= left_edge) return(left_cdf)
    frac <- (yi - left_edge) / (right_edge - left_edge)
    left_cdf + frac * (right_cdf - left_cdf)
  }, numeric(1))

  pmin(pmax(pit, 0), 1)
}


#' Compute Randomised PIT Values for Quantile Dot Plots
#'
#' Computes randomised PIT values for data as represented by a quantile dot
#' plot. Each observation is mapped to a uniform draw over the range of
#' quantile dots it overlaps, following Section 2.1 of Sailynoja et al. (2025).
#'
#' Dot positions are the `n_quantiles` empirical quantiles of `y` at equally
#' spaced probability points, consistent with how `ggdist::stat_dots(quantiles
#' = n_quantiles)` places dots.
#'
#' @param y Numeric vector of observed data.
#' @param n_quantiles Integer. Number of quantile dots (default 100).
#' @param bw Numeric. Dot radius on the data scale. If `NULL` (default), uses
#'   `sqrt(1 / n_quantiles)` relative to the data range, which corresponds to
#'   dots that tile to cover unit area.
#'
#' @return Numeric vector of randomised PIT values in \eqn{[0,1]}, same
#'   length as `y`.
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' set.seed(42)
#' y <- rnorm(200)
#' pit <- pit_qdotplot(y, n_quantiles = 50)
#' hist(pit, breaks = 20, main = "Quantile dot plot PIT")
#'
#' @export
pit_qdotplot <- function(y, n_quantiles = 100L, bw = NULL) {
  y <- .validate_y(y)
  n_q <- as.integer(n_quantiles)
  if (n_q < 2L) rlang::abort("`n_quantiles` must be >= 2.")

  if (is.null(bw)) {
    # Default: dot radius = sqrt(1 / n_q) * (data range / 2)
    # This makes total dot area ≈ 1 on the probability scale
    bw <- sqrt(1 / n_q) * diff(range(y)) / 2
  }
  if (bw <= 0) rlang::abort("`bw` must be positive.")

  # Compute dot positions via ggdist if available, else quantile fallback
  dot_positions <- .compute_dot_positions(y, n_q, bw)

  n <- length(y)
  pit <- numeric(n)

  for (i in seq_len(n)) {
    yi <- y[i]
    # Dots that observation yi "overlaps": |dot_center - yi| <= bw
    overlapping <- which(abs(dot_positions - yi) <= bw)

    if (length(overlapping) == 0L) {
      # No overlapping dot: fall back to empirical CDF
      pit[i] <- mean(y <= yi)
    } else {
      # Range of overlapping quantile indices (1-indexed)
      lo <- (min(overlapping) - 1L) / n_q  # lower quantile fraction
      hi <- min(max(overlapping) / n_q, 1)  # upper quantile fraction
      pit[i] <- stats::runif(1L, lo, hi)
    }
  }

  pmin(pmax(pit, 0), 1)
}


# ---------------------------------------------------------------------------
# Internal: compute dot positions for a quantile dot plot
# ---------------------------------------------------------------------------
# A quantile dot plot with n_q dots places each dot at an equally-spaced
# empirical quantile.  This matches the behaviour of
# ggdist::stat_dots(quantiles = n_q) and does not require ggdist at runtime.
.compute_dot_positions <- function(y, n_q, bw) {
  probs <- (seq_len(n_q) - 0.5) / n_q
  as.numeric(stats::quantile(y, probs = probs, type = 7))
}
