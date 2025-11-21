"""
Simple test to verify endpoints work
"""

import os
import sys
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, 'c:\\BSCS-4B\\Thesis\\OPAS_Application\\OPAS_Django')
django.setup()

from django.test import Client
from rest_framework.test import APIClient
from apps.users.models import User, UserRole

print("\n" + "=" * 70)
print("TESTING NOTIFICATION & ANNOUNCEMENT ENDPOINTS")
print("=" * 70)

# Create a test seller user
seller_user, created = User.objects.get_or_create(
    email='test_seller@example.com',
    defaults={
        'first_name': 'Test',
        'last_name': 'Seller',
        'role': UserRole.SELLER,
        'seller_status': 'APPROVED',
    }
)

if created:
    seller_user.set_password('testpass123')
    seller_user.save()
    print(f"\n✓ Created test seller: {seller_user.email}")
else:
    print(f"\n✓ Using existing test seller: {seller_user.email}")

# Create API client and authenticate
client = APIClient()
print("\n[TESTING ENDPOINTS]")

# Test 1: Get Notifications (unauthenticated - should fail)
print("\n1. GET /api/users/seller/notifications/ [NO AUTH]")
response = client.get('/api/users/seller/notifications/')
print(f"   Status: {response.status_code}")
if response.status_code == 401:
    print("   ✓ Correctly requires authentication")
else:
    print(f"   Response: {response.data if hasattr(response, 'data') else response.content[:200]}")

# Authenticate
client.force_authenticate(user=seller_user)
print(f"\n   Authenticated as: {seller_user.email}")

# Test 2: Get Notifications (authenticated)
print("\n2. GET /api/users/seller/notifications/ [AUTHENTICATED]")
response = client.get('/api/users/seller/notifications/')
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    print("   ✓ Endpoint works!")
    print(f"   Response: {response.data if hasattr(response, 'data') else response.content[:200]}")
else:
    print(f"   ✗ Error: {response.data if hasattr(response, 'data') else response.content[:500]}")

# Test 3: Get Announcements
print("\n3. GET /api/users/seller/announcements/ [AUTHENTICATED]")
response = client.get('/api/users/seller/announcements/')
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    print("   ✓ Endpoint works!")
    print(f"   Response: {response.data if hasattr(response, 'data') else response.content[:200]}")
else:
    print(f"   ✗ Error: {response.data if hasattr(response, 'data') else response.content[:500]}")

# Test 4: Get Notifications Filtered by Type
print("\n4. GET /api/users/seller/notifications/?type=Orders [AUTHENTICATED]")
response = client.get('/api/users/seller/notifications/?type=Orders')
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    print("   ✓ Filtering works!")
else:
    print(f"   ✗ Error: {response.data if hasattr(response, 'data') else response.content[:500]}")

print("\n" + "=" * 70)
print("ENDPOINT TESTING COMPLETE")
print("=" * 70 + "\n")
