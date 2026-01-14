#!/usr/bin/env python
import os
import sys
import django

# Setup Django
sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellerProduct, ProductCategory

print("=" * 80)
print("CATEGORY DEBUGGING SCRIPT")
print("=" * 80)

# 1. List all categories in database
print("\n1. ALL CATEGORIES IN DATABASE:")
print("-" * 80)
categories = ProductCategory.objects.all().values('id', 'name', 'slug', 'parent_id')
for cat in categories:
    parent_info = f" (Parent: {cat['parent_id']})" if cat['parent_id'] else ""
    print(f"  ID: {cat['id']:3d} | Name: {cat['name']:30s} | Slug: {cat['slug']:20s}{parent_info}")

# 2. Compare with hardcoded Flutter categories
print("\n2. FLUTTER HARDCODED CATEGORIES (from add_product_screen.dart):")
print("-" * 80)
flutter_categories = {
    'VEGETABLE': {'label': 'Vegetables', 'id': 223},
    'FRUIT': {'label': 'Fruits', 'id': 274},
    'LIVESTOCK': {'label': 'Livestock', 'id': 322},
    'POULTRY': {'label': 'Poultry', 'id': 359},
    'SEEDS': {'label': 'Seeds', 'id': 360},
    'FERTILIZERS': {'label': 'Fertilizers', 'id': 361},
    'FEEDS': {'label': 'Feeds', 'id': 362},
    'MEDICINES': {'label': 'Medicines', 'id': 363},
}

for key, cat_info in flutter_categories.items():
    db_cat = ProductCategory.objects.filter(id=cat_info['id']).first()
    if db_cat:
        match = "✅ MATCH" if db_cat.name.lower() == cat_info['label'].lower() else "❌ MISMATCH"
        print(f"  {key:15s} (ID {cat_info['id']:3d}): Flutter='{cat_info['label']:20s}' | DB='{db_cat.name:20s}' | {match}")
    else:
        print(f"  {key:15s} (ID {cat_info['id']:3d}): Flutter='{cat_info['label']:20s}' | DB='NOT FOUND'            | ❌ MISSING")

# 3. Show all products with their categories
print("\n3. ALL PRODUCTS WITH THEIR CATEGORIES:")
print("-" * 80)
products = SellerProduct.objects.all().select_related('category')
if products.exists():
    for prod in products:
        category_name = prod.category.name if prod.category else "NULL/NOT SET"
        category_id = prod.category.id if prod.category else "NULL"
        print(f"  Product: {prod.name:30s} | ID: {prod.id:3d} | Category: {category_name:30s} (ID: {category_id})")
else:
    print("  No products found in database")

# 4. Check for 'Agricultural Product' category
print("\n4. CHECKING FOR 'Agricultural Product' CATEGORY:")
print("-" * 80)
ag_product = ProductCategory.objects.filter(name__icontains='agricultural').first()
if ag_product:
    print(f"  ✅ Found: ID {ag_product.id}, Name: '{ag_product.name}', Slug: '{ag_product.slug}'")
else:
    print(f"  ❌ Not found in database")

print("\n" + "=" * 80)
