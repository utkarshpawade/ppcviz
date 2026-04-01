# PAVA Calibration Plot for Binary Outcomes

Produces a calibration plot for binary (0/1) posterior predictive checks
using isotonic regression (Pool Adjacent Violators Algorithm, PAVA) to
estimate the Conditional Expectation Probabilities (CEP). Consistency
intervals are obtained via bootstrap resampling.

## Usage

``` r
ppc_calibration(y, yrep, n_quantiles = 10L, prob = 0.9, n_boot = 500L, ...)
```

## Arguments

- y:

  Integer or logical vector of observed binary outcomes (0/1 or
  FALSE/TRUE). Length `n`.

- yrep:

  Numeric matrix of posterior predictive draws. Rows = draws, columns =
  observations. Dimensions: `S x n` where `S` is the number of posterior
  draws.

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

A `ggplot` object. The plot shows predicted probability on the x-axis,
the isotonic-regression CEP estimate on the y-axis, a shaded consistency
interval, and a diagonal reference line (perfect calibration).

## Details

This plot is not available in bayesplot and implements the methodology
from Sections 4 of Sailynoja et al. (2025).

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
set.seed(42)
n <- 200
# Well-calibrated predictions
true_p <- stats::plogis(rnorm(n))
y <- stats::rbinom(n, 1, true_p)
yrep <- do.call(rbind, lapply(seq_len(100), function(i) {
  stats::rbinom(n, 1, true_p)
}))
ppc_calibration(y, yrep)

```
