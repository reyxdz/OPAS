#!/usr/bin/env python
"""Test dashboard endpoint accessibility and response format."""
import os
import django
import json
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.authtoken.models import Token

from apps.users.models import UserRole, SellerStatus
from apps.users.admin_models import AdminUser, AdminRole

User = get_user_model()

print("=" * 80)
print("DASHBOARD ENDPOINT TEST")
print("=" * 80)

# Create or get test admin user
admin_username = 'test_admin'
admin_user, created = User.objects.get_or_create(
    username=admin_username,
    defaults={
        'email': 'test_admin@opas.com',
        'first_name': 'Test',
        'last_name': 'Admin',
        'role': UserRole.ADMIN
    }
)

if created:
    admin_user.set_password('AdminTest@123')
    admin_user.save()

print(f"✓ {'Created' if created else 'Found existing'} admin user: {admin_user.email}")

# Ensure AdminUser profile exists
try:
    admin_profile = AdminUser.objects.get(user=admin_user)
except AdminUser.DoesNotExist:
    admin_profile = AdminUser.objects.create(
        user=admin_user,
        admin_role=AdminRole.SYSTEM_ADMIN,
        department='Operations'
    )

# Get or create token
token, created = Token.objects.get_or_create(user=admin_user)
print(f"{'✓ Created' if created else '✓ Using existing'} token: {token.key[:20]}...")

# Test unauthenticated access
print("\n2. Testing unauthenticated access...")
client = Client()
response = client.get('/api/admin/dashboard/stats/')
if response.status_code == 401:
    print(f"✓ Unauthenticated access denied (401)")
else:
    print(f"✗ Expected 401, got {response.status_code}")

# Test authenticated access
print("\n3. Testing authenticated access...")
client = Client()
client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

start_time = timezone.now()
response = client.get('/api/admin/dashboard/stats/')
end_time = timezone.now()
elapsed = (end_time - start_time).total_seconds()

print(f"Response status: {response.status_code}")
print(f"Response time: {elapsed:.3f}s")

if response.status_code == 200:
    print("✓ Endpoint accessible (200)")
    
    # Parse response
    data = response.json()
    
    print("\n4. Validating response structure...")
    
    # Check required fields
    required_fields = [
        'timestamp',
        'seller_metrics',
        'market_metrics',
        'opas_metrics',
        'price_compliance',
        'alerts',
        'marketplace_health_score'
    ]
    
    missing_fields = [f for f in required_fields if f not in data]
    if missing_fields:
        print(f"✗ Missing fields: {missing_fields}")
    else:
        print("✓ All required top-level fields present")
    
    # Check seller metrics
    seller_fields = [
        'total_sellers', 'pending_approvals', 'active_sellers',
        'suspended_sellers', 'new_this_month', 'approval_rate'
    ]
    missing = [f for f in seller_fields if f not in data.get('seller_metrics', {})]
    if missing:
        print(f"✗ Missing seller_metrics fields: {missing}")
    else:
        print("✓ Seller metrics complete")
    
    # Check market metrics
    market_fields = [
        'active_listings', 'total_sales_today', 'total_sales_month',
        'avg_price_change', 'avg_transaction'
    ]
    missing = [f for f in market_fields if f not in data.get('market_metrics', {})]
    if missing:
        print(f"✗ Missing market_metrics fields: {missing}")
    else:
        print("✓ Market metrics complete")
    
    # Check OPAS metrics
    opas_fields = [
        'pending_submissions', 'approved_this_month', 'total_inventory',
        'low_stock_count', 'expiring_count', 'total_inventory_value'
    ]
    missing = [f for f in opas_fields if f not in data.get('opas_metrics', {})]
    if missing:
        print(f"✗ Missing opas_metrics fields: {missing}")
    else:
        print("✓ OPAS metrics complete")
    
    # Check price compliance
    compliance_fields = [
        'compliant_listings', 'non_compliant', 'compliance_rate'
    ]
    missing = [f for f in compliance_fields if f not in data.get('price_compliance', {})]
    if missing:
        print(f"✗ Missing price_compliance fields: {missing}")
    else:
        print("✓ Price compliance metrics complete")
    
    # Check alerts
    alert_fields = [
        'price_violations', 'seller_issues', 'inventory_alerts', 'total_open_alerts'
    ]
    missing = [f for f in alert_fields if f not in data.get('alerts', {})]
    if missing:
        print(f"✗ Missing alerts fields: {missing}")
    else:
        print("✓ Alerts metrics complete")
    
    # Check health score
    health_score = data.get('marketplace_health_score')
    if health_score is not None and 0 <= health_score <= 100:
        print(f"✓ Health score valid: {health_score}")
    else:
        print(f"✗ Health score invalid: {health_score}")
    
    # Display sample data
    print("\n5. Sample metrics:")
    print(f"   Total sellers: {data['seller_metrics']['total_sellers']}")
    print(f"   Active listings: {data['market_metrics']['active_listings']}")
    print(f"   Compliance rate: {data['price_compliance']['compliance_rate']}%")
    print(f"   Health score: {health_score}/100")
    
    # Performance check
    print("\n6. Performance validation:")
    if elapsed < 2.0:
        print(f"✓ Response time < 2s: {elapsed:.3f}s")
    else:
        print(f"⚠ Response time > 2s: {elapsed:.3f}s (target: < 2s)")
    
else:
    print(f"✗ Expected 200, got {response.status_code}")
    print(f"Response: {response.content}")

print("\n" + "=" * 80)
print("TEST COMPLETE")
print("=" * 80)
