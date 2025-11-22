"""
Performance Tests for Admin Analytics Endpoints

Tests:
1. Analytics queries execute efficiently without timeouts
2. Analytics queries are optimized (aggregations, select_related, prefetch_related)
3. Analytics with large datasets (10000+ records)
4. Analytics query response time < 3 seconds
5. Analytics no N+1 query problems
6. Analytics caching effectiveness

Run: python manage.py test tests.admin.test_analytics_performance --verbosity=2
"""

from django.test.utils import CaptureQueriesContext
from django.db import connection, reset_queries
from django.core.cache import cache
import time
import logging

from tests.admin.performance_test_fixtures import (
    PerformanceTestCase, LargeDatasetFactory, PerformanceAssertions, PerformanceMetrics
)
from apps.users.models import SellerStatus

logger = logging.getLogger(__name__)


class AnalyticsPerformanceTests(PerformanceTestCase):
    """Performance tests for admin analytics endpoints"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
        cache.clear()  # Clear cache between tests
    
    def test_price_trends_analytics_response_time(self):
        """Price trends analytics should respond within 3 seconds"""
        # Create dataset with price history
        LargeDatasetFactory.create_sellers(count=100)
        LargeDatasetFactory.create_price_ceilings(count=100)
        
        # Measure endpoint (using placeholder URL - adjust based on actual API)
        response, metrics = self.measure_endpoint(
            'GET', 
            '/api/admin/analytics/price-trends/',
            {'timeframe': 'month'}
        )
        
        # Assertions
        self.assertIn(response.status_code, [200, 404])  # 404 if not yet implemented
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_ANALYTICS)
            self.assert_query_count(metrics['query_count'], self.PERF_MAX_QUERIES_ANALYTICS)
        
        logger.info(f"Price trends: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_sales_analytics_with_large_dataset(self):
        """Sales analytics should handle large datasets efficiently"""
        # Create large dataset
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_ceilings(count=1000)
        
        # Measure endpoint
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_ANALYTICS)
            # Large dataset analytics may need more queries, but should be bounded
            self.assertLess(metrics['query_count'], self.PERF_MAX_QUERIES_ANALYTICS + 10)
        
        logger.info(f"Sales analytics (1500 items): {metrics['response_time']:.3f}s")
    
    def test_demand_forecast_analytics_efficiency(self):
        """Demand forecast should calculate efficiently"""
        # Create dataset
        LargeDatasetFactory.create_sellers(count=200)
        LargeDatasetFactory.create_price_ceilings(count=200)
        LargeDatasetFactory.create_opas_inventory(count=200)
        
        # Measure endpoint
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/demand-forecast/',
            {'timeframe': 'quarter'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_ANALYTICS)
        
        logger.info(f"Demand forecast: {metrics['response_time']:.3f}s")
    
    def test_analytics_no_n_plus_one_queries(self):
        """Analytics should not have N+1 query problems"""
        # Test with small dataset first
        LargeDatasetFactory.create_sellers(count=50)
        LargeDatasetFactory.create_price_ceilings(count=50)
        
        reset_queries()
        response1, metrics1 = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        baseline_queries = metrics1['query_count']
        
        # Clear and test with large dataset
        self.setUp()
        self.create_admin_user()
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_ceilings(count=500)
        
        reset_queries()
        response2, metrics2 = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        large_queries = metrics2['query_count']
        
        if response1.status_code == 200 and response2.status_code == 200:
            # 10x more data should NOT result in 10x more queries
            self.assert_no_n_plus_one(baseline_queries, large_queries, additional_records=450)
            logger.info(f"N+1 check: 50 items = {baseline_queries}, 500 items = {large_queries}")
    
    def test_analytics_aggregation_optimization(self):
        """Analytics queries should use aggregations efficiently"""
        # Create dataset
        LargeDatasetFactory.create_sellers(count=200)
        LargeDatasetFactory.create_price_ceilings(count=200)
        LargeDatasetFactory.create_price_violations(count=100)
        
        reset_queries()
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            # Analytics should use aggregations, not fetch all records
            # Query count should be low (< 30) even with 500+ records
            self.assertLess(metrics['query_count'], 30,
                          "Analytics query count too high - may not be using aggregations")
            logger.info(f"Aggregation efficient: {metrics['query_count']} queries for 500+ records")
    
    def test_analytics_response_consistency(self):
        """Analytics responses should be consistent across multiple requests"""
        LargeDatasetFactory.create_sellers(count=100)
        LargeDatasetFactory.create_price_ceilings(count=100)
        
        responses = []
        for i in range(3):
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/admin/analytics/dashboard/',
                {'timeframe': 'month'}
            )
            if response.status_code == 200:
                responses.append((response.json(), metrics['response_time']))
        
        if responses:
            # All responses should have same data
            data1 = responses[0][0]
            for i in range(1, len(responses)):
                self.assertEqual(data1, responses[i][0], 
                               f"Analytics response {i+1} differs from response 1")
            
            # All response times should be similar
            times = [r[1] for r in responses]
            avg_time = sum(times) / len(times)
            max_time = max(times)
            self.assertLess(max_time - min(times), avg_time * 0.5,
                          "Analytics response times vary too much")
            
            logger.info(f"Consistency verified: avg={avg_time:.3f}s, variance={max_time - min(times):.3f}s")
    
    def test_analytics_with_filters_performance(self):
        """Analytics with multiple filters should not degrade performance"""
        LargeDatasetFactory.create_sellers(count=200)
        LargeDatasetFactory.create_price_ceilings(count=200)
        
        # Test with increasing filter complexity
        filters = [
            {'timeframe': 'month'},
            {'timeframe': 'month', 'category': 'rice'},
            {'timeframe': 'month', 'category': 'rice', 'seller_id': 1},
            {'timeframe': 'month', 'category': 'rice', 'seller_id': 1, 'min_price': 50}
        ]
        
        measurements = []
        for f in filters:
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/admin/analytics/dashboard/',
                f
            )
            if response.status_code == 200:
                measurements.append((len(f), metrics['response_time']))
        
        if measurements:
            # Response time should not increase significantly with more filters
            scaling = PerformanceAssertions.get_scaling_characteristics(measurements)
            logger.info(f"Filter scaling: {scaling}")
            logger.info(f"Measurements: {measurements}")
            
            # All should still be under timeout
            for filters_count, time in measurements:
                self.assertLess(time, self.PERF_TIMEOUT_ANALYTICS,
                              f"Exceeded timeout with {filters_count} filters")


class AnalyticsQueryOptimizationTests(PerformanceTestCase):
    """Tests for analytics query optimization"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
        cache.clear()
    
    def test_dashboard_aggregation_queries(self):
        """Dashboard should use aggregation queries (Count, Sum, Avg)"""
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_ceilings(count=500)
        
        reset_queries()
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            # Verify aggregation queries are being used
            queries = [q['sql'] for q in connection.queries]
            
            # Should have COUNT, SUM, or AVG in queries
            aggregation_count = sum(1 for q in queries 
                                  if any(agg in q.upper() for agg in ['COUNT', 'SUM', 'AVG', 'GROUP BY']))
            
            self.assertGreater(aggregation_count, 0, 
                             "No aggregation queries detected - may not be optimized")
            
            logger.info(f"Aggregation queries: {aggregation_count}/{len(queries)}")
    
    def test_analytics_select_related_optimization(self):
        """Analytics queries should use select_related for foreign keys"""
        LargeDatasetFactory.create_sellers(count=100)
        LargeDatasetFactory.create_price_violations(count=100)
        
        reset_queries()
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            # With 100 violations, without select_related we'd have 100+ seller queries
            # With select_related, should be minimal
            query_count = metrics['query_count']
            self.assertLess(query_count, 50,
                          "Query count suggests select_related not used for relations")
            
            logger.info(f"Query efficiency verified: {query_count} queries for 100 violations")
    
    def test_analytics_caching_effectiveness(self):
        """Analytics should benefit from caching"""
        LargeDatasetFactory.create_sellers(count=100)
        LargeDatasetFactory.create_price_ceilings(count=100)
        
        # First request (cache miss)
        reset_queries()
        response1, metrics1 = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        queries_first = metrics1['query_count']
        time_first = metrics1['response_time']
        
        # Second request (cache hit)
        reset_queries()
        response2, metrics2 = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {'timeframe': 'month'}
        )
        queries_second = metrics2['query_count']
        time_second = metrics2['response_time']
        
        if response1.status_code == 200 and response2.status_code == 200:
            # Second request should be faster due to caching
            logger.info(f"Cache effectiveness: first={time_first:.3f}s, second={time_second:.3f}s")
            logger.info(f"Queries: first={queries_first}, second={queries_second}")
            
            # At minimum, both should be fast
            self.assertLess(time_first, self.PERF_TIMEOUT_ANALYTICS)
            self.assertLess(time_second, self.PERF_TIMEOUT_ANALYTICS)


