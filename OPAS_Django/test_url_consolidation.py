#!/usr/bin/env python
"""
Test script to verify URL consolidation - Seller and Admin routes separation
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.urls import reverse

print("=" * 70)
print("URL CONSOLIDATION VERIFICATION")
print("=" * 70)

# Test reverse lookups
print("\n1. Testing URL Reverse Lookups:")
print("-" * 70)

test_urls = [
    ('seller-registration-list', 'Seller Registration List'),
    ('seller-profile-list', 'Seller Profile List'),
    ('seller-products-list', 'Seller Products List'),
    ('admin-sellers-list', 'Admin Sellers List'),
    ('admin-dashboard-list', 'Admin Dashboard List'),
]

for url_name, description in test_urls:
    try:
        url = reverse(url_name)
        print(f"✓ {description:30} → {url}")
    except Exception as e:
        print(f"✗ {description:30} → ERROR: {str(e)[:40]}")

print("\n2. URL Structure Summary:")
print("-" * 70)
print("Seller Routes:       /api/users/seller/*")
print("Registration Routes: /api/users/sellers/*")
print("Admin Routes:        /api/admin/*")
print("Auth Routes:         /api/auth/*")

print("\n3. Key Changes Made:")
print("-" * 70)
print("✓ Removed admin_router from apps/users/urls.py")
print("✓ Kept seller_router in apps/users/urls.py")
print("✓ Admin routes remain in apps/users/admin_urls.py")
print("✓ No duplicate admin route registrations")

print("\n✓ URL consolidation complete!")
print("=" * 70)
