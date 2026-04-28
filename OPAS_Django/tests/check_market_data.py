#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.forecasting.models import MarketHistoricalData

# Check how many products we have in MarketHistoricalData
products = MarketHistoricalData.objects.values('product_name').distinct()
count = products.count()
total_records = MarketHistoricalData.objects.count()

print(f'📊 Market Historical Data Summary:')
print('-' * 50)
print(f'Total unique products: {count}')
print(f'Total records: {total_records}')
print()
print('Product list:')
for i, prod in enumerate(products[:20], 1):
    print(f'{i}. {prod["product_name"]}')
if count > 20:
    print(f'... and {count - 20} more products')
