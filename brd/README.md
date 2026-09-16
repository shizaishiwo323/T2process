# T2 BRD inversion files

These files were copied from `C:\Users\imgw\python\research\bnmr_mcmc-main\T2反演方法验证`.

- `matlab/brd1.p` is the MATLAB BRD solver (P-code; source is not available here). `matlab/main_1D_T2process.m` reads FID data and calls it; the other MATLAB files beside it are its helpers. `matlab/batch/run_BRD.m` processes workbook sheets and calls the same solver.
- `python/BRD_invrs.py` comes from `nidhal数据代码/data1/BRD_invrs.txt`. The Colab-only `!pip install xlsxwriter` line was replaced with a comment so the file is valid Python. It implements nonnegative Tikhonov inversion with SciPy NNLS; equivalence to `brd1.p` has not been established.

The scripts retain their original data paths and parameters. Set the input paths for your data before running them. The Python script also needs `xlsxwriter` for Excel output.
