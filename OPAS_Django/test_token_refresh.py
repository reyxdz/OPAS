#!/usr/bin/env python
"""Test token refresh"""

import os
import sys
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework_simplejwt.tokens import AccessToken, RefreshToken
from apps.users.models import User

print("=" * 80)
print("Testing Token Refresh")
print("=" * 80)

# Get buyer
buyer = User.objects.get(id=43)
print(f"\nUsing buyer: {buyer.email} (ID: {buyer.id})")

# Create fresh tokens
refresh = RefreshToken.for_user(buyer)
access = str(refresh.access_token)
refresh_str = str(refresh)

print(f"\n✅ Fresh Access Token: {access[:50]}...")
print(f"✅ Fresh Refresh Token: {refresh_str[:50]}...")

# Test with client
client = Client()

# Test 1: Use access token to call order endpoint
print("\n" + "=" * 80)
print("Test 1: Call order endpoint with fresh access token")
print("=" * 80)

response = client.post(
    '/api/orders/create/',
    data=json.dumps({
        'cart_items': [41],
        'payment_method': 'delivery',
        'delivery_address': '123 Main St'
    }),
    content_type='application/json',
    HTTP_AUTHORIZATION=f'Bearer {access}'
)

print(f"Status: {response.status_code}")
if response.status_code == 201:
    print("✅ Order created successfully!")
    data = json.loads(response.content)
    print(f"Order ID: {data.get('id')}")
else:
    print(f"❌ Failed: {response.content}")

# Test 2: Test token refresh
print("\n" + "=" * 80)
print("Test 2: Test token refresh endpoint")
print("=" * 80)

response = client.post(
    '/api/auth/token/refresh/',
    data=json.dumps({'refresh': refresh_str}),
    content_type='application/json'
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    print("✅ Token refresh successful!")
    data = json.loads(response.content)
    new_access = data.get('access')
    print(f"New access token: {new_access[:50]}...")
else:
    print(f"❌ Failed: {response.content}")
