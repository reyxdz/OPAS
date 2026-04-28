"""
Test script for Phase 3.2: Admin Dashboard Stats Endpoint

Tests the GET /api/admin/dashboard/stats/ endpoint to verify:
1. Endpoint is accessible
2. Response format matches Phase 3.2 specification
3. All required fields are present
4. Permissions work correctly
5. Response time is acceptable
"""

import os
import sys
import django
import json
import time
from datetime import timedelta

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase
from rest_framework import status

from apps.users.models import User, UserRole, SellerStatus, SellerProduct, SellerOrder
from apps.users.seller_models import ProductStatus, OrderStatus
from apps.users.admin_models import MarketplaceAlert, OPASInventory, AdminUser

User = get_user_model()


class DashboardStatsEndpointTestCase(APITestCase):
    """Test cases for the dashboard stats endpoint"""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='admin123',
            first_name='Admin',
            last_name='User',
            role=UserRole.ADMIN
        )
        
        # Create AdminUser record
        self.admin_record = AdminUser.objects.create(
            user=self.admin_user,
            admin_role='SUPER_ADMIN',
            department='Operations',
            is_active=True
        )
        
        # Create seller users
        self.seller1 = User.objects.create_user(
            username='seller1',
            email='seller1@example.com',
            password='seller123',
            first_name='Seller',
            last_name='One',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            store_name='Store 1'
        )
        
        self.seller2 = User.objects.create_user(
            username='seller2',
            email='seller2@example.com',
            password='seller123',
            first_name='Seller',
            last_name='Two',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING,
            store_name='Store 2'
        )
        
        # Create buyer user
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='buyer123',
            first_name='Buyer',
            last_name='User',
            role=UserRole.BUYER
        )
    
    def test_endpoint_requires_authentication(self):
        """Test that endpoint requires authentication"""
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        print("✓ Test passed: Endpoint requires authentication")
    
    def test_endpoint_requires_admin_role(self):
        """Test that endpoint requires admin role"""
        self.client.force_authenticate(user=self.buyer)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertIn(response.status_code, [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED])
        print("✓ Test passed: Endpoint requires admin role")
    
    def test_endpoint_accessible_to_admin(self):
        """Test that admin user can access endpoint"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        print("✓ Test passed: Admin user can access endpoint")
    
    def test_response_contains_timestamp(self):
        """Test that response contains timestamp field"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        self.assertIn('timestamp', data)
        self.assertIsNotNone(data['timestamp'])
        print(f"✓ Test passed: Response contains timestamp: {data['timestamp']}")
    
    def test_response_contains_seller_metrics(self):
        """Test that response contains seller_metrics"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('seller_metrics', data)
        seller_metrics = data['seller_metrics']
        
        # Verify all required fields
        required_fields = [
            'total_sellers', 'pending_approvals', 'active_sellers',
            'suspended_sellers', 'new_this_month', 'approval_rate'
        ]
        for field in required_fields:
            self.assertIn(field, seller_metrics, f"Missing field: {field}")
        
        print(f"✓ Test passed: seller_metrics contains all required fields")
        print(f"  Seller metrics: {seller_metrics}")
    
    def test_response_contains_market_metrics(self):
        """Test that response contains market_metrics"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('market_metrics', data)
        market_metrics = data['market_metrics']
        
        # Verify all required fields
        required_fields = [
            'active_listings', 'total_sales_today', 'total_sales_month',
            'avg_price_change', 'avg_transaction'
        ]
        for field in required_fields:
            self.assertIn(field, market_metrics, f"Missing field: {field}")
        
        print(f"✓ Test passed: market_metrics contains all required fields")
        print(f"  Market metrics: {market_metrics}")
    
    def test_response_contains_opas_metrics(self):
        """Test that response contains opas_metrics"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('opas_metrics', data)
        opas_metrics = data['opas_metrics']
        
        # Verify all required fields
        required_fields = [
            'pending_submissions', 'approved_this_month', 'total_inventory',
            'low_stock_count', 'expiring_count', 'total_inventory_value'
        ]
        for field in required_fields:
            self.assertIn(field, opas_metrics, f"Missing field: {field}")
        
        print(f"✓ Test passed: opas_metrics contains all required fields")
        print(f"  OPAS metrics: {opas_metrics}")
    
    def test_response_contains_price_compliance(self):
        """Test that response contains price_compliance"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('price_compliance', data)
        price_compliance = data['price_compliance']
        
        # Verify all required fields
        required_fields = [
            'compliant_listings', 'non_compliant', 'compliance_rate'
        ]
        for field in required_fields:
            self.assertIn(field, price_compliance, f"Missing field: {field}")
        
        print(f"✓ Test passed: price_compliance contains all required fields")
        print(f"  Price compliance: {price_compliance}")
    
    def test_response_contains_alerts(self):
        """Test that response contains alerts"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('alerts', data)
        alerts = data['alerts']
        
        # Verify all required fields
        required_fields = [
            'price_violations', 'seller_issues', 'inventory_alerts', 'total_open_alerts'
        ]
        for field in required_fields:
            self.assertIn(field, alerts, f"Missing field: {field}")
        
        print(f"✓ Test passed: alerts contains all required fields")
        print(f"  Alerts: {alerts}")
    
    def test_response_contains_marketplace_health_score(self):
        """Test that response contains marketplace_health_score"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('marketplace_health_score', data)
        health_score = data['marketplace_health_score']
        
        # Verify it's a number between 0 and 100
        self.assertIsInstance(health_score, int)
        self.assertGreaterEqual(health_score, 0)
        self.assertLessEqual(health_score, 100)
        
        print(f"✓ Test passed: marketplace_health_score is valid: {health_score}")
    
    def test_response_format_matches_specification(self):
        """Test that complete response format matches Phase 3.2 specification"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Verify all top-level fields
        expected_fields = [
            'timestamp', 'seller_metrics', 'market_metrics', 'opas_metrics',
            'price_compliance', 'alerts', 'marketplace_health_score'
        ]
        
        for field in expected_fields:
            self.assertIn(field, data, f"Missing top-level field: {field}")
        
        print("✓ Test passed: Response format matches Phase 3.2 specification")
        print("\nFull response structure:")
        print(json.dumps(data, indent=2, default=str))
    
    def test_response_time_acceptable(self):
        """Test that response time is acceptable (< 2 seconds)"""
        self.client.force_authenticate(user=self.admin_user)
        
        start_time = time.time()
        response = self.client.get('/api/admin/dashboard/stats/')
        elapsed_time = time.time() - start_time
        
        self.assertLess(elapsed_time, 2.0)
        print(f"✓ Test passed: Response time acceptable: {elapsed_time:.3f} seconds")
    
    def test_seller_metrics_accuracy(self):
        """Test that seller metrics are calculated correctly"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        seller_metrics = data['seller_metrics']
        
        # Verify calculated values
        self.assertEqual(seller_metrics['total_sellers'], 2)  # seller1 and seller2
        self.assertEqual(seller_metrics['active_sellers'], 1)  # Only seller1 is APPROVED
        self.assertEqual(seller_metrics['pending_approvals'], 1)  # Only seller2 is PENDING
        self.assertEqual(seller_metrics['suspended_sellers'], 0)  # None suspended
        
        print(f"✓ Test passed: Seller metrics are accurate")


