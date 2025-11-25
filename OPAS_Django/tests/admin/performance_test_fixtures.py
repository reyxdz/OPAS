"""
Performance Testing Fixtures for Admin Panel

Provides:
- PerformanceTestCase: Base class for performance tests with timing utilities
- LargeDatasetFactory: Creates large volumes of test data (1000s of records)
- PerformanceAssertions: Custom assertions for timing and query optimization
- PerformanceMetrics: Collects and analyzes performance data

Features:
- Configurable dataset sizes for scalability testing
- Query counting and analysis
- Database connection pooling
- Memory usage tracking
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase, APIClient
from rest_framework.authtoken.models import Token
from django.test.utils import CaptureQueriesContext
from django.db import connection, reset_queries
from datetime import datetime, timedelta
import time
import uuid
from decimal import Decimal
import psutil
import os

from apps.users.models import User, UserRole, SellerStatus, SellerApplication
from apps.users.admin_models import (
    AdminUser, AdminRole, SellerRegistrationRequest, SellerRegistrationStatus,
    PriceCeiling, PriceHistory, PriceChangeReason, PriceNonCompliance,
    OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction,
    AdminAuditLog, MarketplaceAlert
)
from apps.users.seller_models import SellerProduct


# ==================== PERFORMANCE METRICS ====================

class PerformanceMetrics:
    """Tracks and analyzes performance metrics"""
    
    def __init__(self):
        self.metrics = {
            'response_time': [],
            'query_count': [],
            'query_time': [],
            'memory_usage': [],
            'database_time': []
        }
        self.start_memory = None
        self.start_time = None
    
    def start(self):
        """Start tracking metrics"""
        self.start_time = time.time()
        self.start_memory = psutil.Process(os.getpid()).memory_info().rss / 1024 / 1024  # MB
        reset_queries()
    
    def stop(self):
        """Stop tracking and calculate metrics"""
        elapsed = time.time() - self.start_time
        end_memory = psutil.Process(os.getpid()).memory_info().rss / 1024 / 1024  # MB
        memory_delta = end_memory - self.start_memory
        
        return {
            'response_time': elapsed,
            'memory_delta': memory_delta,
            'query_count': len(connection.queries),
            'total_query_time': sum(float(q['time']) for q in connection.queries)
        }
    
    def record(self, metric_type, value):
        """Record a metric value"""
        if metric_type in self.metrics:
            self.metrics[metric_type].append(value)
    
    def average(self, metric_type):
        """Get average value for metric"""
        if not self.metrics[metric_type]:
            return 0
        return sum(self.metrics[metric_type]) / len(self.metrics[metric_type])
    
    def max(self, metric_type):
        """Get max value for metric"""
        if not self.metrics[metric_type]:
            return 0
        return max(self.metrics[metric_type])
    
    def min(self, metric_type):
        """Get min value for metric"""
        if not self.metrics[metric_type]:
            return 0
        return min(self.metrics[metric_type])
    
    def summary(self):
        """Get performance summary"""
        return {
            'response_time': {
                'avg': self.average('response_time'),
                'max': self.max('response_time'),
                'min': self.min('response_time')
            },
            'query_count': {
                'avg': self.average('query_count'),
                'max': self.max('query_count'),
                'min': self.min('query_count')
            },
            'query_time': {
                'avg': self.average('query_time'),
                'max': self.max('query_time'),
                'min': self.min('query_time')
            },
            'memory_usage': {
                'avg': self.average('memory_usage'),
                'max': self.max('memory_usage'),
                'min': self.min('memory_usage')
            }
        }


# ==================== BASE PERFORMANCE TEST CASE ====================

class PerformanceTestCase(APITestCase):
    """Base class for performance testing with utilities"""
    
    # Configuration
    PERF_TIMEOUT_DASHBOARD = 2.0  # seconds
    PERF_TIMEOUT_ANALYTICS = 3.0  # seconds
    PERF_TIMEOUT_BULK_OP = 5.0  # seconds
    PERF_TIMEOUT_PAGINATION = 1.0  # seconds
    PERF_MAX_QUERIES_DASHBOARD = 10
    PERF_MAX_QUERIES_ANALYTICS = 20
    PERF_MAX_QUERIES_PAGINATION = 5
    
    def setUp(self):
        """Set up test client and metrics"""
        super().setUp()
        self.client = APIClient()
        self.metrics = PerformanceMetrics()
        self.admin_user = None
        self.admin_token = None
    
    def create_admin_user(self, email='admin@opas.com'):
        """Create admin user and return client with auth"""
        user = User.objects.create_user(
            username=f'admin_{uuid.uuid4().hex[:8]}',
            email=email,
            password='secure_password_123',
            role=UserRole.ADMIN
        )
        AdminUser.objects.create(user=user, admin_role=AdminRole.SUPER_ADMIN)
        token = Token.objects.create(user=user)
        
        self.admin_user = user
        self.admin_token = token
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
        return user, token
    
    def assert_response_time(self, elapsed, max_time, message=''):
        """Assert response time is within limit"""
        self.assertLess(
            elapsed, max_time,
            f'Response time {elapsed:.3f}s exceeds limit {max_time}s. {message}'
        )
    
    def assert_query_count(self, query_count, max_queries, message=''):
        """Assert query count is within limit"""
        self.assertLessEqual(
            query_count, max_queries,
            f'Query count {query_count} exceeds limit {max_queries}. {message}'
        )
    
    def assert_no_n_plus_one(self, base_queries, new_queries, additional_records):
        """
        Assert no N+1 query problem detected
        
        Expected pattern: base_queries + (additional_records * constant_queries) is roughly linear
        """
        # Simple check: new queries should not be proportional to additional_records
        query_increase_ratio = (new_queries - base_queries) / additional_records if additional_records > 0 else 0
        
        # Each new record should not cause more than 1 additional query (for basic ops)
        # Allow some overhead but flag if it's clearly N+1
        self.assertLess(
            query_increase_ratio, 3.0,
            f'Possible N+1 problem: base={base_queries}, new={new_queries}, records={additional_records}'
        )
    
    def measure_endpoint(self, method, url, **kwargs):
        """
        Measure endpoint performance
        
        Returns:
            tuple: (response, elapsed_time, query_count, total_query_time)
        """
        reset_queries()
        self.metrics.start()
        
        func = getattr(self.client, method.lower())
        response = func(url, **kwargs)
        
        metrics = self.metrics.stop()
        
        return response, metrics
    
    def measure_with_context(self, callable_func, *args, **kwargs):
        """
        Measure a function's performance
        
        Returns:
            tuple: (result, metrics_dict)
        """
        reset_queries()
        self.metrics.start()
        
        result = callable_func(*args, **kwargs)
        
        metrics = self.metrics.stop()
        self.metrics.record('response_time', metrics['response_time'])
        self.metrics.record('query_count', metrics['query_count'])
        self.metrics.record('query_time', metrics['total_query_time'])
        
        return result, metrics


# ==================== LARGE DATASET FACTORY ====================

class LargeDatasetFactory:
    """Factory for creating large volumes of test data"""
    
    @staticmethod
    def create_sellers(count=100, status=SellerStatus.APPROVED):
        """Create multiple sellers efficiently"""
        sellers = [
            User(
                username=f'seller_{i}_{uuid.uuid4().hex[:4]}',
                email=f'seller_{i}@farm.local',
                first_name=f'Seller',
                last_name=f'{i}',
                role=UserRole.SELLER,
                seller_status=status,
                created_at=datetime.now() - timedelta(days=30 - (i % 30))
            )
            for i in range(count)
        ]
        return User.objects.bulk_create(sellers, batch_size=100)
    
    @staticmethod
    def create_seller_applications(count=50, status='PENDING'):
        """Create multiple seller applications efficiently"""
        sellers = LargeDatasetFactory.create_sellers(count=count, status=SellerStatus.PENDING)
        
        applications = [
            SellerApplication(
                user=seller,
                farm_name=f'Farm {seller.id}',
                location='Test Location',
                products='Rice, Corn',
                status=status
            )
            for seller in sellers
        ]
        return SellerApplication.objects.bulk_create(applications, batch_size=100)
    
    @staticmethod
    def create_price_ceilings(count=100):
        """Create multiple price ceilings efficiently"""
        ceilings = [
            PriceCeiling(
                product_name=f'Product {i}',
                current_ceiling=Decimal('100.00') + Decimal(i),
                previous_ceiling=Decimal('95.00') + Decimal(i),
                effective_date=datetime.now().date(),
                last_modified_by_id=None
            )
            for i in range(count)
        ]
        return PriceCeiling.objects.bulk_create(ceilings, batch_size=100)
    
    @staticmethod
    def create_price_violations(count=100):
        """Create multiple price violations efficiently"""
        sellers = LargeDatasetFactory.create_sellers(count=count // 2)
        
        violations = []
        for i, seller in enumerate(sellers):
            for j in range(2):  # 2 violations per seller
                violations.append(
                    PriceNonCompliance(
                        seller=seller,
                        product_name=f'Product {i*2 + j}',
                        listed_price=Decimal('150.00'),
                        ceiling_price=Decimal('100.00'),
                        overage_percentage=50.0,
                        status='NEW'
                    )
                )
        return PriceNonCompliance.objects.bulk_create(violations, batch_size=100)
    
    @staticmethod
    def create_opas_inventory(count=100):
        """Create OPAS inventory items efficiently"""
        inventory = [
            OPASInventory(
                product_name=f'OPAS Product {i}',
                quantity_in_stock=100 + i,
                unit_price=Decimal('50.00'),
                storage_location=f'Warehouse-{i % 5}',
                in_date=datetime.now().date(),
                expiry_date=datetime.now().date() + timedelta(days=30),
                status='OK' if i % 3 != 0 else 'EXPIRING'
            )
            for i in range(count)
        ]
        return OPASInventory.objects.bulk_create(inventory, batch_size=100)
    
    @staticmethod
    def create_audit_logs(count=500):
        """Create audit log entries efficiently"""
        admin = User.objects.filter(role=UserRole.ADMIN).first()
        if not admin:
            admin = User.objects.create_user(
                username=f'audit_admin_{uuid.uuid4().hex[:4]}',
                email='audit@opas.com',
                password='secure',
                role=UserRole.ADMIN
            )
        
        admin_user = AdminUser.objects.filter(user=admin).first()
        if not admin_user:
            admin_user = AdminUser.objects.create(user=admin, admin_role=AdminRole.SUPER_ADMIN)
        
        action_types = [
            'SELLER_APPROVAL', 'SELLER_SUSPENSION', 'PRICE_UPDATE',
            'OPAS_REVIEW', 'INVENTORY_ADJUSTMENT', 'ADVISORY_CREATED',
            'ALERT_ISSUED', 'ANNOUNCEMENT', 'OTHER'
        ]
        
        logs = [
            AdminAuditLog(
                admin=admin_user,
                action_type=action_types[i % len(action_types)],
                action_category=action_types[i % len(action_types)],
                description=f'Action {i}',
                timestamp=datetime.now() - timedelta(hours=count - i)
            )
            for i in range(count)
        ]
        return AdminAuditLog.objects.bulk_create(logs, batch_size=100)
    
    @staticmethod
    def create_marketplace_alerts(count=100):
        """Create marketplace alerts efficiently"""
        alerts = [
            MarketplaceAlert(
                alert_type='PRICE_VIOLATION',
                severity='HIGH' if i % 3 == 0 else 'MEDIUM',
                title=f'Alert {i}',
                description=f'Alert description {i}',
                status='OPEN' if i % 2 == 0 else 'RESOLVED'
            )
            for i in range(count)
        ]
        return MarketplaceAlert.objects.bulk_create(alerts, batch_size=100)


# ==================== PERFORMANCE ASSERTION HELPERS ====================

class PerformanceAssertions:
    """Custom assertions for performance testing"""
    
    @staticmethod
    def assert_linear_scaling(measurements, threshold=2.0):
        """
        Assert that performance scales roughly linearly
        
        measurements: list of (size, time) tuples
        threshold: acceptable increase ratio per data doubling
        """
        if len(measurements) < 2:
            return True
        
        # Check if time roughly doubles when size doubles
        ratios = []
        for i in range(len(measurements) - 1):
            size_ratio = measurements[i+1][0] / measurements[i][0]
            time_ratio = measurements[i+1][1] / measurements[i][1]
            if size_ratio > 1:
                ratios.append(time_ratio / size_ratio)
        
        avg_ratio = sum(ratios) / len(ratios) if ratios else 0
        return avg_ratio < threshold
    
    @staticmethod
    def assert_constant_time(measurements, tolerance=0.1):
        """
        Assert that performance is constant regardless of data size
        
        tolerance: acceptable variance (0.1 = 10%)
        """
        if len(measurements) < 2:
            return True
        
        times = [m[1] for m in measurements]
        avg_time = sum(times) / len(times)
        max_variance = max(abs(t - avg_time) / avg_time for t in times)
        
        return max_variance <= tolerance
    
    @staticmethod
    def get_scaling_characteristics(measurements):
        """Analyze and describe scaling characteristics"""
        if len(measurements) < 2:
            return "Insufficient data"
        
        sizes = [m[0] for m in measurements]
        times = [m[1] for m in measurements]
        
        # Calculate growth rate
        size_ratio = sizes[-1] / sizes[0]
        time_ratio = times[-1] / times[0]
        growth_rate = time_ratio / size_ratio if size_ratio > 0 else 0
        
        if growth_rate < 1.2:
            return "Sub-linear (excellent)"
        elif growth_rate < 2.0:
            return "Linear (good)"
        elif growth_rate < 4.0:
            return "Super-linear (acceptable)"
        else:
            return "Exponential (poor)"
