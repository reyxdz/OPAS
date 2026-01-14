import pandas as pd
import matplotlib.pyplot as plt
from statsmodels.tsa.statespace.sarimax import SARIMAX

# --- 1 & 2. DEMAND Forecasting Plot Setup ---

# Load data and prepare demand time series
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])
talong_ts = talong_clean_df.set_index('Date')
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum().fillna(0)

# Fit SARIMA Model (1, 1, 1)(0, 1, 0)12
order_d = (1, 1, 1)
seasonal_order_d = (0, 1, 0, 12)
sarima_model = SARIMAX(
    monthly_demand_ts,
    order=order_d,
    seasonal_order=seasonal_order_d,
    enforce_stationarity=False,
    enforce_invertibility=False
)
sarima_results = sarima_model.fit(disp=False)

# Generate forecast (6 months)
start_date = monthly_demand_ts.index.max() + pd.DateOffset(months=1)
end_date = start_date + pd.DateOffset(months=5)
forecast_d = sarima_results.get_prediction(start=start_date, end=end_date)
forecast_mean_d = forecast_d.predicted_mean
forecast_ci_d = forecast_d.conf_int()

# Demand Plot
plt.figure(figsize=(10, 6))
# Plot historical data
monthly_demand_ts.plot(label='Historical Demand', color='tab:blue', marker='o')
# Plot forecast mean
forecast_mean_d.plot(ax=plt.gca(), label='6-Month Forecast', color='tab:red', linestyle='--')
# Plot confidence interval
plt.fill_between(forecast_ci_d.index,
                 forecast_ci_d.iloc[:, 0],
                 forecast_ci_d.iloc[:, 1], color='pink', alpha=0.3, label='95% Confidence Interval')

plt.title('Talong Demand Forecast (kg) with SARIMA(1, 1, 1)(0, 1, 0)₁₂')
plt.xlabel('Date')
plt.ylabel('Demand (kg)')
plt.legend(loc='upper left')
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
plt.savefig('talong_demand_forecast_plot.png')
plt.close()

# --- 3 & 4. PRICE Forecasting Plot Setup ---

# Load data and prepare price time series (WAP - only non-zero sales periods)
talong_clean_df['Sales_Value'] = talong_clean_df['Quantity (kg)'] * talong_clean_df['Price (PHP)']
monthly_data = talong_clean_df.set_index('Date').groupby(pd.Grouper(freq='M'))
monthly_demand_sum = monthly_data['Quantity (kg)'].sum()
monthly_sales_value = monthly_data['Sales_Value'].sum()
talong_monthly_ts = pd.concat([monthly_demand_sum, monthly_sales_value], axis=1)
price_ts = (talong_monthly_ts['Sales_Value'] / talong_monthly_ts['Quantity (kg)']).dropna().rename('WAP_Price_PHP')

# Fit ARIMA Model (1, 1, 0)
order_p = (1, 1, 0)
arima_model = SARIMAX(price_ts, order=order_p, enforce_stationarity=False, enforce_invertibility=False)
arima_results = arima_model.fit(disp=False)

# Generate forecast (6 months) using integer indices due to irregular time index
N = len(price_ts)
forecast_steps = 6
start_index = N
end_index = N + forecast_steps - 1

forecast_p = arima_results.get_prediction(start=start_index, end=end_index)
forecast_mean_p = forecast_p.predicted_mean
forecast_ci_p = forecast_p.conf_int()

# Create future date index for plotting (must match forecast points)
last_date = price_ts.index.max()
future_dates = pd.date_range(start=last_date + pd.DateOffset(days=1), periods=forecast_steps, freq='M')
forecast_mean_p.index = future_dates
forecast_ci_p.index = future_dates

# Price Plot
plt.figure(figsize=(10, 6))
# Plot historical data
price_ts.plot(label='Historical Price', color='tab:blue', marker='o')
# Plot forecast mean
forecast_mean_p.plot(ax=plt.gca(), label='6-Month Forecast', color='tab:red', linestyle='--')
# Plot confidence interval
plt.fill_between(forecast_ci_p.index,
                 forecast_ci_p.iloc[:, 0],
                 forecast_ci_p.iloc[:, 1], color='pink', alpha=0.3, label='95% Confidence Interval')

plt.title('Talong Price Forecast (PHP) with ARIMA(1, 1, 0)')
plt.xlabel('Date')
plt.ylabel('Price (PHP)')
plt.legend(loc='upper left')
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
plt.savefig('talong_price_forecast_plot.png')
plt.close()


