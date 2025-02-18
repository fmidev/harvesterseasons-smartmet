import pandas as pd
import numpy as np
import sys
from scipy.optimize import curve_fit

def fit_correction_function(control_values, historical_values, degree=3):
    """
    Fit a polynomial correction function using quantile mapping between 
    control forecasts and historical observations.
    """
    # Remove any NaN values
    mask = ~np.isnan(control_values) & ~np.isnan(historical_values)
    control_values = control_values[mask]
    historical_values = historical_values[mask]
    
    sorted_control = np.sort(control_values)
    sorted_historical = np.sort(historical_values)
    
    percentiles = np.linspace(0, 100, len(sorted_control))
    control_quantiles = np.percentile(sorted_control, percentiles)
    hist_quantiles = np.percentile(sorted_historical, percentiles)
    
    coeffs = np.polyfit(control_quantiles, hist_quantiles, degree)
    return coeffs

def print_training_columns(df):
    """Print available columns in training data"""
    print("\nAvailable columns in training data:")
    for col in df.columns:
        print(f"  {col}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python correction_script.py <training_data.csv> <forecast_data.csv>")
        sys.exit(1)

    training_file = sys.argv[1]
    forecast_file = sys.argv[2]

    # Extract location from forecast filename 
    # From patterns like:
    # ECXSF_202501_WG_PT24H_MAX_Vuosaari_151028.csv -> Vuosaari
    # Raahe.csv -> Raahe
    if '_' in forecast_file:
        location = forecast_file.split('_')[5]  # For January pattern
    else:
        location = forecast_file.split('.')[0]  # For February pattern
        location = location.split('/')[-1]  # Get just filename without path

    print(f"\nProcessing location: {location}")

    # Read data
    train_data = pd.read_csv(training_file)
    forecast_data = pd.read_csv(forecast_file)

    # Print columns to help identify the correct names
    print_training_columns(train_data)

    try:
        # Get ECXSF control member (00) and observations
        historical_values = train_data[target_column]  # Observations
        control_values = forecast_data['WG_PT24H_MAX_00']  # ECXSF control member
        
        print(f"\nFitting correction between ECXSF control run 'WG_PT24H_MAX_00' and observations '{target_column}'")
        
        # Fit correction function
        coeffs = fit_correction_function(control_values, historical_values)

        # Print the polynomial coefficients
        print("\nCorrection polynomial coefficients (highest degree first):")
        for i, coeff in enumerate(coeffs):
            power = len(coeffs) - i - 1
            if power == 0:
                print(f"  {coeff:+.6f}")
            else:
                print(f"  {coeff:+.6f} x^{power}")

        print("\nTo correct a forecast value x, compute:")
        correction_str = " + ".join([f"({c:+.6f} * x^{len(coeffs)-i-1})" for i, c in enumerate(coeffs)])
        print(f"y = {correction_str}")

        # Test the correction on a few values
        test_values = np.linspace(control_values.min(), control_values.max(), 5)
        print("\nExample corrections:")
        for x in test_values:
            y = np.polyval(coeffs, x)
            print(f"  {x:.1f} -> {y:.1f}")

    except KeyError as e:
        print(f"\nError: Column not found: {e}")
        print("Make sure input files contain required columns")

if __name__ == "__main__":
    main()
