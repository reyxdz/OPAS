"""
Performance Tests for Admin Bulk Operations

Tests:
1. Bulk seller approvals complete without timeout (5 seconds max)
2. Batch price ceiling updates complete efficiently
3. Bulk OPAS submissions don't timeout
4. Bulk operations scale linearly with record count
5. Bulk operations don't block UI (implement properly with async if needed)
6. Large inventory adjustments complete efficiently

Run: python manage.py test tests.admin.test_bulk_operations_performance --verbosity=2
"""

from django.test.utils import CaptureQueriesContext
from django.db import connection, reset_queries, transaction
import time
import logging
from decimal import Decimal

from tests.admin.performance_test_fixtures import (
    PerformanceTestCase, LargeDatasetFactory, PerformanceAssertions, PerformanceMetrics
)
from apps.users.models import SellerStatus, SellerApplication
from apps.users.admin_models import PriceCeiling, PriceChangeReason

logger = logging.getLogger(__name__)


class BulkSellerApprovalsPerformanceTests(PerformanceTestCase):
    """Performance tests for bulk seller approval operations"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_bulk_approve_10_sellers(self):
        """Approving 10 sellers should complete quickly"""
        # Create pending sellers
        applications = LargeDatasetFactory.create_seller_applications(count=10, status='PENDING')
        
        def bulk_approve():
            for app in applications:
                app.approve(admin_user=self.admin_user)
        
        result, metrics = self.measure_with_context(bulk_approve)
        
        # Should complete in < 500ms
        self.assertLess(metrics['response_time'], 0.5,
                       f"Bulk approval of 10 sellers took {metrics['response_time']:.3f}s")
        
        logger.info(f"Bulk approve 10: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_bulk_approve_100_sellers(self):
        """Approving 100 sellers should complete within timeout (5 seconds)"""
        # Create pending sellers
        applications = LargeDatasetFactory.create_seller_applications(count=100, status='PENDING')
        
        def bulk_approve():
            for app in applications:
                app.approve(admin_user=self.admin_user)
        
        result, metrics = self.measure_with_context(bulk_approve)
        
        # Should complete within timeout
        self.assertLess(metrics['response_time'], self.PERF_TIMEOUT_BULK_OP,
                       f"Bulk approval of 100 sellers took {metrics['response_time']:.3f}s")
        
        # Should be roughly linear - 10x more sellers shouldn't take 10x longer
        # 100 sellers should take < 5 seconds
        logger.info(f"Bulk approve 100: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_bulk_approve_500_sellers(self):
        """Approving 500 sellers should complete within extended timeout"""
        # Create pending sellers
        applications = LargeDatasetFactory.create_seller_applications(count=500, status='PENDING')
        
        def bulk_approve():
            # Use batch updates for better performance
            app_ids = [app.id for app in applications]
            SellerApplication.objects.filter(id__in=app_ids).update(
                status='APPROVED'
            )
        
        result, metrics = self.measure_with_context(bulk_approve)
        
        # Bulk update should be very fast
        self.assertLess(metrics['response_time'], 2.0,
                       f"Bulk approval of 500 sellers took {metrics['response_time']:.3f}s")
        
        logger.info(f"Bulk approve 500: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_bulk_reject_multiple_sellers(self):
        """Bulk rejecting sellers should be efficient"""
        applications = LargeDatasetFactory.create_seller_applications(count=50, status='PENDING')
        
        def bulk_reject():
            for app in applications:
                app.reject(admin_user=self.admin_user, reason='Does not meet requirements')
        
        result, metrics = self.measure_with_context(bulk_reject)
        
        # Should complete quickly
        self.assertLess(metrics['response_time'], self.PERF_TIMEOUT_BULK_OP)
        
        logger.info(f"Bulk reject 50: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_bulk_approve_scaling(self):
        """Bulk approvals should scale linearly"""
        measurements = []
        
        for size in [10, 25, 50, 100]:
            self.setUp()
            self.create_admin_user()
            applications = LargeDatasetFactory.create_seller_applications(count=size, status='PENDING')
            
            def bulk_approve():
                for app in applications:
                    app.approve(admin_user=self.admin_user)
            
            result, metrics = self.measure_with_context(bulk_approve)
            measurements.append((size, metrics['response_time']))
        
        # Check scaling
        scaling = PerformanceAssertions.get_scaling_characteristics(measurements)
        logger.info(f"Bulk approval scaling: {scaling}")
        logger.info(f"Measurements: {measurements}")
        
        # All should be under timeout
        for size, time in measurements:
            self.assertLess(time, self.PERF_TIMEOUT_BULK_OP,
                          f"Bulk approve exceeded timeout at size {size}")


class BulkPriceUpdatePerformanceTests(PerformanceTestCase):
    """Performance tests for bulk price ceiling updates"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_batch_update_10_price_ceilings(self):
        """Updating 10 price ceilings should be quick"""
        ceilings = LargeDatasetFactory.create_price_ceilings(count=10)
        
        def batch_update():
            for ceiling in ceilings:
                ceiling.current_ceiling = ceiling.current_ceiling + Decimal('5.00')
                ceiling.save()
        
        result, metrics = self.measure_with_context(batch_update)
        
        self.assertLess(metrics['response_time'], 0.5)
        
        logger.info(f"Batch update 10 ceilings: {metrics['response_time']:.3f}s")
    
    def test_batch_update_100_price_ceilings(self):
        """Updating 100 price ceilings should complete efficiently"""
        ceilings = LargeDatasetFactory.create_price_ceilings(count=100)
        
        def batch_update():
            # Efficient bulk update
            ceiling_ids = [c.id for c in ceilings]
            PriceCeiling.objects.filter(id__in=ceiling_ids).update(
                current_ceiling=Decimal('105.00')
            )
        
        result, metrics = self.measure_with_context(batch_update)
        
        # Bulk update should be very fast (single query)
        self.assertLess(metrics['response_time'], 0.5)
        self.assertEqual(metrics['query_count'], 1)  # Single bulk update query
        
        logger.info(f"Bulk update 100 ceilings: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_batch_update_500_price_ceilings(self):
        """Updating 500 price ceilings should still be efficient"""
        ceilings = LargeDatasetFactory.create_price_ceilings(count=500)
        
        def batch_update():
            ceiling_ids = [c.id for c in ceilings]
            PriceCeiling.objects.filter(id__in=ceiling_ids).update(
                current_ceiling=Decimal('110.00')
            )
        
        result, metrics = self.measure_with_context(batch_update)
        
        # Bulk update should still be fast (single query)
        self.assertLess(metrics['response_time'], 1.0)
        
        logger.info(f"Bulk update 500 ceilings: {metrics['response_time']:.3f}s")
    
    def test_batch_price_update_with_history_tracking(self):
        """Price updates with history tracking should still be efficient"""
        sellers = LargeDatasetFactory.create_sellers(count=100)
        ceilings = LargeDatasetFactory.create_price_ceilings(count=100)
        
        def batch_update_with_tracking():
            # Simulate updating with history
            for ceiling in ceilings:
                ceiling.previous_ceiling = ceiling.current_ceiling
                ceiling.current_ceiling = ceiling.current_ceiling + Decimal('10.00')
                ceiling.save()
        
        result, metrics = self.measure_with_context(batch_update_with_tracking)
        
        # Should still be under timeout even with history tracking
        self.assertLess(metrics['response_time'], self.PERF_TIMEOUT_BULK_OP)
        
        logger.info(f"Batch update 100 with history: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_price_update_scaling(self):
        """Price updates should scale linearly"""
        measurements = []
        
        for size in [25, 50, 100, 250]:
            self.setUp()
            self.create_admin_user()
            ceilings = LargeDatasetFactory.create_price_ceilings(count=size)
            
            def batch_update():
                ceiling_ids = [c.id for c in ceilings]
                PriceCeiling.objects.filter(id__in=ceiling_ids).update(
                    current_ceiling=Decimal('105.00')
                )
            
            result, metrics = self.measure_with_context(batch_update)
            measurements.append((size, metrics['response_time']))
        
        scaling = PerformanceAssertions.get_scaling_characteristics(measurements)
        logger.info(f"Price update scaling: {scaling}")
        logger.info(f"Measurements: {measurements}")
        
        # All should be very fast (bulk update is constant time + batch overhead)
        for size, time in measurements:
            self.assertLess(time, 2.0, f"Price update exceeded limit at size {size}")


class BulkOPASOperationsPerformanceTests(PerformanceTestCase):
    """Performance tests for bulk OPAS operations"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_inventory_adjustment_10_items(self):
        """Adjusting 10 OPAS inventory items should be quick"""
        inventory = LargeDatasetFactory.create_opas_inventory(count=10)
        
        def adjust_inventory():
            for item in inventory:
                item.quantity_in_stock += 10
                item.save()
        
        result, metrics = self.measure_with_context(adjust_inventory)
        
        self.assertLess(metrics['response_time'], 0.5)
        
        logger.info(f"Adjust 10 inventory items: {metrics['response_time']:.3f}s")
    
    def test_inventory_adjustment_100_items(self):
        """Adjusting 100 OPAS inventory items should be efficient"""
        inventory = LargeDatasetFactory.create_opas_inventory(count=100)
        
        def adjust_inventory():
            for item in inventory:
                item.quantity_in_stock += 5
                item.save()
        
        result, metrics = self.measure_with_context(adjust_inventory)
        
        # Should complete within reasonable time
        self.assertLess(metrics['response_time'], self.PERF_TIMEOUT_BULK_OP)
        
        logger.info(f"Adjust 100 inventory items: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_inventory_status_update_bulk(self):
        """Bulk inventory status updates should be efficient"""
        inventory = LargeDatasetFactory.create_opas_inventory(count=200)
        
        def bulk_status_update():
            # Mark some as expiring
            from apps.users.admin_models import OPASInventory
            OPASInventory.objects.filter(id__in=[i.id for i in inventory[:50]]).update(
                status='EXPIRING'
            )
        
        result, metrics = self.measure_with_context(bulk_status_update)
        
        # Bulk update should be very fast
        self.assertLess(metrics['response_time'], 0.5)
        
        logger.info(f"Bulk inventory status update: {metrics['response_time']:.3f}s")
    
    def test_opas_operations_scaling(self):
        """OPAS bulk operations should scale efficiently"""
        measurements = []
        
        for size in [50, 100, 200, 500]:
            self.setUp()
            self.create_admin_user()
            inventory = LargeDatasetFactory.create_opas_inventory(count=size)
            
            def adjust():
                from apps.users.admin_models import OPASInventory
                OPASInventory.objects.filter(id__in=[i.id for i in inventory]).update(
                    quantity_in_stock=OPASInventory.objects.first().quantity_in_stock
                )
            
            result, metrics = self.measure_with_context(adjust)
            measurements.append((size, metrics['response_time']))
        
        scaling = PerformanceAssertions.get_scaling_characteristics(measurements)
        logger.info(f"OPAS operations scaling: {scaling}")
        logger.info(f"Measurements: {measurements}")
        
        # All should be fast
        for size, time in measurements:
            self.assertLess(time, 2.0, f"OPAS operation exceeded limit at size {size}")


class BulkAuditLoggingPerformanceTests(PerformanceTestCase):
    """Performance tests for bulk operations with audit logging"""
    
    def setUp(self):
        """Set up test client and create admin user"""
        super().setUp()
        self.create_admin_user()
    
    def test_bulk_operations_with_audit_logging(self):
        """Bulk operations with audit logging should not significantly degrade performance"""
        ceilings = LargeDatasetFactory.create_price_ceilings(count=100)
        
        def bulk_update_with_logging():
            # Simulate bulk update with audit logging
            from apps.users.admin_models import AdminAuditLog, AdminActionType
            
            # Update prices
            ceiling_ids = [c.id for c in ceilings]
            PriceCeiling.objects.filter(id__in=ceiling_ids).update(
                current_ceiling=Decimal('120.00')
            )
            
            # Create single audit log entry for bulk operation
            AdminAuditLog.objects.create(
                admin_user=self.admin_user,
                action_type=AdminActionType.PRICE_UPDATE,
                description=f'Bulk price update: 100 ceilings'
            )
        
        result, metrics = self.measure_with_context(bulk_update_with_logging)
        
        # Should still be fast
        self.assertLess(metrics['response_time'], self.PERF_TIMEOUT_BULK_OP)
        
        logger.info(f"Bulk update with logging: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
    
    def test_individual_audit_log_entries_do_not_block(self):
        """Creating many audit log entries should not cause timeouts"""
        LargeDatasetFactory.create_sellers(count=100)
        
        def create_audit_logs():
            from apps.users.admin_models import AdminAuditLog, AdminActionType
            logs = []
            for i in range(100):
                logs.append(AdminAuditLog(
                    admin_user=self.admin_user,
                    action_type=AdminActionType.SELLER_APPROVAL,
                    description=f'Approval {i}'
                ))
            AdminAuditLog.objects.bulk_create(logs, batch_size=50)
        
        result, metrics = self.measure_with_context(create_audit_logs)
        
        # Should be very fast with bulk_create
        self.assertLess(metrics['response_time'], 1.0)
        
        logger.info(f"Create 100 audit logs: {metrics['response_time']:.3f}s, {metrics['query_count']} queries")
