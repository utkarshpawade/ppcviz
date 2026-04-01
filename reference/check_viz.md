# Convenience Wrapper: Check Whether a Visualization is Appropriate

Computes visualization PIT values for a chosen method and then runs
[`viz_gof()`](https://utkarshpawade.github.io/ppcviz/reference/viz_gof.md)
to test uniformity. Prints a human-readable verdict and returns the
[`viz_gof()`](https://utkarshpawade.github.io/ppcviz/reference/viz_gof.md)
result invisibly.

## Usage

``` r
check_viz(y, method = c("kde", "histogram", "qdotplot"), ...)
```

## Arguments

- y:

  Numeric vector of observed data.

- method:

  Which visualization method to test. One of:

  `"kde"`

  :   Test a kernel density estimate (via
      [`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md)).

  `"histogram"`

  :   Test a histogram density (via
      [`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md)).

  `"qdotplot"`

  :   Test a quantile dot plot (via
      [`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md)).

- ...:

  Additional arguments passed to the PIT function
  ([`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md),
  [`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md),
  or
  [`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md)).

## Value

An object of class `"viz_gof"` (invisibly).

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## See also

[`viz_gof()`](https://utkarshpawade.github.io/ppcviz/reference/viz_gof.md),
[`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md),
[`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md),
[`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md)

## Examples

``` r
set.seed(42)
y <- rnorm(300)
check_viz(y, method = "kde")
#> KDE density plot is APPROPRIATE for this data. (max ECDF deviation = 0.0250 is within the 95% simultaneous band)

# Bounded data: KDE without correction should fail
y_beta <- rbeta(300, 2, 5)
check_viz(y_beta, method = "kde")
#> KDE density plot is APPROPRIATE for this data. (max ECDF deviation = 0.0350 is within the 95% simultaneous band)
# With correction:
check_viz(y_beta, method = "kde", bounds = c(0, 1))
#> KDE density plot is APPROPRIATE for this data. (max ECDF deviation = 0.0417 is within the 95% simultaneous band)
```
