#' Automatic PPC Plot Recommender
#'
#' Examines data properties (discreteness, boundaries) and optionally tests
#' whether a KDE visualization is faithful to the data, then returns a
#' data-driven recommendation for which posterior predictive check (PPC) plot
#' function to use. Recommendations follow the decision logic from Sailynoja
#' et al. (2025).
#'
#' @param y Numeric vector of observed data.
#' @param yrep Optional numeric matrix of posterior predictive draws (rows =
#'   draws, columns = observations). If provided and `y` is continuous, runs
#'   [check_viz()] to test whether a KDE is appropriate.
#'
#' @return An S3 object of class `"ppc_recommendation"` with components:
#'   \describe{
#'     \item{`recommended`}{Character vector of recommended function names.}
#'     \item{`avoid`}{Character vector of functions to avoid.}
#'     \item{`reason`}{Character scalar explaining the recommendation.}
#'     \item{`data_type`}{One of `"continuous"`, `"discrete"`, `"mixed"`,
#'       `"binary"`.}
#'     \item{`bounds`}{Detected boundary information (a `bounds_check` object).}
#'     \item{`discrete`}{Discreteness detection result (a `discrete_check`
#'       object).}
#'     \item{`kde_gof`}{A `viz_gof` object if KDE was tested, otherwise `NULL`.}
#'   }
#'
#' @references Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
#'   Recommendations for visual predictive checks in Bayesian workflow.
#'   arXiv:2503.01509.
#'
#' @seealso [detect_discrete()], [detect_bounds()], [check_viz()],
#'   [ppc_calibration()]
#'
#' @examples
#' set.seed(42)
#'
#' # Continuous unbounded
#' recommend_ppc(rnorm(300))
#'
#' # Non-negative (exponential)
#' recommend_ppc(rexp(300))
#'
#' # Proportions
#' recommend_ppc(rbeta(300, 2, 5))
#'
#' # Discrete counts
#' recommend_ppc(rpois(300, lambda = 3))
#'
#' # Zero-inflated
#' recommend_ppc(c(rep(0, 80), rnorm(220, mean = 2)))
#'
#' # Binary
#' recommend_ppc(sample(0:1, 300, replace = TRUE))
#'
#' @export
recommend_ppc <- function(y, yrep = NULL) {
  y <- .validate_y(y)

  disc   <- detect_discrete(y)
  bounds <- detect_bounds(y)

  kde_gof   <- NULL
  data_type <- NULL
  recommended <- character(0)
  avoid       <- character(0)
  reason      <- character(0)

  is_binary <- all(y %in% c(0, 1)) && disc$n_unique == 2L

  if (is_binary) {
    data_type   <- "binary"
    recommended <- c("ppc_calibration()", "ppc_calibration_residual()")
    avoid       <- c("ppc_dens_overlay()", "ppc_ecdf_overlay()")
    reason      <- paste0(
      "Data is BINARY (only 0 and 1). ",
      "Use PAVA calibration plots to assess probability calibration. ",
      "Density-based and ECDF plots are not appropriate for binary outcomes."
    )

  } else if (disc$is_discrete && !disc$is_mixed) {
    n_unique <- disc$n_unique
    data_type <- "discrete"

    if (n_unique <= 20L) {
      recommended <- c("ppc_rootogram()", "ppc_bars()")
      avoid       <- c("ppc_dens_overlay()", "ppc_dots()")
      reason      <- sprintf(
        "Data is DISCRETE with %d unique values. ",
        n_unique
      )
    } else {
      recommended <- c("ppc_ecdf_overlay(discrete = TRUE)", "ppc_rootogram()")
      avoid       <- c("ppc_dens_overlay()", "ppc_dots()")
      reason      <- sprintf(
        "Data is DISCRETE with %d unique values (large discrete space). ",
        n_unique
      )
    }
    reason <- paste0(reason,
      "KDE-based density plots will misrepresent the distribution. ",
      "Use rootogram or bar plots for small discrete spaces, ",
      "or ECDF-based plots for larger ones."
    )

  } else if (disc$is_mixed) {
    data_type   <- "mixed"
    recommended <- c("ppc_rootogram()", "ppc_ecdf_overlay(discrete = TRUE)")
    avoid       <- c("ppc_dens_overlay()")
    reason      <- paste0(
      "Data appears MIXED / ZERO-INFLATED. ",
      "Point masses were detected alongside a continuous bulk. ",
      "Separate the discrete and continuous components, or use ",
      "ppc_rootogram() for count-like data."
    )

  } else {
    data_type <- "continuous"

    if (!is.null(yrep)) {
      kde_gof <- suppressWarnings(check_viz(y, method = "kde"))
    }

    if (bounds$likely_proportion) {
      recommended <- c(
        "ppc_dens_overlay(bounds = c(0, 1))",
        "ppc_ecdf_overlay()"
      )
      avoid  <- c("ppc_dens_overlay()  # without bounds")
      reason <- paste0(
        "Data appears to be PROPORTIONS bounded to [0, 1]. ",
        "Use boundary-corrected KDE with bounds = c(0, 1) to avoid ",
        "density leakage outside the valid range."
      )
    } else if (bounds$likely_non_negative) {
      recommended <- c(
        "ppc_dens_overlay(bounds = c(0, Inf))",
        "ppc_ecdf_overlay()"
      )
      avoid  <- c("ppc_dens_overlay()  # without bounds")
      reason <- paste0(
        "Data appears NON-NEGATIVE with a hard lower bound at 0. ",
        "Use boundary-corrected KDE with bounds = c(0, Inf) to prevent ",
        "density mass at negative values."
      )
    } else if (!is.null(bounds$lower) || !is.null(bounds$upper)) {
      lb_str <- if (is.null(bounds$lower)) "-Inf" else sprintf("%.4g", bounds$lower)
      ub_str <- if (is.null(bounds$upper)) "Inf"  else sprintf("%.4g", bounds$upper)
      recommended <- c(
        sprintf("ppc_dens_overlay(bounds = c(%s, %s))", lb_str, ub_str),
        "ppc_ecdf_overlay()"
      )
      avoid  <- c("ppc_dens_overlay()  # without bounds")
      reason <- sprintf(
        "Data appears BOUNDED to approximately [%s, %s]. ",
        lb_str, ub_str
      )
      reason <- paste0(reason,
        "Use boundary-corrected KDE to avoid density leakage."
      )
    } else {
      # Unbounded continuous
      if (!is.null(kde_gof) && kde_gof$passes) {
        recommended <- c("ppc_dens_overlay()", "ppc_ecdf_overlay()")
        avoid       <- character(0)
        reason      <- paste0(
          "Data is CONTINUOUS and UNBOUNDED. ",
          "A KDE density plot passes the goodness-of-fit test ",
          "(max deviation = ", sprintf("%.4f", kde_gof$max_deviation), "). ",
          "ppc_dens_overlay() is appropriate."
        )
      } else if (!is.null(kde_gof) && !kde_gof$passes) {
        recommended <- c("ppc_dots()", "ppc_ecdf_overlay()")
        avoid       <- c("ppc_dens_overlay()")
        reason      <- paste0(
          "Data is CONTINUOUS and UNBOUNDED, but the KDE density plot ",
          "FAILS the goodness-of-fit test ",
          "(max deviation = ", sprintf("%.4f", kde_gof$max_deviation), "). ",
          "Consider ppc_dots() (quantile dot plot) or ppc_ecdf_overlay() instead."
        )
      } else {
        recommended <- c("ppc_dens_overlay()", "ppc_ecdf_overlay()")
        avoid       <- character(0)
        reason      <- paste0(
          "Data appears CONTINUOUS and UNBOUNDED. ",
          "ppc_dens_overlay() is generally appropriate. ",
          "Provide `yrep` to additionally test KDE faithfulness."
        )
      }
    }
  }

  result <- structure(
    list(
      recommended = recommended,
      avoid       = avoid,
      reason      = reason,
      data_type   = data_type,
      bounds      = bounds,
      discrete    = disc,
      kde_gof     = kde_gof
    ),
    class = "ppc_recommendation"
  )

  print(result)
  invisible(result)
}


#' @export
print.ppc_recommendation <- function(x, ...) {
  cat("PPC plot recommendation\n")
  cat("=======================\n")
  cat(sprintf("  Data type: %s\n\n", toupper(x$data_type)))

  cat("  Reason:\n")
  # Word-wrap the reason at ~70 chars
  wrapped <- strwrap(x$reason, width = 68, prefix = "    ")
  cat(paste(wrapped, collapse = "\n"), "\n\n")

  if (length(x$recommended) > 0L) {
    cat("  RECOMMENDED:\n")
    for (fn in x$recommended) cat(sprintf("    + %s\n", fn))
  }
  if (length(x$avoid) > 0L) {
    cat("\n  AVOID:\n")
    for (fn in x$avoid) cat(sprintf("    - %s\n", fn))
  }

  cat("\n")
  invisible(x)
}
