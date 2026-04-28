#!/usr/bin/env python
"""Create OPAS products from CSV into database.

CSV products are stored in OPASProduct table (not SellerProduct).
They are exclusively for demand forecasting and NOT for sale on marketplace.
"""

import os
import sys
import csv
import django
from collections import defaultdict
from django.utils import timezone

# Setup Django
sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.opas_models import OPASProduct

# Parse CSV to get unique products
csv_file = r'C:\BSCS-4B\Thesis\OPAS_Application\demand_and_price_forecasting\cleaned data.csv'
csv_products = set()

with open(csv_file, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if not any(row.values()):
            continue
        commodity = row.get('COMMODITY', '').strip()
        if commodity and commodity.lower() not in ['commodity', 'nan', '']:
            csv_products.add(commodity)

print(f"\nFound {len(csv_products)} unique products in CSV")

# Create OPAS products in database
print("\nCreating OPAS products (for forecasting only):")
created_count = 0
existing_count = 0

for product_name in sorted(csv_products):
    product, created = OPASProduct.objects.get_or_create(
        name=product_name,
        defaults={
            'is_active': True,
            'imported_from_csv': timezone.now(),
        }
    )
    
    if created:
        print(f"  Created: {product_name}")
        created_count += 1
    else:
        print(f"  Already exists: {product_name}")
        existing_count += 1

print("\n" + "=" * 70)
print(f"Summary:")
print(f"  Created: {created_count} new OPAS products")
print(f"  Existing: {existing_count} products")
print(f"  Total: {len(csv_products)} products")
print(f"\nNote: These products are stored in OPASProduct table")
print(f"      They are for forecasting only, NOT for marketplace sales")
print("=" * 70)
