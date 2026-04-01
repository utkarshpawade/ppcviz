# PAVA Calibration Residual Plot

Similar to
[`ppc_calibration()`](https://utkarshpawade.github.io/ppcviz/reference/ppc_calibration.md),
but plots residuals (CEP - predicted probability) on the y-axis so that
perfect calibration is a horizontal line at zero. Optionally uses a
covariate `x` on the x-axis to diagnose covariate-specific
miscalibration.

## Usage

``` r
ppc_calibration_residual(
  y,
  yrep,
  x = NULL,
  n_quantiles = 10L,
  prob = 0.9,
  n_boot = 500L,
  ...
)
```

## Arguments

- y:

  Integer or logical vector of observed binary outcomes (0/1 or
  FALSE/TRUE). Length `n`.

- yrep:

  Numeric matrix of posterior predictive draws. Rows = draws, columns =
  observations. Dimensions: `S x n` where `S` is the number of posterior
  draws.

- x:

  Optional numeric vector of length `n`. If provided, used as the x-axis
  variable instead of predicted probabilities. Useful for visualising
  calibration as a function of a covariate.

- n_quantiles:

  Integer. Number of quantile bins for grouping predicted probabilities
  before applying isotonic regression (default 10). More bins give finer
  resolution but noisier estimates.

- prob:

  Nominal coverage probability for the consistency intervals (default
  0.9).

- n_boot:

  Integer. Number of bootstrap resamples for the consistency intervals
  (default 500).

- ...:

  Currently unused; reserved for future arguments.

## Value

A `ggplot` object.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
set.seed(42)
n <- 200
true_p <- stats::plogis(rnorm(n))
y <- stats::rbinom(n, 1, true_p)
yrep <- do.call(rbind, lapply(seq_len(100), function(i) {
  stats::rbinom(n, 1, true_p)
}))
ppc_calibration_residual(y, yrep)

```
