# Compute Randomised PIT Values for Quantile Dot Plots

Computes randomised PIT values for data as represented by a quantile dot
plot. Each observation is mapped to a uniform draw over the range of
quantile dots it overlaps, following Section 2.1 of Sailynoja et al.
(2025).

## Usage

``` r
pit_qdotplot(y, n_quantiles = 100L, bw = NULL)
```

## Arguments

- y:

  Numeric vector of observed data.

- n_quantiles:

  Integer. Number of quantile dots (default 100).

- bw:

  Numeric. Dot radius on the data scale. If `NULL` (default), uses
  `sqrt(1 / n_quantiles)` relative to the data range, which corresponds
  to dots that tile to cover unit area.

## Value

Numeric vector of randomised PIT values in \\\[0,1\]\\, same length as
`y`.

## Details

Dot positions are the `n_quantiles` empirical quantiles of `y` at
equally spaced probability points, consistent with how
`ggdist::stat_dots(quantiles = n_quantiles)` places dots.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
set.seed(42)
y <- rnorm(200)
pit <- pit_qdotplot(y, n_quantiles = 50)
hist(pit, breaks = 20, main = "Quantile dot plot PIT")

```
