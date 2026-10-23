# nmr_t2 standard package

This directory has been standardized as a Python package for NMR T2 processing.

## Features

- **NNLS inversion** with MATLAB-compatible core behavior
- **L-curve regularization selection** with the slope-of-the-L-curve criterion
  of Zou et al. (2016): the reciprocal of the absolute L-curve slope closest to
  0.25 within 0.1–10
- **Paired plotting** for raw decay and T2 spectrum
- **Gaussian peak decomposition** for spectrum interpretation

## Package structure

- `nmr_t2/config.py`: typed configuration objects
- `nmr_t2/io_utils.py`: robust Excel parsing and standardized exports
- `nmr_t2/nnls.py`: fixed-regularization inversion
- `nmr_t2/lcurve.py`: L-curve inversion
- `nmr_t2/plotting.py`: figure generation
- `nmr_t2/gaussian.py`: Gaussian decomposition
- `nmr_t2/pipelines.py`: high-level workflows

## Standard output naming

All high-level pipelines export files under this convention:

`<dataset_name>__<artifact_name>.<ext>`

Examples:

- `SimulationDecay__nnls_spectrum.xlsx`
- `SimulationDecay__nnls_summary.csv`
- `SimulationDecay__lcurve_metrics.xlsx`
- `SimulationDecay__gaussian_summary.xlsx`

## Backward compatibility

The legacy modules are preserved as compatibility layers:

- `inversion_functions.py`
- `gaussian_decomposition_functions.py`
- `run_nnls.py`
- `run_nnls_lcurve.py`
- `plot_nmr_t2.py`

They now delegate to the standardized package implementation.

## Quick start

You can run the complete workflow demo from `main.ipynb`.

## References

- Zou, Y.-L., Xie, R.-H., & Arad, A. (2016). Numerical estimation of choice of the
  regularization parameter for NMR T2 inversion. *Petroleum Science*, 13(2), 237–246.
  https://doi.org/10.1007/s12182-016-0093-6 — slope-of-the-L-curve criterion used
  to select the smoothing factor (threshold 0.25 for curvature smoothing).
- Hansen, P. C. (1992). Analysis of discrete ill-posed problems by means of the
  L-curve. *SIAM Review*, 34(4), 561–580. https://doi.org/10.1137/1034115
- Whittall, K. P., & MacKay, A. L. (1989). Quantitative interpretation of NMR
  relaxation data. *Journal of Magnetic Resonance*, 84(1), 134–152.
  https://doi.org/10.1016/0022-2364(89)90011-5 — non-negative least-squares inversion.
