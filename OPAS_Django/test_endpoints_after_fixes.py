#!/usr/bin/env python
import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework.authtoken.models import Token
from apps.users.models import User, UserRole

print("=" * 70)
print("ENDPOINT TESTS AFTER FIXES")
print("=" * 70)

# Test 1: Buyer registration
print("\n1. BUYER REGISTRATION TEST:")
print("-" * 70)
buyer = User.objects.filter(role=UserRole.BUYER).first()
token, _ = Token.objects.get_or_create(user=buyer)
client = Client()

# Clean up existing registrations
from apps.users.models import SellerRegistrationRequest
SellerRegistrationRequest.objects.filter(seller=buyer).delete()

registration_data = {
    'farm_name': 'Test Farm',
    'farm_location': 'Test Location',
    'products_grown': 'Rice, Corn',
    'store_name': 'Test Store',
    'store_description': 'Test store'
}

response = client.post(
    '/api/users/sellers/register-application/',
    data=json.dumps(registration_data),
    content_type='application/json',
    HTTP_AUTHORIZATION=f'Token {token.key}'
)

print(f"Status: {response.status_code}")
if response.status_code == 201:
    print("✓ Buyer can submit registration")
else:
    print(f"✗ Error: {response.content.decode()[:100]}")

# Test 2: Admin fetch sellers
print("\n2. ADMIN FETCH SELLERS TEST:")
print("-" * 70)
admin = User.objects.filter(username='opas_admin').first()
admin_token, _ = Token.objects.get_or_create(user=admin)

response = client.get(
    '/api/admin/sellers/',
    HTTP_AUTHORIZATION=f'Token {admin_token.key}'
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    data = json.loads(response.content.decode())
    count = len(data) if isinstance(data, list) else data.get('count', 0)
    print(f"✓ Admin can fetch sellers (Count: {count})")
else:
    print(f"✗ Error: {response.content.decode()[:100]}")

print("\n" + "=" * 70)
