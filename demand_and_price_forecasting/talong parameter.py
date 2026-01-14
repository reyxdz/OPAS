import pandas as pd
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
import matplotlib.pyplot as plt

# 1. Read the cleaned Talong data
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])

# 2. Aggregate to a monthly frequency, ensuring all months are covered.
talong_ts = talong_clean_df.set_index('Date')
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum()

# 3. Impute Demand: Fill NaN (missing months) with 0
monthly_demand_ts = monthly_demand_ts.fillna(0)

# 4. Calculate the differenced series: Non-seasonal (d=1) then Seasonal (D=1, m=12)
ts_diff = monthly_demand_ts.diff(1).diff(12).dropna()

print("Differenced Time Series Head:")
print(ts_diff.head().to_markdown(numalign="left", stralign="left"))

# 5. Plot ACF and PACF for the differenced series
fig, axes = plt.subplots(2, 1, figsize=(12, 6))

plot_acf(ts_diff, ax=axes[0], lags=8, title='ACF - Differenced Talong Demand ($d=1, D=1, m=12$)', color='tab:blue')
plot_pacf(ts_diff, ax=axes[1], lags=8, title='PACF - Differenced Talong Demand ($d=1, D=1, m=12$)', color='tab:red')

plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_demand_acf_pacf_differenced.png'
plt.savefig(save_path)
plt.close()


import pandas as pd
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
import matplotlib.pyplot as plt

# 1. Read the cleaned Talong data
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])

# 2. Aggregate to a monthly frequency, ensuring all months are covered.
talong_ts = talong_clean_df.set_index('Date')
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum()

# 3. Impute Demand: Fill NaN (missing months) with 0
monthly_demand_ts = monthly_demand_ts.fillna(0)

# 4. Calculate the differenced series: Non-seasonal (d=1) then Seasonal (D=1, m=12)
ts_diff = monthly_demand_ts.diff(1).diff(12).dropna()

# 5. Plot ACF and PACF for the differenced series
# NOTE: Adjusted nlags to 8 due to small sample size after differencing (18 points).
nlags_max = 8
fig, axes = plt.subplots(2, 1, figsize=(12, 6))

plot_acf(ts_diff, ax=axes[0], lags=nlags_max, title=f'ACF - Differenced Talong Demand ($d=1, D=1, m=12$)', color='tab:blue')
plot_pacf(ts_diff, ax=axes[1], lags=nlags_max, title=f'PACF - Differenced Talong Demand ($d=1, D=1, m=12$)', color='tab:red')

plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_demand_acf_pacf_differenced.png'
plt.savefig(save_path)
plt.close()
