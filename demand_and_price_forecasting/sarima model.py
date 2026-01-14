import pandas as pd
import numpy as np
from pmdarima import auto_arima
from statsmodels.tsa.statespace.sarimax import SARIMAX 
from sklearn.metrics import mean_squared_error, mean_absolute_percentage_error
import warnings

# Suppress convergence and other non-critical warnings during the model search
warnings.filterwarnings("ignore")

# --- 1. Imputation Function (To handle NaN prices) ---
def impute_prices(group):
    """
    Fills NaN prices using ffill (last known price) then mean for any remaining NaNs.
    This ensures the time series is continuous.
    """
    # 1. Forward Fill: Use the last known price
    group['Average_Price_per_kg'].fillna(method='ffill', inplace=True)
    
    # 2. Mean Fill: Use the commodity's mean price if NaNs still exist (e.g., at the start)
    group['Average_Price_per_kg'].fillna(group['Average_Price_per_kg'].mean(), inplace=True)
    return group

# --- MAIN MODELING BLOCK ---

# Load the clean file
try:
    df_final = pd.read_csv(r'C:\Users\User\OneDrive\Desktop\Model\datas\SARIMA_FINAL_DATA.csv')
except FileNotFoundError:
    print("ERROR: SARIMA_Final_Data.csv not found. Please run data_prep.py first.")
    exit()

# Set up the index and apply imputation
df_final['DATE'] = pd.to_datetime(df_final['DATE'])
# Grouping by commodity and applying the imputation function to each group
df_imputed = df_final.groupby('COMMODITY', group_keys=False).apply(impute_prices) 
df_imputed.set_index('DATE', inplace=True)

# Define storage for results
all_metrics = {}
all_forecast_results = {} # Stores Actual vs. Forecast data for plotting

# Identify all unique commodities
commodities = df_imputed['COMMODITY'].unique()


# --- 2. TRAIN/TEST SPLIT DEFINITION ---
split_ratio = 0.8
split_date_index = int(len(df_imputed.index.unique()) * split_ratio)
split_date = df_imputed.index.unique()[split_date_index]

for commodity in commodities:
    
    # Isolate the time series for the current commodity
    df_commodity = df_imputed[df_imputed['COMMODITY'] == commodity].drop(columns='COMMODITY')
    
    # --- 💡 NEW ROBUST DATA FILTER ---
    # 1. Require at least 20 weeks of total data
    if len(df_commodity) < 20: 
        print(f"\n   Skipping {commodity}: Total data too short ({len(df_commodity)} weeks).")
        continue
    
    # Split the specific commodity's data based on the date
    train = df_commodity[df_commodity.index < split_date]
    test = df_commodity[df_commodity.index >= split_date]
    
    if len(train) < 15: # 2. Require at least 15 weeks for training
        print(f"\n   Skipping {commodity}: Training data too short ({len(train)} weeks).")
        continue

    print(f"\n================ Starting Modeling for: {commodity} ================")

    
    for target_col in ['Demand_kg', 'Average_Price_per_kg']:
        series_train = train[target_col].dropna() # Drop any NAs that might have slipped through
        
        # 3. Check for Zero Variance (Flat Data)
        # We need the training data to have more than 1 unique value
        if series_train.nunique() <= 1:
             print(f"   Skipping {target_col}: Data is constant or flat. Cannot model.")
             continue
        
        series_test = test[target_col] # Keep test set as is
        
        # --- SARIMA TRAINING (The existing try/except block starts here) ---
        try:
            # Parameter Selection
            model_auto = auto_arima(
                series_train, 
                seasonal=True, 
                m=1,
                stepwise=True,
                suppress_warnings=True, 
                error_action='ignore'
            )
            
            # B. Model Fitting
            order = model_auto.order
            seasonal_order = model_auto.seasonal_order
            
            sarima_model_fit = SARIMAX(
                series_train, 
                order=order, 
                seasonal_order=seasonal_order, 
                enforce_stationarity=False, 
                enforce_invertibility=False
            ).fit(disp=False)

            # C. Forecasting on the Test Set
            forecast_result = sarima_model_fit.predict(
                start=series_test.index[0], 
                end=series_test.index[-1]
            )
            
            # D. Evaluation (Only proceed if forecast succeeded)
            rmse = np.sqrt(mean_squared_error(series_test, forecast_result))
            mape = mean_absolute_percentage_error(series_test, forecast_result) * 100
            
            
            # Store results
            key = f'{commodity}_{target_col}'
            all_metrics[key] = {'RMSE': rmse, 'MAPE': mape, 'Order': f'{order}{seasonal_order}'}
            all_forecast_results[key] = pd.DataFrame({'Actual': series_test, 'Forecast': forecast_result})
            
            print(f"   {target_col}: RMSE={rmse:.2f}, MAPE={mape:.2f}% | Order: {order}{seasonal_order}")

        except Exception as e:
            # Catch errors like flat series, too few data, or convergence failure
            print(f"   FATAL ERROR: Could not train {target_col} model for {commodity}. Skipping. Error: {e}")
            continue # Skip to the next target_col/commodity\

# --- 4. Final Future Prediction Generation ---

from statsmodels.tsa.statespace.sarimax import SARIMAX

