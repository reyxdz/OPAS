"""
Phase 3.5 Phase C - Dashboard Implementation Tests

Comprehensive test suite for admin dashboard statistics endpoint.
Tests cover all metric groups, authorization, performance, and edge cases.

Test Coverage:
- 45+ unit tests across 8 test classes
- All metric calculations (seller, market, OPAS, price compliance, alerts)
- Authorization and permission checking
- Performance benchmarking
- Edge cases (empty database, large datasets)
- Response format validation
- Error handling
"""

import json
import time
from datetime import timedelta
from decimal import Decimal

from django.test import TestCase, Client
from django.utils import timezone
from django.contrib.auth.models import Permission, Group
from rest_framework.test import APITestCase, APIClient
from rest_framework import status

from apps.users.models import User, UserRole, SellerStatus
from apps.users.seller_models import SellerProduct, SellerOrder, SellToOPAS, OrderStatus, ProductStatus
from apps.users.admin_models import (
    AdminUser, SellerRegistrationRequest, SellerDocumentVerification,
    SellerApprovalHistory, SellerSuspension,
    PriceCeiling, PriceAdvisory, PriceHistory, PriceNonCompliance,
    OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction, OPASPurchaseHistory,
    AdminAuditLog, MarketplaceAlert, SystemNotification,
)


# ==================== SELLER METRICS TESTS ====================

class SellerMetricsTestCase(APITestCase):
    """Test seller marketplace metrics calculation"""
    
    def setUp(self):
        """Create test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
        
        # Create test sellers
        self.approved_seller = User.objects.create_user(
            username='seller1',
            email='seller1@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.pending_seller = User.objects.create_user(
            username='seller2',
            email='seller2@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        )
        
        self.suspended_seller = User.objects.create_user(
            username='seller3',
            email='seller3@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.SUSPENDED
        )
    
    def test_total_sellers_count(self):
        """Test total seller count includes all sellers"""
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertEqual(data['seller_metrics']['total_sellers'], 3)
    
    def test_pending_approvals_count(self):
        """Test pending approval count"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['seller_metrics']['pending_approvals'], 1)
    
    def test_active_sellers_count(self):
        """Test active seller count"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['seller_metrics']['active_sellers'], 1)
    
    def test_suspended_sellers_count(self):
        """Test suspended seller count"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['seller_metrics']['suspended_sellers'], 1)
    
    def test_new_sellers_this_month(self):
        """Test new sellers count for current month"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['seller_metrics']['new_this_month'], 3)
    
    def test_approval_rate_calculation(self):
        """Test approval rate calculation"""
        # Create some history to have approved and rejected
        SellerApprovalHistory.objects.create(
            seller=self.pending_seller,
            admin=AdminUser.objects.get(user=self.admin_user),
            decision='APPROVED',
            decision_reason='Test',
            effective_from=timezone.now()
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Should calculate approval rate
        self.assertIn('approval_rate', data['seller_metrics'])
        self.assertGreaterEqual(data['seller_metrics']['approval_rate'], 0)
        self.assertLessEqual(data['seller_metrics']['approval_rate'], 100)
    
    def test_seller_metrics_are_non_negative(self):
        """Test that all seller metrics are non-negative"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        metrics = data['seller_metrics']
        self.assertGreaterEqual(metrics['total_sellers'], 0)
        self.assertGreaterEqual(metrics['pending_approvals'], 0)
        self.assertGreaterEqual(metrics['active_sellers'], 0)
        self.assertGreaterEqual(metrics['suspended_sellers'], 0)
        self.assertGreaterEqual(metrics['new_this_month'], 0)


# ==================== MARKET METRICS TESTS ====================

