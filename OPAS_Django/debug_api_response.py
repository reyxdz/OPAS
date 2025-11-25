#!/usr/bin/env python
"""
Debug script to trace exact API response and Flutter behavior
"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from apps.users.models import User, UserRole, SellerApplication
from rest_framework.authtoken.models import Token

print("=" * 80)
print("DEBUGGING: TRACE EXACT API RESPONSE")
print("=" * 80)

# Step 1: Check database
print("\n[STEP 1] Database Check")
print("-" * 80)
pending_apps = SellerApplication.objects.filter(status='PENDING')
print(f"Database has {pending_apps.count()} PENDING applications")
for app in pending_apps:
    print(f"  • {app.id}: {app.user.email} - {app.farm_name}")

# Step 2: Get admin and make request
print("\n[STEP 2] Making API Request")
print("-" * 80)
admin = User.objects.filter(role=UserRole.ADMIN).first()
if not admin:
    print("❌ No admin user found")
    exit(1)

client = Client()
token, _ = Token.objects.get_or_create(user=admin)
headers = {'HTTP_AUTHORIZATION': f'Token {token.key}'}

print(f"Admin user: {admin.email}")
print(f"Auth token: {token.key[:20]}...")
print(f"Endpoint: /api/admin/sellers/pending-approvals/")

response = client.get('/api/admin/sellers/pending-approvals/', **headers)

print(f"\nResponse Status: {response.status_code}")
print(f"Response Content-Type: {response.get('Content-Type', 'Not set')}")
print(f"Response Length: {len(response.content)} bytes")

# Step 3: Parse response
print("\n[STEP 3] Response Content")
print("-" * 80)
try:
    data = json.loads(response.content)
    print("Response is valid JSON:")
    print(json.dumps(data, indent=2, default=str)[:1000])  # First 1000 chars
except Exception as e:
    print(f"❌ Error parsing JSON: {e}")
    print(f"Raw response: {response.content}")
    exit(1)

# Step 4: Check response structure
print("\n[STEP 4] Response Structure")
print("-" * 80)
print(f"Top-level keys: {list(data.keys())}")
print(f"Count field: {data.get('count')}")
print(f"Results field type: {type(data.get('results'))}")
print(f"Results length: {len(data.get('results', []))}")

if data.get('results'):
    print(f"\n[STEP 5] First Result Details")
    print("-" * 80)
    first = data['results'][0]
    print(f"Keys in first result: {list(first.keys())}")
    print("\nFirst result content:")
    for key, value in first.items():
        if key not in ['user', 'reviewed_by']:  # Skip object references
            print(f"  {key}: {value}")

# Step 6: Simulate Flutter's getPendingSellerApprovals
print("\n[STEP 6] Simulating Flutter's AdminService.getPendingSellerApprovals()")
print("-" * 80)

def getPendingSellerApprovals_flutter_logic(response_data):
    """Simulate the exact Flutter logic"""
    data = response_data
    
    # This is from admin_service.dart line 115-125
    if isinstance(data, list):
        print("Response is a list")
        return data
    elif isinstance(data, dict) and 'results' in data:
        print("Response is dict with 'results' key")
        return list(data['results'])
    elif isinstance(data, dict) and 'approvals' in data:
        print("Response is dict with 'approvals' key")
        return list(data['approvals'])
    else:
        print(f"Response format not recognized: {type(data)}, keys: {list(data.keys()) if isinstance(data, dict) else 'N/A'}")
        return []

result = getPendingSellerApprovals_flutter_logic(data)
print(f"\nFlutter would get: {len(result)} items")

if result:
    print(f"\n[STEP 7] Simulating Flutter's _parseApplication()")
    print("-" * 80)
    first_item = result[0]
    
    # This is from pending_seller_approvals_screen.dart line 45-51
    submitted_at = first_item.get('submitted_at', '')
    seller_full_name = first_item.get('seller_full_name', '')
    seller_email = first_item.get('seller_email', '')
    
    display_name = seller_full_name if seller_full_name else seller_email.split('@')[0]
    
    parsed = {
        'id': first_item.get('id'),
        'name': display_name if display_name else 'Unknown',
        'farmName': first_item.get('farm_name', ''),
        'farmLocation': first_item.get('farm_location', ''),
        'storeName': first_item.get('store_name', ''),
        'storeDescription': first_item.get('store_description', ''),
        'appliedDate': submitted_at,
        'email': seller_email,
    }
    
    print("Parsed application:")
    for key, value in parsed.items():
        print(f"  {key}: {value}")
    
    # Check if any fields are empty
    empty_fields = [k for k, v in parsed.items() if not v or v == '']
    if empty_fields:
        print(f"\n⚠️  PROBLEM: These fields are empty: {empty_fields}")
    else:
        print(f"\n✅ All fields populated correctly")
else:
    print("❌ No results returned")

print("\n" + "=" * 80)
