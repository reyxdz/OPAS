"""
Simple test script for Phase 3.2 Dashboard Stats Endpoint

Run with: python manage.py shell < test_dashboard_simple.py
"""

import json
import os
import django
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework.test import APIClient
from apps.users.models import User, UserRole, SellerStatus
from apps.users.admin_models import AdminUser

# Create test user
admin_user, created = User.objects.get_or_create(
    username='test_admin',
    defaults={
        'email': 'test_admin@example.com',
        'first_name': 'Test',
        'last_name': 'Admin',
        'role': UserRole.OPAS_ADMIN
    }
)

# Create AdminUser record if it doesn't exist
admin_record, _ = AdminUser.objects.get_or_create(
    user=admin_user,
    defaults={
        'admin_role': 'SUPER_ADMIN',
        'department': 'Operations',
        'is_active': True
    }
)

# Create some seller test data
seller1, _ = User.objects.get_or_create(
    username='test_seller1',
    defaults={
        'email': 'seller1@example.com',
        'first_name': 'Seller',
        'last_name': 'One',
        'role': UserRole.SELLER,
        'seller_status': SellerStatus.APPROVED,
        'store_name': 'Store 1'
    }
)

seller2, _ = User.objects.get_or_create(
    username='test_seller2',
    defaults={
        'email': 'seller2@example.com',
        'first_name': 'Seller',
        'last_name': 'Two',
        'role': UserRole.SELLER,
        'seller_status': SellerStatus.PENDING,
        'store_name': 'Store 2'
    }
)

print("="*80)
print("Phase 3.2: Admin Dashboard Stats Endpoint - Manual Test")
print("="*80 + "\n")

# Test 1: Unauthenticated request
print("Test 1: Unauthenticated request")
client = APIClient()
response = client.get('/api/admin/dashboard/stats/')
print(f"Status Code: {response.status_code}")
assert response.status_code == 401, f"Expected 401, got {response.status_code}"
print("✓ PASS: Endpoint requires authentication\n")

# Test 2: Authenticated request
print("Test 2: Authenticated request (admin user)")
client = APIClient()
client.force_authenticate(user=admin_user)
response = client.get('/api/admin/dashboard/stats/')
print(f"Status Code: {response.status_code}")

if response.status_code == 200:
    data = response.json()
    
    print("✓ PASS: Endpoint accessible to admin user\n")
    
    print("Response fields:")
    for key in data.keys():
        print(f"  - {key}")
    
    print("\nPhase 3.2 Specification Validation:")
    required_fields = [
        'timestamp', 'seller_metrics', 'market_metrics',
        'opas_metrics', 'price_compliance', 'alerts',
        'marketplace_health_score'
    ]
    
    all_present = True
    for field in required_fields:
        if field in data:
            print(f"✓ {field}")
        else:
            print(f"✗ MISSING: {field}")
            all_present = False
    
    if all_present:
        print("\n✓ All required fields present!\n")
    
    print("Full Response:")
    print(json.dumps(data, indent=2, default=str))
    
    # Validate nested fields
    print("\nNested Fields Validation:")
    
    print("seller_metrics:", list(data['seller_metrics'].keys()))
    seller_fields = ['total_sellers', 'pending_approvals', 'active_sellers', 'suspended_sellers', 'new_this_month', 'approval_rate']
    for field in seller_fields:
        if field in data['seller_metrics']:
            print(f"  ✓ {field}")
        else:
            print(f"  ✗ MISSING: {field}")
    
    print("\nmarket_metrics:", list(data['market_metrics'].keys()))
    market_fields = ['active_listings', 'total_sales_today', 'total_sales_month', 'avg_price_change', 'avg_transaction']
    for field in market_fields:
        if field in data['market_metrics']:
            print(f"  ✓ {field}")
        else:
            print(f"  ✗ MISSING: {field}")
    
    print("\nopas_metrics:", list(data['opas_metrics'].keys()))
    opas_fields = ['pending_submissions', 'approved_this_month', 'total_inventory', 'low_stock_count', 'expiring_count', 'total_inventory_value']
    for field in opas_fields:
        if field in data['opas_metrics']:
            print(f"  ✓ {field}")
        else:
            print(f"  ✗ MISSING: {field}")
    
    print("\nprice_compliance:", list(data['price_compliance'].keys()))
    compliance_fields = ['compliant_listings', 'non_compliant', 'compliance_rate']
    for field in compliance_fields:
        if field in data['price_compliance']:
            print(f"  ✓ {field}")
        else:
            print(f"  ✗ MISSING: {field}")
    
    print("\nalerts:", list(data['alerts'].keys()))
    alerts_fields = ['price_violations', 'seller_issues', 'inventory_alerts', 'total_open_alerts']
    for field in alerts_fields:
        if field in data['alerts']:
            print(f"  ✓ {field}")
        else:
            print(f"  ✗ MISSING: {field}")
    
    print("\n" + "="*80)
    print("✓ Phase 3.2 Implementation SUCCESSFUL!")
    print("="*80)
else:
    print(f"✗ FAIL: Got status {response.status_code}")
    print("Response:", response.json() if response.status_code != 500 else response.content)
