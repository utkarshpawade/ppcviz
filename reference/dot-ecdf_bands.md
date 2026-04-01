# Compute simultaneous ECDF confidence bands (internal)

Returns lower and upper pointwise bounds such that their simultaneous
coverage is approximately `prob` for a uniform distribution.

## Usage

``` r
.ecdf_bands(z, n, gamma)
```

## Arguments

- z:

  Numeric vector of evaluation points in (0, 1).

- n:

  Integer. Sample size.

- gamma:

  Numeric scalar from
  [`.adjust_gamma_optimize()`](https://utkarshpawade.github.io/ppcviz/reference/dot-adjust_gamma_optimize.md).

## Value

Data frame with columns `z`, `lower`, `upper`.
