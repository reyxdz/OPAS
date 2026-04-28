#!/usr/bin/env python
import os
import django
import json
import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from rest_framework_simplejwt.tokens import RefreshToken

admin_user = User.objects.filter(username='opas_admin').first()
refresh = RefreshToken.for_user(admin_user)
access_token = str(refresh.access_token)

headers = {'Authorization': f'Bearer {access_token}'}
response = requests.get('http://localhost:8000/api/admin/sellers/pending-approvals/', headers=headers, timeout=10)
data = response.json()

print(f'Status: {response.status_code}')
print(f'Count: {data["count"]}')
print(f'Results: {len(data["results"])} items')
if data['results']:
    for item in data['results']:
        print(f'  - {item["farm_name"]} ({item["seller_email"]})')
