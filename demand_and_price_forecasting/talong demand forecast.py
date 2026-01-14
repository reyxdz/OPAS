import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX
import numpy as np

# --- Data Preparation (Re-run) ---
# 1. Read the cleaned Talong data
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])

# 2. Aggregate to a monthly frequency, ensuring all months are covered.
talong_ts = talong_clean_df.set_index('Date')
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum()

# 3. Impute Demand: Fill NaN (missing months) with 0
monthly_demand_ts = monthly_demand_ts.fillna(0)

# --- Model Fitting (SARIMA) ---

# Parameters derived from ACF/PACF: SARIMA(1, 1, 1)(0, 1, 0)_12
order = (1, 1, 1)
seasonal_order = (0, 1, 0, 12)

# Create and fit the SARIMA model
# We use the full dataset for fitting due to the limited number of data points
try:
    model = SARIMAX(
        monthly_demand_ts,
        order=order,
        seasonal_order=seasonal_order,
        enforce_stationarity=False,
        enforce_invertibility=False,
        # Set max_iter higher for a small dataset that might struggle to converge
        initialization_method='approximate_diffuse'
    )

    results = model.fit(disp=False)
    print("--- SARIMA Model Summary ---")
    print(results.summary())

    # --- Forecasting ---
    # Forecast 6 periods (months) beyond the end of the current series (July 2025)
    start_date = monthly_demand_ts.index[-1] + pd.Timedelta(days=1)
    end_date = start_date + pd.DateOffset(months=6)

    # Generate the forecast
    forecast = results.get_forecast(steps=6)

    # Create a DataFrame for the forecast results
    forecast_df = forecast.summary_frame(alpha=0.05) # 95% confidence interval

    # Generate the forecast index (next 6 months)
    forecast_index = pd.date_range(
        start=monthly_demand_ts.index[-1] + pd.Timedelta(days=1),
        periods=6,
        freq='M'
    ).to_period('M')

    forecast_df.index = forecast_index
    forecast_df = forecast_df.rename(columns={'mean': 'Forecast_Demand_kg',
                                              'lower 95%': 'Lower_Bound_95%',
                                              'upper 95%': 'Upper_Bound_95%'})

    # Demand must be non-negative
    forecast_df['Forecast_Demand_kg'] = np.maximum(0, forecast_df['Forecast_Demand_kg'])
    forecast_df['Lower_Bound_95%'] = np.maximum(0, forecast_df['Lower_Bound_95%'])

    print("\n--- Talong Demand Forecast (Next 6 Months) ---")
    print(forecast_df[['Forecast_Demand_kg', 'Lower_Bound_95%', 'Upper_Bound_95%']].to_markdown(numalign="left", stralign="left"))

except Exception as e:
    print(f"An error occurred during SARIMA fitting: {e}")
    # Fallback plan for highly unstable model/small data: try a simpler ARIMA
    try:
        model_fallback = SARIMAX(
            monthly_demand_ts,
            order=(1, 1, 1), # ARIMA (non-seasonal only)
            initialization_method='approximate_diffuse'
        ).fit(disp=False)
        print("\n--- Fallback ARIMA Model Summary ---")
        print(model_fallback.summary())

        forecast_fallback = model_fallback.get_forecast(steps=6)
        forecast_df_fallback = forecast_fallback.summary_frame(alpha=0.05)
        forecast_df_fallback.index = forecast_index
        forecast_df_fallback = forecast_df_fallback.rename(columns={'mean': 'Forecast_Demand_kg'})
        print("\n--- Talong Demand Forecast (Fallback ARIMA) ---")
        print(forecast_df_fallback[['Forecast_Demand_kg']].to_markdown(numalign="left", stralign="left"))

    except Exception as e_fallback:
        print(f"An error occurred during fallback ARIMA fitting: {e_fallback}")
        print("Cannot reliably fit a statistical model with the current sparse data.")


import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX

# 1. Read the cleaned Talong data
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])

# 2. Aggregate to a monthly frequency, ensuring all months are covered.
talong_ts = talong_clean_df.set_index('Date')
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum()

# 3. Impute Demand: Fill NaN (missing months) with 0
monthly_demand_ts = monthly_demand_ts.fillna(0)

# 4. Define the SARIMA orders based on ACF/PACF analysis: (1, 1, 1)(0, 1, 0)12
order = (1, 1, 1)
seasonal_order = (0, 1, 0, 12)

# 5. Fit the SARIMA model
# We use the full dataset for the fit since we have limited historical points.
sarima_model = SARIMAX(
    monthly_demand_ts,
    order=order,
    seasonal_order=seasonal_order,
    enforce_stationarity=False,
    enforce_invertibility=False
)

sarima_results = sarima_model.fit(disp=False)

print("\n--- SARIMA Model Summary: Talong Demand (kg) ---")
print(sarima_results.summary())

# 6. Generate a forecast for the next 6 months
# Start and end date for forecast (from the month after the last data point, Jul 2025)
start_date = monthly_demand_ts.index.max() + pd.DateOffset(months=1)
end_date = start_date + pd.DateOffset(months=5) # 6 months total (Aug 2025 to Jan 2026)

forecast = sarima_results.get_prediction(start=start_date, end=end_date)
forecast_mean = forecast.predicted_mean
forecast_ci = forecast.conf_int()

# Combine results into a DataFrame
forecast_df = pd.DataFrame({
    'Forecast Date': forecast_mean.index.strftime('%Y-%m'),
    'Forecast Demand (kg)': forecast_mean.round(2),
    'Lower 95% CI': forecast_ci['lower Quantity (kg)'].round(2),
    'Upper 95% CI': forecast_ci['upper Quantity (kg)'].round(2)
})

# Display the forecast
print("\n--- Talong Monthly Demand Forecast (Next 6 Months) ---")
print(forecast_df.to_markdown(index=False, numalign="left", stralign="left"))