class DashboardStatsResponseValidationTest(APITestCase):
    """Additional tests to validate response data types and ranges"""
    
    def setUp(self):
        """Set up test data"""
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='admin123',
            first_name='Admin',
            last_name='User',
            role=UserRole.ADMIN
        )
        
        # Create AdminUser record
        AdminUser.objects.create(
            user=self.admin_user,
            admin_role='SUPER_ADMIN',
            department='Operations',
            is_active=True
        )
        
        self.client = APIClient()
    
    def test_metric_values_are_correct_types(self):
        """Test that all metric values have correct data types"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Check seller_metrics types
        for key in ['total_sellers', 'pending_approvals', 'active_sellers', 'suspended_sellers', 'new_this_month']:
            self.assertIsInstance(data['seller_metrics'][key], int, f"seller_metrics.{key} should be int")
        self.assertIsInstance(data['seller_metrics']['approval_rate'], (int, float), "approval_rate should be numeric")
        
        # Check market_metrics types
        for key in ['active_listings', 'total_sales_today', 'total_sales_month', 'avg_price_change', 'avg_transaction']:
            self.assertIsInstance(data['market_metrics'][key], (int, float), f"market_metrics.{key} should be numeric")
        
        # Check opas_metrics types
        for key in ['pending_submissions', 'approved_this_month', 'total_inventory', 'low_stock_count', 'expiring_count']:
            self.assertIsInstance(data['opas_metrics'][key], int, f"opas_metrics.{key} should be int")
        self.assertIsInstance(data['opas_metrics']['total_inventory_value'], (int, float), "total_inventory_value should be numeric")
        
        # Check price_compliance types
        self.assertIsInstance(data['price_compliance']['compliant_listings'], int)
        self.assertIsInstance(data['price_compliance']['non_compliant'], int)
        self.assertIsInstance(data['price_compliance']['compliance_rate'], (int, float))
        
        # Check alerts types
        for key in ['price_violations', 'seller_issues', 'inventory_alerts', 'total_open_alerts']:
            self.assertIsInstance(data['alerts'][key], int, f"alerts.{key} should be int")
        
        # Check marketplace_health_score type
        self.assertIsInstance(data['marketplace_health_score'], int)
        
        print("✓ Test passed: All metric values have correct data types")
    
    def test_metric_values_in_valid_ranges(self):
        """Test that metric values are within valid ranges"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # All counts should be >= 0
        self.assertGreaterEqual(data['seller_metrics']['total_sellers'], 0)
        self.assertGreaterEqual(data['seller_metrics']['approval_rate'], 0)
        self.assertLessEqual(data['seller_metrics']['approval_rate'], 100)
        
        self.assertGreaterEqual(data['market_metrics']['active_listings'], 0)
        self.assertGreaterEqual(data['market_metrics']['total_sales_today'], 0)
        
        # Compliance rate should be 0-100
        self.assertGreaterEqual(data['price_compliance']['compliance_rate'], 0)
        self.assertLessEqual(data['price_compliance']['compliance_rate'], 100)
        
        # Health score should be 0-100
        self.assertGreaterEqual(data['marketplace_health_score'], 0)
        self.assertLessEqual(data['marketplace_health_score'], 100)
        
        print("✓ Test passed: All metric values are within valid ranges")


