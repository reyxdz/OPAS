#!/usr/bin/env python
"""Test seller products endpoint with data"""

import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import User, UserRole, SellerStatus
from apps.users.seller_models import SellerProduct
import traceback

# Find or create a test seller
seller = User.objects.filter(role=UserRole.SELLER, seller_status=SellerStatus.APPROVED).first()
if not seller:
    seller = User.objects.create_user(
        email='test_seller_with_products@test.com',
        username='test_seller_with_products',
        password='testpass123',
        role=UserRole.SELLER,
        seller_status=SellerStatus.APPROVED,
        store_name='Test Store'
    )

print(f'Using seller: {seller.email}')

# Create test products
SellerProduct.objects.filter(seller=seller).delete()

products_data = [
    {
        'name': 'Fresh Tomatoes',
        'description': 'Ripe, red tomatoes',
        'product_type': 'VEGETABLE',
        'price': 50.00,
        'ceiling_price': 60.00,
        'quality_grade': 'PREMIUM',
        'stock_level': 100,
        'minimum_stock': 10,
        'unit': 'kg',
    },
    {
        'name': 'Organic Lettuce',
        'description': 'Fresh organic lettuce',
        'product_type': 'VEGETABLE',
        'price': 35.00,
        'ceiling_price': 45.00,
        'quality_grade': 'STANDARD',
        'stock_level': 50,
        'minimum_stock': 5,
        'unit': 'bunch',
    },
    {
        'name': 'Bananas',
        'description': 'Yellow bananas',
        'product_type': 'FRUIT',
        'price': 40.00,
        'ceiling_price': 50.00,
        'quality_grade': 'BASIC',
        'stock_level': 200,
        'minimum_stock': 20,
        'unit': 'kg',
    },
]

for pdata in products_data:
    SellerProduct.objects.create(seller=seller, **pdata)

print(f'Created {SellerProduct.objects.filter(seller=seller).count()} products')

# Get token
refresh = RefreshToken.for_user(seller)
access_token = str(refresh.access_token)

# Test endpoint
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

print('\n' + '='*80)
print('Testing GET /api/users/seller/products/')
print('='*80)

try:
    response = client.get('/api/users/seller/products/')
    print(f'Status Code: {response.status_code}')
    
    if response.status_code == 200:
        print(f'✅ Success! Response contains {len(response.data)} products:\n')
        for i, product in enumerate(response.data, 1):
            print(f'{i}. {product.get("name")}')
            print(f'   - ID: {product.get("id")}')
            print(f'   - Seller ID: {product.get("seller_id")}')
            print(f'   - Category: {product.get("category")}')
            print(f'   - Price: {product.get("price")}')
            print(f'   - Stock: {product.get("stock_level")}')
            print(f'   - Status: {product.get("status")}')
            print()
    else:
        print(f'❌ Error: {response.data}')
        
except Exception as e:
    print(f'❌ Exception: {e}')
    traceback.print_exc()
