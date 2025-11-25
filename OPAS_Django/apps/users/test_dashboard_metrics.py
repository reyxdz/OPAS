"""
Unit tests for admin dashboard metrics calculations.

Tests cover:
- Seller metrics calculation
- Market metrics calculation
- OPAS metrics calculation
- Price compliance calculation
- Alerts and health score calculation
- Performance benchmarks
"""

from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import timedelta
from decimal import Decimal
import time

from .models import UserRole, SellerStatus
from .seller_models import SellerProduct, SellerOrder, ProductStatus, OrderStatus, SellToOPAS
from .admin_models import (
    OPASInventory,
    PriceNonCompliance,
    MarketplaceAlert,
    PriceHistory,
    AdminUser,
    AdminRole,
)

User = get_user_model()


class SellerMetricsTestCase(TestCase):
    """Test seller metrics calculations"""
    
    def setUp(self):
        """Create test data"""
        # Create multiple sellers with different statuses
        self.seller_pending = User.objects.create_user(
            email='pending@seller.com',
            password='pass123',
            username='pending_seller',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        )
        
        self.seller_approved = User.objects.create_user(
            email='approved@seller.com',
            password='pass123',
            username='approved_seller',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.seller_suspended = User.objects.create_user(
            email='suspended@seller.com',
            password='pass123',
            username='suspended_seller',
            role=UserRole.SELLER,
            seller_status=SellerStatus.SUSPENDED,
            suspended_at=timezone.now()
        )
        
        self.seller_rejected = User.objects.create_user(
            email='rejected@seller.com',
            password='pass123',
            username='rejected_seller',
            role=UserRole.SELLER,
            seller_status=SellerStatus.REJECTED
        )
        
        # Create a seller from this month
        self.seller_new = User.objects.create_user(
            email='new@seller.com',
            password='pass123',
            username='new_seller',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING,
            created_at=timezone.now()
        )
    
    def test_total_sellers_count(self):
        """Test counting total sellers"""
        total_sellers = User.objects.filter(role=UserRole.SELLER).count()
        self.assertEqual(total_sellers, 5)
    
    def test_pending_approvals_count(self):
        """Test counting pending approval sellers"""
        pending = User.objects.filter(
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        ).count()
        self.assertEqual(pending, 2)
    
    def test_active_sellers_count(self):
        """Test counting approved sellers"""
        active = User.objects.filter(
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        ).count()
        self.assertEqual(active, 1)
    
    def test_suspended_sellers_count(self):
        """Test counting suspended sellers"""
        suspended = User.objects.filter(
            role=UserRole.SELLER,
            seller_status=SellerStatus.SUSPENDED
        ).count()
        self.assertEqual(suspended, 1)
    
    def test_approval_rate_calculation(self):
        """Test approval rate calculation"""
        from django.db.models import Count, Q
        
        stats = User.objects.filter(role=UserRole.SELLER).aggregate(
            approved=Count('id', filter=Q(seller_status=SellerStatus.APPROVED)),
            rejected=Count('id', filter=Q(seller_status=SellerStatus.REJECTED))
        )
        
        if (stats['approved'] + stats['rejected']) > 0:
            approval_rate = (
                stats['approved'] / (stats['approved'] + stats['rejected']) * 100
            )
            # We have 1 approved and 1 rejected, so rate should be 50%
            self.assertEqual(approval_rate, 50.0)
    
    def test_new_sellers_this_month(self):
        """Test counting new sellers created this month"""
        from django.db.models import Count, Q
        
        current_month = timezone.now()
        new_sellers = User.objects.filter(
            role=UserRole.SELLER,
            created_at__month=current_month.month,
            created_at__year=current_month.year
        ).count()
        # Should include both seller_new and seller_pending (created at same time)
        self.assertGreaterEqual(new_sellers, 1)


class MarketMetricsTestCase(TestCase):
    """Test market metrics calculations"""
    
    def setUp(self):
        """Create test data"""
        self.seller = User.objects.create_user(
            email='seller@test.com',
            password='pass123',
            username='seller1',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.buyer = User.objects.create_user(
            email='buyer@test.com',
            password='pass123',
            username='buyer1',
            role=UserRole.BUYER
        )
        
        # Create active products
        self.product1 = SellerProduct.objects.create(
            seller=self.seller,
            name='Product 1',
            product_type='Vegetable',
            price=Decimal('10.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        self.product2 = SellerProduct.objects.create(
            seller=self.seller,
            name='Product 2 (Deleted)',
            product_type='Fruit',
            price=Decimal('15.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=True,
            deleted_at=timezone.now()
        )
        
        # Create orders
        today = timezone.now()
        self.order_today = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product1,
            order_number='ORD-001',
            quantity=5,
            price_per_unit=Decimal('10.00'),
            total_amount=Decimal('50.00'),
            status=OrderStatus.DELIVERED,
            created_at=today,
            delivered_at=today
        )
        
        last_month = today - timedelta(days=30)
        self.order_last_month = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product1,
            order_number='ORD-002',
            quantity=10,
            price_per_unit=Decimal('10.00'),
            total_amount=Decimal('100.00'),
            status=OrderStatus.DELIVERED,
            created_at=last_month,
            delivered_at=last_month
        )
    
    def test_active_listings_excludes_deleted(self):
        """Test that deleted products are excluded from active listings"""
        active_count = SellerProduct.objects.filter(
            is_deleted=False,
            status=ProductStatus.ACTIVE
        ).count()
        self.assertEqual(active_count, 1)
    
    def test_total_sales_today(self):
        """Test calculating total sales for today"""
        from django.db.models import Sum
        
        today = timezone.now().date()
        total_sales = SellerOrder.objects.filter(
            created_at__date=today,
            status=OrderStatus.DELIVERED
        ).aggregate(total=Sum('total_amount'))['total'] or 0
        
        # Both orders are created with today's date. Total should be 50 + 100 = 150
        self.assertEqual(total_sales, Decimal('150.00'))
    
    def test_avg_transaction_calculation(self):
        """Test average transaction calculation"""
        from django.db.models import Sum, Count
        
        today = timezone.now().date()
        current_month_start = today.replace(day=1)
        
        monthly_stats = SellerOrder.objects.filter(
            created_at__date__gte=current_month_start,
            status=OrderStatus.DELIVERED
        ).aggregate(
            total=Sum('total_amount'),
            count=Count('id')
        )
        
        total = monthly_stats['total'] or 0
        count = monthly_stats['count'] or 1
        avg_transaction = total / count if count > 0 else 0
        
        self.assertGreater(avg_transaction, 0)


class OPASMetricsTestCase(TestCase):
    """Test OPAS metrics calculations"""
    
    def setUp(self):
        """Create test data"""
        self.seller = User.objects.create_user(
            email='seller@test.com',
            password='pass123',
            username='seller1',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Test Product',
            product_type='Vegetable',
            price=Decimal('20.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        # Create pending submission
        self.submission_pending = SellToOPAS.objects.create(
            seller=self.seller,
            product=self.product,
            submission_number='SUB-001',
            quantity_offered=100,
            offered_price=Decimal('18.00'),
            status='PENDING'
        )
        
        # Create approved submission
        self.submission_approved = SellToOPAS.objects.create(
            seller=self.seller,
            product=self.product,
            submission_number='SUB-002',
            quantity_offered=50,
            offered_price=Decimal('17.00'),
            approved_price=Decimal('17.50'),
            status='ACCEPTED'
        )
        
        # Create inventory
        self.inventory = OPASInventory.objects.create(
            product=self.product,
            quantity_received=1000,
            quantity_on_hand=50,
            low_stock_threshold=100,
            in_date=timezone.now(),
            expiry_date=timezone.now() + timedelta(days=5)
        )
    
    def test_pending_submissions_count(self):
        """Test counting pending OPAS submissions"""
        pending = SellToOPAS.objects.filter(status='PENDING').count()
        self.assertEqual(pending, 1)
    
    def test_approved_submissions_count(self):
        """Test counting approved submissions"""
        from django.db.models import Count, Q
        
        current_month = timezone.now().date().replace(day=1)
        approved = SellToOPAS.objects.filter(
            status='ACCEPTED',
            created_at__date__gte=current_month
        ).count()
        self.assertGreaterEqual(approved, 1)
    
    def test_total_inventory_quantity(self):
        """Test total inventory calculation"""
        total = OPASInventory.objects.total_quantity()
        self.assertEqual(total, 50)
    
    def test_low_stock_detection(self):
        """Test detecting low stock inventory"""
        low_stock = OPASInventory.objects.low_stock().count()
        self.assertEqual(low_stock, 1)  # quantity_on_hand=50 < threshold=100
    
    def test_expiring_inventory_detection(self):
        """Test detecting expiring inventory within 7 days"""
        expiring = OPASInventory.objects.expiring_soon(days=7).count()
        self.assertEqual(expiring, 1)


class PriceComplianceTestCase(TestCase):
    """Test price compliance calculations"""
    
    def setUp(self):
        """Create test data"""
        self.seller = User.objects.create_user(
            email='seller@test.com',
            password='pass123',
            username='seller1',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        # Compliant product (within ceiling)
        self.product_compliant = SellerProduct.objects.create(
            seller=self.seller,
            name='Compliant Product',
            product_type='Vegetable',
            price=Decimal('10.00'),
            ceiling_price=Decimal('12.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        # Non-compliant product (exceeds ceiling)
        self.product_non_compliant = SellerProduct.objects.create(
            seller=self.seller,
            name='Non-Compliant Product',
            product_type='Fruit',
            price=Decimal('15.00'),
            ceiling_price=Decimal('12.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
    
    def test_compliant_listings_count(self):
        """Test counting compliant products"""
        compliant = SellerProduct.objects.filter(is_deleted=False).compliant().count()
        self.assertEqual(compliant, 1)
    
    def test_non_compliant_listings_count(self):
        """Test counting non-compliant products"""
        non_compliant = SellerProduct.objects.filter(is_deleted=False).non_compliant().count()
        self.assertEqual(non_compliant, 1)
    
    def test_compliance_rate_calculation(self):
        """Test compliance rate calculation"""
        compliant = SellerProduct.objects.filter(is_deleted=False).compliant().count()
        non_compliant = SellerProduct.objects.filter(is_deleted=False).non_compliant().count()
        
        total = compliant + non_compliant
        rate = (compliant / total * 100) if total > 0 else 0
        
        self.assertEqual(rate, 50.0)


class AlertsAndHealthTestCase(TestCase):
    """Test alerts and health score calculations"""
    
    def setUp(self):
        """Create test data"""
        self.seller = User.objects.create_user(
            email='seller@test.com',
            password='pass123',
            username='seller1',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        # Create alerts
        self.alert_open = MarketplaceAlert.objects.create(
            title='Price Violation',
            description='Seller exceeded price ceiling',
            alert_type='PRICE_VIOLATION',
            severity='WARNING',
            status='OPEN',
            affected_seller=self.seller
        )
        
        self.alert_resolved = MarketplaceAlert.objects.create(
            title='Inventory Issue',
            description='Low stock detected',
            alert_type='INVENTORY_ALERT',
            severity='INFO',
            status='RESOLVED',
            affected_seller=self.seller,
            resolved_at=timezone.now()
        )
    
    def test_open_alerts_count(self):
        """Test counting open alerts"""
        from django.db.models import Count
        
        open_alerts = MarketplaceAlert.objects.filter(status='OPEN').count()
        self.assertEqual(open_alerts, 1)
    
    def test_alert_type_filtering(self):
        """Test filtering alerts by type"""
        from django.db.models import Count, Q
        
        price_violations = MarketplaceAlert.objects.filter(
            alert_type='PRICE_VIOLATION',
            status='OPEN'
        ).count()
        self.assertEqual(price_violations, 1)
    
    def test_health_score_calculation(self):
        """Test marketplace health score calculation"""
        # This is a simplified test
        # In production, would use actual compliance rate, seller ratings, fulfillment rates
        
        compliance_rate = 80.0  # Example
        seller_rating_score = 75.0  # Example
        order_fulfillment_rate = 90.0  # Example
        
        health_score = (
            (compliance_rate * 0.4) +
            (seller_rating_score * 0.3) +
            (order_fulfillment_rate * 0.3)
        )
        
        self.assertGreater(health_score, 0)
        self.assertLessEqual(health_score, 100)
        # Calculated: (80 * 0.4) + (75 * 0.3) + (90 * 0.3) = 32 + 22.5 + 27 = 81.5
        self.assertAlmostEqual(health_score, 81.5)


class PerformanceTestCase(TestCase):
    """Test performance of metric calculations"""
    
    def setUp(self):
        """Create a larger dataset for performance testing"""
        # Create multiple sellers
        sellers = [
            User.objects.create_user(
                email=f'seller{i}@test.com',
                password='pass123',
                username=f'seller{i}',
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED if i % 2 == 0 else SellerStatus.PENDING
            )
            for i in range(10)
        ]
        
        # Create products
        for seller in sellers:
            for j in range(5):
                SellerProduct.objects.create(
                    seller=seller,
                    name=f'Product {j}',
                    product_type='Vegetable',
                    price=Decimal('10.00'),
                    status=ProductStatus.ACTIVE,
                    is_deleted=False
                )
    
    def test_seller_metrics_performance(self):
        """Test performance of seller metrics calculation"""
        from django.db.models import Count, Q
        
        start = time.time()
        
        seller_stats = User.objects.filter(role=UserRole.SELLER).aggregate(
            total=Count('id'),
            pending=Count('id', filter=Q(seller_status=SellerStatus.PENDING)),
            approved=Count('id', filter=Q(seller_status=SellerStatus.APPROVED))
        )
        
        elapsed = (time.time() - start) * 1000  # Convert to ms
        
        # Should complete in under 100ms
        self.assertLess(elapsed, 100)
    
    def test_active_listings_performance(self):
        """Test performance of active listings calculation"""
        start = time.time()
        
        active_count = SellerProduct.objects.filter(
            is_deleted=False,
            status=ProductStatus.ACTIVE
        ).count()
        
        elapsed = (time.time() - start) * 1000  # Convert to ms
        
        # Should complete in under 100ms
        self.assertLess(elapsed, 100)
        self.assertEqual(active_count, 50)


class FulfillmentMetricsTestCase(TestCase):
    """Test order fulfillment metrics"""
    
    def setUp(self):
        """Create test data"""
        self.seller = User.objects.create_user(
            email='seller@test.com',
            password='pass123',
            username='seller1',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.buyer = User.objects.create_user(
            email='buyer@test.com',
            password='pass123',
            username='buyer1',
            role=UserRole.BUYER
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Test Product',
            product_type='Vegetable',
            price=Decimal('10.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
    
    def test_fulfillment_days_calculation(self):
        """Test calculation of fulfillment days"""
        today = timezone.now()
        delivery_date = today + timedelta(days=5)
        
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product,
            order_number='ORD-001',
            quantity=5,
            price_per_unit=Decimal('10.00'),
            total_amount=Decimal('50.00'),
            status=OrderStatus.FULFILLED,
            created_at=today,
            delivery_date=delivery_date
        )
        
        # Deliver on day 3 - adjust by the same hour as created_at to ensure exact 3 days
        delivery_time = today + timedelta(days=3, hours=1)
        order.status = OrderStatus.DELIVERED
        order.delivered_at = delivery_time
        order.fulfillment_days = (delivery_time - order.created_at).days
        order.on_time = delivery_time <= delivery_date
        order.save()
        
        # fulfillment_days should be 3 (integer division of days)
        self.assertEqual(order.fulfillment_days, 3)
        self.assertTrue(order.on_time)
    
    def test_late_delivery_tracking(self):
        """Test tracking late deliveries"""
        today = timezone.now()
        delivery_date = today + timedelta(days=5)
        
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product,
            order_number='ORD-002',
            quantity=5,
            price_per_unit=Decimal('10.00'),
            total_amount=Decimal('50.00'),
            status=OrderStatus.FULFILLED,
            created_at=today,
            delivery_date=delivery_date
        )
        
        # Deliver on day 7 (late) - add 1 hour to ensure exactly 7 days difference
        delivery_time = today + timedelta(days=7, hours=1)
        order.status = OrderStatus.DELIVERED
        order.delivered_at = delivery_time
        order.fulfillment_days = (delivery_time - order.created_at).days
        order.on_time = delivery_time <= delivery_date
        order.save()
        
        # fulfillment_days should be 7 (integer division of days)
        self.assertEqual(order.fulfillment_days, 7)
        self.assertFalse(order.on_time)


class DashboardAuthorizationTestCase(TestCase):
    """Test authorization and authentication for dashboard endpoint"""
    
    def setUp(self):
        """Create test users with different roles"""
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='pass123',
            username='admin',
            role=UserRole.ADMIN,
            is_staff=True
        )
        
        # Create AdminUser instance for permission checking
        AdminUser.objects.create(
            user=self.admin_user,
            admin_role=AdminRole.SUPER_ADMIN,
            is_active=True
        )
        
        self.seller_user = User.objects.create_user(
            email='seller@test.com',
            password='pass123',
            username='seller',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.buyer_user = User.objects.create_user(
            email='buyer@test.com',
            password='pass123',
            username='buyer',
            role=UserRole.BUYER
        )
    
    def test_dashboard_stats_requires_authentication(self):
        """Test that unauthenticated users cannot access dashboard"""
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 401)
    
    def test_dashboard_stats_admin_access(self):
        """Test that admin users can access dashboard"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 200)
    
    def test_dashboard_stats_seller_denied(self):
        """Test that seller users are denied access to dashboard"""
        self.client.force_login(self.seller_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        # Should be 403 Forbidden (not authorized for admin action)
        self.assertEqual(response.status_code, 403)
    
    def test_dashboard_stats_buyer_denied(self):
        """Test that buyer users are denied access to dashboard"""
        self.client.force_login(self.buyer_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        # Should be 403 Forbidden (not authorized for admin action)
        self.assertEqual(response.status_code, 403)


class DashboardIntegrationTestCase(TestCase):
    """Integration tests for dashboard endpoint with complete scenarios"""
    
    def setUp(self):
        """Create comprehensive test data"""
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='pass123',
            username='admin',
            role=UserRole.ADMIN,
            is_staff=True
        )
        
        # Create AdminUser instance for permission checking
        AdminUser.objects.create(
            user=self.admin_user,
            admin_role=AdminRole.SUPER_ADMIN,
            is_active=True
        )
        
        # Create sellers with various statuses
        self.seller_approved = User.objects.create_user(
            email='seller1@test.com',
            password='pass123',
            username='seller1',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.seller_pending = User.objects.create_user(
            email='seller2@test.com',
            password='pass123',
            username='seller2',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        )
        
        self.buyer = User.objects.create_user(
            email='buyer@test.com',
            password='pass123',
            username='buyer',
            role=UserRole.BUYER
        )
        
        # Create products
        self.product1 = SellerProduct.objects.create(
            seller=self.seller_approved,
            name='Product 1',
            product_type='Vegetable',
            price=Decimal('10.00'),
            ceiling_price=Decimal('12.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        self.product2 = SellerProduct.objects.create(
            seller=self.seller_approved,
            name='Product 2',
            product_type='Fruit',
            price=Decimal('20.00'),
            ceiling_price=Decimal('12.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        # Create orders
        today = timezone.now()
        self.order1 = SellerOrder.objects.create(
            seller=self.seller_approved,
            buyer=self.buyer,
            product=self.product1,
            order_number='ORD-001',
            quantity=10,
            price_per_unit=Decimal('10.00'),
            total_amount=Decimal('100.00'),
            status=OrderStatus.DELIVERED,
            created_at=today,
            delivered_at=today,
            delivery_date=today,
            on_time=True,
            fulfillment_days=1
        )
        
        self.order2 = SellerOrder.objects.create(
            seller=self.seller_approved,
            buyer=self.buyer,
            product=self.product2,
            order_number='ORD-002',
            quantity=5,
            price_per_unit=Decimal('20.00'),
            total_amount=Decimal('100.00'),
            status=OrderStatus.DELIVERED,
            created_at=today,
            delivered_at=today + timedelta(days=10),
            delivery_date=today + timedelta(days=5),
            on_time=False,
            fulfillment_days=10
        )
        
        # Create OPAS submissions
        self.opas_submission = SellToOPAS.objects.create(
            seller=self.seller_approved,
            product=self.product1,
            submission_number='OPAS-001',
            quantity_offered=100,
            offered_price=Decimal('9.00'),
            status='PENDING'
        )
        
        # Create inventory
        self.inventory = OPASInventory.objects.create(
            product=self.product1,
            quantity_received=500,
            quantity_on_hand=200,
            low_stock_threshold=100,
            in_date=today,
            expiry_date=today + timedelta(days=30)
        )
        
        # Create alerts
        self.alert = MarketplaceAlert.objects.create(
            title='Price Violation',
            description='Product exceeds ceiling',
            alert_type='PRICE_VIOLATION',
            severity='WARNING',
            status='OPEN',
            affected_seller=self.seller_approved
        )
    
    def test_dashboard_stats_returns_all_metric_groups(self):
        """Test that response contains all required metric groups"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify all required fields are present
        self.assertIn('timestamp', data)
        self.assertIn('seller_metrics', data)
        self.assertIn('market_metrics', data)
        self.assertIn('opas_metrics', data)
        self.assertIn('price_compliance', data)
        self.assertIn('alerts', data)
        self.assertIn('marketplace_health_score', data)
    
    def test_dashboard_seller_metrics_structure(self):
        """Test seller metrics response structure"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        seller_metrics = data['seller_metrics']
        
        # Verify seller metrics fields
        self.assertIn('total_sellers', seller_metrics)
        self.assertIn('pending_approvals', seller_metrics)
        self.assertIn('active_sellers', seller_metrics)
        self.assertIn('suspended_sellers', seller_metrics)
        self.assertIn('new_this_month', seller_metrics)
        self.assertIn('approval_rate', seller_metrics)
        
        # Verify values are correct
        self.assertEqual(seller_metrics['total_sellers'], 2)  # 2 sellers created
        self.assertEqual(seller_metrics['pending_approvals'], 1)
        self.assertEqual(seller_metrics['active_sellers'], 1)
        self.assertEqual(seller_metrics['suspended_sellers'], 0)
    
    def test_dashboard_market_metrics_structure(self):
        """Test market metrics response structure"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        market_metrics = data['market_metrics']
        
        # Verify market metrics fields
        self.assertIn('active_listings', market_metrics)
        self.assertIn('total_sales_today', market_metrics)
        self.assertIn('total_sales_month', market_metrics)
        self.assertIn('avg_price_change', market_metrics)
        self.assertIn('avg_transaction', market_metrics)
        
        # Verify values
        self.assertEqual(market_metrics['active_listings'], 2)
        self.assertEqual(market_metrics['total_sales_today'], 200.0)
    
    def test_dashboard_opas_metrics_structure(self):
        """Test OPAS metrics response structure"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        opas_metrics = data['opas_metrics']
        
        # Verify OPAS metrics fields
        self.assertIn('pending_submissions', opas_metrics)
        self.assertIn('approved_this_month', opas_metrics)
        self.assertIn('total_inventory', opas_metrics)
        self.assertIn('low_stock_count', opas_metrics)
        self.assertIn('expiring_count', opas_metrics)
        self.assertIn('total_inventory_value', opas_metrics)
        
        # Verify values
        self.assertEqual(opas_metrics['pending_submissions'], 1)
        self.assertEqual(opas_metrics['total_inventory'], 200)
    
    def test_dashboard_price_compliance_structure(self):
        """Test price compliance response structure"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        compliance = data['price_compliance']
        
        # Verify price compliance fields
        self.assertIn('compliant_listings', compliance)
        self.assertIn('non_compliant', compliance)
        self.assertIn('compliance_rate', compliance)
        
        # Verify values (1 compliant, 1 non-compliant)
        self.assertEqual(compliance['compliant_listings'], 1)
        self.assertEqual(compliance['non_compliant'], 1)
        self.assertEqual(compliance['compliance_rate'], 50.0)
    
    def test_dashboard_alerts_structure(self):
        """Test alerts response structure"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        alerts = data['alerts']
        
        # Verify alerts fields
        self.assertIn('price_violations', alerts)
        self.assertIn('seller_issues', alerts)
        self.assertIn('inventory_alerts', alerts)
        self.assertIn('total_open_alerts', alerts)
        
        # Verify values
        self.assertEqual(alerts['price_violations'], 1)
        self.assertEqual(alerts['total_open_alerts'], 1)
    
    def test_dashboard_health_score_is_valid(self):
        """Test that health score is valid (0-100)"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        health_score = data['marketplace_health_score']
        
        # Verify health score is between 0 and 100
        self.assertGreaterEqual(health_score, 0)
        self.assertLessEqual(health_score, 100)
    
    def test_dashboard_response_format(self):
        """Test that response format matches specification"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'application/json')
        
        data = response.json()
        
        # Verify timestamp is present and is valid ISO format
        self.assertIn('timestamp', data)
        self.assertIsNotNone(data['timestamp'])
    
    def test_dashboard_with_empty_database(self):
        """Test dashboard returns sensible defaults with no data"""
        # Create fresh admin for isolated test
        admin = User.objects.create_user(
            email='admin2@test.com',
            password='pass123',
            username='admin2',
            role=UserRole.ADMIN,
            is_staff=True
        )
        
        # Create AdminUser instance for permission checking
        AdminUser.objects.create(
            user=admin,
            admin_role=AdminRole.SUPER_ADMIN,
            is_active=True
        )
        
        # Delete all non-admin users and their related data
        User.objects.exclude(pk=admin.pk).delete()
        
        self.client.force_login(admin)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify all zeros for empty database
        self.assertEqual(data['seller_metrics']['total_sellers'], 0)
        self.assertEqual(data['market_metrics']['active_listings'], 0)
        self.assertEqual(data['opas_metrics']['pending_submissions'], 0)
        self.assertEqual(data['alerts']['total_open_alerts'], 0)
    
    def test_dashboard_response_contains_numeric_types(self):
        """Test that all metrics contain proper numeric types"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify seller metrics types
        seller = data['seller_metrics']
        self.assertIsInstance(seller['total_sellers'], int)
        self.assertIsInstance(seller['pending_approvals'], int)
        self.assertIsInstance(seller['approval_rate'], (int, float))
        
        # Verify market metrics types
        market = data['market_metrics']
        self.assertIsInstance(market['active_listings'], int)
        self.assertIsInstance(market['total_sales_today'], (int, float))
        
        # Verify health score is integer
        self.assertIsInstance(data['marketplace_health_score'], int)


class DashboardPerformanceIntegrationTestCase(TestCase):
    """Integration tests for dashboard performance with realistic data"""
    
    def setUp(self):
        """Create realistic dataset for performance testing"""
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='pass123',
            username='admin',
            role=UserRole.ADMIN,
            is_staff=True
        )
        
        # Create AdminUser instance for permission checking
        AdminUser.objects.create(
            user=self.admin_user,
            admin_role=AdminRole.SUPER_ADMIN,
            is_active=True
        )
        
        # Create 50 sellers
        sellers = []
        for i in range(50):
            seller = User.objects.create_user(
                email=f'seller{i}@test.com',
                password='pass123',
                username=f'seller{i}',
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED if i % 3 == 0 else (
                    SellerStatus.PENDING if i % 3 == 1 else SellerStatus.SUSPENDED
                )
            )
            sellers.append(seller)
        
        # Create 100 buyers
        buyers = []
        for i in range(100):
            buyer = User.objects.create_user(
                email=f'buyer{i}@test.com',
                password='pass123',
                username=f'buyer{i}',
                role=UserRole.BUYER
            )
            buyers.append(buyer)
        
        # Create products and orders
        today = timezone.now()
        for seller in sellers:
            for j in range(10):
                product = SellerProduct.objects.create(
                    seller=seller,
                    name=f'Product {j}',
                    product_type='Vegetable' if j % 2 == 0 else 'Fruit',
                    price=Decimal('10.00') + Decimal(j),
                    ceiling_price=Decimal('15.00') + Decimal(j),
                    status=ProductStatus.ACTIVE,
                    is_deleted=False
                )
                
                # Create orders
                for k, buyer in enumerate(buyers[:5]):
                    SellerOrder.objects.create(
                        seller=seller,
                        buyer=buyer,
                        product=product,
                        order_number=f'ORD-{seller.id}-{j}-{k}',
                        quantity=k + 1,
                        price_per_unit=Decimal('10.00') + Decimal(j),
                        total_amount=Decimal('50.00') + Decimal(k * 10),
                        status=OrderStatus.DELIVERED,
                        created_at=today,
                        delivered_at=today,
                        delivery_date=today,
                        on_time=True,
                        fulfillment_days=1
                    )
    
    def test_dashboard_performance_large_dataset(self):
        """Test dashboard loads within 2 seconds with realistic data (500+ records)"""
        self.client.force_login(self.admin_user)
        
        import time
        start_time = time.time()
        response = self.client.get('/api/admin/dashboard/stats/')
        elapsed_time = time.time() - start_time
        
        self.assertEqual(response.status_code, 200)
        # Should load in under 2 seconds
        self.assertLess(elapsed_time, 2.0, 
                        f"Dashboard took {elapsed_time:.2f}s to load (target: < 2.0s)")
    
    def test_dashboard_returns_correct_metrics_large_dataset(self):
        """Test that metrics are calculated correctly with large dataset"""
        self.client.force_login(self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify metrics are reasonable
        seller_metrics = data['seller_metrics']
        self.assertEqual(seller_metrics['total_sellers'], 50)
        
        market_metrics = data['market_metrics']
        # 50 sellers * 10 products = 500 products
        self.assertEqual(market_metrics['active_listings'], 500)
        
        # 500 products * 5 buyers * 1 order = 2500 orders
        # But orders are cumulative across all sellers, products, and buyers
        # Actual: 50 sellers * 10 products * 5 buyers = 2500 orders
        self.assertGreater(market_metrics['total_sales_today'], 0)
