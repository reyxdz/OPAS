import pandas as pd
from statsmodels.tsa.stattools import adfuller
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
import matplotlib.pyplot as plt

# 1. Read the cleaned Talong data
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])

# Calculate the Sales Value for weighted average price calculation
talong_clean_df['Sales_Value'] = talong_clean_df['Quantity (kg)'] * talong_clean_df['Price (PHP)']

# 2. Aggregate to a monthly frequency (resampling handles the index)
monthly_data = talong_clean_df.set_index('Date').resample('Me')

# Calculate aggregated metrics
monthly_demand_sum = monthly_data['Quantity (kg)'].sum()
monthly_sales_value = monthly_data['Sales_Value'].sum()

# Calculate Weighted Average Price (WAP)
monthly_price_ts = (monthly_sales_value / monthly_demand_sum).rename('Weighted_Avg_Price_PHP')

# Filter for only months where sales occurred (WAP is not NaN)
price_ts_non_zero = monthly_price_ts.dropna()

print("Talong Price Time Series (Non-Zero Sales Months):")
print(price_ts_non_zero.to_markdown(numalign="left", stralign="left"))

# --- Time Series Analysis: Stationarity Check (ADF Test) ---
# 3. Run the Augmented Dickey-Fuller (ADF) Test
adf_result_price = adfuller(price_ts_non_zero)

print("\nAugmented Dickey-Fuller Test Results (Talong Price):")
print(f"ADF Statistic: {adf_result_price[0]:.4f}")
print(f"P-value: {adf_result_price[1]:.4f}")

# --- Time Series Analysis: Parameter Selection (ACF/PACF Plots) ---
# Check if differencing is needed based on P-value > 0.05
if adf_result_price[1] > 0.05:
    # Apply first-order differencing (d=1)
    price_ts_diff = price_ts_non_zero.diff(1).dropna()
    d_order = 1
else:
    price_ts_diff = price_ts_non_zero
    d_order = 0

# The sample size is only 14 after dropping NaNs, so nlags must be small (50% of 14 is 7, so use 6)
nlags_max = 6
fig, axes = plt.subplots(2, 1, figsize=(12, 6))

plot_acf(price_ts_diff, ax=axes[0], lags=nlags_max, title=f'ACF - Talong Price (d={d_order})', color='tab:blue')
plot_pacf(price_ts_diff, ax=axes[1], lags=nlags_max, title=f'PACF - Talong Price (d={d_order})', color='tab:red')

plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_price_acf_pacf.png'
plt.savefig(save_path)
plt.close()


import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX

# --- Data Preparation (Re-running successful parts) ---
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])
talong_clean_df['Sales_Value'] = talong_clean_df['Quantity (kg)'] * talong_clean_df['Price (PHP)']

monthly_data = talong_clean_df.set_index('Date').groupby(pd.Grouper(freq='M'))
monthly_demand_sum = monthly_data['Quantity (kg)'].sum()
monthly_sales_value = monthly_data['Sales_Value'].sum()

talong_monthly_ts = pd.concat([monthly_demand_sum, monthly_sales_value], axis=1)
talong_monthly_ts['WAP'] = talong_monthly_ts['Sales_Value'] / talong_monthly_ts['Quantity (kg)']
price_ts = talong_monthly_ts['WAP'].dropna().rename('WAP_Price_PHP')
# --- End of Data Preparation ---

# Fit the ARIMA Model (1, 1, 0)
order_price = (1, 1, 0)
arima_model = SARIMAX(
    price_ts,
    order=order_price,
    enforce_stationarity=False,
    enforce_invertibility=False
)
arima_results = arima_model.fit(disp=False)

print("\n--- ARIMA Model Summary: Talong Price (PHP) ---")
print(arima_results.summary())

# 6. Generate a forecast for the next 6 months using INTEGER indices
N = len(price_ts)
forecast_steps = 6
start_index = N  # Start at the position immediately after the last data point
end_index = N + forecast_steps - 1

# Generate forecast
forecast = arima_results.get_prediction(start=start_index, end=end_index)
forecast_mean = forecast.predicted_mean
forecast_ci = forecast.conf_int()

# Create the correct future date index manually for display
last_date = price_ts.index.max()
future_dates = pd.date_range(start=last_date + pd.DateOffset(days=1), periods=forecast_steps, freq='M')

# Combine results into a DataFrame
forecast_df_price = pd.DataFrame({
    'Forecast Date': future_dates.strftime('%Y-%m'),
    'Forecast Price (PHP)': forecast_mean.values.round(2),
    'Lower 95% CI': forecast_ci['lower WAP_Price_PHP'].values.round(2),
    'Upper 95% CI': forecast_ci['upper WAP_Price_PHP'].values.round(2)
})

# Display the forecast
print("\n--- Talong Monthly Price Forecast (Next 6 Months) ---")
print(forecast_df_price.to_markdown(index=False, numalign="left", stralign="left"))