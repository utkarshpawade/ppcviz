# ppcviz

**Diagnostics and Recommendations for Visual Predictive Checks**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

`ppcviz` implements the novel contributions from:

> [Säilynoja, T., Johnson, A., Martin, R., & Vehtari, A. (2025).  
> *Recommendations for visual predictive checks in Bayesian workflow*.  
> arXiv:2503.01509](https://arxiv.org/abs/2503.01509)

The package answers a question that `bayesplot` cannot: **is the plot type I
chose faithful to my data?** A KDE overlay, a histogram, and a quantile dot
plot all represent the same data differently — `ppcviz` quantifies how much
each representation distorts the distribution, using the data's own PIT values
as a probe.

---

## What is new vs. bayesplot?

`bayesplot` already provides excellent PPC plots. `ppcviz` adds what is
**not** in `bayesplot`:

| Feature | `bayesplot` | `ppcviz` |
|---|---|---|
| Boundary-corrected KDE PPC | `ppc_dens_overlay(bounds=)` | — |
| **Visualization PIT values** | — | `pit_kde()`, `pit_histogram()`, `pit_qdotplot()` |
| **Viz. goodness-of-fit test** | — | `viz_gof()`, `check_viz()` |
| **Data property detection** | — | `detect_discrete()`, `detect_bounds()` |
| **PAVA calibration plots** | — | `ppc_calibration()`, `ppc_calibration_residual()`, `ppc_calibration_discrete()` |
| **Automatic recommender** | — | `recommend_ppc()` |

---

## Installation

```r
# Install from local source
install.packages("c:/Projects/Paper Implementation/ppcviz",
                 repos = NULL, type = "source")

# Or with devtools (once on CRAN/GitHub):
# devtools::install_github("example/ppcviz")
```

---

## Quick demo

```r
library(ppcviz)

set.seed(42)
y <- rnorm(300)

# 1. Detect data properties
detect_discrete(y)   # => not discrete
detect_bounds(y)     # => no natural bounds

# 2. Test if a KDE is an appropriate visualization
check_viz(y, method = "kde")
# i KDE density plot is APPROPRIATE for this data.

# 3. Test if KDE is appropriate for bounded Beta data
y_beta <- rbeta(300, 2, 5)
check_viz(y_beta, method = "kde")
# ! KDE density plot may be MISLEADING for this data.

check_viz(y_beta, method = "kde", bounds = c(0, 1))
# i KDE density plot is APPROPRIATE for this data.

# 4. PAVA calibration plot for binary outcomes
n      <- 200
true_p <- plogis(rnorm(n))
y_bin  <- rbinom(n, 1, true_p)
yrep   <- do.call(rbind, lapply(1:100, function(i) rbinom(n, 1, true_p)))
ppc_calibration(y_bin, yrep)

# 5. Get an automatic recommendation
recommend_ppc(rpois(300, lambda = 3))
# => Use ppc_rootogram() or ppc_bars() — discrete data detected
```

---

## Function reference

### PIT computation

| Function | Description |
|---|---|
| `pit_kde(y, bw, kernel, bounds)` | Visualization PIT w.r.t. KDE |
| `pit_histogram(y, breaks)` | Visualization PIT w.r.t. histogram |
| `pit_qdotplot(y, n_quantiles, bw)` | Randomised PIT for quantile dot plots |

### Goodness-of-fit

| Function | Description |
|---|---|
| `viz_gof(pit, prob, K)` | Simultaneous ECDF uniformity test |
| `check_viz(y, method, ...)` | Wrapper: compute PIT + print verdict |

### Data property detection

| Function | Description |
|---|---|
| `detect_discrete(y, threshold)` | Detect point masses / discreteness |
| `detect_bounds(y, tol)` | Detect natural lower/upper bounds |

### Calibration plots (binary & discrete)

| Function | Description |
|---|---|
| `ppc_calibration(y, yrep, ...)` | PAVA calibration plot for binary y |
| `ppc_calibration_residual(y, yrep, x, ...)` | Calibration residual plot |
| `ppc_calibration_discrete(y, yrep, ...)` | Calibration for ordinal/categorical y |

### Recommender

| Function | Description |
|---|---|
| `recommend_ppc(y, yrep)` | Data-driven PPC plot recommendation |

---

## Citation

```bibtex
@misc{sailynoja2025ppc,
  title  = {Recommendations for visual predictive checks in {B}ayesian workflow},
  author = {S{\"a}ilynoja, Teemu and Johnson, Andrew and Martin, Ravi and Vehtari, Aki},
  year   = {2025},
  eprint = {2503.01509},
  archivePrefix = {arXiv}
}
```
