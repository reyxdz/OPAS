#!/usr/bin/env python
"""Test OPAS product display with Naval, Biliran location"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.admin_serializers import OPASProductUploadSerializer, get_or_create_opas_seller
from apps.users.seller_serializers import ProductListBuyerSerializer
from apps.users.seller_models import SellerProduct

# Create a test product
test_data = {
    'product_name': 'Farm-Fresh Tomatoes',
    'description': 'Fresh red tomatoes from Naval, Biliran',
    'price': '85.00',
    'stock_level': 100,
    'category_forecast': 'VEGETABLE',
    'product_type': 'Tomato',
    'product_subtype': 'Cherry',
}

serializer = OPASProductUploadSerializer(data=test_data)
if serializer.is_valid():
    result = serializer.save()
    product_id = result['product_id']
    
    # Get the product and serialize it for display
    product = SellerProduct.objects.get(id=product_id)
    
    # Serialize using buyer serializer (what's displayed on cards)
    display_serializer = ProductListBuyerSerializer(product)
    data = display_serializer.data
    
    print('✓ Test Product Created for Display Verification:')
    print(f"  Product Name: {data['name']}")
    print(f"  Price: ₱{data['price']}")
    print(f"  Seller Name: {data['seller_name']}")
    print(f"  Farm Location: {data['farm_location']}")
    print(f"  Category: {data['category']}")
else:
    print('✗ Error:', serializer.errors)
