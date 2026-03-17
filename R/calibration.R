#' PAVA Calibration Plot for Binary Outcomes
#'
#' Produces a calibration plot for binary (0/1) posterior predictive checks
#' using isotonic regression (Pool Adjacent Violators Algorithm, PAVA) to
#' estimate the Conditional Expectation Probabilities (CEP). Consistency
#' intervals are obtained via bootstrap resampling.
#'
#' This plot is not available in bayesplot and implements the methodology from
#' Sections 4 of Sailynoja et al. (2025).
#'
#' @param y Integer or logical vector of observed binary outcomes (0/1 or
#'   FALSE/TRUE). Length `n`.
#' @param yrep Numeric matrix of posterior predictive draws. Rows = draws,
#'   columns = observations. Dimensions: `S x n` where `S` is the number of
#'   posterior draws.
#' @param n_quantiles Integer. Number of quantile bins for grouping predicted
#'   probabilities before applying isotonic regression (default 10). More bins
#'   give finer resolution but noisier estimates.
#' @param prob Nominal coverage probability for the consistency intervals
#'   (default 0.9).
#' @param n_boot Integer. Number of bootstrap resamples for the consistency
#'   intervals (default 500).
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return A `ggplot` object. The plot shows predicted probability on the
#'   x-axis, the isotonic-regression CEP estimate on the y-axis, a shaded
#'   consistency interval, and a diagonal reference line (perfect calibration).
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' set.seed(42)
#' n <- 200
#' # Well-calibrated predictions
#' true_p <- stats::plogis(rnorm(n))
#' y <- stats::rbinom(n, 1, true_p)
#' yrep <- do.call(rbind, lapply(seq_len(100), function(i) {
#'   stats::rbinom(n, 1, true_p)
#' }))
#' ppc_calibration(y, yrep)
#'
#' @export
ppc_calibration <- function(y, yrep, n_quantiles = 10L,
                             prob = 0.9, n_boot = 500L, ...) {
  args <- .check_calibration_args(y, yrep)
  y    <- args$y
  p    <- args$p

  cep_df <- .compute_cep(y, p, n_quantiles)
  boot   <- .boot_cep(y, p, n_quantiles, n_boot, prob)

  .plot_calibration(
    cep_df  = cep_df,
    boot    = boot,
    x_label = "Predicted probability",
    y_label = "CEP (isotonic regression)",
    title   = "Calibration plot (PAVA)",
    ref_line = TRUE
  )
}


#' PAVA Calibration Residual Plot
#'
#' Similar to [ppc_calibration()], but plots residuals (CEP - predicted
#' probability) on the y-axis so that perfect calibration is a horizontal line
#' at zero. Optionally uses a covariate `x` on the x-axis to diagnose
#' covariate-specific miscalibration.
#'
#' @inheritParams ppc_calibration
#' @param x Optional numeric vector of length `n`. If provided, used as the
#'   x-axis variable instead of predicted probabilities. Useful for visualising
#'   calibration as a function of a covariate.
#'
#' @return A `ggplot` object.
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' set.seed(42)
#' n <- 200
#' true_p <- stats::plogis(rnorm(n))
#' y <- stats::rbinom(n, 1, true_p)
#' yrep <- do.call(rbind, lapply(seq_len(100), function(i) {
#'   stats::rbinom(n, 1, true_p)
#' }))
#' ppc_calibration_residual(y, yrep)
#'
#' @export
ppc_calibration_residual <- function(y, yrep, x = NULL, n_quantiles = 10L,
                                      prob = 0.9, n_boot = 500L, ...) {
  args <- .check_calibration_args(y, yrep)
  y    <- args$y
  p    <- args$p
  n    <- length(y)

  if (!is.null(x)) {
    if (!is.numeric(x) || length(x) != n) {
      rlang::abort("`x` must be a numeric vector of the same length as `y`.")
    }
    x_axis_vals <- x
    x_label     <- "Covariate x"
  } else {
    x_axis_vals <- p
    x_label     <- "Predicted probability"
  }

  # Compute CEP w.r.t. predicted probabilities (always), then map to x-axis
  cep_df   <- .compute_cep(y, p, n_quantiles)
  boot     <- .boot_cep(y, p, n_quantiles, n_boot, prob)

  # Residuals: CEP - predicted probability midpoint of each bin
  cep_df$resid      <- cep_df$cep - cep_df$p_mid
  boot$lower_resid  <- boot$lower - cep_df$p_mid
  boot$upper_resid  <- boot$upper - cep_df$p_mid

  col <- .ppcviz_colors()

  plot_df <- data.frame(
    p_mid        = cep_df$p_mid,
    resid        = cep_df$resid,
    lower_resid  = boot$lower_resid,
    upper_resid  = boot$upper_resid
  )

  ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$p_mid)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower_resid, ymax = .data$upper_resid),
      fill  = col$light,
      alpha = 0.8
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$lower_resid),
      colour   = col$mid,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$upper_resid),
      colour   = col$mid,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$resid),
      colour    = col$dark,
      linewidth = 1
    ) +
    ggplot2::geom_point(
      ggplot2::aes(y = .data$resid),
      colour = col$dark,
      size   = 2
    ) +
    ggplot2::geom_hline(yintercept = 0, colour = col$y, linetype = "dotted") +
    ggplot2::labs(
      title    = "Calibration residual plot (PAVA)",
      x        = x_label,
      y        = "CEP - predicted probability",
      subtitle = sprintf("%.0f%% consistency intervals | n = %d",
                         prob * 100, length(y))
    ) +
    .ppcviz_theme()
}


