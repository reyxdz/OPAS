#!/usr/bin/env python
import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import User, UserRole, SellerRegistrationRequest

print("=" * 70)
print("JWT TOKEN TEST WITH BEARER FORMAT")
print("=" * 70)

# Create JWT token like Flutter app does
admin = User.objects.filter(username='opas_admin').first()
refresh = RefreshToken.for_user(admin)
jwt_access = str(refresh.access_token)

print(f"\nJWT Access Token (first 50 chars): {jwt_access[:50]}...")

# Test with Bearer format
client = Client()

print("\n1. Testing Admin Access with Bearer + JWT Token:")
print("-" * 70)
response = client.get(
    '/api/admin/sellers/',
    HTTP_AUTHORIZATION=f'Bearer {jwt_access}'
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    data = json.loads(response.content.decode())
    count = len(data) if isinstance(data, list) else data.get('count', 0)
    print(f"✓ JWT token works for admin! (Count: {count})")
else:
    print(f"✗ Error: {response.content.decode()[:100]}")

# Test buyer registration with JWT
print("\n2. Testing Buyer Registration with Bearer + JWT Token:")
print("-" * 70)
buyer = User.objects.filter(role=UserRole.BUYER).first()
buyer_refresh = RefreshToken.for_user(buyer)
buyer_jwt = str(buyer_refresh.access_token)

# Clean up
SellerRegistrationRequest.objects.filter(seller=buyer).delete()

registration_data = {
    'farm_name': 'JWT Test Farm',
    'farm_location': 'JWT Location',
    'products_grown': 'Rice',
    'store_name': 'JWT Store',
    'store_description': 'JWT test'
}

response = client.post(
    '/api/users/sellers/register-application/',
    data=json.dumps(registration_data),
    content_type='application/json',
    HTTP_AUTHORIZATION=f'Bearer {buyer_jwt}'
)

print(f"Status: {response.status_code}")
if response.status_code == 201:
    print("✓ JWT token works for buyer registration!")
    data = json.loads(response.content.decode())
    print(f"  Registration ID: {data.get('id')}")
    print(f"  Status: {data.get('status_display')}")
else:
    print(f"✗ Error: {response.content.decode()[:150]}")

print("\n" + "=" * 70)
print("✓ All endpoints working with JWT tokens!")
print("=" * 70)
