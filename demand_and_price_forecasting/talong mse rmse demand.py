import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX
from sklearn.metrics import mean_squared_error
import numpy as np
import re

# --- 1. Data Preparation: Talong Demand ---
FILE_PATH = r'C:\Users\User\OneDrive\Desktop\Model\cleaned datasets.csv'

# Load the file, skipping the initial description line.
try:
    df = pd.read_csv(FILE_PATH, header=None)
except FileNotFoundError:
    print(f"Error: File not found at {FILE_PATH}")
    exit()

# Forward-fill Column 0 (Date/Period) to propagate the date.
df[0] = df[0].ffill()

# Filter for rows that contain 'Talong' in Column 2 (Commodity).
talong_df = df[df[2].astype(str).str.contains(r'Talong\s*[A-Z]?', case=False, na=False)].copy()

# Select the relevant columns and rename them
talong_df = talong_df[[0, 2, 3, 4]].rename(columns={
    0: 'Date_Period',
    2: 'Commodity',
    3: 'Quantity_Raw',
    4: 'Price_Raw'
})

# Clean and Convert Quantity (kg)
def clean_quantity(raw_str):
    if pd.isna(raw_str):
        return np.nan
    cleaned = re.sub(r'[^\d\.\s]', '', str(raw_str)).strip()
    match = re.search(r'[\d\.]+', cleaned)
    return float(match.group(0)) if match else np.nan

talong_df['Quantity (kg)'] = talong_df['Quantity_Raw'].apply(clean_quantity)

# Convert 'Date_Period' to a single representative date
def period_to_date(period_str):
    match = re.search(r'([A-Za-z]+\s+[\d]+)[^\d]*([\d]{4})', period_str)
    if match:
        day_month_part = match.group(1).split()
        day = day_month_part[-1]
        month = day_month_part[0]
        year = match.group(2)
        try:
            return pd.to_datetime(f'{month} {day}, {year}', errors='coerce')
        except:
            pass 
    
    match_my = re.search(r'([A-Za-z]+).*?([\d]{4})', period_str)
    if match_my:
        return pd.to_datetime(f'15 {match_my.group(1)}, {match_my.group(2)}', dayfirst=True, errors='coerce')
    
    return pd.NaT

talong_df['Date'] = talong_df['Date_Period'].apply(period_to_date)
talong_df.dropna(subset=['Date'], inplace=True) 
talong_df.sort_values(by='Date', inplace=True)

# Create the Monthly Demand Time Series (Sum of Quantity, imputed NaN with 0)
monthly_demand_ts = talong_df.set_index('Date')['Quantity (kg)'].resample('M').sum().fillna(0)


# --- 2. Data Splitting: Training and Test Sets ---
N = len(monthly_demand_ts)
test_periods = 6 # Use the last 6 months for testing

if N < 12:
    print(f"Error: Not enough data points ({N}) to create a 6-month test set and fit a seasonal model. Proceeding with all data as training, but RMSE calculation will be inaccurate.")
    # Set a fallback if data is too small (though it should be okay for Talong)
    test_periods = 0
    
if N > 0 and test_periods > 0:
    train_ts = monthly_demand_ts.iloc[:-test_periods]
    test_ts = monthly_demand_ts.iloc[-test_periods:]

    print(f"Total Historical Data Points (Months): {N}")
    print(f"Training Set Size: {len(train_ts)}")
    print(f"Test Set Size: {len(test_ts)} (from {test_ts.index.min().strftime('%Y-%m')} to {test_ts.index.max().strftime('%Y-%m')})")
else:
    print("Error: Talong data series is too short or empty for train/test split.")
    exit()


# --- 3. Model Fitting on Training Data ---
# Talong Demand Model Parameters: SARIMA(1, 1, 1)(0, 1, 0)_12
demand_order = (1, 1, 1)
demand_seasonal_order = (0, 1, 0, 12)

sarima_model = SARIMAX(
    train_ts,
    order=demand_order,
    seasonal_order=demand_seasonal_order,
    enforce_stationarity=False,
    enforce_invertibility=False
)

try:
    sarima_results = sarima_model.fit(disp=False)
except Exception as e:
    print(f"Model fitting failed: {e}")
    exit()


# --- 4. Generate Predictions for the Test Set ---
start_index = len(train_ts)
end_index = len(train_ts) + len(test_ts) - 1

predictions = sarima_results.get_prediction(start=start_index, end=end_index)
predicted_mean = predictions.predicted_mean

# Ensure predictions align with test_ts dates
predicted_mean.index = test_ts.index


# --- 5. Calculate MSE and RMSE ---
# Make sure predicted_mean and test_ts have the same index before calculation
test_ts_aligned = test_ts.loc[predicted_mean.index]

mse = mean_squared_error(test_ts_aligned, predicted_mean)
rmse = np.sqrt(mse)

print("\n--- Talong Demand Forecasting Evaluation ---")
print(f"Model: SARIMA{demand_order}{demand_seasonal_order}")
print(f"Mean Squared Error (MSE): {mse:.2f}")
print(f"Root Mean Squared Error (RMSE): {rmse:.2f} kg")

# Create a comparison DataFrame
comparison_df = pd.DataFrame({
    'Date': test_ts_aligned.index.strftime('%Y-%m'),
    'Actual Demand (kg)': np.round(test_ts_aligned.values, 2),
    'Predicted Demand (kg)': np.round(predicted_mean.values, 2),
    'Absolute Error (kg)': np.round(np.abs(test_ts_aligned.values - predicted_mean.values), 2)
})

print("\n--- Talong Demand: Actual vs. Predicted (Test Set) ---")
print(comparison_df.to_markdown(index=False, numalign="left", stralign="left"))
comparison_df.to_csv('talong_demand_test_set_comparison.csv', index=False)
print("Saved comparison table to 'talong_demand_test_set_comparison.csv'")