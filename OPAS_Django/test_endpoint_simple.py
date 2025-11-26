#!/usr/bin/env python
"""Test seller products endpoint"""

import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import User, UserRole, SellerStatus
import traceback

# Find or create a test seller
seller = User.objects.filter(role=UserRole.SELLER, seller_status=SellerStatus.APPROVED).first()
if not seller:
    print('No approved seller found, creating one...')
    seller = User.objects.create_user(
        email='test_seller_endpoint@test.com',
        username='test_seller_endpoint',
        password='testpass123',
        role=UserRole.SELLER,
        seller_status=SellerStatus.APPROVED,
        store_name='Test Store'
    )
    print(f'Created seller: {seller.email}')

print(f'Testing with seller: {seller.email}')

# Get token
refresh = RefreshToken.for_user(seller)
access_token = str(refresh.access_token)

# Test endpoint
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

print('\nTesting GET /api/users/seller/products/')
try:
    response = client.get('/api/users/seller/products/')
    print(f'Status Code: {response.status_code}')
    
    if response.status_code == 200:
        print(f'✅ Success! Response: {response.data}')
    else:
        print(f'❌ Error: {response.data}')
        
except Exception as e:
    print(f'❌ Exception: {e}')
    traceback.print_exc()
