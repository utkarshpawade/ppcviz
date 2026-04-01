# Detect Natural Bounds in Data

Checks whether continuous data has natural lower and/or upper bounds by
examining the minimum and maximum values and the density near those
extremes. A sharp density cutoff near the data range suggests a hard
boundary.

## Usage

``` r
detect_bounds(y, tol = 0.01)
```

## Arguments

- y:

  Numeric vector of observed data.

- tol:

  Relative tolerance for boundary detection (default 0.01). Controls how
  much "room" must exist between the data range and the detected
  boundary.

## Value

An S3 object of class `"bounds_check"` with components:

- `lower`:

  Detected lower bound (numeric), or `NULL` if none found.

- `upper`:

  Detected upper bound (numeric), or `NULL` if none found.

- `likely_non_negative`:

  Logical. TRUE if data is all non-negative and a lower bound near 0 is
  detected.

- `likely_proportion`:

  Logical. TRUE if data appears bounded to \\\[0, 1\]\\.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## Examples

``` r
# Unbounded continuous data
detect_bounds(rnorm(300))
#> Boundary detection check
#> ------------------------
#>   Data range: [-2.941, 2.723]
#> 
#>   Lower bound: none detected
#>   Upper bound: none detected
#> 
#>   Result: No natural boundaries detected. Data appears UNBOUNDED.
#>   Recommendation: Standard ppc_dens_overlay() should be appropriate.

# Non-negative data (e.g., exponential)
detect_bounds(rexp(300))
#> Boundary detection check
#> ------------------------
#>   Data range: [0.006111, 5.636]
#> 
#>   Lower bound: 0
#>   Upper bound: 5.636
#> 
#>   Result: Data appears NON-NEGATIVE (lower bound = 0).
#>   Recommendation: Use ppc_dens_overlay(bounds = c(0, Inf)) or
#>   ppc_ecdf_overlay().

# Proportion data bounded to [0, 1]
detect_bounds(rbeta(300, 2, 5))
#> Boundary detection check
#> ------------------------
#>   Data range: [0.009824, 0.8503]
#> 
#>   Lower bound: 0
#>   Upper bound: 1
#> 
#>   Result: Data appears to be PROPORTIONS bounded to [0, 1].
#>   Recommendation: Use ppc_dens_overlay(bounds = c(0, 1)) or
#>   ppc_ecdf_overlay() to avoid boundary bias in KDE.
```
