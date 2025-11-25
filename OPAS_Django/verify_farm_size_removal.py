#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import SellerRegistrationRequest

print("=" * 70)
print("DATABASE FIELD VERIFICATION")
print("=" * 70)

# Get all fields from model
fields = SellerRegistrationRequest._meta.get_fields()

print("\nSeller Registration Fields:")
print("-" * 70)
for field in fields:
    if 'farm' in field.name.lower() or 'product' in field.name.lower() or 'store' in field.name.lower():
        print(f"  - {field.name}")

print("\n" + "=" * 70)

# Check if farm_size is in fields
farm_size_exists = any(f.name == 'farm_size' for f in fields)

if farm_size_exists:
    print("ERROR: farm_size field still exists in model!")
else:
    print("OK: farm_size field successfully removed from model!")

print("=" * 70)
