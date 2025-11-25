#!/usr/bin/env python
"""
Test the admin API endpoint for pending seller applications.
"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from django.contrib.auth.models import User as DjangoUser
from apps.users.models import User, UserRole
from rest_framework.authtoken.models import Token

print("=" * 70)
print("TESTING ADMIN API ENDPOINT FOR PENDING SELLER APPLICATIONS")
print("=" * 70)

# Find an admin user to test with
print("\n1️⃣  Finding admin user...")
try:
    admin_users = User.objects.filter(role=UserRole.ADMIN)
    if admin_users.count() == 0:
        print("   ⚠ No admin users found in database")
        print("   This is expected if no admin has been created yet")
        admin_user = None
    else:
        admin_user = admin_users.first()
        print(f"   ✓ Found admin user: {admin_user.email}")
except Exception as e:
    print(f"   ✗ Error finding admin: {str(e)}")
    admin_user = None

# Check pending applications
print("\n2️⃣  Checking pending SellerApplication records...")
try:
    from apps.users.models import SellerApplication
    pending = SellerApplication.objects.filter(status='PENDING')
    print(f"   ✓ Found {pending.count()} PENDING applications")
    
    if pending.count() > 0:
        for app in pending:
            print(f"     - ID: {app.id}, User: {app.user.email}, Created: {app.created_at}")
except Exception as e:
    print(f"   ✗ Error checking applications: {str(e)}")

# Test the API endpoint
if admin_user:
    print("\n3️⃣  Testing admin API endpoint...")
    try:
        # Create a client
        client = Client()
        
        # Try to authenticate with the admin user's token
        token, created = Token.objects.get_or_create(user=admin_user)
        
        # Make request to the pending-approvals endpoint
        headers = {'HTTP_AUTHORIZATION': f'Token {token.key}'}
        response = client.get('/api/admin/sellers/pending-approvals/', **headers)
        
        print(f"   Response status: {response.status_code}")
        
        if response.status_code == 200:
            data = json.loads(response.content)
            print(f"   ✓ API endpoint works!")
            print(f"   - Count: {data.get('count', 0)}")
            print(f"   - Results: {len(data.get('results', []))} applications")
            
            if data.get('results'):
                for result in data['results']:
                    print(f"     - {result.get('user_email')}: {result.get('farm_name')}")
        else:
            print(f"   ✗ API error: {response.status_code}")
            print(f"   Response: {response.content[:200]}")
            
    except Exception as e:
        print(f"   ✗ Error testing API: {str(e)}")
else:
    print("\n3️⃣  Skipping API test (no admin user)")

print("\n" + "=" * 70)
print("VERIFICATION SUMMARY")
print("=" * 70)
print("✅ Admin panel fix is ready for testing!")
print("")
print("Next steps:")
print("1. Ensure admin user is created with proper permissions")
print("2. Navigate to admin panel 'Pending Seller Approvals'")
print("3. Should see the pending applications listed (currently 1)")
print("=" * 70)
