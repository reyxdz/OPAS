#!/usr/bin/env python
import os
import django
from datetime import datetime

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.forecasting.models import ProductForecast
from apps.users.seller_models import SellerProduct

# Get all farmer products
products = SellerProduct.objects.all()
total_products = products.count()

# Test forecast data to cycle through
forecast_data = [
    {'demand': 180, 'price': 47, 'confidence': 'HIGH', 'model': 'SARIMA'},
    {'demand': 130, 'price': 33, 'confidence': 'MEDIUM', 'model': 'ARIMA'},
    {'demand': 190, 'price': 24, 'confidence': 'LOW', 'model': 'SIMPLE'},
]

print(f'Creating test forecasts for {total_products} farmer products...')
print('-' * 60)

success_count = 0
fail_count = 0

# Clear existing forecasts first
ProductForecast.objects.all().delete()

for i, product in enumerate(products, 1):
    try:
        data = forecast_data[i % len(forecast_data)]
        
        # Create a forecast entry for the farmer product
        ProductForecast.objects.create(
            product=product,  # Link to the actual SellerProduct
            forecast_date=datetime.now(),
            forecast_period='2025-01',
            demand_forecast_kg=data['demand'],
            demand_lower_bound=data['demand'] - 10,
            demand_upper_bound=data['demand'] + 10,
            price_forecast=data['price'],
            price_lower_bound=data['price'] - 2,
            price_upper_bound=data['price'] + 2,
            confidence_level=data['confidence'],
            model_type=data['model'],
            rmse_demand=5.5,
            rmse_price=1.2,
            is_current=True,
        )
        print(f'[{i:2d}/{total_products}] ✅ {product.name:20s} - {data["model"]:6s} ({data["confidence"]})')
        success_count += 1
    except Exception as e:
        print(f'[{i:2d}/{total_products}] ❌ {product.name:20s} - Error: {str(e)[:40]}')
        fail_count += 1

print('-' * 60)
print(f'✅ Created: {success_count} forecasts')
print(f'❌ Failed: {fail_count}')
print(f'📊 Total in database: {ProductForecast.objects.count()}')
