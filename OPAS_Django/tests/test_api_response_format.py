#!/usr/bin/env python
"""
Test to verify the exact API response format matches Flutter expectations.
"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from apps.users.models import User, UserRole
from rest_framework.authtoken.models import Token

print("=" * 80)
print("TESTING API RESPONSE FORMAT FOR FLUTTER COMPATIBILITY")
print("=" * 80)

# Get admin user
admin_users = User.objects.filter(role=UserRole.ADMIN)
if admin_users.count() == 0:
    print("❌ No admin users found")
    exit(1)

admin_user = admin_users.first()
print(f"\n✓ Found admin user: {admin_user.email}")

# Create client and authenticate
client = Client()
token, created = Token.objects.get_or_create(user=admin_user)

# Make API request
headers = {'HTTP_AUTHORIZATION': f'Token {token.key}'}
response = client.get('/api/admin/sellers/pending-approvals/', **headers)

if response.status_code != 200:
    print(f"❌ API error: {response.status_code}")
    print(f"Response: {response.content}")
    exit(1)

data = json.loads(response.content)
results = data.get('results', [])

if not results:
    print("⚠️  No pending applications in response")
    exit(1)

# Check first result
first_app = results[0]
print(f"\n" + "=" * 80)
print("FIRST APPLICATION RESPONSE")
print("=" * 80)
print(json.dumps(first_app, indent=2, default=str))

# Check required fields for Flutter
print(f"\n" + "=" * 80)
print("FLUTTER FIELD VALIDATION")
print("=" * 80)

required_fields = {
    'id': 'Application ID',
    'seller_email': 'Seller email (for display)',
    'seller_full_name': 'Seller full name (for display)',
    'farm_name': 'Farm name',
    'farm_location': 'Farm location',
    'store_name': 'Store/business name',
    'store_description': 'Store description',
    'submitted_at': 'Application submission date',
    'status': 'Application status',
}

missing_fields = []
for field, description in required_fields.items():
    if field in first_app:
        print(f"✅ {field}: {description}")
        print(f"   Value: {first_app[field]}")
    else:
        print(f"❌ {field}: {description} - MISSING!")
        missing_fields.append(field)

# Also check for extra/alternative fields
print(f"\n" + "=" * 80)
print("ALTERNATIVE FIELDS (if main ones missing)")
print("=" * 80)

if 'user_email' in first_app and 'seller_email' not in first_app:
    print(f"⚠️  'user_email' present but 'seller_email' missing")
    print(f"   Value: {first_app['user_email']}")

if 'created_at' in first_app and 'submitted_at' not in first_app:
    print(f"⚠️  'created_at' present but 'submitted_at' missing")
    print(f"   Value: {first_app['created_at']}")

# Summary
print(f"\n" + "=" * 80)
if missing_fields:
    print(f"❌ VALIDATION FAILED - Missing fields:")
    for field in missing_fields:
        print(f"   - {field}")
else:
    print(f"✅ ALL REQUIRED FIELDS PRESENT!")
    print(f"\nFlutter app should now be able to display the applications correctly.")

print("=" * 80)
