# Package index

## Visualization PIT values

Compute probability integral transform (PIT) values for a specific plot
type. Non-uniform PITs indicate the visualization misrepresents the data
distribution.

- [`pit_kde()`](https://utkarshpawade.github.io/ppcviz/reference/pit_kde.md)
  : Compute Visualization PIT Values for KDE
- [`pit_histogram()`](https://utkarshpawade.github.io/ppcviz/reference/pit_histogram.md)
  : Compute Visualization PIT Values for a Histogram
- [`pit_qdotplot()`](https://utkarshpawade.github.io/ppcviz/reference/pit_qdotplot.md)
  : Compute Randomised PIT Values for Quantile Dot Plots

## Goodness-of-fit tests

Test whether PIT values are consistent with the uniform distribution
using simultaneous ECDF confidence bands.

- [`viz_gof()`](https://utkarshpawade.github.io/ppcviz/reference/viz_gof.md)
  : Goodness-of-Fit Test for Visualization PIT Values
- [`check_viz()`](https://utkarshpawade.github.io/ppcviz/reference/check_viz.md)
  : Convenience Wrapper: Check Whether a Visualization is Appropriate

## Data property detection

Detect discreteness, point masses, and natural boundaries in observed
data before choosing a plot type.

- [`detect_discrete()`](https://utkarshpawade.github.io/ppcviz/reference/detect_discrete.md)
  : Detect Discreteness or Point Masses in Data
- [`detect_bounds()`](https://utkarshpawade.github.io/ppcviz/reference/detect_bounds.md)
  : Detect Natural Bounds in Data

## Calibration plots

PAVA-based calibration plots for binary and discrete outcomes. Not
available in bayesplot.

- [`ppc_calibration()`](https://utkarshpawade.github.io/ppcviz/reference/ppc_calibration.md)
  : PAVA Calibration Plot for Binary Outcomes
- [`ppc_calibration_residual()`](https://utkarshpawade.github.io/ppcviz/reference/ppc_calibration_residual.md)
  : PAVA Calibration Residual Plot
- [`ppc_calibration_discrete()`](https://utkarshpawade.github.io/ppcviz/reference/ppc_calibration_discrete.md)
  : PAVA Calibration Plot for Discrete / Multinomial Outcomes

## Automatic recommender

Data-driven recommendation of the most appropriate PPC plot function.

- [`recommend_ppc()`](https://utkarshpawade.github.io/ppcviz/reference/recommend_ppc.md)
  : Automatic PPC Plot Recommender
