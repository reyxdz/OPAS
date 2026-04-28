import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.forecasting.models import MarketHistoricalData
from datetime import datetime

# Get data for one product
data = MarketHistoricalData.objects.filter(product_name='Upo').order_by('market_date').values('market_date')[:20]

print("Sample data for Upo product:")
print("=" * 60)
for i, record in enumerate(data, 1):
    print(f"{i}. Date: {record['market_date']}")

# Check date differences
dates = [record['market_date'] for record in MarketHistoricalData.objects.filter(product_name='Upo').order_by('market_date').values('market_date')]
if len(dates) > 1:
    diff = (dates[1] - dates[0]).days
    print(f"\nDate granularity: {diff} days apart")
    if diff == 7:
        print("➜ This is WEEKLY data")
    elif diff == 30 or diff == 31:
        print("➜ This is MONTHLY data")
    elif diff == 1:
        print("➜ This is DAILY data")
