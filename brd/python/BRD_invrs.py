import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import nnls

# ==========================================
# 1. LOAD DATA
# ==========================================
# Original file path indicates an Excel file.
#file_path = '/content/i1_60-70.1.pea.xlsx'
file_path = '/content/peat1-squez.1.pea.xlsx'

# Read the file. Based on your snippet, the actual header is on the 4th line (index 3).
# We read only the first two columns: Time and Amplitude.
df = None # Initialize df to None
try:
    # Use pd.read_excel for .xlsx files
    df = pd.read_excel(file_path, header=3, usecols=[0, 1])
    df.columns = ['Time', 'Signal'] # Rename for convenience
except FileNotFoundError:
    print(f"Error: File '{file_path}' not found. Please ensure the file is uploaded to your Colab environment or the path is correct.")
    print("If the file is not an Excel file, you might need a different reader.")
except Exception as e:
    print(f"An unexpected error occurred while loading the file: {e}")

# Proceed only if the DataFrame was successfully loaded
if df is not None:
    t = df['Time'].values
    y = df['Signal'].values

    # ==========================================
    # 2. SETUP INVERSION PARAMETERS
    # ==========================================
    # The "Alpha" parameter from your software (Smoothness vs Fit)
    # Try changing this: 0.1 is standard. 1.0 is smoother. 0.01 is sharper.
    alpha = 0.1

    # T2 Grid: The range of T2 values we want to solve for.
    # Min T2 is usually the first echo time; Max T2 is ~3x the last echo.
    num_bins = 200
    #T2_min = t[0] / 19.6
    #T2_max = t[-1] * 17.0068
    T2_min = t[0] / 9.7
    T2_max = t[-1] * 3

    # Create logarithmically spaced T2 bins
    T2_grid = np.logspace(np.log10(T2_min), np.log10(T2_max), num_bins)

    # ==========================================
    # 3. BUILD THE KERNEL MATRIX
    # ==========================================
    # This matrix K relates the T2 spectrum to the decay curve.
    # K[i, j] = exp(-t[i] / T2[j])
    K = np.exp(-t[:, None] / T2_grid[None, :])

    # ==========================================
    # 4. APPLY REGULARIZATION (BRD / TIKHONOV)
    # ==========================================
    # To solve Min ||Kx - y||^2 + alpha * ||x||^2 using NNLS,
    # we augment the matrix K and the vector y.

    # Create the Identity matrix scaled by sqrt(alpha)
    Reg_Matrix = np.eye(num_bins) * np.sqrt(alpha)

    # Augment K: Stack K on top of the Regularization Matrix
    K_aug = np.vstack([K, Reg_Matrix])

    # Augment y: Stack y on top of Zeros (matching the number of T2 bins)
    y_aug = np.concatenate([y, np.zeros(num_bins)])

    # ==========================================
    # 5. SOLVE (INVERSION)
    # ==========================================
    print(f"Running Inversion with Alpha = {alpha}...")
    # scipy.optimize.nnls enforces x >= 0 (Non-Negative constraint)
    spectrum, residual = nnls(K_aug, y_aug)

    # ==========================================
    # 6. CALCULATE FIT AND PLOT
    # ==========================================
    # Generate the fitted curve from our new spectrum
    fitted_signal = K @ spectrum

    # Calculate SNR (Signal-to-Noise Ratio)= as the mean of the original signal divided by the standard deviation of the residuals (the difference between the original signal and the fitted signal)
    # Assuming noise is the difference between the original signal and the fitted signal
    # If the residual from nnls is already representing noise, it could also be used,
    # but (y - fitted_signal) gives the actual point-by-point noise estimate.
    noise = y - fitted_signal
    # Avoid division by zero if std is 0 (e.g., perfect fit or constant noise)
    snr = np.mean(y) / np.std(noise) if np.std(noise) > 0 else np.inf

    # Calculate R-squared (Coefficient of Determination)
    ss_total = np.sum((y - np.mean(y)) ** 2)
    ss_residual = np.sum((y - fitted_signal) ** 2)
    r_squared = 1 - (ss_residual / ss_total) if ss_total > 0 else np.nan

    # Plotting
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    # Plot 1: The Raw Decay vs The Fit
    ax1.plot(t, y, 'b.', label='Raw Data', markersize=2, alpha=0.3)
    ax1.plot(t, fitted_signal, 'r-', label='BRD Fit', linewidth=1.5)
    ax1.set_xlabel('Time (ms)')
    ax1.set_ylabel('Signal Amplitude')
    ax1.set_title('Raw Decay & Fit')
    ax1.legend()
    ax1.grid(True)

    # Plot 2: The T2 Spectrum (The result you want)
    ax2.semilogx(T2_grid, spectrum, 'k-', linewidth=2)
    ax2.fill_between(T2_grid, spectrum, color='gray', alpha=0.3)
    ax2.set_xlabel('T2 Relaxation Time (ms)')
    ax2.set_ylabel('Amplitude')
    ax2.set_title(f'T2 Distribution (Alpha={alpha})')
    ax2.grid(True, which="both", ls="-")

    plt.tight_layout()
    plt.show()

    # ==========================================
    # 7. Statistics and Outputs
    # ==========================================
    ## Prepare DataFrames for Excel
    df_decay = pd.DataFrame({
        'Time': t,
        'Signal': y,
        'Fitted Signal': fitted_signal,
        'Noise': noise # Added Noise column
    })

    df_spectrum = pd.DataFrame({
        'T2 Relaxation Time': T2_grid,
        'Amplitude': spectrum
    })

    print("df_decay head:")
    print(df_decay.head())
    print("\ndf_spectrum head:")
    print(df_spectrum.head())

    ## Compile Summary Statistics and Parameters
    num_echoes = len(t)

    summary_stats = pd.Series({
        'Alpha': alpha,
        'Number of Bins': num_bins,
        'Residual': residual,
        'Number of Echoes': num_echoes,
        'SNR': snr,
        'R-squared': r_squared # Added R-squared
    })

    print("Summary Statistics:")
    print(summary_stats)

    # Install xlsxwriter in the Python environment before running.
    output_file_name = 'T2_Analysis_Results.xlsx'

    with pd.ExcelWriter(output_file_name, engine='xlsxwriter') as writer:
        df_decay.to_excel(writer, sheet_name='Decay_Fit', index=False)
        df_spectrum.to_excel(writer, sheet_name='T2_Spectrum', index=False)
        # Convert summary_stats Series to DataFrame for saving to Excel
        summary_stats.to_frame(name='Value').to_excel(writer, sheet_name='Summary_Statistics')

    print(f"All data successfully saved to '{output_file_name}'")
else:
    print("Skipping further execution because the data could not be loaded.")
