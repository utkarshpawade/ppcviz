#' Goodness-of-Fit Test for Visualization PIT Values
#'
#' Tests whether a set of PIT values (from [pit_kde()], [pit_histogram()], or
#' [pit_qdotplot()]) is consistent with the uniform distribution on \eqn{[0,1]},
#' using simultaneous ECDF confidence bands. Non-uniformity indicates that the
#' visualization is *misleading* — it does not faithfully represent the
#' distribution of the data.
#'
#' The simultaneous bands use the Sailynoja, Burkner & Vehtari (2022)
#' calibration method: a scaled Brownian bridge envelope
#' \eqn{[t \pm \gamma \sqrt{t(1-t)/n}]} where \eqn{\gamma} is determined by
#' Monte Carlo simulation to achieve the desired simultaneous coverage.
#'
#' @param pit Numeric vector of PIT values in \eqn{[0,1]} (e.g. from
#'   [pit_kde()], [pit_histogram()], or [pit_qdotplot()]).
#' @param prob Nominal simultaneous coverage probability for the confidence
#'   band (default 0.95).
#' @param K Integer. Number of evaluation points on \eqn{(0,1)} for the ECDF
#'   comparison. If `NULL`, uses `min(length(pit), 1000)`.
#' @param n_sim Integer. Number of Monte Carlo simulations used to calibrate
#'   the band. Default 1000. Increase for smoother results.
#'
#' @return An S3 object of class `"viz_gof"` with components:
#'   \describe{
#'     \item{`pit`}{The input PIT values.}
#'     \item{`passes`}{Logical. TRUE if the ECDF lies entirely within the
#'       confidence band (visualization passes the GoF test).}
#'     \item{`K`}{Number of evaluation points used.}
#'     \item{`prob`}{Nominal coverage probability.}
#'     \item{`ecdf_values`}{Numeric vector of ECDF values at the `K` points.}
#'     \item{`z`}{Evaluation points (expected quantiles under uniformity).}
#'     \item{`lower`}{Lower band boundary at each evaluation point.}
#'     \item{`upper`}{Upper band boundary at each evaluation point.}
#'     \item{`max_deviation`}{Maximum |ECDF(z) - z| over all evaluation points.}
#'     \item{`gamma`}{Calibrated gamma used for the band.}
#'   }
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#'   Sailynoja, T., Burkner, P.-C., & Vehtari, A. (2022). Graphical test for
#'   discrete uniformity as a faster alternative to the Kolmogorov-Smirnov
#'   test. Statistics and Computing, 32, 32.
#'
#' @seealso [pit_kde()], [pit_histogram()], [pit_qdotplot()], [check_viz()]
#'
#' @examples
#' set.seed(42)
#' # Should pass: PIT from a well-calibrated KDE of normal data
#' y <- rnorm(300)
#' pit <- pit_kde(y)
#' result <- viz_gof(pit)
#' print(result)
#' plot(result)
#'
#' # Should potentially fail: KDE on bounded Beta data without bounds correction
#' y_beta <- rbeta(300, 2, 5)
#' pit_bad <- pit_kde(y_beta)  # no bounds = boundary bias
#' result_bad <- viz_gof(pit_bad)
#' print(result_bad)
#'
#' @export
viz_gof <- function(pit, prob = 0.95, K = NULL, n_sim = 1000L) {
  if (!is.numeric(pit) || any(is.na(pit))) {
    rlang::abort("`pit` must be a numeric vector with no NA values.")
  }
  if (any(pit < 0 | pit > 1)) {
    rlang::abort("`pit` values must be in [0, 1].")
  }
  if (!is.numeric(prob) || length(prob) != 1L || prob <= 0 || prob >= 1) {
    rlang::abort("`prob` must be a single number in (0, 1).")
  }

  n <- length(pit)
  if (is.null(K)) K <- min(n, 1000L)
  K <- as.integer(K)

  # Evaluation points (open interval to avoid 0/1 boundary issues with SE)
  z <- (seq_len(K) - 0.5) / K

  # Calibrate gamma via Monte Carlo
  gamma <- .adjust_gamma_optimize(n = n, prob = prob, K = K, n_sim = n_sim)

  # Compute bands
  bands <- .ecdf_bands(z, n, gamma)

  # Evaluate empirical ECDF of pit at z
  ecdf_fn <- stats::ecdf(pit)
  ecdf_vals <- ecdf_fn(z)

  # Max deviation
  max_dev <- max(abs(ecdf_vals - z))

  # Passes if ECDF lies within the band at all evaluation points
  passes <- all(ecdf_vals >= bands$lower & ecdf_vals <= bands$upper)

  structure(
    list(
      pit           = pit,
      passes        = passes,
      K             = K,
      prob          = prob,
      ecdf_values   = ecdf_vals,
      z             = z,
      lower         = bands$lower,
      upper         = bands$upper,
      max_deviation = max_dev,
      gamma         = gamma
    ),
    class = "viz_gof"
  )
}

