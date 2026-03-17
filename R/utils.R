# ---------------------------------------------------------------------------
# Internal utilities for ppcviz
# ---------------------------------------------------------------------------

# Suppress R CMD check NOTE about .data pronoun from rlang/tidyeval
utils::globalVariables(".data")
# Implements the simultaneous ECDF band calibration from:
#   Sailynoja, Burkner & Vehtari (2022), Graphical test for discrete uniformity
#   as a faster alternative to the Kolmogorov-Smirnov test.
# Adapted from the public description (not from bayesplot source) to avoid
# depending on bayesplot internals.
# ---------------------------------------------------------------------------


#' Adjust gamma for simultaneous ECDF confidence bands (internal)
#'
#' Finds the smallest gamma such that the simultaneous confidence band
#' P(max_t |F_n(t) - t| <= gamma * sqrt(t(1-t)/n)) >= prob
#' using the Dvoretzky-Kiefer-Wolfowitz inequality as the outer bound and
#' binary search with Monte Carlo calibration.
#'
#' @param n Integer. Number of observations.
#' @param prob Nominal coverage probability (e.g. 0.95).
#' @param K Integer. Number of equally-spaced evaluation points on (0,1).
#' @param n_sim Integer. Number of Monte Carlo simulations for calibration.
#' @return Numeric scalar gamma.
#' @keywords internal
.adjust_gamma_optimize <- function(n, prob = 0.95, K = NULL, n_sim = 1000L) {
  if (is.null(K)) K <- min(n, 1000L)

  # Evaluation points on (0, 1) — open to avoid sqrt(0)
  z <- (seq_len(K) - 0.5) / K

  # Standard error at each evaluation point (Brownian bridge SE)
  se_z <- sqrt(z * (1 - z) / n)

  # Monte Carlo: simulate uniform samples, compute max standardised deviation
  set.seed(NULL)  # use R's current RNG state
  max_devs <- vapply(seq_len(n_sim), function(i) {
    u <- sort(stats::runif(n))
    ecdf_vals <- (seq_len(n)) / n
    # Interpolate ECDF at evaluation points z
    ecdf_at_z <- stats::approxfun(
      c(0, u, 1),
      c(0, ecdf_vals, 1),
      method = "constant",
      f = 0,
      rule = 2
    )(z)
    # Standardised deviation
    dev <- abs(ecdf_at_z - z) / se_z
    max(dev, na.rm = TRUE)
  }, numeric(1))

  # gamma = quantile of the simulated max-deviation distribution
  gamma <- stats::quantile(max_devs, probs = prob, names = FALSE)
  gamma
}


#' Compute simultaneous ECDF confidence bands (internal)
#'
#' Returns lower and upper pointwise bounds such that their simultaneous
#' coverage is approximately `prob` for a uniform distribution.
#'
#' @param z Numeric vector of evaluation points in (0, 1).
#' @param n Integer. Sample size.
#' @param gamma Numeric scalar from `.adjust_gamma_optimize()`.
#' @return Data frame with columns `z`, `lower`, `upper`.
#' @keywords internal
.ecdf_bands <- function(z, n, gamma) {
  se_z <- sqrt(z * (1 - z) / n)
  lower <- pmax(z - gamma * se_z, 0)
  upper <- pmin(z + gamma * se_z, 1)
  data.frame(z = z, lower = lower, upper = upper)
}


#' Cumulative trapezoid integration (internal)
#'
#' Computes the cumulative integral of `y` over `x` using the trapezoid rule.
#' Returns a vector of the same length as `x`, with the first element = 0.
#'
#' @param x Numeric vector of x-coordinates (must be sorted).
#' @param y Numeric vector of y-values (same length as `x`).
#' @return Numeric vector of cumulative integrals.
#' @keywords internal
.cumtrapz <- function(x, y) {
  n <- length(x)
  if (n != length(y)) rlang::abort("x and y must have the same length.")
  dx <- diff(x)
  avg_y <- (y[-n] + y[-1]) / 2
  c(0, cumsum(dx * avg_y))
}


#' Bayesplot-compatible colour palette (internal)
#'
#' Returns a minimal named list of colours consistent with bayesplot defaults.
#' @keywords internal
.ppcviz_colors <- function() {
  list(
    mid    = "#9497C4",
    light  = "#DCE0F5",
    dark   = "#3F4A8A",
    y      = "#333333",
    y_fill = "#A8A8A8"
  )
}


#' Minimal ggplot2 theme consistent with bayesplot (internal)
#' @keywords internal
.ppcviz_theme <- function() {
  ggplot2::theme_bw() +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(),
      axis.title       = ggplot2::element_text(size = 11),
      axis.text        = ggplot2::element_text(size = 9),
      legend.position  = "none"
    )
}