forecast_steps = 4 # Predict the next 4 weeks
final_future_forecasts = {}
final_forecast_success = False

# Loop through every model that successfully trained in the evaluation step
df_imputed.columns = df_imputed.columns.str.strip()  # Normalize ONCE before loop

for key, metrics in all_metrics.items():
    print(f"\n=== Processing key: {key} ===")
    
    # Parse key safely
    if '_Demand_kg' in key:
        commodity = key.replace('_Demand_kg', '')
        target_col = 'Demand_kg'
    elif '_Average_Price_per_kg' in key:
        commodity = key.replace('_Average_Price_per_kg', '')
        target_col = 'Average_Price_per_kg'
    else:
        print(f"Skipping unknown key format: {key}")
        continue
    
    print(f"Commodity: {commodity}, Target: {target_col}")
    
    # Get the series
    filtered = df_imputed[df_imputed['COMMODITY'] == commodity]
    if filtered.empty:
        print(f"Warning: No data for commodity '{commodity}', skipping...")
        continue
    
    full_series = filtered[target_col].dropna()
    if full_series.empty:
        print(f"Warning: No data for {commodity} / {target_col}, skipping...")
        continue
    
    print(f"Series length: {len(full_series)}")
    
    # Parse order and seasonal_order safely
    try:
        order_str = str(metrics['Order']).strip()
        print(f"DEBUG - Order string for {key}: '{order_str}'")
        
        # Extract (p,d,q) and (P,D,Q,m)
        parts = order_str.replace('(', '').replace(')', '').split(',')
        if len(parts) >= 3:
            order = (int(parts[0]), int(parts[1]), int(parts[2]))
            if len(parts) >= 7:
                P, D, Q, m = int(parts[3]), int(parts[4]), int(parts[5]), int(parts[6])
                # FIX: Ensure seasonal period is at least 2, or use non-seasonal
                if m < 2:
                    seasonal_order = (0, 0, 0, 0)  # Non-seasonal
                else:
                    seasonal_order = (P, D, Q, m)
            else:
                seasonal_order = (0, 0, 0, 0)
        else:
            order = (1, 1, 1)
            seasonal_order = (0, 0, 0, 0)
    except Exception as e:
        print(f"Error parsing order for {key}: {e}")
        order = (1, 1, 1)
        seasonal_order = (0, 0, 0, 0)
    
    # Re-train on full series and forecast
    try:
        final_model = SARIMAX(full_series, order=order, seasonal_order=seasonal_order, 
                              enforce_stationarity=False, enforce_invertibility=False).fit(disp=False)
        future_forecast = final_model.forecast(steps=forecast_steps)
        final_future_forecasts[key] = future_forecast
        final_forecast_success = True
        print(f"✅ Forecast success for {key}")
    except Exception as e:
        print(f"❌ Failed final forecast for {key}: {e}")
        # Fallback: use simple ARIMA (non-seasonal)
        try:
            final_model = SARIMAX(full_series, order=order, seasonal_order=(0,0,0,0),
                                  enforce_stationarity=False, enforce_invertibility=False).fit(disp=False)
            future_forecast = final_model.forecast(steps=forecast_steps)
            final_future_forecasts[key] = future_forecast
            final_forecast_success = True
            print(f"✅ Forecast success (non-seasonal fallback) for {key}")
        except Exception as e2:
            print(f"❌ Fallback also failed for {key}: {e2}")
        
# Display the results 
if final_forecast_success and final_future_forecasts:
    future_forecasts_df = pd.DataFrame(final_future_forecasts)
    print("\nFUTURE FORECASTS (Next 4 Weeks):")
    print(future_forecasts_df.to_markdown(numalign="left", stralign="left"))

    # Save the file
    future_forecasts_df.to_csv('SARIMA_Future_Forecasts.csv', index=True)
    print("\n✅ Future forecasts saved to SARIMA_Future_Forecasts.csv")
else:
    print("\n⚠️ No stable forecasts were generated for saving the final CSV.")

# Display Final Metrics
metrics_df = pd.DataFrame.from_dict(all_metrics, orient='index')
print("\n\nFINAL MODEL METRICS SUMMARY:")
print(metrics_df.sort_values(by='MAPE').to_markdown(numalign="left", stralign="left"))


# -------------------------------------------------------------------
# --- SAVING EVALUATION RESULTS FOR VISUALIZATION ---
# -------------------------------------------------------------------

all_forecasts_list = []
# Loop through the dictionary holding the test set results
for key, df in all_forecast_results.items():
    commodity, target = key.rsplit('_', 1)
    
    # Restructure the small DataFrame for saving
    df = df.reset_index()
    df['COMMODITY'] = commodity
    df['TARGET'] = target
    
    # Clean the index column name (if it's not already 'DATE')
    if 'index' in df.columns:
        df.rename(columns={'index': 'DATE'}, inplace=True)
    
    all_forecasts_list.append(df)

# Concatenate all results into one large DataFrame
df_evaluation_results = pd.concat(all_forecasts_list)

# Save the combined DataFrame to a CSV file
df_evaluation_results.to_csv('SARIMA_Evaluation_Results.csv', index=False)
print("\n✅ Evaluation results saved to SARIMA_Evaluation_Results.csv for plotting.")