import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX
import matplotlib.pyplot as plt

# --- 1. DEMAND FORECAST PLOT SETUP ---

# Data Preparation
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])
talong_ts = talong_clean_df.set_index('Date')
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum().fillna(0)

# Model Fitting
sarima_model = SARIMAX(
    monthly_demand_ts,
    order=(1, 1, 1),
    seasonal_order=(0, 1, 0, 12),
    enforce_stationarity=False,
    enforce_invertibility=False
)
sarima_results = sarima_model.fit(disp=False)

# Forecasting (6 months)
start_date_demand = monthly_demand_ts.index.max() + pd.DateOffset(months=1)
end_date_demand = start_date_demand + pd.DateOffset(months=5)

forecast_demand = sarima_results.get_prediction(start=start_date_demand, end=end_date_demand)
forecast_demand_mean = forecast_demand.predicted_mean
forecast_demand_ci = forecast_demand.conf_int()

# Demand Plot Generation
plt.figure(figsize=(12, 6))
# Historical Data
monthly_demand_ts.plot(label='Historical Demand', color='tab:blue', marker='o', linestyle='-')
# Forecast Mean
forecast_demand_mean.plot(ax=plt.gca(), label='6-Month Forecast', color='tab:red', linestyle='--')
# Confidence Interval
plt.fill_between(forecast_demand_ci.index,
                 forecast_demand_ci.iloc[:, 0],
                 forecast_demand_ci.iloc[:, 1], color='pink', alpha=0.3, label='95% Confidence Interval')

plt.title('Talong Monthly Demand Forecast (kg)')
plt.xlabel('Date')
plt.ylabel('Demand (kg)')
plt.grid(True, alpha=0.5)
plt.legend()
plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_demand_forecast_plot.png'
plt.savefig(save_path)
plt.close()

# --- 2. PRICE FORECAST PLOT SETUP ---

# Data Preparation
talong_clean_df['Sales_Value'] = talong_clean_df['Quantity (kg)'] * talong_clean_df['Price (PHP)']
monthly_data = talong_clean_df.set_index('Date').groupby(pd.Grouper(freq='M'))
monthly_demand_sum = monthly_data['Quantity (kg)'].sum()
monthly_sales_value = monthly_data['Sales_Value'].sum()
talong_monthly_ts = pd.concat([monthly_demand_sum, monthly_sales_value], axis=1)
talong_monthly_ts['WAP'] = talong_monthly_ts['Sales_Value'] / talong_monthly_ts['Quantity (kg)']
price_ts = talong_monthly_ts['WAP'].dropna().rename('WAP_Price_PHP')

# Model Fitting
arima_model = SARIMAX(
    price_ts,
    order=(1, 1, 0),
    enforce_stationarity=False,
    enforce_invertibility=False
)
arima_results = arima_model.fit(disp=False)

# Forecasting (6 months) using integer indices
N_price = len(price_ts)
forecast_steps = 6
start_index_price = N_price
end_index_price = N_price + forecast_steps - 1

forecast_price = arima_results.get_prediction(start=start_index_price, end=end_index_price)
forecast_price_mean = forecast_price.predicted_mean
forecast_price_ci = forecast_price.conf_int()

# Create the correct future date index manually for display
last_date_price = price_ts.index.max()
future_dates_price = pd.date_range(start=last_date_price + pd.DateOffset(days=1), periods=forecast_steps, freq='M')

# Price Plot Generation
plt.figure(figsize=(12, 6))
# Historical Data
price_ts.plot(label='Historical Price', color='tab:blue', marker='o', linestyle='-')
# Forecast Mean
plt.plot(future_dates_price, forecast_price_mean.values, label='6-Month Forecast', color='tab:red', linestyle='--')
# Confidence Interval
plt.fill_between(future_dates_price,
                 forecast_price_ci.iloc[:, 0].values,
                 forecast_price_ci.iloc[:, 1].values, color='pink', alpha=0.3, label='95% Confidence Interval')

plt.title('Talong Monthly Weighted Average Price Forecast (PHP)')
plt.xlabel('Date')
plt.ylabel('Price (PHP)')
plt.grid(True, alpha=0.5)
plt.legend()
plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_price_forecast_plot.png'
plt.savefig(save_path)
plt.close()