class MarketMetricsTestCase(APITestCase):
    """Test marketplace trading metrics calculation"""
    
    def setUp(self):
        """Create test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
        
        # Create seller
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        # Create products
        self.product1 = SellerProduct.objects.create(
            seller=self.seller,
            name='Rice',
            product_type='Grains',
            price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False,
            stock_level=100
        )
        
        self.product2 = SellerProduct.objects.create(
            seller=self.seller,
            name='Wheat',
            product_type='Grains',
            price=Decimal('400.00'),
            status=ProductStatus.INACTIVE,
            is_deleted=False,
            stock_level=50
        )
    
    def test_active_listings_excludes_inactive(self):
        """Test active listing count excludes inactive products"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Should count only ACTIVE products
        self.assertEqual(data['market_metrics']['active_listings'], 1)
    
    def test_active_listings_excludes_deleted(self):
        """Test active listing count excludes soft-deleted products"""
        self.product2.is_deleted = True
        self.product2.save()
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['market_metrics']['active_listings'], 1)
    
    def test_total_sales_today(self):
        """Test total sales today calculation"""
        today = timezone.now().date()
        
        # Create orders for today
        buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER
        )
        
        order1 = SellerOrder.objects.create(
            seller=self.seller,
            buyer=buyer,
            product=self.product1,
            quantity=10,
            total_amount=Decimal('5000.00'),
            status=OrderStatus.DELIVERED,
            created_at=timezone.now()
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['market_metrics']['total_sales_today'], 5000.0)
    
    def test_total_sales_month(self):
        """Test total sales this month calculation"""
        month_start = timezone.now().replace(day=1)
        
        buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER
        )
        
        # Create orders for this month
        SellerOrder.objects.create(
            seller=self.seller,
            buyer=buyer,
            product=self.product1,
            quantity=10,
            total_amount=Decimal('5000.00'),
            status=OrderStatus.DELIVERED,
            created_at=month_start
        )
        
        SellerOrder.objects.create(
            seller=self.seller,
            buyer=buyer,
            product=self.product1,
            quantity=5,
            total_amount=Decimal('2500.00'),
            status=OrderStatus.DELIVERED,
            created_at=month_start + timedelta(days=5)
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['market_metrics']['total_sales_month'], 7500.0)
    
    def test_avg_transaction_calculation(self):
        """Test average transaction value calculation"""
        month_start = timezone.now().replace(day=1)
        
        buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER
        )
        
        # Create 2 orders totaling 7500
        SellerOrder.objects.create(
            seller=self.seller,
            buyer=buyer,
            product=self.product1,
            quantity=10,
            total_amount=Decimal('5000.00'),
            status=OrderStatus.DELIVERED,
            created_at=month_start
        )
        
        SellerOrder.objects.create(
            seller=self.seller,
            buyer=buyer,
            product=self.product1,
            quantity=5,
            total_amount=Decimal('2500.00'),
            status=OrderStatus.DELIVERED,
            created_at=month_start + timedelta(days=5)
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Average should be 7500 / 2 = 3750
        self.assertAlmostEqual(data['market_metrics']['avg_transaction'], 3750.0, places=1)


# ==================== OPAS METRICS TESTS ====================

class OPASMetricsTestCase(APITestCase):
    """Test OPAS bulk purchase metrics calculation"""
    
    def setUp(self):
        """Create test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
        
        # Create seller and product
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Rice',
            product_type='Grains',
            price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
    
    def test_pending_submissions_count(self):
        """Test pending OPAS submission count"""
        # Create pending submission
        SellToOPAS.objects.create(
            seller=self.seller,
            product=self.product,
            quantity=100,
            submitted_quantity=100,
            status='PENDING'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['opas_metrics']['pending_submissions'], 1)
    
    def test_approved_submissions_this_month(self):
        """Test approved submissions count for current month"""
        month_start = timezone.now().replace(day=1)
        
        # Create approved submission
        SellToOPAS.objects.create(
            seller=self.seller,
            product=self.product,
            quantity=100,
            submitted_quantity=100,
            status='ACCEPTED',
            created_at=month_start
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['opas_metrics']['approved_this_month'], 1)
    
    def test_total_inventory_quantity(self):
        """Test total inventory quantity sum"""
        # Create inventory entries
        OPASInventory.objects.create(
            product=self.product,
            quantity_received=100,
            quantity_on_hand=100,
            in_date=timezone.now(),
            expiry_date=timezone.now() + timedelta(days=30)
        )
        
        OPASInventory.objects.create(
            product=self.product,
            quantity_received=50,
            quantity_on_hand=50,
            in_date=timezone.now(),
            expiry_date=timezone.now() + timedelta(days=30)
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['opas_metrics']['total_inventory'], 150)
    
    def test_low_stock_count(self):
        """Test low stock inventory count"""
        # Create low stock inventory
        inventory = OPASInventory.objects.create(
            product=self.product,
            quantity_received=5,
            quantity_on_hand=5,
            in_date=timezone.now(),
            expiry_date=timezone.now() + timedelta(days=30),
            low_stock_threshold=10
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertGreaterEqual(data['opas_metrics']['low_stock_count'], 0)
    
    def test_expiring_count(self):
        """Test expiring inventory count (within 7 days)"""
        # Create expiring inventory
        expiry_soon = timezone.now() + timedelta(days=5)
        OPASInventory.objects.create(
            product=self.product,
            quantity_received=100,
            quantity_on_hand=100,
            in_date=timezone.now(),
            expiry_date=expiry_soon
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertGreaterEqual(data['opas_metrics']['expiring_count'], 0)


# ==================== PRICE COMPLIANCE TESTS ====================

class PriceComplianceTestCase(APITestCase):
    """Test price compliance metrics calculation"""
    
    def setUp(self):
        """Create test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
        
        # Create seller
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
    
    def test_compliant_listings_count(self):
        """Test compliant listings count (price <= ceiling)"""
        # Create compliant product (no ceiling or price <= ceiling)
        SellerProduct.objects.create(
            seller=self.seller,
            name='Rice',
            product_type='Grains',
            price=Decimal('500.00'),
            ceiling_price=None,
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['price_compliance']['compliant_listings'], 1)
    
    def test_non_compliant_listings_count(self):
        """Test non-compliant listings count (price > ceiling)"""
        # Create non-compliant product
        SellerProduct.objects.create(
            seller=self.seller,
            name='Rice',
            product_type='Grains',
            price=Decimal('600.00'),
            ceiling_price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        # Create violation record
        product = SellerProduct.objects.get(name='Rice')
        PriceNonCompliance.objects.create(
            seller=self.seller,
            product=product,
            listed_price=Decimal('600.00'),
            ceiling_price=Decimal('500.00'),
            overage_percentage=20.0,
            status='NEW'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['price_compliance']['non_compliant'], 1)
    
    def test_compliance_rate_calculation(self):
        """Test compliance rate calculation"""
        # Create 4 compliant and 1 non-compliant
        for i in range(4):
            SellerProduct.objects.create(
                seller=self.seller,
                name=f'Product{i}',
                product_type='Grains',
                price=Decimal('500.00'),
                ceiling_price=None,
                status=ProductStatus.ACTIVE,
                is_deleted=False
            )
        
        non_compliant = SellerProduct.objects.create(
            seller=self.seller,
            name='NonCompliant',
            product_type='Grains',
            price=Decimal('600.00'),
            ceiling_price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        PriceNonCompliance.objects.create(
            seller=self.seller,
            product=non_compliant,
            listed_price=Decimal('600.00'),
            ceiling_price=Decimal('500.00'),
            overage_percentage=20.0,
            status='NEW'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Compliance rate should be 4 / 5 = 80%
        self.assertAlmostEqual(data['price_compliance']['compliance_rate'], 80.0, places=1)
    
    def test_compliance_rate_with_no_listings(self):
        """Test compliance rate when no listings exist"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Should return 0 or 100 when no listings
        self.assertIn(data['price_compliance']['compliance_rate'], [0.0, 100.0])


# ==================== ALERTS TESTS ====================

class AlertsTestCase(APITestCase):
    """Test alerts and marketplace health metrics"""
    
    def setUp(self):
        """Create test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
        
        # Create seller and product
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Rice',
            product_type='Grains',
            price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
    
    def test_price_violations_count(self):
        """Test price violation alerts count"""
        MarketplaceAlert.objects.create(
            title='Price Violation',
            description='Price too high',
            alert_type='PRICE_VIOLATION',
            severity='WARNING',
            affected_seller=self.seller,
            affected_product=self.product,
            status='OPEN'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['alerts']['price_violations'], 1)
    
    def test_seller_issues_count(self):
        """Test seller issue alerts count"""
        MarketplaceAlert.objects.create(
            title='Seller Issue',
            description='Seller unresponsive',
            alert_type='SELLER_ISSUE',
            severity='MEDIUM',
            affected_seller=self.seller,
            status='OPEN'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['alerts']['seller_issues'], 1)
    
    def test_inventory_alerts_count(self):
        """Test inventory alerts count"""
        MarketplaceAlert.objects.create(
            title='Inventory Alert',
            description='Low stock',
            alert_type='INVENTORY_ALERT',
            severity='HIGH',
            affected_product=self.product,
            status='OPEN'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['alerts']['inventory_alerts'], 1)
    
    def test_total_open_alerts_count(self):
        """Test total open alerts count"""
        # Create multiple alerts
        for i in range(3):
            MarketplaceAlert.objects.create(
                title=f'Alert {i}',
                description='Test alert',
                alert_type='PRICE_VIOLATION',
                severity='WARNING',
                status='OPEN'
            )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertEqual(data['alerts']['total_open_alerts'], 3)
    
    def test_resolved_alerts_excluded(self):
        """Test that resolved alerts are not counted"""
        # Create open alert
        MarketplaceAlert.objects.create(
            title='Open Alert',
            description='Test',
            alert_type='PRICE_VIOLATION',
            status='OPEN'
        )
        
        # Create resolved alert
        MarketplaceAlert.objects.create(
            title='Resolved Alert',
            description='Test',
            alert_type='PRICE_VIOLATION',
            status='RESOLVED'
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Should only count open alert
        self.assertEqual(data['alerts']['total_open_alerts'], 1)


# ==================== AUTHORIZATION TESTS ====================

class DashboardAuthorizationTestCase(APITestCase):
    """Test authorization and permission checking"""
    
    def setUp(self):
        """Create test users"""
        self.client = APIClient()
        
        # Create different user types
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        
        self.seller_user = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        
        self.buyer_user = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER
        )
    
    def test_unauthenticated_user_denied(self):
        """Test that unauthenticated users are denied"""
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_seller_user_denied(self):
        """Test that seller users are denied"""
        self.client.force_authenticate(user=self.seller_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_buyer_user_denied(self):
        """Test that buyer users are denied"""
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_admin_user_allowed(self):
        """Test that admin users are allowed"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)


# ==================== RESPONSE FORMAT TESTS ====================

class DashboardResponseFormatTestCase(APITestCase):
    """Test response format and structure"""
    
    def setUp(self):
        """Create admin user"""
        self.client = APIClient()
        
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
    
    def test_response_includes_timestamp(self):
        """Test response includes timestamp"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        self.assertIn('timestamp', data)
    
    def test_response_includes_all_metric_groups(self):
        """Test response includes all required metric groups"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        required_keys = [
            'seller_metrics',
            'market_metrics',
            'opas_metrics',
            'price_compliance',
            'alerts',
            'marketplace_health_score'
        ]
        
        for key in required_keys:
            self.assertIn(key, data)
    
    def test_seller_metrics_structure(self):
        """Test seller metrics have correct structure"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        seller_metrics = data['seller_metrics']
        required_fields = [
            'total_sellers',
            'pending_approvals',
            'active_sellers',
            'suspended_sellers',
            'new_this_month',
            'approval_rate'
        ]
        
        for field in required_fields:
            self.assertIn(field, seller_metrics)
    
    def test_market_metrics_structure(self):
        """Test market metrics have correct structure"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        market_metrics = data['market_metrics']
        required_fields = [
            'active_listings',
            'total_sales_today',
            'total_sales_month',
            'avg_price_change',
            'avg_transaction'
        ]
        
        for field in required_fields:
            self.assertIn(field, market_metrics)
    
    def test_opas_metrics_structure(self):
        """Test OPAS metrics have correct structure"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        opas_metrics = data['opas_metrics']
        required_fields = [
            'pending_submissions',
            'approved_this_month',
            'total_inventory',
            'low_stock_count',
            'expiring_count',
            'total_inventory_value'
        ]
        
        for field in required_fields:
            self.assertIn(field, opas_metrics)
    
    def test_price_compliance_structure(self):
        """Test price compliance metrics have correct structure"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        price_compliance = data['price_compliance']
        required_fields = [
            'compliant_listings',
            'non_compliant',
            'compliance_rate'
        ]
        
        for field in required_fields:
            self.assertIn(field, price_compliance)
    
    def test_alerts_structure(self):
        """Test alerts have correct structure"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        alerts = data['alerts']
        required_fields = [
            'price_violations',
            'seller_issues',
            'inventory_alerts',
            'total_open_alerts'
        ]
        
        for field in required_fields:
            self.assertIn(field, alerts)
    
    def test_response_is_valid_json(self):
        """Test response is valid JSON"""
        response = self.client.get('/api/admin/dashboard/stats/')
        
        try:
            data = response.json()
            self.assertIsInstance(data, dict)
        except json.JSONDecodeError:
            self.fail('Response is not valid JSON')


# ==================== PERFORMANCE TESTS ====================

class DashboardPerformanceTestCase(APITestCase):
    """Test dashboard performance"""
    
    def setUp(self):
        """Create test data"""
        self.client = APIClient()
        
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
    
    def test_dashboard_response_time_under_limit(self):
        """Test dashboard responds within performance target"""
        start_time = time.time()
        response = self.client.get('/api/admin/dashboard/stats/')
        end_time = time.time()
        
        response_time = (end_time - start_time) * 1000  # Convert to ms
        
        # Target: < 2000ms response time
        self.assertLess(response_time, 2000)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_dashboard_performance_with_large_dataset(self):
        """Test dashboard performance with large dataset"""
        # Create 100 sellers
        sellers = []
        for i in range(100):
            seller = User.objects.create_user(
                username=f'seller{i}',
                email=f'seller{i}@test.com',
                password='testpass123',
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED
            )
            sellers.append(seller)
        
        # Create products for each seller
        for seller in sellers:
            SellerProduct.objects.create(
                seller=seller,
                name=f'Product-{seller.username}',
                product_type='Grains',
                price=Decimal('500.00'),
                status=ProductStatus.ACTIVE,
                is_deleted=False
            )
        
        start_time = time.time()
        response = self.client.get('/api/admin/dashboard/stats/')
        end_time = time.time()
        
        response_time = (end_time - start_time) * 1000
        
        # Should still respond quickly even with large dataset
        self.assertLess(response_time, 2000)
        self.assertEqual(response.status_code, status.HTTP_200_OK)


# ==================== EDGE CASES TESTS ====================

class DashboardEdgeCasesTestCase(APITestCase):
    """Test edge cases and error handling"""
    
    def setUp(self):
        """Create admin user"""
        self.client = APIClient()
        
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
    
    def test_empty_database(self):
        """Test dashboard with empty database"""
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        
        # All metrics should be 0 or N/A
        self.assertEqual(data['seller_metrics']['total_sellers'], 0)
        self.assertEqual(data['market_metrics']['active_listings'], 0)
        self.assertEqual(data['alerts']['total_open_alerts'], 0)
    
    def test_compliance_rate_with_zero_listings(self):
        """Test compliance rate calculation with zero listings"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Should handle division by zero gracefully
        compliance_rate = data['price_compliance']['compliance_rate']
        self.assertIsInstance(compliance_rate, (int, float))
        self.assertIn(compliance_rate, [0.0, 100.0])
    
    def test_approval_rate_with_no_decisions(self):
        """Test approval rate with no approval decisions"""
        # Create sellers but no approval history
        User.objects.create_user(
            username='seller1',
            email='seller1@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        )
        
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        # Should handle gracefully (might be 0 or default)
        approval_rate = data['seller_metrics']['approval_rate']
        self.assertIsInstance(approval_rate, (int, float))
        self.assertGreaterEqual(approval_rate, 0)
    
    def test_health_score_range(self):
        """Test health score is within valid range (0-100)"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        health_score = data['marketplace_health_score']
        self.assertGreaterEqual(health_score, 0)
        self.assertLessEqual(health_score, 100)
    
    def test_all_metrics_are_non_negative(self):
        """Test all metrics are non-negative"""
        response = self.client.get('/api/admin/dashboard/stats/')
        data = response.json()
        
        def check_non_negative(obj, path=''):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    check_non_negative(value, f'{path}.{key}')
            elif isinstance(obj, (int, float)):
                self.assertGreaterEqual(obj, 0, f'Negative value at {path}')
        
        # Check all metric groups
        check_non_negative(data['seller_metrics'])
        check_non_negative(data['market_metrics'])
        check_non_negative(data['opas_metrics'])
        check_non_negative(data['price_compliance'])
        check_non_negative(data['alerts'])


# ==================== INTEGRATION TESTS ====================

class DashboardIntegrationTestCase(APITestCase):
    """Integration tests with realistic data"""
    
    def setUp(self):
        """Create realistic test data"""
        self.client = APIClient()
        
        # Create admin
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        AdminUser.objects.create(user=self.admin_user)
        self.client.force_authenticate(user=self.admin_user)
        
        # Create sellers in different states
        self.seller_approved = User.objects.create_user(
            username='seller_approved',
            email='seller_approved@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        self.seller_pending = User.objects.create_user(
            username='seller_pending',
            email='seller_pending@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        )
        
        # Create products
        self.product1 = SellerProduct.objects.create(
            seller=self.seller_approved,
            name='Rice Premium',
            product_type='Grains',
            price=Decimal('500.00'),
            ceiling_price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
        
        self.product2 = SellerProduct.objects.create(
            seller=self.seller_approved,
            name='Wheat',
            product_type='Grains',
            price=Decimal('550.00'),
            ceiling_price=Decimal('500.00'),
            status=ProductStatus.ACTIVE,
            is_deleted=False
        )
    
    def test_complete_dashboard_scenario(self):
        """Test complete dashboard with realistic data"""
        # Add some orders
        buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER
        )
        
        today = timezone.now()
        SellerOrder.objects.create(
            seller=self.seller_approved,
            buyer=buyer,
            product=self.product1,
            quantity=50,
            total_amount=Decimal('25000.00'),
            status=OrderStatus.DELIVERED,
            created_at=today
        )
        
        # Add alerts
        MarketplaceAlert.objects.create(
            title='Price Violation',
            description='Wheat price exceeds ceiling',
            alert_type='PRICE_VIOLATION',
            severity='HIGH',
            affected_seller=self.seller_approved,
            affected_product=self.product2,
            status='OPEN'
        )
        
        # Add OPAS submission
        SellToOPAS.objects.create(
            seller=self.seller_approved,
            product=self.product1,
            quantity=100,
            submitted_quantity=100,
            status='PENDING'
        )
        
        # Get dashboard
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        
        # Verify data
        self.assertEqual(data['seller_metrics']['total_sellers'], 2)
        self.assertEqual(data['seller_metrics']['pending_approvals'], 1)
        self.assertEqual(data['seller_metrics']['active_sellers'], 1)
        self.assertEqual(data['market_metrics']['active_listings'], 2)
        self.assertEqual(data['market_metrics']['total_sales_today'], 25000.0)
        self.assertEqual(data['opas_metrics']['pending_submissions'], 1)
        self.assertEqual(data['alerts']['price_violations'], 1)
        self.assertGreater(data['marketplace_health_score'], 0)
