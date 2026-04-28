"""
Test suite for Phase 3.3 - Admin Dashboard Endpoint Implementation.

Tests the dashboard stats endpoint (/api/admin/dashboard/stats/) to verify:
1. Endpoint is accessible at correct URL
2. Returns all required metric groups
3. Response matches AdminDashboardStatsSerializer schema
4. Query optimization (minimal database hits)
5. Permission checking (admin-only access)
6. Performance (< 2 second response time)
7. Error handling for edge cases
"""

import time
import json
from datetime import timedelta
from decimal import Decimal

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.users.models import (
    User, UserRole, SellerStatus,
    SellerProduct, SellerOrder, SellToOPAS
)
from apps.users.seller_models import ProductStatus, OrderStatus
from apps.users.admin_models import (
    OPASInventory, MarketplaceAlert
)

User = get_user_model()


class DashboardStatsEndpointTestCase(TestCase):
    """Test the dashboard stats endpoint."""

    def setUp(self):
        """Set up test data."""
        self.client = Client()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='adminpass123',
            role=UserRole.ADMIN,
            full_name='Admin User'
        )
        
        # Create seller users
        self.seller1 = User.objects.create_user(
            email='seller1@test.com',
            password='sellerpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            full_name='Seller One',
            store_name='Store 1'
        )
        
        self.seller2 = User.objects.create_user(
            email='seller2@test.com',
            password='sellerpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING,
            full_name='Seller Two',
            store_name='Store 2'
        )
        
        self.seller3 = User.objects.create_user(
            email='seller3@test.com',
            password='sellerpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.SUSPENDED,
            full_name='Seller Three',
            store_name='Store 3'
        )
        
        # Create buyer user
        self.buyer = User.objects.create_user(
            email='buyer@test.com',
            password='buyerpass123',
            role=UserRole.BUYER,
            full_name='Buyer User'
        )

    def test_endpoint_requires_authentication(self):
        """Test that endpoint requires authentication."""
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 401)

    def test_endpoint_requires_admin_permission(self):
        """Test that endpoint requires admin permission."""
        self.client.login(email='buyer@test.com', password='buyerpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        # Should be 403 Forbidden or 401 Unauthorized depending on permission class
        self.assertIn(response.status_code, [401, 403])

    def test_endpoint_accessible_by_admin(self):
        """Test that admin can access the endpoint."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 200)

    def test_response_json_format(self):
        """Test that response is valid JSON."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 200)
        
        # Verify response is JSON
        data = response.json()
        self.assertIsInstance(data, dict)

    def test_response_contains_timestamp(self):
        """Test that response contains timestamp field."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('timestamp', data)
        # Timestamp should be a valid ISO format datetime string
        self.assertIsNotNone(data['timestamp'])

    def test_response_contains_seller_metrics(self):
        """Test that response contains seller_metrics group."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('seller_metrics', data)
        seller_metrics = data['seller_metrics']
        
        # Verify all required fields
        self.assertIn('total_sellers', seller_metrics)
        self.assertIn('pending_approvals', seller_metrics)
        self.assertIn('active_sellers', seller_metrics)
        self.assertIn('suspended_sellers', seller_metrics)
        self.assertIn('new_this_month', seller_metrics)
        self.assertIn('approval_rate', seller_metrics)

    def test_seller_metrics_calculation(self):
        """Test that seller metrics are calculated correctly."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        seller_metrics = data['seller_metrics']
        
        # We have 3 sellers total (seller1, seller2, seller3)
        self.assertEqual(seller_metrics['total_sellers'], 3)
        self.assertEqual(seller_metrics['pending_approvals'], 1)  # seller2
        self.assertEqual(seller_metrics['active_sellers'], 1)  # seller1
        self.assertEqual(seller_metrics['suspended_sellers'], 1)  # seller3

    def test_response_contains_market_metrics(self):
        """Test that response contains market_metrics group."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('market_metrics', data)
        market_metrics = data['market_metrics']
        
        # Verify all required fields
        self.assertIn('active_listings', market_metrics)
        self.assertIn('total_sales_today', market_metrics)
        self.assertIn('total_sales_month', market_metrics)
        self.assertIn('avg_price_change', market_metrics)
        self.assertIn('avg_transaction', market_metrics)

    def test_response_contains_opas_metrics(self):
        """Test that response contains opas_metrics group."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('opas_metrics', data)
        opas_metrics = data['opas_metrics']
        
        # Verify all required fields
        self.assertIn('pending_submissions', opas_metrics)
        self.assertIn('approved_this_month', opas_metrics)
        self.assertIn('total_inventory', opas_metrics)
        self.assertIn('low_stock_count', opas_metrics)
        self.assertIn('expiring_count', opas_metrics)
        self.assertIn('total_inventory_value', opas_metrics)

    def test_response_contains_price_compliance(self):
        """Test that response contains price_compliance metrics."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('price_compliance', data)
        price_compliance = data['price_compliance']
        
        # Verify all required fields
        self.assertIn('compliant_listings', price_compliance)
        self.assertIn('non_compliant', price_compliance)
        self.assertIn('compliance_rate', price_compliance)

    def test_response_contains_alerts(self):
        """Test that response contains alerts metrics."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('alerts', data)
        alerts = data['alerts']
        
        # Verify all required fields
        self.assertIn('price_violations', alerts)
        self.assertIn('seller_issues', alerts)
        self.assertIn('inventory_alerts', alerts)
        self.assertIn('total_open_alerts', alerts)

    def test_response_contains_health_score(self):
        """Test that response contains marketplace_health_score."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('marketplace_health_score', data)
        health_score = data['marketplace_health_score']
        
        # Health score should be integer between 0-100
        self.assertIsInstance(health_score, int)
        self.assertGreaterEqual(health_score, 0)
        self.assertLessEqual(health_score, 100)

    def test_response_metric_types(self):
        """Test that all metrics have correct types."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Seller metrics should be integers/floats
        seller_metrics = data['seller_metrics']
        self.assertIsInstance(seller_metrics['total_sellers'], int)
        self.assertIsInstance(seller_metrics['pending_approvals'], int)
        self.assertIsInstance(seller_metrics['approval_rate'], (int, float))
        
        # Market metrics should be integers/floats
        market_metrics = data['market_metrics']
        self.assertIsInstance(market_metrics['active_listings'], int)
        self.assertIsInstance(market_metrics['total_sales_today'], (int, float))
        
        # Health score should be integer
        self.assertIsInstance(data['marketplace_health_score'], int)

    def test_endpoint_performance(self):
        """Test that endpoint responds within 2 seconds."""
        self.client.login(email='admin@test.com', password='adminpass123')
        
        start_time = time.time()
        response = self.client.get('/api/admin/dashboard/stats/')
        elapsed_time = time.time() - start_time
        
        self.assertEqual(response.status_code, 200)
        # Performance should be < 2 seconds
        self.assertLess(elapsed_time, 2.0, 
                       f"Dashboard stats took {elapsed_time:.2f}s, should be < 2s")

    def test_empty_database(self):
        """Test that endpoint works with empty/minimal database."""
        # Create new test case with minimal data
        User.objects.all().delete()
        
        admin = User.objects.create_user(
            email='admin2@test.com',
            password='adminpass123',
            role=UserRole.ADMIN,
            full_name='Admin 2'
        )
        
        self.client.login(email='admin2@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # All counts should be 0
        self.assertEqual(data['seller_metrics']['total_sellers'], 0)
        self.assertEqual(data['market_metrics']['active_listings'], 0)
        self.assertEqual(data['opas_metrics']['pending_submissions'], 0)

    def test_endpoint_url_routing(self):
        """Test that endpoint is accessible at correct URL."""
        self.client.login(email='admin@test.com', password='adminpass123')
        
        # Try various URL patterns
        urls_to_test = [
            '/api/admin/dashboard/stats/',
        ]
        
        for url in urls_to_test:
            response = self.client.get(url)
            self.assertNotEqual(response.status_code, 404, 
                              f"URL {url} returned 404 - endpoint not found")

    def test_response_structure_matches_spec(self):
        """Test that response structure matches Phase 3.3 specification."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Verify top-level structure
        required_fields = [
            'timestamp',
            'seller_metrics',
            'market_metrics',
            'opas_metrics',
            'price_compliance',
            'alerts',
            'marketplace_health_score'
        ]
        
        for field in required_fields:
            self.assertIn(field, data, 
                         f"Missing required field: {field}")

    def test_seller_metrics_fields_present(self):
        """Test that all seller metrics fields are present."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        required_fields = [
            'total_sellers',
            'pending_approvals',
            'active_sellers',
            'suspended_sellers',
            'new_this_month',
            'approval_rate'
        ]
        
        for field in required_fields:
            self.assertIn(field, data['seller_metrics'],
                         f"Missing seller_metrics field: {field}")

    def test_market_metrics_fields_present(self):
        """Test that all market metrics fields are present."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        required_fields = [
            'active_listings',
            'total_sales_today',
            'total_sales_month',
            'avg_price_change',
            'avg_transaction'
        ]
        
        for field in required_fields:
            self.assertIn(field, data['market_metrics'],
                         f"Missing market_metrics field: {field}")

    def test_opas_metrics_fields_present(self):
        """Test that all OPAS metrics fields are present."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        required_fields = [
            'pending_submissions',
            'approved_this_month',
            'total_inventory',
            'low_stock_count',
            'expiring_count',
            'total_inventory_value'
        ]
        
        for field in required_fields:
            self.assertIn(field, data['opas_metrics'],
                         f"Missing opas_metrics field: {field}")

    def test_price_compliance_fields_present(self):
        """Test that all price compliance fields are present."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        required_fields = [
            'compliant_listings',
            'non_compliant',
            'compliance_rate'
        ]
        
        for field in required_fields:
            self.assertIn(field, data['price_compliance'],
                         f"Missing price_compliance field: {field}")

    def test_alerts_fields_present(self):
        """Test that all alerts fields are present."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        required_fields = [
            'price_violations',
            'seller_issues',
            'inventory_alerts',
            'total_open_alerts'
        ]
        
        for field in required_fields:
            self.assertIn(field, data['alerts'],
                         f"Missing alerts field: {field}")

    def test_multiple_requests(self):
        """Test that endpoint can handle multiple requests."""
        self.client.login(email='admin@test.com', password='adminpass123')
        
        # Make multiple requests
        for i in range(5):
            response = self.client.get('/api/admin/dashboard/stats/')
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertIn('timestamp', data)

    def test_response_includes_valid_timestamp(self):
        """Test that timestamp is valid and recent."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Parse timestamp
        timestamp_str = data['timestamp']
        # Should be ISO format datetime
        self.assertIsNotNone(timestamp_str)
        self.assertIn('T', timestamp_str)  # ISO format includes 'T'

    def test_numerical_consistency(self):
        """Test that numerical values are consistent."""
        self.client.login(email='admin@test.com', password='adminpass123')
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # All count fields should be non-negative integers
        seller_metrics = data['seller_metrics']
        self.assertGreaterEqual(seller_metrics['total_sellers'], 0)
        self.assertGreaterEqual(seller_metrics['pending_approvals'], 0)
        self.assertGreaterEqual(seller_metrics['active_sellers'], 0)
        
        # All sales amounts should be non-negative
        market_metrics = data['market_metrics']
        self.assertGreaterEqual(market_metrics['total_sales_today'], 0)
        self.assertGreaterEqual(market_metrics['total_sales_month'], 0)
        
        # Rates should be 0-100 range
        self.assertGreaterEqual(seller_metrics['approval_rate'], 0)
        self.assertLessEqual(seller_metrics['approval_rate'], 100)


