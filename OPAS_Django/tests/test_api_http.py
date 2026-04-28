#!/usr/bin/env python
import os
import django
import json
import requests
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from django.contrib.auth.tokens import default_token_generator
from rest_framework.authtoken.models import Token
from rest_framework_simplejwt.tokens import RefreshToken

# Get admin user
admin_user = User.objects.filter(username='opas_admin').first()
if not admin_user:
    print("Error: Admin user not found")
    exit(1)

print(f"Testing with user: {admin_user.username} ({admin_user.email})")
print(f"User role: {admin_user.role}")

# Get JWT token for testing
refresh = RefreshToken.for_user(admin_user)
access_token = str(refresh.access_token)

print(f"Access token: {access_token[:20]}...")

# Test the API endpoint
api_url = 'http://localhost:8000/api/admin/sellers/pending-approvals/'
headers = {
    'Authorization': f'Bearer {access_token}',
    'Accept': 'application/json',
}

print(f"\nCalling: {api_url}")
print(f"Headers: {headers}")

try:
    response = requests.get(api_url, headers=headers, timeout=5)
    print(f"\nResponse Status: {response.status_code}")
    print(f"Response Content-Type: {response.headers.get('Content-Type')}")
    
    data = response.json()
    print(f"\nResponse Data:")
    print(json.dumps(data, indent=2, default=str))
    
    # Verify structure for Flutter
    if isinstance(data, dict):
        if 'results' in data:
            print(f"\n✓ Response has 'results' key with {len(data['results'])} items")
            if data['results']:
                first_item = data['results'][0]
                print(f"First item keys: {list(first_item.keys())}")
        if 'count' in data:
            print(f"✓ Response has 'count' key: {data['count']}")
    elif isinstance(data, list):
        print(f"\n✓ Response is a list with {len(data)} items")
        if data:
            first_item = data[0]
            print(f"First item keys: {list(first_item.keys())}")
            
except requests.exceptions.ConnectionError:
    print("ERROR: Cannot connect to API. Is Django server running on http://localhost:8000?")
except Exception as e:
    print(f"ERROR: {e}")