#' PAVA Calibration Plot for Discrete / Multinomial Outcomes
#'
#' Extends the binary calibration plot to discrete or ordinal outcomes
#' (Section 5 of Sailynoja et al. 2025). For each unique category `k` in `y`,
#' it plots predicted P(Y = k) vs. the isotonic-regression CEP for that
#' category, with consistency intervals.
#'
#' @inheritParams ppc_calibration
#'
#' @return A `ggplot` object with one facet per category.
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @examples
#' set.seed(42)
#' n <- 200
#' # Ordinal 0/1/2 outcome
#' true_logit <- rnorm(n)
#' y <- ifelse(true_logit < -0.5, 0L, ifelse(true_logit < 0.5, 1L, 2L))
#' # Simulate yrep from a noisy version of the true probabilities
#' yrep <- do.call(rbind, lapply(seq_len(100), function(i) {
#'   ifelse(rnorm(n) < -0.5, 0L, ifelse(rnorm(n) < 0.5, 1L, 2L))
#' }))
#' ppc_calibration_discrete(y, yrep)
#'
#' @export
ppc_calibration_discrete <- function(y, yrep, n_quantiles = 10L,
                                      prob = 0.9, n_boot = 500L, ...) {
  if (!is.numeric(y) && !is.integer(y)) {
    rlang::abort("`y` must be a numeric or integer vector.")
  }
  y <- as.integer(y)
  .check_yrep_dims(y, yrep)
  yrep <- as.matrix(yrep)

  categories <- sort(unique(y))
  if (length(categories) < 2L) {
    rlang::abort("`y` must have at least 2 unique values.")
  }
  if (length(categories) > 20L) {
    rlang::warn(
      paste0("`y` has ", length(categories), " unique values. ",
             "Consider using ppc_calibration() for binary outcomes or ",
             "ppc_ecdf_overlay(discrete=TRUE) for large discrete spaces.")
    )
  }

  n <- length(y)
  col <- .ppcviz_colors()

  all_panels <- lapply(categories, function(k) {
    # Binarise: 1 if y == k, else 0
    y_k <- as.integer(y == k)
    # Predicted P(Y = k) = colMeans of (yrep == k)
    p_k <- colMeans(yrep == k)

    cep_df_k <- .compute_cep(y_k, p_k, n_quantiles)
    boot_k   <- .boot_cep(y_k, p_k, n_quantiles, n_boot, prob)

    data.frame(
      category = k,
      p_mid    = cep_df_k$p_mid,
      cep      = cep_df_k$cep,
      lower    = boot_k$lower,
      upper    = boot_k$upper
    )
  })

  plot_df <- do.call(rbind, all_panels)
  plot_df$category <- factor(plot_df$category)

  ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$p_mid, y = .data$cep)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
      fill  = col$light,
      alpha = 0.8
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$lower),
      colour   = col$mid,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$upper),
      colour   = col$mid,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(colour = col$dark, linewidth = 1) +
    ggplot2::geom_point(colour = col$dark, size = 2) +
    ggplot2::geom_abline(
      intercept = 0, slope = 1,
      colour  = col$y,
      linetype = "dotted"
    ) +
    ggplot2::facet_wrap(~ .data$category, labeller = ggplot2::label_both) +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(
      title    = "Discrete calibration plot (PAVA)",
      x        = "Predicted P(Y = k)",
      y        = "CEP: observed proportion",
      subtitle = sprintf("%.0f%% consistency intervals | n = %d",
                         prob * 100, n)
    ) +
    .ppcviz_theme()
}


# ---------------------------------------------------------------------------
# Internal calibration helpers
# ---------------------------------------------------------------------------

.check_calibration_args <- function(y, yrep) {
  if (!is.numeric(y) && !is.logical(y)) {
    rlang::abort("`y` must be a numeric (0/1) or logical vector.")
  }
  y <- as.integer(y)
  if (!all(y %in% c(0L, 1L))) {
    rlang::abort("`y` must contain only 0 and 1 values for binary calibration.")
  }
  .check_yrep_dims(y, yrep)
  yrep <- as.matrix(yrep)

  # Predicted probability = column means of posterior predictive draws
  # For binary yrep, this is P(Y = 1 | data)
  p <- colMeans(yrep)
  list(y = y, p = p)
}

.check_yrep_dims <- function(y, yrep) {
  if (!is.matrix(yrep) && !is.data.frame(yrep)) {
    rlang::abort("`yrep` must be a matrix with rows = draws, columns = observations.")
  }
  yrep <- as.matrix(yrep)
  if (ncol(yrep) != length(y)) {
    rlang::abort(sprintf(
      "`yrep` must have %d columns (one per observation); got %d.",
      length(y), ncol(yrep)
    ))
  }
}

