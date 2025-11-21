#!/usr/bin/env python
"""Test that seller models can be imported and used"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User, UserRole, SellerStatus
from apps.users.models import (
    SellerProduct,
    SellerOrder,
    SellToOPAS,
    SellerPayout,
    SellerForecast,
)

print("✅ SELLER MODELS IMPORT TEST")
print("=" * 80)
print("\n✓ Successfully imported models from apps.users.models:")
print("  - User")
print("  - UserRole")
print("  - SellerStatus")
print("  - SellerProduct")
print("  - SellerOrder")
print("  - SellToOPAS")
print("  - SellerPayout")
print("  - SellerForecast")

print("\n" + "=" * 80)
print("\n📊 MODEL INFORMATION")
print("=" * 80)

models_info = [
    ('SellerProduct', SellerProduct),
    ('SellerOrder', SellerOrder),
    ('SellToOPAS', SellToOPAS),
    ('SellerPayout', SellerPayout),
    ('SellerForecast', SellerForecast),
]

for model_name, model_class in models_info:
    print(f"\n✓ {model_name}")
    print(f"  - Database table: {model_class._meta.db_table}")
    print(f"  - Fields: {len(model_class._meta.get_fields())}")
    print(f"  - App label: {model_class._meta.app_label}")

print("\n" + "=" * 80)
print("\n✅ DATABASE QUERIES TEST")
print("=" * 80)

# Test that we can query the models
print("\nQuerying database for existing records...")
print(f"\n  - SellerProduct count: {SellerProduct.objects.count()}")
print(f"  - SellerOrder count: {SellerOrder.objects.count()}")
print(f"  - SellToOPAS count: {SellToOPAS.objects.count()}")
print(f"  - SellerPayout count: {SellerPayout.objects.count()}")
print(f"  - SellerForecast count: {SellerForecast.objects.count()}")

print("\n" + "=" * 80)
print("✅ All seller models are properly set up and accessible!")
print("=" * 80)
