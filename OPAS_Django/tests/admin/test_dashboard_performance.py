"""
Performance Tests for Admin Dashboard

Tests:
1. Dashboard stats endpoint response time < 2 seconds
2. Dashboard metrics calculation efficiency
3. Dashboard scaling with large dataset sizes
4. Dashboard query optimization (no N+1 problems)
5. Memory usage during dashboard operations

Run: python manage.py test tests.admin.test_dashboard_performance --verbosity=2
"""

from django.test.utils import CaptureQueriesContext
from django.db import connection, reset_queries
import time
import logging

from tests.admin.performance_test_fixtures import (
    PerformanceTestCase, LargeDatasetFactory, PerformanceAssertions, PerformanceMetrics
)
from apps.users.models import User, UserRole, SellerStatus

logger = logging.getLogger(__name__)


class DashboardPerformanceTests(PerformanceTestCase):
    """Performance tests for admin dashboard"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_dashboard_loads_under_2_seconds_small_dataset(self):
        """Dashboard should load in < 2 seconds with small dataset (10 sellers)"""
        # Create small dataset
        LargeDatasetFactory.create_sellers(count=10)
        
        # Measure endpoint
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        # Assertions
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        self.assert_query_count(metrics['query_count'], self.PERF_MAX_QUERIES_DASHBOARD)
        
        logger.info(f"Small dataset: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_dashboard_loads_under_2_seconds_medium_dataset(self):
        """Dashboard should load in < 2 seconds with medium dataset (100 sellers)"""
        # Create medium dataset
        LargeDatasetFactory.create_sellers(count=100)
        
        # Measure endpoint
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        # Assertions
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        self.assert_query_count(metrics['query_count'], self.PERF_MAX_QUERIES_DASHBOARD)
        
        logger.info(f"Medium dataset: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_dashboard_loads_under_2_seconds_large_dataset(self):
        """Dashboard should load in < 2 seconds with large dataset (1000 sellers)"""
        # Create large dataset
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Measure endpoint
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        # Assertions
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        # May need slightly more queries with large dataset, but not proportional
        self.assert_query_count(metrics['query_count'], self.PERF_MAX_QUERIES_DASHBOARD + 5)
        
        logger.info(f"Large dataset: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_dashboard_no_n_plus_one_queries(self):
        """Dashboard should not have N+1 query problems"""
        # Create small dataset and measure baseline
        LargeDatasetFactory.create_sellers(count=10)
        
        reset_queries()
        response1, metrics1 = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        baseline_queries = metrics1['query_count']
        
        # Create larger dataset
        self.setUp()  # Reset
        self.create_admin_user()
        LargeDatasetFactory.create_sellers(count=100)
        
        reset_queries()
        response2, metrics2 = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        large_queries = metrics2['query_count']
        
        # Assert no proportional query increase (N+1 check)
        # With 10x more data, we should NOT have 10x more queries
        self.assert_no_n_plus_one(baseline_queries, large_queries, additional_records=90)
        
        logger.info(f"N+1 check: 10 sellers = {baseline_queries} queries, 100 sellers = {large_queries} queries")
    
    def test_dashboard_metrics_accuracy(self):
        """Dashboard metrics should be calculated accurately"""
        # Create diverse dataset
        approved_sellers = LargeDatasetFactory.create_sellers(count=50, status=SellerStatus.APPROVED)
        pending_sellers = LargeDatasetFactory.create_sellers(count=10, status=SellerStatus.PENDING)
        suspended_sellers = LargeDatasetFactory.create_sellers(count=5, status=SellerStatus.SUSPENDED)
        
        # Get dashboard stats
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        # Assertions
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify metrics
        self.assertEqual(data['seller_metrics']['active_sellers'], 50)
        self.assertEqual(data['seller_metrics']['pending_approvals'], 10)
        self.assertEqual(data['seller_metrics']['suspended_users'], 5)
        self.assertEqual(data['seller_metrics']['total_sellers'], 65)
        
        logger.info(f"Metrics verified: {data['seller_metrics']}")
    
    def test_dashboard_concurrent_metric_updates(self):
        """Dashboard should handle concurrent metric updates efficiently"""
        # Create dataset
        LargeDatasetFactory.create_sellers(count=100)
        
        # Simulate multiple rapid requests
        measurements = []
        for _ in range(5):
            response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
            measurements.append((1, metrics['response_time']))
            self.assertEqual(response.status_code, 200)
        
        # All requests should be consistently fast
        times = [m[1] for m in measurements]
        avg_time = sum(times) / len(times)
        max_time = max(times)
        
        self.assertLess(max_time, self.PERF_TIMEOUT_DASHBOARD)
        self.assertLess(avg_time, self.PERF_TIMEOUT_DASHBOARD)
        
        logger.info(f"Concurrent requests: avg={avg_time:.3f}s, max={max_time:.3f}s")
    
    def test_dashboard_scaling_characteristics(self):
        """Verify dashboard scales appropriately with data size"""
        measurements = []
        
        # Test with increasing dataset sizes
        for size in [10, 50, 100, 500]:
            self.setUp()
            self.create_admin_user()
            LargeDatasetFactory.create_sellers(count=size)
            
            response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
            self.assertEqual(response.status_code, 200)
            measurements.append((size, metrics['response_time']))
        
        # Check scaling - should be linear or sub-linear
        scaling = PerformanceAssertions.get_scaling_characteristics(measurements)
        logger.info(f"Dashboard scaling: {scaling}")
        logger.info(f"Measurements: {measurements}")
        
        # All measurements should still be under limit
        for size, time in measurements:
            self.assertLess(time, self.PERF_TIMEOUT_DASHBOARD, 
                           f"Dashboard exceeded timeout at size {size}")
    
    def test_dashboard_with_price_violations(self):
        """Dashboard should handle price violation metrics efficiently"""
        # Create sellers and price violations
        LargeDatasetFactory.create_sellers(count=100)
        LargeDatasetFactory.create_price_violations(count=100)
        
        # Measure dashboard
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        # Assertions
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        data = response.json()
        
        # Price compliance metrics should be present
        self.assertIn('price_compliance', data)
        
        logger.info(f"With violations: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_dashboard_with_opas_inventory(self):
        """Dashboard should handle OPAS inventory metrics efficiently"""
        # Create sellers and OPAS inventory
        LargeDatasetFactory.create_sellers(count=100)
        LargeDatasetFactory.create_opas_inventory(count=100)
        
        # Measure dashboard
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        # Assertions
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        data = response.json()
        
        # OPAS metrics should be present
        self.assertIn('opas_metrics', data)
        
        logger.info(f"With OPAS inventory: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_dashboard_aggregation_query_efficiency(self):
        """Dashboard aggregation queries should be optimized"""
        # Create comprehensive dataset
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_violations(count=50)
        LargeDatasetFactory.create_opas_inventory(count=100)
        
        # Measure with query context
        reset_queries()
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        
        # Check query efficiency
        # Dashboard should use aggregation queries (Count, Sum, Avg)
        # Not individual item queries
        query_count = metrics['query_count']
        
        # With aggregations, should be roughly constant regardless of data size
        self.assertLess(query_count, 15, "Dashboard using too many queries (possible aggregation issue)")
        
        logger.info(f"Query efficiency: {query_count} queries for 650+ records")
        logger.info(f"Response time: {metrics['response_time']:.3f}s")
    
    def test_dashboard_memory_usage(self):
        """Dashboard should not cause excessive memory usage"""
        # Create large dataset
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Measure endpoint
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        
        # Memory delta should be reasonable (< 50 MB for this operation)
        self.assertLess(metrics['memory_delta'], 50, 
                       f"Excessive memory usage: {metrics['memory_delta']} MB")
        
        logger.info(f"Memory usage: {metrics['memory_delta']:.2f} MB")


class DashboardMetricsCalculationTests(PerformanceTestCase):
    """Tests for specific dashboard metric calculations"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_seller_count_metric_efficiency(self):
        """Seller count metrics should calculate efficiently"""
        LargeDatasetFactory.create_sellers(count=500, status=SellerStatus.APPROVED)
        LargeDatasetFactory.create_sellers(count=100, status=SellerStatus.PENDING)
        
        reset_queries()
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        self.assertLess(metrics['response_time'], 1.0)  # Seller counts should be very fast
        self.assertLess(metrics['query_count'], 10)
    
    def test_compliance_rate_metric_efficiency(self):
        """Compliance rate calculation should be optimized"""
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_ceilings(count=500)
        LargeDatasetFactory.create_price_violations(count=50)
        
        reset_queries()
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        data = response.json()
        
        # Compliance rate should be present and reasonable
        self.assertIn('price_compliance', data)
        compliance_rate = data['price_compliance']['compliance_rate']
        self.assertGreaterEqual(compliance_rate, 0)
        self.assertLessEqual(compliance_rate, 100)
    
    def test_marketplace_health_score_efficiency(self):
        """Marketplace health score should calculate efficiently"""
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_violations(count=50)
        LargeDatasetFactory.create_marketplace_alerts(count=100)
        
        reset_queries()
        response, metrics = self.measure_endpoint('GET', '/api/users/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_DASHBOARD)
        data = response.json()
        
        # Health score should be present and in valid range
        self.assertIn('marketplace_health_score', data)
        health_score = data['marketplace_health_score']
        self.assertGreaterEqual(health_score, 0)
        self.assertLessEqual(health_score, 100)
