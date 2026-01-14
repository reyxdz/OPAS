import pandas as pd
import re

# Load the file, skipping the initial description line, and let pandas handle the rest.
# Since the table structure is highly irregular, we read without a header initially.
df = pd.read_csv(r"C:\Users\User\OneDrive\Desktop\Model\cleaned datasets.csv", header=None)

# Inspect the loaded data
print("Initial DataFrame Head:")
print(df.head(20).to_markdown(index=False, numalign="left", stralign="left"))
print("\nInitial DataFrame Info:")
df.info()

# 1. Forward-fill Column 0 (Date/Period) to propagate the date.
df[0] = df[0].ffill()

# 2. Filter for rows that contain 'Talong' in Column 2 (Commodity).
# Use regex to find 'Talong' followed by optional space and a letter (e.g., 'Talong B')
talong_df = df[df[2].astype(str).str.contains(r'Talong\s*[A-Z]?', case=False, na=False)].copy()

# Select the relevant columns and rename them
talong_df = talong_df[[0, 2, 3, 4]].rename(columns={
    0: 'Date_Period',
    2: 'Commodity',
    3: 'Quantity_Raw',
    4: 'Price_Raw'
})

# 3. Clean and convert the Quantity column
# Remove non-digit/non-decimal/non-space characters (like 'kgs', 'kls', 'kg', 'packs'), handle fragmented numbers like '6. 8'
def clean_quantity(raw_string):
    if pd.isna(raw_string):
        return None
    # Replace fragmented numbers like '6. 8' with '6.8'
    cleaned_string = raw_string.replace('. ', '.').strip()
    # Extract the leading number, ignoring units like 'kgs', 'packs', and comments
    match = re.search(r'^[\d\s\.,]+', cleaned_string)
    if match:
        number_part = match.group(0).replace(',', '').strip()
        try:
            return float(number_part)
        except ValueError:
            return None
    return None

talong_df['Quantity (kg)'] = talong_df['Quantity_Raw'].apply(clean_quantity)

# 4. Clean and convert the Price column
talong_df['Price (PHP)'] = pd.to_numeric(talong_df['Price_Raw'].astype(str).str.replace(r'[^\d.]', '', regex=True), errors='coerce')

# 5. Extract a single representative date for time series indexing
def extract_start_date(period_str):
    try:
        # A list of common date formats to try
        date_formats = ["%B %d – %d, %Y", "%B %d- %d, %Y", "%B %d–%d, %Y",
                        "%B %d- %d, %Y", "%B %d- %d, %Y", "%B %d- %d, %Y", # For "November 16 – 30, 2023"
                        "%B %d- %d, %Y", # For "November 3- 15, 2023"
                        "%B %d- %d, %Y", # For "October 1- 15, 2023"
                        "%B %d-%d, %Y",  # For "February 11-April 29, 2025" - This will be tricky, use the start date.
                        "%B %d- %B %d, %Y", # For multi-month ranges
                        "%d-%b-%y", "%d-%b-%Y"] # For '31-Aug-23' and '7-Nov-23'

        # Try to parse single dates first
        if re.match(r'^\d{1,2}-\w{3}-\d{2,4}$', period_str):
            return pd.to_datetime(period_str, errors='coerce')

        # Extract the first date part from ranges
        match = re.match(r'(\w+)\s*(\d{1,2})', period_str)
        if match:
            month_name = match.group(1)
            day = match.group(2)
            year_match = re.search(r'(\d{4})', period_str)
            year = year_match.group(1) if year_match else '2023' # Default to 2023 if year is missing

            # Construct a string that pd.to_datetime can reliably parse (e.g., 'November 16, 2023')
            date_str = f"{month_name} {day}, {year}"
            return pd.to_datetime(date_str, errors='coerce')

        return pd.to_datetime(period_str, errors='coerce')

    except Exception:
        return pd.NaT

talong_df['Date'] = talong_df['Date_Period'].apply(extract_start_date)
# For the remaining NaT values, we will assign a default day if the month/year is present or drop them for simplicity in this demo.
# The row "February 19 – April 19, 2024" should parse to Feb 19, 2024. Let's check the result.

# Final selection and cleaning of columns
talong_clean_df = talong_df[['Date', 'Commodity', 'Quantity (kg)', 'Price (PHP)']].dropna(subset=['Date', 'Quantity (kg)', 'Price (PHP)'])

print("\nCleaned Talong Data (First 15 Rows):")
print(talong_clean_df.head(15).to_markdown(index=False, numalign="left", stralign="left"))
print("\nCleaned Talong Data Info:")
talong_clean_df.info()

# Save to CSV for the user to download if needed (though not explicitly requested, it's good practice)
talong_clean_df.to_csv('talong_time_series_data.csv', index=False)


# Standardize the commodity name
talong_clean_df['Commodity'] = 'Talong'

# Calculate the Total Sales Value for weighted average price calculation
talong_clean_df['Sales_Value'] = talong_clean_df['Quantity (kg)'] * talong_clean_df['Price (PHP)']

