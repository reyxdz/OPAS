"""Quick check of available historical data"""
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.forecasting.models import HistoricalTransactions
from apps.users.models import SellerProduct
from django.db.models import Count

# Check what products have historical data
print("Products with historical transaction data:")
print("=" * 80)

top_products = (HistoricalTransactions.objects
               .values('product_id', 'product__name')
               .annotate(count=Count('id'), avg_qty=Count('quantity_sold_kg'))
               .order_by('-count')[:10])

for p in top_products:
    print(f"Product ID {p['product_id']:3d}: {p['product__name']:30s} - {p['count']:3d} records")

print(f"\nTotal historical transactions: {HistoricalTransactions.objects.count()}")
print(f"Total unique products: {HistoricalTransactions.objects.values('product_id').distinct().count()}")
