# Compute Visualization PIT Values for a Histogram

Computes PIT values of `y` with respect to the piecewise-constant
density implied by the histogram of `y`. The histogram is computed using
[`graphics::hist()`](https://rdrr.io/r/graphics/hist.html), and the CDF
is derived from the cumulative bin densities.

## Usage

``` r
pit_histogram(y, breaks = "Freedman-Diaconis")
```

## Arguments

- y:

  Numeric vector of observed data.

- breaks:

  Breakpoints specification passed to
  [`graphics::hist()`](https://rdrr.io/r/graphics/hist.html). Default
  `"Freedman-Diaconis"`. Can be a string method name, a number of bins,
  or a numeric vector of breakpoints.

## Value

Numeric vector of PIT values in \\\[0,1\]\\, same length as `y`.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
set.seed(42)
y <- rnorm(200)
pit <- pit_histogram(y)
hist(pit, breaks = 20, main = "Histogram PIT — should be ~uniform")

```
