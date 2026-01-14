#!/usr/bin/env python
"""Check products in database and CSV."""

import os
import sys
import csv
import django
from collections import defaultdict

# Setup Django
sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellerProduct

# Get products from database
print("=" * 70)
print("PRODUCTS IN DATABASE")
print("=" * 70)

db_products = list(SellerProduct.objects.filter(is_deleted=False).values('id', 'name').order_by('name'))
print(f"Total: {len(db_products)}")
for prod in db_products[:30]:
    print(f"  {prod['id']:3} - {prod['name']}")

if len(db_products) > 30:
    print(f"  ... and {len(db_products) - 30} more")

# Get products from CSV
print("\n" + "=" * 70)
print("PRODUCTS IN CSV")
print("=" * 70)

csv_file = r'C:\BSCS-4B\Thesis\OPAS_Application\demand_and_price_forecasting\cleaned data.csv'
csv_products = defaultdict(int)

try:
    with open(csv_file, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not any(row.values()):
                continue
            commodity = row.get('COMMODITY', '').strip()
            if commodity and commodity.lower() not in ['commodity', 'nan', '']:
                csv_products[commodity] += 1
except FileNotFoundError:
    print(f"File not found: {csv_file}")
    sys.exit(1)

print(f"Total unique: {len(csv_products)}")
sorted_products = sorted(csv_products.items(), key=lambda x: x[1], reverse=True)
for product, count in sorted_products:
    print(f"  {count:3} entries - {product}")

# Compare
print("\n" + "=" * 70)
print("MATCHING ANALYSIS")
print("=" * 70)

db_names = {p['name'].lower().strip() for p in db_products}
csv_names = {p[0].lower().strip() for p in sorted_products}

matches = db_names & csv_names
only_in_db = db_names - csv_names
only_in_csv = csv_names - db_names

print(f"Exact matches: {len(matches)}")
for name in sorted(matches):
    print(f"  - {name}")

if only_in_csv:
    print(f"\nIn CSV but not in DB: {len(only_in_csv)}")
    for name in sorted(only_in_csv):
        print(f"  - {name}")

if only_in_db:
    print(f"\nIn DB but not in CSV: {len(only_in_db)}")
    for name in sorted(only_in_db)[:10]:
        print(f"  - {name}")
    if len(only_in_db) > 10:
        print(f"  ... and {len(only_in_db) - 10} more")
