#!/usr/bin/env python
"""Verify serializer field types"""

import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import User, UserRole, SellerStatus
import json

seller = User.objects.filter(role=UserRole.SELLER, seller_status=SellerStatus.APPROVED).first()
refresh = RefreshToken.for_user(seller)
access_token = str(refresh.access_token)

client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

response = client.get('/api/users/seller/products/')
if response.status_code == 200 and response.data:
    print('Sample Product Response:')
    print(json.dumps(response.data[0], indent=2))
    print('\nField Types:')
    p = response.data[0]
    print(f"  seller_id type: {type(p.get('seller_id')).__name__} = {p.get('seller_id')}")
    print(f"  price type: {type(p.get('price')).__name__} = {p.get('price')}")
    print(f"  id type: {type(p.get('id')).__name__} = {p.get('id')}")
    print(f"  stock_level type: {type(p.get('stock_level')).__name__} = {p.get('stock_level')}")