def run_manual_tests():
    """Run manual tests with detailed output"""
    print("\n" + "="*80)
    print("Phase 3.2: Admin Dashboard Stats Endpoint - Test Suite")
    print("="*80 + "\n")
    
    # Create test suite
    test_suite = [
        DashboardStatsEndpointTestCase('test_endpoint_requires_authentication'),
        DashboardStatsEndpointTestCase('test_endpoint_requires_admin_role'),
        DashboardStatsEndpointTestCase('test_endpoint_accessible_to_admin'),
        DashboardStatsEndpointTestCase('test_response_contains_timestamp'),
        DashboardStatsEndpointTestCase('test_response_contains_seller_metrics'),
        DashboardStatsEndpointTestCase('test_response_contains_market_metrics'),
        DashboardStatsEndpointTestCase('test_response_contains_opas_metrics'),
        DashboardStatsEndpointTestCase('test_response_contains_price_compliance'),
        DashboardStatsEndpointTestCase('test_response_contains_alerts'),
        DashboardStatsEndpointTestCase('test_response_contains_marketplace_health_score'),
        DashboardStatsEndpointTestCase('test_response_format_matches_specification'),
        DashboardStatsEndpointTestCase('test_response_time_acceptable'),
        DashboardStatsEndpointTestCase('test_seller_metrics_accuracy'),
        DashboardStatsResponseValidationTest('test_metric_values_are_correct_types'),
        DashboardStatsResponseValidationTest('test_metric_values_in_valid_ranges'),
    ]
    
    # Run tests
    from django.test.runner import DiscoverRunner
    runner = DiscoverRunner(verbosity=2)
    
    passed = 0
    failed = 0
    
    for test in test_suite:
        try:
            test.debug()
            passed += 1
        except Exception as e:
            failed += 1
            print(f"✗ Test failed: {str(e)}")
    
    print("\n" + "="*80)
    print(f"Test Results: {passed} passed, {failed} failed")
    print("="*80 + "\n")
    
    return failed == 0


if __name__ == '__main__':
    import unittest
    
    # Run the test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    suite.addTests(loader.loadTestsFromTestCase(DashboardStatsEndpointTestCase))
    suite.addTests(loader.loadTestsFromTestCase(DashboardStatsResponseValidationTest))
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)