#' @export
print.viz_gof <- function(x, ...) {
  verdict <- if (x$passes) "PASSES" else "FAILS"
  symbol  <- if (x$passes) "[OK]" else "[!!]"
  cat(sprintf(
    "%s Visualization GoF test %s (prob = %.0f%%, max deviation = %.4f)\n",
    symbol, verdict, x$prob * 100, x$max_deviation
  ))
  if (!x$passes) {
    cat("    The visualization is potentially misleading for this data.\n")
  } else {
    cat("    The visualization appears faithful to the data distribution.\n")
  }
  invisible(x)
}

#' @export
plot.viz_gof <- function(x, ...) {
  col <- .ppcviz_colors()

  df_band <- data.frame(
    z     = x$z,
    lower = x$lower,
    upper = x$upper,
    ecdf  = x$ecdf_values,
    diff  = x$ecdf_values - x$z
  )

  pass_label <- if (x$passes) "passes" else "FAILS"
  subtitle   <- sprintf(
    "Simultaneous %.0f%% band | max deviation = %.4f | %s",
    x$prob * 100, x$max_deviation, pass_label
  )

  ggplot2::ggplot(df_band, ggplot2::aes(x = .data$z)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower - .data$z, ymax = .data$upper - .data$z),
      fill  = col$light,
      alpha = 0.8
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$lower - .data$z),
      colour    = col$mid,
      linewidth = 0.5,
      linetype  = "dashed"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$upper - .data$z),
      colour    = col$mid,
      linewidth = 0.5,
      linetype  = "dashed"
    ) +
    ggplot2::geom_step(
      ggplot2::aes(y = .data$diff),
      colour    = col$dark,
      linewidth = 0.8
    ) +
    ggplot2::geom_hline(yintercept = 0, colour = col$y, linetype = "dotted") +
    ggplot2::scale_x_continuous(
      name   = "Expected quantile (uniform)",
      limits = c(0, 1)
    ) +
    ggplot2::scale_y_continuous(name = "ECDF(z) - z") +
    ggplot2::labs(
      title    = "Visualization goodness-of-fit: PIT-ECDF difference plot",
      subtitle = subtitle
    ) +
    .ppcviz_theme()
}


#' Convenience Wrapper: Check Whether a Visualization is Appropriate
#'
#' Computes visualization PIT values for a chosen method and then runs
#' [viz_gof()] to test uniformity. Prints a human-readable verdict and returns
#' the [viz_gof()] result invisibly.
#'
#' @param y Numeric vector of observed data.
#' @param method Which visualization method to test. One of:
#'   \describe{
#'     \item{`"kde"`}{Test a kernel density estimate (via [pit_kde()]).}
#'     \item{`"histogram"`}{Test a histogram density (via [pit_histogram()]).}
#'     \item{`"qdotplot"`}{Test a quantile dot plot (via [pit_qdotplot()]).}
#'   }
#' @param ... Additional arguments passed to the PIT function
#'   ([pit_kde()], [pit_histogram()], or [pit_qdotplot()]).
#'
#' @return An object of class `"viz_gof"` (invisibly).
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @seealso [viz_gof()], [pit_kde()], [pit_histogram()], [pit_qdotplot()]
#'
#' @examples
#' set.seed(42)
#' y <- rnorm(300)
#' check_viz(y, method = "kde")
#'
#' # Bounded data: KDE without correction should fail
#' y_beta <- rbeta(300, 2, 5)
#' check_viz(y_beta, method = "kde")
#' # With correction:
#' check_viz(y_beta, method = "kde", bounds = c(0, 1))
#'
#' @export
check_viz <- function(y, method = c("kde", "histogram", "qdotplot"), ...) {
  method <- match.arg(method)
  y <- .validate_y(y)

  pit <- switch(method,
    kde       = pit_kde(y, ...),
    histogram = pit_histogram(y, ...),
    qdotplot  = pit_qdotplot(y, ...)
  )

  result <- viz_gof(pit)

  # Human-readable verdict
  method_name <- switch(method,
    kde       = "KDE density plot",
    histogram = "histogram",
    qdotplot  = "quantile dot plot"
  )

  if (result$passes) {
    reason <- sprintf(
      "max ECDF deviation = %.4f is within the %.0f%% simultaneous band",
      result$max_deviation, result$prob * 100
    )
    rlang::inform(sprintf(
      "%s is APPROPRIATE for this data. (%s)",
      method_name, reason
    ))
  } else {
    reason <- sprintf(
      "max ECDF deviation = %.4f exceeds the %.0f%% simultaneous band",
      result$max_deviation, result$prob * 100
    )
    rlang::warn(sprintf(
      "%s may be MISLEADING for this data. (%s)\n  Consider a different visualization or boundary correction.",
      method_name, reason
    ))
  }

  invisible(result)
}
