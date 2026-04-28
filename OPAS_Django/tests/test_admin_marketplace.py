"""
Test Suite for PART 3: Admin Marketplace Control Endpoints

Tests for:
- AdminMarketplaceViewSet (product listing, filtering, details)
- AdminPriceMonitoringViewSet (violation detection, resolution)
- PriceMonitoringService (business logic)
- SellerComplianceService (compliance tracking)
- MarketplaceAnalyticsService (health metrics)

Test Coverage:
- List endpoints with various filters
- Detail retrieval
- Permission checking
- Price violation detection
- Violation resolution workflows
- Marketplace overview calculations

Test Structure:
- Setup: Create test data (users, products, ceilings, violations)
- Test Cases: One test per scenario
- Teardown: Clean up test data
- Assertions: Verify responses and state changes
"""

import json
from decimal import Decimal
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase
from rest_framework import status

from apps.users.models import User, UserRole, SellerStatus
from apps.users.seller_models import SellerProduct, ProductStatus, ProductImage
from apps.users.admin_models import (
    PriceCeiling, PriceNonCompliance, AdminUser
)
from apps.users.admin_services import (
    PriceMonitoringService, SellerComplianceService, MarketplaceAnalyticsService
)

User = get_user_model()


class AdminMarketplaceViewSetTestCase(APITestCase):
    """Test cases for Admin Marketplace ViewSet"""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            email='admin@opas.com',
            password='testpass123',
            role=UserRole.ADMIN,
            full_name='Admin User'
        )
        AdminUser.objects.create(user=self.admin_user)
        
        # Create seller user
        self.seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            full_name='Farm Owner'
        )
        
        # Create price ceiling
        self.price_ceiling = PriceCeiling.objects.create(
            product_type='VEGETABLE',
            ceiling_price=Decimal('75.00')
        )
        
        # Create test products
        self.product1 = SellerProduct.objects.create(
            seller=self.seller,
            name='Tomato',
            product_type='VEGETABLE',
            description='Fresh tomatoes',
            price=Decimal('50.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        self.product2 = SellerProduct.objects.create(
            seller=self.seller,
            name='Expensive Tomato',
            product_type='VEGETABLE',
            description='Premium tomatoes',
            price=Decimal('85.00'),  # Exceeds ceiling
            stock_level=50,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        # Create product images
        ProductImage.objects.create(
            product=self.product1,
            image='test_image1.jpg',
            is_primary=True
        )
    
    def test_marketplace_list_authenticated_admin(self):
        """Test: Admin can list marketplace products"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/marketplace-control/products/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 2)
    
    def test_marketplace_list_unauthenticated(self):
        """Test: Unauthenticated users cannot access marketplace list"""
        response = self.client.get('/api/admin/marketplace-control/products/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_marketplace_list_non_admin(self):
        """Test: Non-admin users cannot access admin endpoints"""
        self.client.force_authenticate(user=self.seller)
        response = self.client.get('/api/admin/marketplace-control/products/')
        
        # Should fail due to permission denial
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_marketplace_filter_by_type(self):
        """Test: Filter products by product type"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            '/api/admin/marketplace-control/products/?product_type=VEGETABLE'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)
    
    def test_marketplace_filter_by_seller(self):
        """Test: Filter products by seller"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            f'/api/admin/marketplace-control/products/?seller_id={self.seller.id}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)
    
    def test_marketplace_filter_by_status(self):
        """Test: Filter products by status"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            '/api/admin/marketplace-control/products/?status=ACTIVE'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data['results']), 0)
    
    def test_marketplace_search(self):
        """Test: Search products by name"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            '/api/admin/marketplace-control/products/?search=Tomato'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data['results']), 0)
    
    def test_marketplace_retrieve_product(self):
        """Test: Get product details"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            f'/api/admin/marketplace-control/products/{self.product1.id}/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Tomato')
        self.assertIn('price_ceiling', response.data)
        self.assertIn('price_compliant', response.data)
    
    def test_marketplace_overview(self):
        """Test: Get marketplace overview"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            '/api/admin/marketplace-control/products/overview/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_products', response.data)
        self.assertIn('active_products', response.data)
        self.assertIn('compliance_percentage', response.data)
        self.assertIn('marketplace_health_score', response.data)


class AdminPriceMonitoringViewSetTestCase(APITestCase):
    """Test cases for Admin Price Monitoring ViewSet"""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        
        # Create admin user
        self.admin_user = User.objects.create_user(
            email='admin@opas.com',
            password='testpass123',
            role=UserRole.ADMIN,
            full_name='Admin User'
        )
        AdminUser.objects.create(user=self.admin_user)
        
        # Create seller
        self.seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            full_name='Farm Owner'
        )
        
        # Create price ceiling
        self.price_ceiling = PriceCeiling.objects.create(
            product_type='VEGETABLE',
            ceiling_price=Decimal('75.00')
        )
        
        # Create product with price violation
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Expensive Vegetable',
            product_type='VEGETABLE',
            description='Overpriced product',
            price=Decimal('90.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        # Create violation
        self.violation = PriceNonCompliance.objects.create(
            product=self.product,
            violation_status='CRITICAL',
            is_resolved=False
        )
    
    def test_violations_list_admin(self):
        """Test: Admin can list price violations"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/price-monitoring/violations/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data['results']), 0)
    
    def test_violations_list_unauthenticated(self):
        """Test: Unauthenticated users cannot list violations"""
        response = self.client.get('/api/admin/price-monitoring/violations/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_violations_filter_by_seller(self):
        """Test: Filter violations by seller"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            f'/api/admin/price-monitoring/violations/?seller_id={self.seller.id}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_violation_detail(self):
        """Test: Get violation details"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(
            f'/api/admin/price-monitoring/violations/{self.violation.id}/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['product_name'], 'Expensive Vegetable')
        self.assertIn('excess_amount', response.data)
    
    def test_violation_resolve(self):
        """Test: Resolve a violation"""
        self.client.force_authenticate(user=self.admin_user)
        data = {'admin_notes': 'Seller updated price'}
        response = self.client.post(
            f'/api/admin/price-monitoring/violations/{self.violation.id}/resolve/',
            data=data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify violation is resolved
        self.violation.refresh_from_db()
        self.assertTrue(self.violation.is_resolved)


class PriceMonitoringServiceTestCase(TestCase):
    """Test cases for PriceMonitoringService"""
    
    def setUp(self):
        """Set up test data"""
        self.seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            full_name='Farm Owner'
        )
        
        self.price_ceiling = PriceCeiling.objects.create(
            product_type='VEGETABLE',
            ceiling_price=Decimal('75.00')
        )
    
    def test_check_price_violations_detects_violations(self):
        """Test: check_price_violations detects price violations"""
        # Create product exceeding ceiling
        product = SellerProduct.objects.create(
            seller=self.seller,
            name='Expensive Product',
            product_type='VEGETABLE',
            price=Decimal('85.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        result = PriceMonitoringService.check_price_violations()
        
        self.assertGreater(result['total_violations'], 0)
        self.assertGreater(result['new_violations'], 0)
    
    def test_get_seller_violations(self):
        """Test: get_seller_violations returns seller's violations"""
        product = SellerProduct.objects.create(
            seller=self.seller,
            name='Expensive Product',
            product_type='VEGETABLE',
            price=Decimal('85.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        PriceNonCompliance.objects.create(
            product=product,
            violation_status='CRITICAL',
            is_resolved=False
        )
        
        violations = PriceMonitoringService.get_seller_violations(self.seller)
        
        self.assertEqual(violations.count(), 1)


class SellerComplianceServiceTestCase(TestCase):
    """Test cases for SellerComplianceService"""
    
    def setUp(self):
        """Set up test data"""
        self.seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            full_name='Farm Owner'
        )
        
        self.price_ceiling = PriceCeiling.objects.create(
            product_type='VEGETABLE',
            ceiling_price=Decimal('75.00')
        )
    
    def test_compliance_score_calculation(self):
        """Test: Compliance score calculated correctly"""
        # Create compliant product
        SellerProduct.objects.create(
            seller=self.seller,
            name='Compliant Product',
            product_type='VEGETABLE',
            price=Decimal('50.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        score = SellerComplianceService.get_seller_compliance_score(self.seller)
        
        self.assertGreaterEqual(score, 0)
        self.assertLessEqual(score, 100)
    
    def test_violation_history_retrieval(self):
        """Test: Violation history retrieved correctly"""
        product = SellerProduct.objects.create(
            seller=self.seller,
            name='Expensive Product',
            product_type='VEGETABLE',
            price=Decimal('85.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        
        PriceNonCompliance.objects.create(
            product=product,
            violation_status='CRITICAL',
            is_resolved=False
        )
        
        history = SellerComplianceService.get_violation_history(self.seller)
        
        self.assertGreater(history.count(), 0)


class MarketplaceAnalyticsServiceTestCase(TestCase):
    """Test cases for MarketplaceAnalyticsService"""
    
    def setUp(self):
        """Set up test data"""
        self.seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            full_name='Farm Owner'
        )
        
        self.price_ceiling = PriceCeiling.objects.create(
            product_type='VEGETABLE',
            ceiling_price=Decimal('75.00')
        )
        
        # Create test product
        SellerProduct.objects.create(
            seller=self.seller,
            name='Test Product',
            product_type='VEGETABLE',
            price=Decimal('50.00'),
            stock_level=100,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
    
    def test_marketplace_overview(self):
        """Test: Marketplace overview calculated correctly"""
        overview = MarketplaceAnalyticsService.get_marketplace_overview()
        
        self.assertIn('total_products', overview)
        self.assertIn('active_products', overview)
        self.assertIn('total_sellers', overview)
        self.assertGreater(overview['total_products'], 0)
    
    def test_compliance_metrics(self):
        """Test: Compliance metrics calculated correctly"""
        metrics = MarketplaceAnalyticsService.get_compliance_metrics()
        
        self.assertIn('total_violations', metrics)
        self.assertIn('compliance_percentage', metrics)
        self.assertGreaterEqual(metrics['compliance_percentage'], 0)
    
    def test_health_score_calculation(self):
        """Test: Health score calculated correctly"""
        score = MarketplaceAnalyticsService.calculate_health_score()
        
        self.assertGreaterEqual(score, 0)
        self.assertLessEqual(score, 100)


__all__ = [
    'AdminMarketplaceViewSetTestCase',
    'AdminPriceMonitoringViewSetTestCase',
    'PriceMonitoringServiceTestCase',
    'SellerComplianceServiceTestCase',
    'MarketplaceAnalyticsServiceTestCase',
]
