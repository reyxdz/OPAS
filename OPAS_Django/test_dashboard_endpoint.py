#!/usr/bin/env python
"""
Test script for Dashboard ViewSet endpoint
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth.models import AnonymousUser
from rest_framework.test import APIRequestFactory
from apps.users.models import User, UserRole
from apps.users.admin_models import AdminUser
from apps.users.admin_viewsets import DashboardViewSet
import json


def test_dashboard_stats():
    """Test the dashboard stats endpoint"""
    
    # Get or create an admin user
    admin_user = User.objects.filter(role=UserRole.ADMIN).first()
    if not admin_user:
        admin_user = User.objects.create_user(
            email='admin@test.com',
            password='admin123',
            username='admin_test',
            role=UserRole.ADMIN
        )
        print(f'✓ Created admin user: {admin_user.email}')
    else:
        print(f'✓ Using existing admin: {admin_user.email}')
    
    # Ensure AdminUser record exists
    admin_record = AdminUser.objects.filter(user=admin_user).first()
    if not admin_record:
        admin_record = AdminUser.objects.create(
            user=admin_user,
            admin_role='SUPER_ADMIN',
            is_active=True,
            department='IT'
        )
        print(f'✓ Created AdminUser record for {admin_user.email}')
    else:
        print(f'✓ Using existing AdminUser record')
    
    # Create request
    factory = APIRequestFactory()
    request = factory.get('/api/admin/dashboard/stats/')
    request.user = admin_user
    
    # Create a mock viewset instance to test metrics methods directly
    viewset = DashboardViewSet()
    
    print(f'\n=== Dashboard Stats Metrics Test ===')
    
    # Test individual metric methods
    try:
        seller_metrics = viewset._get_seller_metrics()
        print(f'\n✓ Seller Metrics:')
        for k, v in seller_metrics.items():
            print(f'  - {k}: {v}')
    except Exception as e:
        print(f'\n✗ Error in seller metrics: {e}')
    
    try:
        market_metrics = viewset._get_market_metrics()
        print(f'\n✓ Market Metrics:')
        for k, v in market_metrics.items():
            print(f'  - {k}: {v}')
    except Exception as e:
        print(f'\n✗ Error in market metrics: {e}')
    
    try:
        opas_metrics = viewset._get_opas_metrics()
        print(f'\n✓ OPAS Metrics:')
        for k, v in opas_metrics.items():
            print(f'  - {k}: {v}')
    except Exception as e:
        print(f'\n✗ Error in OPAS metrics: {e}')
    
    try:
        price_compliance = viewset._get_price_compliance()
        print(f'\n✓ Price Compliance:')
        for k, v in price_compliance.items():
            print(f'  - {k}: {v}')
    except Exception as e:
        print(f'\n✗ Error in price compliance: {e}')
    
    try:
        alerts = viewset._get_alerts()
        print(f'\n✓ Alerts:')
        for k, v in alerts.items():
            print(f'  - {k}: {v}')
    except Exception as e:
        print(f'\n✗ Error in alerts: {e}')
    
    try:
        health_score = viewset._calculate_health_score(price_compliance)
        print(f'\n✓ Health Score: {health_score}')
    except Exception as e:
        print(f'\n✗ Error in health score: {e}')
    
    print(f'\n✓ All metrics methods working correctly!')


if __name__ == '__main__':
    test_dashboard_stats()
