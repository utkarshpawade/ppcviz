# Detect Discreteness or Point Masses in Data

Applies the heuristic from Section 2.2 of Sailynoja et al. (2025): if
any value has a relative frequency greater than `threshold`, the data is
flagged as potentially discrete or containing point masses (e.g.,
zero-inflation).

## Usage

``` r
detect_discrete(y, threshold = 0.02)
```

## Arguments

- y:

  Numeric vector of observed data.

- threshold:

  Relative frequency threshold (default 0.02 = 2%). Any value appearing
  more than this fraction of the time is flagged.

## Value

An S3 object of class `"discrete_check"` with components:

- `is_discrete`:

  Logical. TRUE if any value exceeds `threshold`.

- `is_mixed`:

  Logical. TRUE if data appears to be a mixture of continuous bulk and
  discrete point masses (some values flagged but many unique values
  exist).

- `n_unique`:

  Number of unique values.

- `n`:

  Total number of observations.

- `unique_ratio`:

  Ratio of unique values to total observations.

- `flagged_values`:

  Named numeric vector of values exceeding `threshold`, with their
  relative frequencies as values.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
# Continuous data — should not flag anything
detect_discrete(rnorm(200))
#> Discreteness / point-mass check
#> --------------------------------
#>   Observations : 200
#>   Unique values: 200 (ratio 1.000)
#>   Threshold    : 2.0%
#> 
#>   Result: No point masses detected. Data appears continuous.

# Discrete counts
detect_discrete(rpois(200, lambda = 3))
#> Discreteness / point-mass check
#> --------------------------------
#>   Observations : 200
#>   Unique values: 9 (ratio 0.045)
#>   Threshold    : 2.0%
#> 
#>   Result: DISCRETE data detected.
#>   Values with relative frequency > threshold:
#>     value = 0  (freq = 3.0%)
#>     value = 1  (freq = 13.5%)
#>     value = 2  (freq = 26.0%)
#>     value = 3  (freq = 25.5%)
#>     value = 4  (freq = 15.5%)
#>     value = 5  (freq = 6.0%)
#>     value = 6  (freq = 6.5%)
#>     value = 7  (freq = 3.5%)
#>   Recommendation: Use ppc_rootogram() or ppc_bars();
#>   avoid KDE-based plots.

# Zero-inflated: mixture of zeros and continuous values
y_mixed <- c(rep(0, 60), rnorm(140, mean = 2))
detect_discrete(y_mixed)
#> Discreteness / point-mass check
#> --------------------------------
#>   Observations : 200
#>   Unique values: 141 (ratio 0.705)
#>   Threshold    : 2.0%
#> 
#>   Result: MIXED / ZERO-INFLATED data detected.
#>   Point masses with relative frequency > threshold:
#>     value = 0  (freq = 30.0%)
#>   Recommendation: Separate discrete/continuous components;
#>   consider ppc_rootogram() or a hurdle/mixture model check.
```
