# Automatic PPC Plot Recommender

Examines data properties (discreteness, boundaries) and optionally tests
whether a KDE visualization is faithful to the data, then returns a
data-driven recommendation for which posterior predictive check (PPC)
plot function to use. Recommendations follow the decision logic from
Sailynoja et al. (2025).

## Usage

``` r
recommend_ppc(y, yrep = NULL)
```

## Arguments

- y:

  Numeric vector of observed data.

- yrep:

  Optional numeric matrix of posterior predictive draws (rows = draws,
  columns = observations). If provided and `y` is continuous, runs
  [`check_viz()`](https://utkarshpawade.github.io/ppcviz/reference/check_viz.md)
  to test whether a KDE is appropriate.

## Value

An S3 object of class `"ppc_recommendation"` with components:

- `recommended`:

  Character vector of recommended function names.

- `avoid`:

  Character vector of functions to avoid.

- `reason`:

  Character scalar explaining the recommendation.

- `data_type`:

  One of `"continuous"`, `"discrete"`, `"mixed"`, `"binary"`.

- `bounds`:

  Detected boundary information (a `bounds_check` object).

- `discrete`:

  Discreteness detection result (a `discrete_check` object).

- `kde_gof`:

  A `viz_gof` object if KDE was tested, otherwise `NULL`.

## References

Sailynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).
Recommendations for visual predictive checks in Bayesian workflow.
arXiv:2503.01509.

## See also

[`detect_discrete()`](https://utkarshpawade.github.io/ppcviz/reference/detect_discrete.md),
[`detect_bounds()`](https://utkarshpawade.github.io/ppcviz/reference/detect_bounds.md),
[`check_viz()`](https://utkarshpawade.github.io/ppcviz/reference/check_viz.md),
[`ppc_calibration()`](https://utkarshpawade.github.io/ppcviz/reference/ppc_calibration.md)

## Examples

``` r
set.seed(42)

# Continuous unbounded
recommend_ppc(rnorm(300))
#> PPC plot recommendation
#> =======================
#>   Data type: CONTINUOUS
#> 
#>   Reason:
#>     Data appears CONTINUOUS and UNBOUNDED. ppc_dens_overlay() is
#>     generally appropriate. Provide `yrep` to additionally test KDE
#>     faithfulness. 
#> 
#>   RECOMMENDED:
#>     + ppc_dens_overlay()
#>     + ppc_ecdf_overlay()
#> 

# Non-negative (exponential)
recommend_ppc(rexp(300))
#> PPC plot recommendation
#> =======================
#>   Data type: CONTINUOUS
#> 
#>   Reason:
#>     Data appears NON-NEGATIVE with a hard lower bound at 0. Use
#>     boundary-corrected KDE with bounds = c(0, Inf) to prevent
#>     density mass at negative values. 
#> 
#>   RECOMMENDED:
#>     + ppc_dens_overlay(bounds = c(0, Inf))
#>     + ppc_ecdf_overlay()
#> 
#>   AVOID:
#>     - ppc_dens_overlay()  # without bounds
#> 

# Proportions
recommend_ppc(rbeta(300, 2, 5))
#> PPC plot recommendation
#> =======================
#>   Data type: CONTINUOUS
#> 
#>   Reason:
#>     Data appears to be PROPORTIONS bounded to [0, 1]. Use
#>     boundary-corrected KDE with bounds = c(0, 1) to avoid density
#>     leakage outside the valid range. 
#> 
#>   RECOMMENDED:
#>     + ppc_dens_overlay(bounds = c(0, 1))
#>     + ppc_ecdf_overlay()
#> 
#>   AVOID:
#>     - ppc_dens_overlay()  # without bounds
#> 

# Discrete counts
recommend_ppc(rpois(300, lambda = 3))
#> PPC plot recommendation
#> =======================
#>   Data type: DISCRETE
#> 
#>   Reason:
#>     Data is DISCRETE with 11 unique values. KDE-based density plots
#>     will misrepresent the distribution. Use rootogram or bar plots
#>     for small discrete spaces, or ECDF-based plots for larger ones. 
#> 
#>   RECOMMENDED:
#>     + ppc_rootogram()
#>     + ppc_bars()
#> 
#>   AVOID:
#>     - ppc_dens_overlay()
#>     - ppc_dots()
#> 

# Zero-inflated
recommend_ppc(c(rep(0, 80), rnorm(220, mean = 2)))
#> PPC plot recommendation
#> =======================
#>   Data type: MIXED
#> 
#>   Reason:
#>     Data appears MIXED / ZERO-INFLATED. Point masses were detected
#>     alongside a continuous bulk. Separate the discrete and
#>     continuous components, or use ppc_rootogram() for count-like
#>     data. 
#> 
#>   RECOMMENDED:
#>     + ppc_rootogram()
#>     + ppc_ecdf_overlay(discrete = TRUE)
#> 
#>   AVOID:
#>     - ppc_dens_overlay()
#> 

# Binary
recommend_ppc(sample(0:1, 300, replace = TRUE))
#> PPC plot recommendation
#> =======================
#>   Data type: BINARY
#> 
#>   Reason:
#>     Data is BINARY (only 0 and 1). Use PAVA calibration plots to
#>     assess probability calibration. Density-based and ECDF plots
#>     are not appropriate for binary outcomes. 
#> 
#>   RECOMMENDED:
#>     + ppc_calibration()
#>     + ppc_calibration_residual()
#> 
#>   AVOID:
#>     - ppc_dens_overlay()
#>     - ppc_ecdf_overlay()
#> 
```