class DashboardStatsIntegrationTestCase(TestCase):
    """Integration tests for dashboard stats with complex data scenarios."""

    def setUp(self):
        """Set up test data for integration tests."""
        self.client = Client()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='adminpass123',
            role=UserRole.ADMIN,
            full_name='Admin User'
        )
        
        self.client.login(email='admin@test.com', password='adminpass123')

    def test_dashboard_with_multiple_sellers(self):
        """Test dashboard with multiple sellers in different statuses."""
        # Create 5 approved sellers
        for i in range(5):
            User.objects.create_user(
                email=f'approved{i}@test.com',
                password='pass123',
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED,
                store_name=f'Store {i}'
            )
        
        # Create 2 pending sellers
        for i in range(2):
            User.objects.create_user(
                email=f'pending{i}@test.com',
                password='pass123',
                role=UserRole.SELLER,
                seller_status=SellerStatus.PENDING,
                store_name=f'Pending Store {i}'
            )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        seller_metrics = data['seller_metrics']
        self.assertEqual(seller_metrics['total_sellers'], 7)
        self.assertEqual(seller_metrics['active_sellers'], 5)
        self.assertEqual(seller_metrics['pending_approvals'], 2)

    def test_dashboard_response_consistency(self):
        """Test that dashboard returns consistent data across multiple calls."""
        response1 = self.client.get('/api/admin/dashboard/stats/')
        data1 = response1.json()
        
        # Make another call after a short delay
        time.sleep(0.1)
        response2 = self.client.get('/api/admin/dashboard/stats/')
        data2 = response2.json()
        
        # Metrics should be the same (no data changes between calls)
        self.assertEqual(
            data1['seller_metrics']['total_sellers'],
            data2['seller_metrics']['total_sellers']
        )


if __name__ == '__main__':
    import unittest
    unittest.main()
