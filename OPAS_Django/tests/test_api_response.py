#!/usr/bin/env python
import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIRequestFactory
from rest_framework.test import force_authenticate
from apps.users.models import User, UserRole
from apps.users.admin_viewsets import SellerManagementViewSet
from apps.users.admin_models import AdminUser, AdminRole

# Get or create admin user for testing
admin_user = User.objects.filter(username='opas_admin').first()
if not admin_user:
    print("Error: Admin user not found")
    exit(1)

# Ensure AdminUser exists
admin_obj, created = AdminUser.objects.get_or_create(
    user=admin_user,
    defaults={'admin_role': AdminRole.SUPER_ADMIN}
)

# Create a request factory and authenticate
factory = APIRequestFactory()
request = factory.get('/api/admin/sellers/pending-approvals/')
force_authenticate(request, user=admin_user)

# Create viewset and call pending_approvals
viewset = SellerManagementViewSet()
viewset.request = request
viewset.format_kwarg = None

# Call the pending_approvals action
response = viewset.pending_approvals(request)

print("API Response Status:", response.status_code)
print("\nAPI Response Data:")
print(json.dumps(response.data, indent=2, default=str))

# Verify structure for Flutter
if isinstance(response.data, dict):
    if 'results' in response.data:
        print(f"\n✓ Response has 'results' key with {len(response.data['results'])} items")
        if response.data['results']:
            first_item = response.data['results'][0]
            print(f"\nFirst item keys: {list(first_item.keys())}")
    elif 'count' in response.data:
        print(f"\n✓ Response has 'count' key")
elif isinstance(response.data, list):
    print(f"\n✓ Response is a list with {len(response.data)} items")
    if response.data:
        first_item = response.data[0]
        print(f"\nFirst item keys: {list(first_item.keys())}")
