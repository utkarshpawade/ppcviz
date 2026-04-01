# Adjust gamma for simultaneous ECDF confidence bands (internal)

Finds the smallest gamma such that the simultaneous confidence band
P(max_t \|F_n(t) - t\| \<= gamma \* sqrt(t(1-t)/n)) \>= prob using the
Dvoretzky-Kiefer-Wolfowitz inequality as the outer bound and binary
search with Monte Carlo calibration.

## Usage

``` r
.adjust_gamma_optimize(n, prob = 0.95, K = NULL, n_sim = 1000L)
```

## Arguments

- n:

  Integer. Number of observations.

- prob:

  Nominal coverage probability (e.g. 0.95).

- K:

  Integer. Number of equally-spaced evaluation points on (0,1).

- n_sim:

  Integer. Number of Monte Carlo simulations for calibration.

## Value

Numeric scalar gamma.
