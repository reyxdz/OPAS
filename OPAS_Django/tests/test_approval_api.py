#!/usr/bin/env python
import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIClient
from apps.users.models import User, SellerApplication, UserRole, SellerStatus
from django.utils import timezone

# Create a test buyer user or get existing
buyer, created = User.objects.get_or_create(
    username='testbuyer123',
    defaults={
        'email': 'testbuyer123@opas.app',
        'phone_number': '09999999999',
        'role': UserRole.BUYER
    }
)
if created:
    buyer.set_password('password123')
    buyer.save()

# Delete any existing application for this user
SellerApplication.objects.filter(user=buyer).delete()

# Create a pending seller application
app = SellerApplication.objects.create(
    user=buyer,
    farm_name='Test Farm',
    farm_location='Test Location',
    store_name='Test Store',
    store_description='Test Store Description',
    status='PENDING'
)

print(f"✓ Created test application: {app.id}")
print(f"  User: {buyer.email}")
print(f"  Current role: {buyer.role}")
print(f"  Current seller_status: {buyer.seller_status}")

# Get an admin user with CanApproveSellers permission
# This requires admin_role = 'SELLER_MANAGER' or 'SUPER_ADMIN'
admin = User.objects.filter(role='ADMIN', admin_role__in=['SELLER_MANAGER', 'SUPER_ADMIN']).first()
if not admin:
    print("✗ No admin with approve permission found")
    exit(1)

print(f"\n✓ Admin user: {admin.email}")

# Test the approve endpoint
client = APIClient()
client.force_authenticate(user=admin)

print(f"\nTesting approval via API...")
# The @action decorator url_path='approve' creates: /api/admin/sellers/{id}/approve/
response = client.post(f'/api/admin/sellers/{app.id}/approve/', {
    'admin_notes': 'Approved via API',
    'documents_verified': True
}, format='json')

print(f"Response status: {response.status_code}")
if response.status_code in [200, 201]:
    print("✓ Approval successful!")
    
    # Refresh from database
    buyer.refresh_from_db()
    app.refresh_from_db()
    
    print(f"\nAfter approval:")
    print(f"  App status: {app.status}")
    print(f"  User role: {buyer.role}")
    print(f"  User seller_status: {buyer.seller_status}")
    
    if buyer.role == UserRole.SELLER and app.status == 'APPROVED':
        print("\n✓✓✓ APPROVAL WORKING CORRECTLY! ✓✓✓")
    else:
        print("\n✗ Role or status not updated correctly")
else:
    print(f"✗ Approval failed!")
    print(f"Response: {response.data}")

# Cleanup
buyer.delete()
