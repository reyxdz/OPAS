#!/usr/bin/env python
"""Test script to verify fulfillment_methods field is working in API responses"""

import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, 'C:\\BSCS-4B\\Thesis\\OPAS_Application\\OPAS_Django')
django.setup()

from django.contrib.auth import get_user_model
from apps.users.seller_models import SellerProduct
from apps.users.seller_serializers import ProductListBuyerSerializer
from rest_framework.test import APIRequestFactory

User = get_user_model()

print("=" * 70)
print("FULFILLMENT METHODS FIELD TEST")
print("=" * 70)

# 1. Check if field exists in model
print("\n1. Checking SellerProduct model field:")
print("-" * 70)
has_field = hasattr(SellerProduct, 'fulfillment_methods')
print(f"✓ fulfillment_methods field exists: {has_field}")

if has_field:
    field = SellerProduct._meta.get_field('fulfillment_methods')
    print(f"  - Field type: {field.__class__.__name__}")
    print(f"  - Default value: {field.default}")
    print(f"  - Choices: {field.choices}")

# 2. Check database has the field
print("\n2. Checking database schema:")
print("-" * 70)
try:
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name='seller_products' 
            AND column_name='fulfillment_methods'
        """)
        result = cursor.fetchone()
        if result:
            print(f"✓ Column exists in database: {result}")
        else:
            print("✗ Column NOT found in database")
except Exception as e:
    print(f"⚠ Could not check database: {e}")

# 3. Test with sample product
print("\n3. Testing serializer output:")
print("-" * 70)
try:
    products = SellerProduct.objects.filter(fulfillment_methods__isnull=False).first()
    if products:
        factory = APIRequestFactory()
        request = factory.get('/')
        
        serializer = ProductListBuyerSerializer(products, context={'request': request})
        data = serializer.data
        
        if 'fulfillment_methods' in data:
            print(f"✓ fulfillment_methods in serializer output")
            print(f"  Value: {data['fulfillment_methods']}")
        else:
            print("✗ fulfillment_methods NOT in serializer output")
    else:
        print("⚠ No products with fulfillment_methods found")
        # Create one for testing
        try:
            seller = User.objects.filter(email__contains='seller').first()
            if seller:
                product = SellerProduct.objects.create(
                    name='Test Product for Fulfillment',
                    price=100.00,
                    stock_level=10,
                    seller=seller,
                    fulfillment_methods='delivery_and_pickup'
                )
                print(f"\n✓ Created test product: {product.name}")
                print(f"  fulfillment_methods: {product.fulfillment_methods}")
        except Exception as e:
            print(f"Could not create test product: {e}")
except Exception as e:
    print(f"✗ Error testing serializer: {e}")

print("\n" + "=" * 70)
print("TEST COMPLETE")
print("=" * 70)
