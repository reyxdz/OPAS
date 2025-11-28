#!/usr/bin/env python
import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellerProduct

# Get all active products
products = SellerProduct.objects.filter(status='ACTIVE', is_deleted=False)
print(f"Total active products: {products.count()}")

for p in products:
    seller_approved = p.seller.seller_status if p.seller else "No seller"
    print(f"  - ID: {p.id}, Name: {p.name}")
    print(f"    Status: {p.status}, Stock: {p.stock_level}")
    print(f"    Seller Approved: {seller_approved}")
    print(f"    Deleted: {p.is_deleted}")
    print()

# Check what the API would return
from django.db.models import Q
from apps.users.models import SellerStatus
api_products = SellerProduct.objects.filter(
    status='ACTIVE',
    is_deleted=False,
    stock_level__gt=0,
    seller__seller_status=SellerStatus.APPROVED
)
print(f"\nProducts that would show in API: {api_products.count()}")
for p in api_products:
    print(f"  - {p.name} (ID: {p.id})")
