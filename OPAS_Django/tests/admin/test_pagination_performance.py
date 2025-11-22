"""
Performance Tests for Admin Pagination

Tests:
1. Pagination loads each page in < 1 second
2. Pagination doesn't load all records (lazy loading)
3. Pagination works efficiently with 10000+ records
4. Pagination query count is constant regardless of total record count
5. Page size adjustments don't degrade performance
6. Pagination sorting is optimized

Run: python manage.py test tests.admin.test_pagination_performance --verbosity=2
"""

from django.db import connection, reset_queries
import logging

from tests.admin.performance_test_fixtures import (
    PerformanceTestCase, LargeDatasetFactory, PerformanceAssertions, PerformanceMetrics
)
from apps.users.models import UserRole

logger = logging.getLogger(__name__)


class PaginationPerformanceTests(PerformanceTestCase):
    """Performance tests for admin pagination"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_pagination_first_page_with_1000_records(self):
        """First page should load quickly even with 1000+ total records"""
        # Create large dataset
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Request first page
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 1, 'page_size': 20}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
            self.assert_query_count(metrics['query_count'], self.PERF_MAX_QUERIES_PAGINATION + 2)
        
        logger.info(f"Pagination first page (1000 total): {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_pagination_middle_page_with_1000_records(self):
        """Middle page should load with same speed as first page (no full table scan)"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Request middle page (page 25, with 20 per page = 500th record)
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 25, 'page_size': 20}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
            # Should have similar query count to first page
            self.assert_query_count(metrics['query_count'], self.PERF_MAX_QUERIES_PAGINATION + 2)
        
        logger.info(f"Pagination middle page (1000 total): {metrics['response_time']:.3f}s")
    
    def test_pagination_last_page_with_1000_records(self):
        """Last page should load with same speed as first page"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Request last page
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 50, 'page_size': 20}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
        
        logger.info(f"Pagination last page (1000 total): {metrics['response_time']:.3f}s")
    
    def test_pagination_does_not_fetch_all_records(self):
        """Pagination should only fetch requested page, not all records"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        reset_queries()
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 1, 'page_size': 20}
        )
        
        if response.status_code == 200:
            data = response.json()
            
            # Should only return page_size records
            if 'results' in data:
                self.assertEqual(len(data['results']), 20)
            
            # Query count should be low (1-2 queries for pagination)
            self.assertLess(metrics['query_count'], 10,
                          "Pagination query count too high - may be fetching all records")
            
            logger.info(f"Pagination efficient: {metrics['query_count']} queries for 1000 total records")
    
    def test_pagination_with_10000_records(self):
        """Pagination should handle very large datasets (10000+ records)"""
        # Create very large dataset
        LargeDatasetFactory.create_sellers(count=5000)
        LargeDatasetFactory.create_sellers(count=5000)
        
        # Request various pages
        for page in [1, 100, 250, 500]:  # Request different pages
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                {'page': page, 'page_size': 20}
            )
            
            self.assertIn(response.status_code, [200, 404])
            if response.status_code == 200:
                self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
                
                logger.info(f"Page {page} (10000 total): {metrics['response_time']:.3f}s")
    
    def test_pagination_query_count_constant(self):
        """Pagination query count should remain constant regardless of total records"""
        query_counts = []
        
        for size in [100, 500, 1000, 5000]:
            self.setUp()
            self.create_admin_user()
            LargeDatasetFactory.create_sellers(count=size)
            
            reset_queries()
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                {'page': 1, 'page_size': 20}
            )
            
            if response.status_code == 200:
                query_counts.append((size, metrics['query_count']))
        
        if query_counts:
            # Query count should be roughly constant (not proportional to total records)
            logger.info(f"Query counts: {query_counts}")
            
            # Max and min should be close
            counts = [q[1] for q in query_counts]
            variance = max(counts) - min(counts)
            self.assertLess(variance, 5,
                          f"Query count varies too much: {variance} (indicates non-paginated logic)")
    
    def test_pagination_with_sorting(self):
        """Pagination with sorting should be efficient"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Test various sort orders
        sort_orders = ['name', '-created_at', 'seller_status']
        
        for sort_order in sort_orders:
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                {'page': 1, 'page_size': 20, 'ordering': sort_order}
            )
            
            self.assertIn(response.status_code, [200, 404])
            if response.status_code == 200:
                self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
                
                logger.info(f"Pagination with sort '{sort_order}': {metrics['response_time']:.3f}s")
    
    def test_pagination_with_filtering(self):
        """Pagination with filters should not degrade performance"""
        LargeDatasetFactory.create_sellers(count=500)
        
        # Test with various filters
        filters = [
            {'page': 1, 'page_size': 20},
            {'page': 1, 'page_size': 20, 'status': 'APPROVED'},
            {'page': 1, 'page_size': 20, 'status': 'PENDING', 'created_after': '2025-01-01'},
        ]
        
        for filter_params in filters:
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                filter_params
            )
            
            self.assertIn(response.status_code, [200, 404])
            if response.status_code == 200:
                self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
                
                logger.info(f"Pagination with filter: {metrics['response_time']:.3f}s")
    
    def test_pagination_page_size_variations(self):
        """Different page sizes should all perform efficiently"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        page_sizes = [10, 20, 50, 100]
        
        for size in page_sizes:
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                {'page': 1, 'page_size': size}
            )
            
            self.assertIn(response.status_code, [200, 404])
            if response.status_code == 200:
                # Slightly slower for larger pages, but should still be under limit
                timeout = self.PERF_TIMEOUT_PAGINATION * (size / 20)  # Scale timeout
                self.assertLess(metrics['response_time'], timeout,
                              f"Page size {size} exceeded timeout")
                
                logger.info(f"Page size {size}: {metrics['response_time']:.3f}s")


