#' @importFrom rlang .data
#' @keywords internal
#' @noRd
.adjust_gamma_optimize <- function(n, prob = 0.95, K = NULL, n_sim = 1000L) {
  if (is.null(K)) K <- min(n, 1000L)

  z <- (seq_len(K) - 0.5) / K

  se_z <- sqrt(z * (1 - z) / n)

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

  gamma <- stats::quantile(max_devs, probs = prob, names = FALSE)
  gamma
}


#' @keywords internal
#' @noRd
.ecdf_bands <- function(z, n, gamma) {
  se_z <- sqrt(z * (1 - z) / n)
  lower <- pmax(z - gamma * se_z, 0)
  upper <- pmin(z + gamma * se_z, 1)
  data.frame(z = z, lower = lower, upper = upper)
}


#' @keywords internal
#' @noRd
.cumtrapz <- function(x, y) {
  n <- length(x)
  if (n != length(y)) rlang::abort("x and y must have the same length.")
  dx <- diff(x)
  avg_y <- (y[-n] + y[-1]) / 2
  c(0, cumsum(dx * avg_y))
}


#' @keywords internal
#' @noRd
.ppcviz_colors <- function() {
  list(
    mid    = "#9497C4",
    light  = "#DCE0F5",
    dark   = "#3F4A8A",
    y      = "#333333",
    y_fill = "#A8A8A8"
  )
}


#' @keywords internal
#' @noRd
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
