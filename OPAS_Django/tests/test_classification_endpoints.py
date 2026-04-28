#!/usr/bin/env python
"""Test the classification endpoints"""
import os
import sys
import django

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIClient
from django.contrib.auth import get_user_model

User = get_user_model()
client = APIClient()

print("=" * 60)
print("Testing Classification Endpoints")
print("=" * 60)

# Get or create a test admin user for testing
try:
    admin_user = User.objects.get(username='test_admin')
except User.DoesNotExist:
    admin_user = User.objects.create_superuser(
        username='test_admin',
        email='test@admin.com',
        password='testpass123',
        phone_number='+1234567890'
    )
client.force_authenticate(user=admin_user)

# Test 1: Get types for FRUIT
print("\n1. Getting types for FRUIT category:")
response = client.get('/api/admin/forecasts/types-for-category/?category=FRUIT')
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    print(f"   Types: {response.data.get('types', [])}")
else:
    print(f"   Error: {response.data}")

# Test 2: Get subtypes for FRUIT > Banana
print("\n2. Getting subtypes for FRUIT > Banana:")
response = client.get('/api/admin/forecasts/subtypes-for-type/?category=FRUIT&type=Banana')
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    print(f"   Subtypes: {response.data.get('subtypes', [])}")
else:
    print(f"   Error: {response.data}")

# Test 3: Get types for VEGETABLE
print("\n3. Getting types for VEGETABLE category:")
response = client.get('/api/admin/forecasts/types-for-category/?category=VEGETABLE')
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    print(f"   Types: {response.data.get('types', [])}")
else:
    print(f"   Error: {response.data}")

print("\n" + "=" * 60)
print("All tests completed!")
print("=" * 60)
