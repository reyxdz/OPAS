"""Check available forecasting data"""
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.forecasting.models import ProductForecast, MarketHistoricalData, HistoricalTransactions
from apps.users.models import SellerProduct
from django.db.models import Count

print("=" * 80)
print("AVAILABLE DATA SOURCES FOR EVALUATION")
print("=" * 80)

active_products = SellerProduct.objects.filter(is_deleted=False, status='ACTIVE').count()
print(f"\nSellerProducts (Active): {active_products}")
print(f"ProductForecasts: {ProductForecast.objects.count()}")
print(f"MarketHistoricalData: {MarketHistoricalData.objects.count()}")
print(f"HistoricalTransactions: {HistoricalTransactions.objects.count()}")

# Check ProductForecasts
forecasts_count = ProductForecast.objects.values('product__name').annotate(count=Count('id')).count()
print(f"\nProducts with Forecasts: {forecasts_count}")

forecasts = ProductForecast.objects.values('product__name').annotate(count=Count('id')).order_by('-count')[:5]
if forecasts:
    print(f"\nTop 5 products with forecasts:")
    for f in forecasts:
        print(f"  - {f['product__name']}: {f['count']} forecasts")

# Check MarketHistoricalData
market_products = MarketHistoricalData.objects.values('product_name').annotate(count=Count('id')).order_by('-count')[:5]
if market_products:
    print(f"\nTop 5 market data products:")
    for p in market_products:
        print(f"  - {p['product_name']}: {p['count']} records")

print("\n" + "=" * 80)
print("SOLUTION: Use ProductForecast data to evaluate model accuracy")
print("=" * 80)
