#!/usr/bin/env python
"""Test OPAS admin API with stock monitoring fields"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client

client = Client()
response = client.get('/api/admin/opas-products/')

if response.status_code == 200:
    data = response.json()
    if data:
        print('✓ API Response (First Product):')
        print(json.dumps(data[0], indent=2))
    else:
        print('No products found')
else:
    print(f'Error: {response.status_code}')
    print(response.content)
