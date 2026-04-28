#!/usr/bin/env python
"""Check admin credentials and generate fresh JWT token"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
import requests

User = get_user_model()
admins = User.objects.filter(role='ADMIN')

print("Admin users in system:")
for admin in admins:
    print(f"\n  Email: {admin.email}")
    print(f"  Phone: {admin.phone_number}")
    print(f"  Name: {admin.full_name}")
    print(f"  ID: {admin.id}")
    
    # Try to generate a fresh JWT token
    try:
        refresh = RefreshToken.for_user(admin)
        access_token = str(refresh.access_token)
        print(f"  Fresh JWT Token: {access_token[:50]}...")
        
        # Test the token works with the API
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get('http://localhost:8000/api/admin/sellers/pending-approvals/', headers=headers)
        print(f"  Token test status: {response.status_code}")
        if response.status_code == 200:
            count = response.json()['count']
            print(f"  ✅ Token works! Found {count} pending applications")
        else:
            print(f"  ❌ Token error: {response.json().get('detail', 'Unknown error')}")
    except Exception as e:
        print(f"  Error generating token: {e}")

print("\n\nNote: Use the first admin email/phone to login in the Flutter app.")
