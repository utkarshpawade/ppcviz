# Goodness-of-Fit Test for Visualization PIT Values

Tests whether a set of PIT values (from
[`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md),
[`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md),
or
[`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md))
is consistent with the uniform distribution on \\\[0,1\]\\, using
simultaneous ECDF confidence bands. Non-uniformity indicates that the
visualization is *misleading* — it does not faithfully represent the
distribution of the data.

## Usage

``` r
viz_gof(pit, prob = 0.95, K = NULL, n_sim = 1000L)
```

## Arguments

- pit:

  Numeric vector of PIT values in \\\[0,1\]\\ (e.g. from
  [`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md),
  [`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md),
  or
  [`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md)).

- prob:

  Nominal simultaneous coverage probability for the confidence band
  (default 0.95).

- K:

  Integer. Number of evaluation points on \\(0,1)\\ for the ECDF
  comparison. If `NULL`, uses `min(length(pit), 1000)`.

- n_sim:

  Integer. Number of Monte Carlo simulations used to calibrate the band.
  Default 1000. Increase for smoother results.

## Value

An S3 object of class `"viz_gof"` with components:

- `pit`:

  The input PIT values.

- `passes`:

  Logical. TRUE if the ECDF lies entirely within the confidence band
  (visualization passes the GoF test).

- `K`:

  Number of evaluation points used.

- `prob`:

  Nominal coverage probability.

- `ecdf_values`:

  Numeric vector of ECDF values at the `K` points.

- `z`:

  Evaluation points (expected quantiles under uniformity).

- `lower`:

  Lower band boundary at each evaluation point.

- `upper`:

  Upper band boundary at each evaluation point.

- `max_deviation`:

  Maximum \|ECDF(z) - z\| over all evaluation points.

- `gamma`:

  Calibrated gamma used for the band.

## Details

The simultaneous bands use the Sailynoja, Burkner & Vehtari (2022)
calibration method: a scaled Brownian bridge envelope \\\[t \pm \gamma
\sqrt{t(1-t)/n}\]\\ where \\\gamma\\ is determined by Monte Carlo
simulation to achieve the desired simultaneous coverage.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

Sailynoja, T., Burkner, P.-C., & Vehtari, A. (2022). Graphical test for
discrete uniformity as a faster alternative to the Kolmogorov-Smirnov
test. Statistics and Computing, 32, 32.

## See also

[`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md),
[`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md),
[`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md),
[`check_viz()`](https://utkarshpawade.github.io/ppcviz/reference/check_viz.md)

## Examples

``` r
set.seed(42)
# Should pass: PIT from a well-calibrated KDE of normal data
y <- rnorm(300)
pit <- pit_kde(y)
result <- viz_gof(pit)
print(result)
#> [OK] Visualization GoF test PASSES (prob = 95%, max deviation = 0.0250)
#>     The visualization appears faithful to the data distribution.
plot(result)


# Should potentially fail: KDE on bounded Beta data without bounds correction
y_beta <- rbeta(300, 2, 5)
pit_bad <- pit_kde(y_beta)  # no bounds = boundary bias
result_bad <- viz_gof(pit_bad)
print(result_bad)
#> [OK] Visualization GoF test PASSES (prob = 95%, max deviation = 0.0350)
#>     The visualization appears faithful to the data distribution.
```
