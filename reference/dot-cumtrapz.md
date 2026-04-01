# Cumulative trapezoid integration (internal)

Computes the cumulative integral of `y` over `x` using the trapezoid
rule. Returns a vector of the same length as `x`, with the first element
= 0.

## Usage

``` r
.cumtrapz(x, y)
```

## Arguments

- x:

  Numeric vector of x-coordinates (must be sorted).

- y:

  Numeric vector of y-values (same length as `x`).

## Value

Numeric vector of cumulative integrals.
