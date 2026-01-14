import pandas as pd
import numpy as np

# =========================================================================
# ⚠️ ACTION REQUIRED: SET YOUR UNIT CONVERSIONS ⚠️
# Ensure this dictionary is accurate for your local product weights.
# =========================================================================
UNIT_CONVERSIONS = {
    'pcs': 0.25,      
    'tali': 0.5,      
    'packs': 0.75,    
}

# Define dummy cleaning functions for simplicity, as the final cleaning is done 
# in the main logic below after the user's initial structure was corrected.

# --- MAIN DATA PROCESSING BLOCK ---

# Load the file
df = pd.read_csv(r'C:\Users\User\OneDrive\Desktop\Model\datas\cleaned data.csv')

# 1. Drop the empty/NaN rows and set up the index
df.dropna(how='all', inplace=True)
df['DATE'] = pd.to_datetime(df['DATE'], errors='coerce')
df.dropna(subset=['DATE'], inplace=True)
df.set_index('DATE', inplace=True)

# 2. Clean and convert the numeric columns (CRITICAL STEP)

# A. QUANTITY_kg(DEMAND): Remove unit strings, then convert to numeric
df['QUANTITY_kg(DEMAND)'] = (
    df['QUANTITY_kg(DEMAND)']
    .str.lower()
    .str.replace('kg', '', regex=False)
    .str.replace('kls', '', regex=False)
    .str.strip()
)
df['QUANTITY_kg(DEMAND)'] = pd.to_numeric(df['QUANTITY_kg(DEMAND)'], errors='coerce')

# B. TOTAL SALES: Remove commas and convert to numeric
df['TOTAL SALES'] = (
    df['TOTAL SALES']
    .str.replace(',', '', regex=False)
    .str.strip()
)
df['TOTAL SALES'] = pd.to_numeric(df['TOTAL SALES'], errors='coerce')

# C. PRICE per kg: Remove commas and convert to numeric (Fixed for your data)
df['PRICE per kg'] = (
    df['PRICE per kg']
    .astype(str)
    .str.replace(',', '', regex=False)
    .str.strip()
    .astype(float)
)
df['PRICE per kg'] = pd.to_numeric(df['PRICE per kg'], errors='coerce')

# Drop any rows where key numeric columns failed to convert
df.dropna(subset=['QUANTITY_kg(DEMAND)', 'TOTAL SALES', 'PRICE per kg'], inplace=True)


# 3. Final Aggregation for SARIMA (Grouping by Commodity and Week)
# Group by the commodity and resample to a weekly frequency ('W').
df_sarima_ready = df.groupby(['COMMODITY']).resample('W').agg(
    Demand_kg=('QUANTITY_kg(DEMAND)', 'sum'),
    Average_Price_per_kg=('PRICE per kg', 'mean')
).dropna(how='all')

# Reset index and save
df_sarima_ready = df_sarima_ready.reset_index()
# New Save Path: Use your known absolute path structure
save_path = r'C:\Users\User\OneDrive\Desktop\Model\datas\SARIMA_FINAL_DATA.csv'
df_sarima_ready.to_csv(save_path, index=True)

print("SUCCESS: SARIMA_Final_Data.csv has been created and saved!")