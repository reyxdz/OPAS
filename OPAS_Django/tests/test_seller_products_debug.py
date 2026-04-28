#!/usr/bin/env python
"""
Debug test for seller products endpoint
"""

import os
import django
import json
import traceback

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework.test import APIClient
from rest_framework import status
from apps.users.models import User, UserRole, SellerStatus
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.seller_models import SellerProduct

print("\n" + "=" * 80)
print("DEBUG: Testing Seller Products Endpoint")
print("=" * 80)

# Setup test seller
test_seller_data = {
    'email': 'debug_test_seller@test.com',
    'username': 'debug_test_seller',
    'password': 'testpass123',
    'phone_number': '09123456789',
    'role': UserRole.SELLER,
    'seller_status': SellerStatus.APPROVED,
    'store_name': 'Debug Test Store',
}

# Cleanup
User.objects.filter(email=test_seller_data['email']).delete()

# Create seller
try:
    seller = User.objects.create_user(**test_seller_data)
    print(f"✅ Seller created: {seller.email}")
    print(f"   - Role: {seller.role}")
    print(f"   - Seller Status: {seller.seller_status}")
    print(f"   - Is Authenticated: {seller.is_authenticated}")
except Exception as e:
    print(f"❌ Error creating seller: {str(e)}")
    traceback.print_exc()
    exit(1)

# Create test products
try:
    for i in range(2):
        product = SellerProduct.objects.create(
            seller=seller,
            name=f"Test Product {i+1}",
            product_type="VEGETABLE",
            price=50.00,
            stock_level=100,
            quality="GOOD"
        )
    print(f"✅ Created test products")
    products = SellerProduct.objects.filter(seller=seller)
    print(f"   - Total products in DB: {products.count()}")
except Exception as e:
    print(f"❌ Error creating products: {str(e)}")
    traceback.print_exc()

# Get token
refresh = RefreshToken.for_user(seller)
access_token = str(refresh.access_token)
print(f"\n✅ Generated access token")

# Test API endpoint
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

print(f"\n📡 Testing GET /api/users/seller/products/")
try:
    response = client.get('/api/users/seller/products/')
    print(f"   Status: {response.status_code}")
    print(f"   Content-Type: {response.get('Content-Type', 'N/A')}")
    
    if response.status_code != 200:
        print(f"   Response Body: {response.data}")
    else:
        print(f"   ✅ Success! Products returned: {len(response.data)}")
        if response.data:
            print(f"   First product: {response.data[0]}")
    
except Exception as e:
    print(f"   ❌ Error: {str(e)}")
    traceback.print_exc()

# Check database directly
print(f"\n🔍 Database Check:")
try:
    all_products = SellerProduct.objects.all()
    print(f"   Total products in database: {all_products.count()}")
    
    seller_products = SellerProduct.objects.filter(seller=seller)
    print(f"   Products for test seller: {seller_products.count()}")
    
    if seller_products.exists():
        for p in seller_products:
            print(f"     - {p.id}: {p.name} (seller: {p.seller.email})")
except Exception as e:
    print(f"   ❌ Error querying database: {str(e)}")
    traceback.print_exc()

print("\n" + "=" * 80)
