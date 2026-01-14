#!/usr/bin/env python
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(__file__))

django.setup()

from apps.users.models import SellerProduct

# Find test products
products = SellerProduct.objects.filter(name__icontains='test')
print(f'Found {products.count()} test products:')
for p in products:
    print(f'  ID: {p.id}, Name: {p.name}, Price: {p.price}')

# Delete them
if products.exists():
    count = products.delete()
    print(f'\nDeleted: {count}')
else:
    print('\nNo test products found to delete.')
