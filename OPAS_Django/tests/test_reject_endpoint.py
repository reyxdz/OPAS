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
    print("No pending registrations to reject")
    exit(1)

print(f"Testing reject for: {pending.farm_name} (ID: {pending.id})")
print(f"Current status: {pending.status}")

headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json'
}

# Test reject endpoint
api_url = f'http://localhost:8000/api/admin/sellers/{pending.id}/reject/'
data = {
    "rejection_reason": "Documentation incomplete",
    "admin_notes": "Requested proper certificates"
}

print(f"\nCalling: POST {api_url}")
print(f"Data: {json.dumps(data)}")

response = requests.post(api_url, headers=headers, json=data, timeout=10)
print(f"\nResponse Status: {response.status_code}")

if response.status_code in [200, 201]:
    result = response.json()
    print(f"Status after rejection: {result['status']}")
    
    # Verify list now has 0 pending
    response2 = requests.get('http://localhost:8000/api/admin/sellers/pending-approvals/', headers=headers, timeout=10)
    data2 = response2.json()
    print(f"\nPending registrations after rejection: {data2['count']}")
else:
    print(f"Error: {response.text}")