# Aggregate to a monthly frequency

# 1. Group by Month and Year
monthly_data = talong_clean_df.set_index('Date').groupby(pd.Grouper(freq='M'))

# 2. Calculate Total Demand (Quantity) and Total Sales Value
monthly_demand_sum = monthly_data['Quantity (kg)'].sum().rename('Monthly_Demand_kg')
monthly_sales_value = monthly_data['Sales_Value'].sum().rename('Monthly_Sales_Value')

# 3. Combine and calculate Weighted Average Price
talong_monthly_ts = pd.concat([monthly_demand_sum, monthly_sales_value], axis=1).dropna()

# Calculate the Weighted Average Price (Weighted Average Price = Total Sales Value / Total Demand)
talong_monthly_ts['Weighted_Avg_Price_PHP'] = talong_monthly_ts['Monthly_Sales_Value'] / talong_monthly_ts['Monthly_Demand_kg']

# Convert the monthly index to period for cleaner display
talong_monthly_ts.index = talong_monthly_ts.index.to_period('M')

print("\nFinal Talong Monthly Time Series Data:")
print(talong_monthly_ts.to_markdown(numalign="left", stralign="left"))

# --- Next Steps: Prepare for Plotting ---

import matplotlib.pyplot as plt

# Create the plot for Monthly Demand
plt.figure(figsize=(12, 5))
talong_monthly_ts['Monthly_Demand_kg'].plot(marker='o', linestyle='-', color='tab:blue')
plt.title('Talong Monthly Demand (kg) Time Series')
plt.xlabel('Date (Month-Year)')
plt.ylabel('Demand (kg)')
plt.grid(True)
plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_demand_time_series.png'
plt.savefig(save_path)
plt.close()

# Create the plot for Weighted Average Price
plt.figure(figsize=(12, 5))
talong_monthly_ts['Weighted_Avg_Price_PHP'].plot(marker='o', linestyle='-', color='tab:red')
plt.title('Talong Monthly Weighted Average Price (PHP) Time Series')
plt.xlabel('Date (Month-Year)')
plt.ylabel('Weighted Avg. Price (PHP)')
plt.grid(True)
plt.tight_layout()
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_price_time_series.png'
plt.savefig(save_path)
plt.close()


import pandas as pd
from statsmodels.tsa.stattools import adfuller
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
import matplotlib.pyplot as plt

# 1. Read the cleaned Talong data
talong_clean_df = pd.read_csv('talong_time_series_data.csv', parse_dates=['Date'])

# Calculate the Total Sales Value for weighted average price calculation
talong_clean_df['Sales_Value'] = talong_clean_df['Quantity (kg)'] * talong_clean_df['Price (PHP)']

# 2. Aggregate to a monthly frequency, ensuring all months are covered.
# Set the Date as index and resample/group monthly.
talong_ts = talong_clean_df.set_index('Date')

# Group by Month and Year (M) and sum the quantities.
# The 'asfreq' ensures all months between the first and last date are represented, filling with NaN where no sales occurred.
monthly_demand_ts = talong_ts['Quantity (kg)'].resample('M').sum()

# 3. Impute Demand: Fill NaN (missing months) with 0, as per Option B
monthly_demand_ts = monthly_demand_ts.fillna(0).rename('Monthly_Demand_kg')

print("Monthly Demand Series Head (Post-Imputation):")
print(monthly_demand_ts.head().to_markdown(numalign="left", stralign="left"))
print("Monthly Demand Series Tail (Post-Imputation):")
print(monthly_demand_ts.tail().to_markdown(numalign="left", stralign="left"))

# --- Time Series Analysis: Stationarity Check (ADF Test) ---

# 4. Run the Augmented Dickey-Fuller (ADF) Test
adf_result = adfuller(monthly_demand_ts)

print("\nAugmented Dickey-Fuller Test Results (Talong Demand):")
print(f"ADF Statistic: {adf_result[0]:.4f}")
print(f"P-value: {adf_result[1]:.4f}")
print(f"Critical Values (1%): {adf_result[4]['1%']:.4f}")
print(f"Critical Values (5%): {adf_result[4]['5%']:.4f}")

# --- Time Series Analysis: Parameter Selection (ACF/PACF Plots) ---

# 5. Plot ACF and PACF for the original series (d=0)
fig, axes = plt.subplots(2, 1, figsize=(12, 6))

plot_acf(monthly_demand_ts, ax=axes[0], lags=12, title='Autocorrelation Function (ACF) - Original Demand')
plot_pacf(monthly_demand_ts, ax=axes[1], lags=12, title='Partial Autocorrelation Function (PACF) - Original Demand')

plt.tight_layout()
# Use a raw string (r') for Windows paths and target the 'Model' folder
save_path = r'C:\Users\User\OneDrive\Desktop\Model\Talong Product\talong_demand_acf_pacf_original.png'
plt.savefig(save_path)
plt.close()
