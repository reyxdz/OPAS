#!/usr/bin/env python
import requests
import json

# Get token
with open('token.txt') as f:
    token = f.read().strip()

# Test API
url = 'http://localhost:8000/api/admin/forecasts/'
headers = {'Authorization': f'Bearer {token}'}

print(f"Testing: {url}")
print(f"Token: {token[:30]}...\n")

try:
    response = requests.get(url, headers=headers)
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Total Forecasts: {data.get('count', 0)}")
        print(f"\nFirst 3 forecasts:")
        for i, forecast in enumerate(data.get('results', [])[:3]):
            print(f"\n{i+1}. {forecast.get('product_name', 'Unknown')}")
            print(f"   Demand: {forecast.get('demand_forecast_kg')} kg")
            print(f"   Price: ₱{forecast.get('price_forecast')}")
            print(f"   Confidence: {forecast.get('confidence_level')}")
            print(f"   Model: {forecast.get('model_type')}")
        print("\n✅ API is working correctly!")
    else:
        print(f"❌ Error: {response.status_code}")
        print(f"Response: {response.text[:500]}")
        
except Exception as e:
    print(f"❌ Exception: {e}")
