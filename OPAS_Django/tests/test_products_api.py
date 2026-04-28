#!/usr/bin/env python
import os
import sys
import django
import requests
import json

# Setup Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

# Test the API endpoint
from apps.users.models import User, SellerStatus

# Get a test buyer token (or use AllowAny)
url = "http://10.207.234.34:8000/api/products/"
print(f"Testing endpoint: {url}\n")

# Try without token (AllowAny)
response = requests.get(url)
print(f"Status Code: {response.status_code}")
print(f"Response:\n{json.dumps(response.json(), indent=2)}\n")

# Check pagination
if response.status_code == 200:
    data = response.json()
    print(f"Count: {data.get('count')}")
    print(f"Results: {len(data.get('results', []))}")
    if data.get('results'):
        for product in data.get('results', []):
            print(f"  - {product.get('name')} (ID: {product.get('id')})")
