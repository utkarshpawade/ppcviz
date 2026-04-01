# Compute Visualization PIT Values for KDE

Computes probability integral transform (PIT) values of `y` with respect
to the kernel density estimate (KDE) fitted to `y` itself. This
quantifies how well a KDE density plot represents the empirical
distribution of the data.

## Usage

``` r
pit_kde(y, bw = "SJ", kernel = "gaussian", bounds = NULL)
```

## Arguments

- y:

  Numeric vector of observed data.

- bw:

  Bandwidth selector passed to
  [`stats::density()`](https://rdrr.io/r/stats/density.html). Default
  `"SJ"` (Sheather-Jones). Can also be a numeric value.

- kernel:

  Kernel function passed to
  [`stats::density()`](https://rdrr.io/r/stats/density.html). Default
  `"gaussian"`.

- bounds:

  Optional numeric vector of length 2 specifying `c(lower, upper)`
  bounds. Use `NA` or `Inf`/`-Inf` for one-sided bounds, e.g. `c(0, NA)`
  for non-negative data.

## Value

Numeric vector of PIT values in \\\[0,1\]\\, same length as `y`.

## Details

The approach is to: (1) fit a KDE using
[`stats::density()`](https://rdrr.io/r/stats/density.html), (2)
numerically integrate the density to get the CDF via cumulative
trapezoid integration, and (3) evaluate the CDF at each observation. The
resulting PIT values should be uniform on \\\[0,1\]\\ if the KDE
faithfully represents the data.

If `bounds` are provided, the data are reflected at the boundaries
before fitting the KDE (the "reflection method"), and the density is
then cropped to the bounded region and renormalised.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
set.seed(42)
y <- rnorm(200)
pit <- pit_kde(y)
hist(pit, breaks = 20, main = "PIT values — should be ~uniform")


# Bounded data: Beta(2, 5) on [0, 1]
y_beta <- rbeta(200, 2, 5)
pit_bounded <- pit_kde(y_beta, bounds = c(0, 1))
hist(pit_bounded, breaks = 20)

```
