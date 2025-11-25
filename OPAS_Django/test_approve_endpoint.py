#!/usr/bin/env python
import os
import django
import json
import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from apps.users.admin_models import SellerRegistrationRequest, SellerRegistrationStatus
from rest_framework_simplejwt.tokens import RefreshToken

# Get admin user
admin_user = User.objects.filter(username='opas_admin').first()
refresh = RefreshToken.for_user(admin_user)
access_token = str(refresh.access_token)

# Get first pending registration
pending = SellerRegistrationRequest.objects.filter(status=SellerRegistrationStatus.PENDING).first()
if not pending:
    print("No pending registrations")
    exit(1)

print(f"Testing approve for: {pending.farm_name} (ID: {pending.id})")
print(f"Current status: {pending.status}")
print(f"Seller current role: {pending.seller.role}")

headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json'
}

# Test approve endpoint
api_url = f'http://localhost:8000/api/admin/sellers/{pending.id}/approve/'
data = {
    "admin_notes": "Test approval",
    "documents_verified": True
}

print(f"\nCalling: POST {api_url}")
print(f"Data: {json.dumps(data)}")

response = requests.post(api_url, headers=headers, json=data, timeout=10)
print(f"\nResponse Status: {response.status_code}")

if response.status_code in [200, 201]:
    result = response.json()
    print("Response Data:")
    print(json.dumps(result, indent=2, default=str)[:500])
    
    # Check if seller role was updated
    pending.refresh_from_db()
    pending.seller.refresh_from_db()
    print(f"\nAfter approval:")
    print(f"  Registration status: {pending.status}")
    print(f"  Seller role: {pending.seller.role}")
    print(f"  Seller status: {pending.seller.seller_status}")
else:
    print(f"Error: {response.text}")
