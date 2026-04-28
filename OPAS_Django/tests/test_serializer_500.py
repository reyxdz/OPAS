#!/usr/bin/env python
"""
Test ProductDetailBuyerSerializer to identify the 500 error
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, r'c:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
django.setup()

from apps.users.seller_models import SellerProduct
from apps.users.seller_serializers import ProductDetailBuyerSerializer

print("=" * 80)
print("Testing ProductDetailBuyerSerializer")
print("=" * 80)

# Get a product
product = SellerProduct.objects.filter(status='ACTIVE', stock_level__gt=0).first()
if product:
    print(f"\nTesting serializer for product: {product.name} (ID: {product.id})")
    try:
        serializer = ProductDetailBuyerSerializer(product, context={})
        data = serializer.data
        print(f"✅ Serialization successful!")
        print(f"   Fields returned: {len(data)}")
        print(f"\n   Keys: {list(data.keys())}")
    except Exception as e:
        print(f"❌ Serialization failed!")
        print(f"   Error: {type(e).__name__}: {e}")
        import traceback
        print("\n" + traceback.format_exc())
else:
    print("❌ No active products found in database")
