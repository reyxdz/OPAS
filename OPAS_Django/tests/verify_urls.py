#!/usr/bin/env python
"""Check if order endpoints are registered"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, '/c/BSCS-4B/Thesis/OPAS_Application/OPAS_Django')
django.setup()

from django.urls import get_resolver, resolve

resolver = get_resolver()
print("=" * 80)
print("CHECKING FOR ORDER ENDPOINTS")
print("=" * 80)

# Try to resolve the order create endpoint
try:
    match = resolve('/api/orders/create/')
    print(f"✓ /api/orders/create/ -> {match.func} (view: {match.view_name})")
except Exception as e:
    print(f"✗ /api/orders/create/ -> ERROR: {e}")

# Try other order endpoints
print("\nChecking other order paths:")
paths_to_check = [
    '/api/orders/',
    '/api/orders/1/',
    '/api/users/orders/create/',
]

for path in paths_to_check:
    try:
        match = resolve(path)
        print(f"  ✓ {path} -> {match.view_name}")
    except Exception as e:
        print(f"  ✗ {path} -> Not found")

print("\n" + "=" * 80)
print("Checking URL configurations loaded:")
print("=" * 80)
# Check apps.users.urls
print("\nURLs from apps.users.urls:")
from apps.users import urls as users_urls
for pattern in users_urls.urlpatterns[:10]:
    print(f"  - {pattern.pattern}")

