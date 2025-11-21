#!/usr/bin/env python
import requests
import time
import os
import sys

# Add the Django project to the path
sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
import django
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

# Get admin user
try:
    admin = User.objects.get(email='1234567890@opas.com')
    print(f"✓ Found admin user: {admin.email}")
    
    # Create token
    refresh = RefreshToken.for_user(admin)
    access_token = str(refresh.access_token)
    print(f"✓ Generated token: {access_token[:50]}...")
    
    # Test the endpoint
    print("\n=== Testing /api/users/admin/sellers/pending_approvals/ ===")
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    response = requests.get('http://127.0.0.1:8000/api/users/admin/sellers/pending_approvals/', headers=headers, timeout=5)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text[:500]}")
    
    if response.status_code == 200:
        import json
        data = response.json()
        print(f"✓ Successfully retrieved {len(data)} pending applications")
        if data:
            print(f"First application: {json.dumps(data[0], indent=2)}")
    
except Exception as e:
    print(f"✗ Error: {str(e)}")
    import traceback
    traceback.print_exc()
