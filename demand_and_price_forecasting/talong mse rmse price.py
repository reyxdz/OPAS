import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX
from sklearn.metrics import mean_squared_error
import numpy as np
import re

# --- 1. Data Preparation: Talong Price ---
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

# Clean and Convert Price (PHP)
talong_df['Price (PHP)'] = talong_df['Price_Raw'].astype(str).str.replace(',', '', regex=False)
talong_df['Price (PHP)'] = pd.to_numeric(talong_df['Price (PHP)'], errors='coerce')


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
talong_df.dropna(subset=['Date', 'Quantity (kg)', 'Price (PHP)'], inplace=True) 
talong_df.sort_values(by='Date', inplace=True)

# Calculate Sales Value for WAP
talong_df['Sales_Value'] = talong_df['Quantity (kg)'] * talong_df['Price (PHP)']

# Aggregate to monthly data
monthly_data = talong_df.set_index('Date').resample('M')
monthly_demand_sum = monthly_data['Quantity (kg)'].sum()
monthly_sales_value = monthly_data['Sales_Value'].sum()

# Calculate Weighted Average Price (WAP) and remove months with no sales (NaN WAP)
price_ts = (monthly_sales_value / monthly_demand_sum).dropna().rename('Weighted_Avg_Price_PHP')


# --- 2. Data Splitting: Training and Test Sets ---
N = len(price_ts)
test_periods = 6 # Use the last 6 months for testing

if N < 12:
    print(f"Error: Not enough price data points ({N}) to create a 6-month test set and fit a model.")
    exit()

train_ts = price_ts.iloc[:-test_periods]
test_ts = price_ts.iloc[-test_periods:]

print(f"Total Historical Price Data Points (Months): {N}")
print(f"Training Set Size: {len(train_ts)}")
print(f"Test Set Size: {len(test_ts)} (from {test_ts.index.min().strftime('%Y-%m')} to {test_ts.index.max().strftime('%Y-%m')})")


# --- 3. Model Fitting on Training Data ---
# Talong Price Model Parameters: ARIMA(1, 1, 0)
price_order = (1, 1, 0)

arima_model = SARIMAX(
    train_ts,
    order=price_order,
    enforce_stationarity=False,
    enforce_invertibility=False
)

try:
    arima_results = arima_model.fit(disp=False)
except Exception as e:
    print(f"Model fitting failed: {e}")
    exit()


# --- 4. Generate Predictions for the Test Set ---
# Use integer indices for prediction
start_index = len(train_ts)
end_index = len(train_ts) + len(test_ts) - 1

predictions = arima_results.get_prediction(start=start_index, end=end_index)
predicted_mean = predictions.predicted_mean

# Ensure predictions align with test_ts dates
predicted_mean.index = test_ts.index


# --- 5. Calculate MSE and RMSE ---
test_ts_aligned = test_ts.loc[predicted_mean.index]

mse = mean_squared_error(test_ts_aligned, predicted_mean)
rmse = np.sqrt(mse)

print("\n--- Talong Price Forecasting Evaluation ---")
print(f"Model: ARIMA{price_order}")
print(f"Mean Squared Error (MSE): {mse:.2f}")
print(f"Root Mean Squared Error (RMSE): {rmse:.2f} PHP")

# Create a comparison DataFrame
comparison_df = pd.DataFrame({
    'Date': test_ts_aligned.index.strftime('%Y-%m'),
    'Actual Price (PHP)': np.round(test_ts_aligned.values, 2),
    'Predicted Price (PHP)': np.round(predicted_mean.values, 2),
    'Absolute Error (PHP)': np.round(np.abs(test_ts_aligned.values - predicted_mean.values), 2)
})

print("\n--- Talong Price: Actual vs. Predicted (Test Set) ---")
print(comparison_df.to_markdown(index=False, numalign="left", stralign="left"))
comparison_df.to_csv('talong_price_test_set_comparison.csv', index=False)
print("Saved comparison table to 'talong_price_test_set_comparison.csv'")