#' Compute CEP using isotonic regression (PAVA)
#' @param y Binary integer vector.
#' @param p Numeric vector of predicted probabilities.
#' @param n_quantiles Integer. Number of quantile bins.
#' @keywords internal
.compute_cep <- function(y, p, n_quantiles) {
  n_q <- as.integer(n_quantiles)
  breaks <- unique(stats::quantile(p, probs = seq(0, 1, length.out = n_q + 1L),
                                   type = 7))
  bins <- cut(p, breaks = breaks, include.lowest = TRUE)

  # Average predicted probability and observed proportion per bin
  bin_p_mid <- tapply(p, bins, mean)
  bin_obs   <- tapply(y, bins, mean)

  # Remove bins with no data
  valid <- !is.na(bin_p_mid) & !is.na(bin_obs)
  bin_p_mid <- as.numeric(bin_p_mid[valid])
  bin_obs   <- as.numeric(bin_obs[valid])

  # Isotonic regression (monotone non-decreasing)
  if (requireNamespace("Iso", quietly = TRUE)) {
    cep <- Iso::pava(bin_obs, w = as.numeric(table(bins)[valid]))
  } else {
    # Fallback: stats::isoreg
    iso  <- stats::isoreg(bin_p_mid, bin_obs)
    cep  <- iso$yf
  }

  data.frame(p_mid = bin_p_mid, cep = cep)
}

#' Bootstrap consistency intervals for CEP
#' @keywords internal
.boot_cep <- function(y, p, n_quantiles, n_boot, prob) {
  n <- length(y)
  alpha <- 1 - prob

  boot_cep_mat <- tryCatch({
    # Pre-compute quantile breaks from original data
    n_q    <- as.integer(n_quantiles)
    breaks <- unique(stats::quantile(p, probs = seq(0, 1, length.out = n_q + 1L),
                                     type = 7))
    bins   <- cut(p, breaks = breaks, include.lowest = TRUE)
    valid_bins <- levels(bins)[!is.na(tapply(p, bins, mean))]
    n_valid <- length(valid_bins)

    mat <- matrix(NA_real_, nrow = n_boot, ncol = n_valid)

    for (b in seq_len(n_boot)) {
      idx    <- sample.int(n, replace = TRUE)
      y_b    <- y[idx]
      p_b    <- p[idx]
      bins_b <- cut(p_b, breaks = breaks, include.lowest = TRUE)

      p_mid_b <- tapply(p_b, bins_b, mean)
      obs_b   <- tapply(y_b, bins_b, mean)

      valid_b <- !is.na(p_mid_b) & !is.na(obs_b)
      p_mid_b <- as.numeric(p_mid_b[valid_b])
      obs_b   <- as.numeric(obs_b[valid_b])

      if (length(obs_b) < 1L) next

      if (requireNamespace("Iso", quietly = TRUE)) {
        cep_b <- Iso::pava(obs_b, w = as.numeric(table(bins_b)[valid_b]))
      } else {
        cep_b <- stats::isoreg(p_mid_b, obs_b)$yf
      }

      # Align to n_valid bins by padding with NA if needed
      if (length(cep_b) == n_valid) {
        mat[b, ] <- cep_b
      }
    }
    mat
  }, error = function(e) {
    rlang::warn(sprintf("Bootstrap failed: %s. Skipping intervals.", conditionMessage(e)))
    NULL
  })

  if (is.null(boot_cep_mat)) {
    cep_df <- .compute_cep(y, p, n_quantiles)
    return(data.frame(lower = cep_df$cep, upper = cep_df$cep))
  }

  lower <- apply(boot_cep_mat, 2, stats::quantile, probs = alpha / 2,
                 na.rm = TRUE, names = FALSE)
  upper <- apply(boot_cep_mat, 2, stats::quantile, probs = 1 - alpha / 2,
                 na.rm = TRUE, names = FALSE)

  data.frame(lower = lower, upper = upper)
}

#' Internal plot helper for calibration
#' @keywords internal
.plot_calibration <- function(cep_df, boot, x_label, y_label, title,
                               ref_line = TRUE) {
  col <- .ppcviz_colors()

  plot_df <- data.frame(
    p_mid = cep_df$p_mid,
    cep   = cep_df$cep,
    lower = boot$lower,
    upper = boot$upper
  )

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$p_mid, y = .data$cep)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
      fill  = col$light,
      alpha = 0.8
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$lower),
      colour   = col$mid,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$upper),
      colour   = col$mid,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(colour = col$dark, linewidth = 1) +
    ggplot2::geom_point(colour = col$dark, size = 2) +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(title = title, x = x_label, y = y_label) +
    .ppcviz_theme()

  if (ref_line) {
    p <- p + ggplot2::geom_abline(
      intercept = 0, slope = 1,
      colour   = col$y,
      linetype = "dotted"
    )
  }

  p
}