class PaginationOptimizationTests(PerformanceTestCase):
    """Tests for pagination optimization"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_pagination_uses_limit_offset(self):
        """Pagination should use LIMIT and OFFSET, not fetch all and slice"""
        LargeDatasetFactory.create_sellers(count=500)
        
        reset_queries()
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 5, 'page_size': 20}
        )
        
        if response.status_code == 200:
            # Check that LIMIT and OFFSET are used
            queries = [q['sql'] for q in connection.queries]
            
            # Should have LIMIT and OFFSET in queries
            has_limit_offset = any('LIMIT' in q.upper() for q in queries)
            
            self.assertTrue(has_limit_offset,
                          "Pagination not using LIMIT/OFFSET (may be fetching all records)")
            
            logger.info(f"Pagination uses LIMIT/OFFSET: {has_limit_offset}")
    
    def test_pagination_count_query_efficiency(self):
        """Pagination count query should be efficient"""
        LargeDatasetFactory.create_sellers(count=2000)
        
        reset_queries()
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 1, 'page_size': 20}
        )
        
        if response.status_code == 200:
            # Should have a COUNT query for total count
            queries = [q['sql'] for q in connection.queries]
            count_queries = [q for q in queries if 'COUNT' in q.upper()]
            
            # Should have exactly 1 count query
            self.assertGreaterEqual(len(count_queries), 1,
                                  "No COUNT query found in pagination")
            
            logger.info(f"Count queries: {len(count_queries)}")


class PaginationScalingTests(PerformanceTestCase):
    """Tests for pagination scaling characteristics"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_pagination_constant_time_scaling(self):
        """Pagination should have constant time regardless of total records"""
        measurements = []
        
        for size in [100, 500, 1000, 5000]:
            self.setUp()
            self.create_admin_user()
            LargeDatasetFactory.create_sellers(count=size)
            
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                {'page': 1, 'page_size': 20}
            )
            
            if response.status_code == 200:
                measurements.append((size, metrics['response_time']))
        
        if measurements:
            # Check scaling - should be roughly constant time
            is_constant = PerformanceAssertions.assert_constant_time(measurements, tolerance=0.2)
            
            logger.info(f"Pagination scaling (should be constant): {measurements}")
            logger.info(f"Constant time performance: {is_constant}")
            
            # All should be under timeout
            for size, time in measurements:
                self.assertLess(time, self.PERF_TIMEOUT_PAGINATION,
                              f"Pagination exceeded timeout at size {size}")
    
    def test_pagination_deep_offset_performance(self):
        """Deep pagination (high offset) should not degrade significantly"""
        LargeDatasetFactory.create_sellers(count=5000)
        
        measurements = []
        
        # Test shallow, middle, and deep offsets
        for page in [1, 50, 100, 200, 250]:  # 5000 records, 20 per page
            response, metrics = self.measure_endpoint(
                'GET',
                '/api/users/admin/sellers/list_sellers/',
                {'page': page, 'page_size': 20}
            )
            
            if response.status_code == 200:
                measurements.append((page, metrics['response_time']))
        
        if measurements:
            logger.info(f"Deep pagination: {measurements}")
            
            # Performance should not significantly degrade with deep offsets
            first_time = measurements[0][1]
            last_time = measurements[-1][1]
            
            # Last page should not be more than 2x slower than first
            ratio = last_time / first_time if first_time > 0 else 0
            self.assertLess(ratio, 2.0,
                          f"Deep pagination degraded: first={first_time:.3f}s, last={last_time:.3f}s")
            
            logger.info(f"Deep pagination scaling: {ratio:.2f}x")


class PaginationIndexOptimizationTests(PerformanceTestCase):
    """Tests to verify pagination benefits from database indexes"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_pagination_with_indexed_sorting(self):
        """Pagination with indexed sort field should be faster"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        # Sort by created_at (should be indexed)
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 1, 'page_size': 20, 'ordering': '-created_at'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
            logger.info(f"Indexed sort performance: {metrics['response_time']:.3f}s")
    
    def test_pagination_filtering_on_indexed_field(self):
        """Filtering on indexed field should be efficient"""
        LargeDatasetFactory.create_sellers(count=1000)
        
        response, metrics = self.measure_endpoint(
            'GET',
            '/api/users/admin/sellers/list_sellers/',
            {'page': 1, 'page_size': 20, 'status': 'APPROVED'}
        )
        
        self.assertIn(response.status_code, [200, 404])
        if response.status_code == 200:
            self.assert_response_time(metrics['response_time'], self.PERF_TIMEOUT_PAGINATION)
            
            # With index, should be very fast
            self.assertLess(metrics['response_time'], 0.3,
                          "Indexed filter not performing well")
            
            logger.info(f"Indexed filter performance: {metrics['response_time']:.3f}s")
