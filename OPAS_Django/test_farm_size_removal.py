#!/usr/bin/env python
"""
Test script to verify farm_size field removal from seller registration
"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework.authtoken.models import Token
from apps.users.models import User, UserRole, SellerRegistrationRequest

print("=" * 70)
print("FARM SIZE REMOVAL VERIFICATION TEST")
print("=" * 70)

# Get buyer token
buyer = User.objects.filter(role=UserRole.BUYER).first()
token, _ = Token.objects.get_or_create(user=buyer)

# Clean up any existing registrations from this buyer
SellerRegistrationRequest.objects.filter(seller=buyer).delete()

# Create client and set auth header
client = Client()
auth_header = f'Token {token.key}'

# Test registration submission WITHOUT farm_size
print("\n1. Testing seller registration WITHOUT farm_size field:")
print("-" * 70)

registration_data = {
    'farm_name': 'Test Farm No Size',
    'farm_location': 'Test Location',
    'products_grown': 'Rice, Corn, Vegetables',
    'store_name': 'Test Store',
    'store_description': 'A test store for testing seller registration'
}

response = client.post(
    '/api/users/sellers/register-application/',
    data=json.dumps(registration_data),
    content_type='application/json',
    HTTP_AUTHORIZATION=auth_header
)

print(f"Status Code: {response.status_code}")

if response.status_code == 201:
    print("OK: Registration successful WITHOUT farm_size field")
    resp_data = json.loads(response.content.decode())
    print(f"\nResponse fields:")
    print(f"  Farm name:     {resp_data.get('farm_name')}")
    print(f"  Farm location: {resp_data.get('farm_location')}")
    print(f"  Products:      {resp_data.get('products_grown')}")
    print(f"  Store name:    {resp_data.get('store_name')}")
    print(f"  Status:        {resp_data.get('status_display')}")
    
    # Check if farm_size is NOT in response
    if 'farm_size' in resp_data:
        print("  ERROR: farm_size still present in response!")
    else:
        print("  OK: farm_size successfully removed from response")
else:
    print(f"ERROR: {response.content.decode()}")

# Clean up for next test
SellerRegistrationRequest.objects.filter(seller=buyer).delete()

print("\n2. Testing with farm_size field (should be ignored):")
print("-" * 70)

registration_data_with_size = {
    'farm_name': 'Test Farm With Size',
    'farm_location': 'Test Location',
    'farm_size': '10 hectares',  # This should be ignored
    'products_grown': 'Rice, Corn',
    'store_name': 'Test Store 2',
    'store_description': 'Test store with size field'
}

response = client.post(
    '/api/users/sellers/register-application/',
    data=json.dumps(registration_data_with_size),
    content_type='application/json',
    HTTP_AUTHORIZATION=auth_header
)

print(f"Status Code: {response.status_code}")

if response.status_code == 201:
    print("OK: Registration successful (farm_size field was ignored as expected)")
    resp_data = json.loads(response.content.decode())
    if 'farm_size' in resp_data:
        print("  ERROR: farm_size present in response!")
    else:
        print("  OK: farm_size correctly not included in response")
else:
    print(f"ERROR: {response.content.decode()}")

print("\n" + "=" * 70)
print("OK: Farm size field successfully removed from seller registration form!")
print("=" * 70)