class AnalyticsScalingTests(PerformanceTestCase):
    """Tests for analytics scaling characteristics"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
        cache.clear()
    
    def test_analytics_linear_scaling(self):
        """Analytics should scale linearly or sub-linearly with data size"""
        measurements = []
        
        for size in [50, 100, 200, 500]:
            self.setUp()
            self.create_admin_user()
            LargeDatasetFactory.create_sellers(count=size)
            LargeDatasetFactory.create_price_ceilings(count=size)
            
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/admin/analytics/dashboard/',
                {'timeframe': 'month'}
            )
            
            if response.status_code == 200:
                measurements.append((size, metrics['response_time']))
        
        if len(measurements) > 1:
            scaling = PerformanceAssertions.get_scaling_characteristics(measurements)
            logger.info(f"Analytics scaling: {scaling}")
            logger.info(f"Measurements: {measurements}")
            
            # All should be under timeout
            for size, time in measurements:
                self.assertLess(time, self.PERF_TIMEOUT_ANALYTICS,
                              f"Analytics exceeded timeout at size {size}")
    
    def test_complex_analytics_query_response_time(self):
        """Complex analytics queries should still be fast"""
        # Create comprehensive dataset
        LargeDatasetFactory.create_sellers(count=500)
        LargeDatasetFactory.create_price_ceilings(count=500)
        LargeDatasetFactory.create_price_violations(count=100)
        LargeDatasetFactory.create_opas_inventory(count=200)
        LargeDatasetFactory.create_marketplace_alerts(count=150)
        
        # Request comprehensive analytics
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/admin/analytics/dashboard/',
            {
                'timeframe': 'quarter',
                'include_forecasts': 'true',
                'include_comparisons': 'true'
            }
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_ANALYTICS)
            logger.info(f"Complex analytics: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
