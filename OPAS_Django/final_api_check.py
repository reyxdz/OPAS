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

print('=' * 60)
print('FINAL API VERIFICATION')
print('=' * 60)
print('Endpoint: GET /api/admin/sellers/pending-approvals/')
print(f'Status Code: {response.status_code}')
print(f'Total Pending: {data["count"]}')
print()
print('Pending Applications:')
for i, item in enumerate(data['results'], 1):
    print(f'{i}. {item["farm_name"]}')
    print(f'   Email: {item["seller_email"]}')
    print(f'   Full Name: {item["seller_full_name"]}')
    print(f'   Store: {item["store_name"]}')
    print()
