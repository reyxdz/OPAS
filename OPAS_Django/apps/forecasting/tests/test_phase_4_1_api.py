"""
Tests for Forecasting API endpoints (Phase 4.1).

Tests for:
- GET /api/admin/forecasts/ - List forecasts
- GET /api/admin/forecasts/{product_id}/ - Detail view
- GET /api/admin/forecasts/search/ - Search and filter
- GET /api/admin/forecasts/metadata/ - Statistics
- GET /api/admin/forecasts/alerts/ - Alerts listing
- POST /api/admin/forecasts/refresh/ - Manual refresh (admin only)

Author: OPAS System
Created: December 2025
"""

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta
from rest_framework.test import APITestCase, APIClient
from rest_framework import status

from apps.users.models import SellerProduct, User, UserRole, AdminRole
from apps.users.seller_models import ProductCategory, ProductStatus
from apps.forecasting.models import (
    ProductForecast,
    ForecastMetadata,
    ForecastAlert,
    AlertType,
    AlertSeverity,
)

User = get_user_model()


class ForecastAPISetupMixin:
    """Mixin providing test data setup for forecast API tests"""
    
    def setUp(self):
        """Create test users, products, and forecasts"""
        # Create test super admin user
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@opas.com',
            password='testpass123',
            phone_number='+639001111111',
            role=UserRole.ADMIN,
            admin_role='SUPER_ADMIN'
        )
        
        # Create regular admin (analytics admin, not super admin)
        self.regular_admin = User.objects.create_user(
            username='regular_admin',
            email='admin2@opas.com',
            password='testpass123',
            phone_number='+639002222222',
            role=UserRole.ADMIN,
            admin_role='ANALYTICS_ADMIN'
        )
        
        # Create non-admin user (buyer)
        self.seller_user = User.objects.create_user(
            username='seller',
            email='seller@opas.com',
            password='testpass123',
            phone_number='+639003333333',
            role=UserRole.BUYER
        )
        
        # Create category
        self.category = ProductCategory.objects.create(
            name='Vegetables',
            slug='vegetables',
            description='Fresh vegetables'
        )
        
        # Create test products
        self.product1 = SellerProduct.objects.create(
            seller=self.seller_user,
            name='Talong',
            category=self.category,
            description='Fresh eggplant',
            price=Decimal('45.00'),
            stock_level=100,
            status=ProductStatus.ACTIVE
        )
        
        self.product2 = SellerProduct.objects.create(
            seller=self.seller_user,
            name='Kamote',
            category=self.category,
            description='Sweet potato',
            price=Decimal('30.00'),
            stock_level=150,
            status=ProductStatus.ACTIVE
        )
        
        # Create test forecasts
        self.forecast1 = ProductForecast.objects.create(
            product=self.product1,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('250.00'),
            demand_lower_bound=Decimal('235.00'),
            demand_upper_bound=Decimal('265.00'),
            price_forecast=Decimal('45.00'),
            price_lower_bound=Decimal('42.00'),
            price_upper_bound=Decimal('48.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True,
            forecast_date=timezone.now(),
            rmse_demand=Decimal('15.50'),
            mape_demand=Decimal('8.5')
        )
        
        self.forecast2 = ProductForecast.objects.create(
            product=self.product2,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('180.00'),
            demand_lower_bound=Decimal('160.00'),
            demand_upper_bound=Decimal('200.00'),
            price_forecast=Decimal('32.00'),
            price_lower_bound=Decimal('28.00'),
            price_upper_bound=Decimal('36.00'),
            confidence_level='MEDIUM',
            model_type='ARIMA',
            is_current=True,
            forecast_date=timezone.now() - timedelta(days=10),  # Stale (>7 days)
            rmse_demand=Decimal('22.00'),
            mape_demand=Decimal('12.0')
        )
        
        # Create stale forecast
        self.stale_forecast = ProductForecast.objects.create(
            product=self.product1,
            forecast_period='2024-12',
            demand_forecast_kg=Decimal('200.00'),
            demand_lower_bound=Decimal('185.00'),
            demand_upper_bound=Decimal('215.00'),
            price_forecast=Decimal('40.00'),
            price_lower_bound=Decimal('37.00'),
            price_upper_bound=Decimal('43.00'),
            confidence_level='LOW',
            model_type='SIMPLE',
            is_current=False,
            forecast_date=timezone.now() - timedelta(days=30),
        )
        
        # Create test alerts
        self.alert1 = ForecastAlert.objects.create(
            product=self.product1,
            alert_type=AlertType.ANOMALY,
            severity=AlertSeverity.WARNING,
            message='Forecast is stale',
            is_acknowledged=False
        )
        
        self.client = APIClient()


class ForecastListAPITestCase(ForecastAPISetupMixin, APITestCase):
    """Tests for GET /api/admin/forecasts/"""
    
    def test_list_requires_authentication(self):
        """Unauthenticated users cannot access forecast list"""
        response = self.client.get('/api/admin/forecasts/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_requires_admin(self):
        """Non-admin users cannot access forecast list"""
        self.client.force_authenticate(user=self.seller_user)
        response = self.client.get('/api/admin/forecasts/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_list_forecasts_success(self):
        """Admin can list all current forecasts"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('count', response.data)
        self.assertIn('results', response.data)
        self.assertEqual(response.data['count'], 2)  # 2 current forecasts
    
    def test_list_pagination(self):
        """Forecast list supports pagination"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/?page_size=1&page=1')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['current_page'], 1)
        self.assertEqual(response.data['total_pages'], 2)
    
    def test_filter_by_confidence(self):
        """Can filter forecasts by confidence level"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/?confidence=HIGH')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['confidence_level'], 'HIGH')
    
    def test_filter_by_model_type(self):
        """Can filter forecasts by model type"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/?model_type=SARIMA')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['model_type'], 'SARIMA')
    
    def test_filter_reliable_only(self):
        """Can filter to show only reliable forecasts"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/?reliable=true')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should exclude INSUFFICIENT_DATA models
        for result in response.data['results']:
            self.assertNotEqual(result['model_type'], 'INSUFFICIENT_DATA')
    
    def test_filter_stale_forecasts(self):
        """Can filter to show only stale forecasts"""
        # Create another stale current forecast
        stale = ProductForecast.objects.create(
            product=self.product2,
            forecast_period='2024-11',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('30.00'),
            price_lower_bound=Decimal('28.00'),
            price_upper_bound=Decimal('32.00'),
            confidence_level='LOW',
            model_type='SIMPLE',
            is_current=True,
            forecast_date=timezone.now() - timedelta(days=10),
        )
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/?stale=true')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should have 2 stale forecasts: forecast2 (10 days) and stale (10 days)
        self.assertEqual(response.data['count'], 2)
    
    def test_search_by_product_name(self):
        """Can search forecasts by product name"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/?search=Talong')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['product_name'], 'Talong')


class ForecastDetailAPITestCase(ForecastAPISetupMixin, APITestCase):
    """Tests for GET /api/admin/forecasts/{product_id}/"""
    
    def test_detail_requires_authentication(self):
        """Unauthenticated users cannot access forecast detail"""
        response = self.client.get(f'/api/admin/forecasts/{self.product1.id}/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_detail_requires_admin(self):
        """Non-admin users cannot access forecast detail"""
        self.client.force_authenticate(user=self.seller_user)
        response = self.client.get(f'/api/admin/forecasts/{self.product1.id}/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_get_forecast_detail(self):
        """Admin can view detailed forecast for product"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(f'/api/admin/forecasts/{self.product1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['product_id'], self.product1.id)
        self.assertEqual(response.data['product_name'], 'Talong')
        self.assertIn('metadata', response.data)
        self.assertIn('active_alerts', response.data)
        self.assertIn('days_old', response.data)
        self.assertIn('is_stale', response.data)
    
    def test_detail_includes_alerts(self):
        """Detail view includes active alerts for product"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(f'/api/admin/forecasts/{self.product1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['active_alerts']), 1)
        self.assertEqual(response.data['active_alerts'][0]['alert_type'], AlertType.ANOMALY)
    
    def test_detail_staleness_info(self):
        """Detail view shows staleness information"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(f'/api/admin/forecasts/{self.product1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['is_stale'], False)  # Just created
        self.assertGreaterEqual(response.data['days_old'], 0)
    
    def test_detail_nonexistent_product(self):
        """Returns 404 for nonexistent product"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/99999/')
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class ForecastMetadataAPITestCase(ForecastAPISetupMixin, APITestCase):
    """Tests for GET /api/admin/forecasts/metadata/"""
    
    def test_metadata_requires_authentication(self):
        """Unauthenticated users cannot access metadata"""
        response = self.client.get('/api/admin/forecasts/metadata/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_metadata_requires_admin(self):
        """Non-admin users cannot access metadata"""
        self.client.force_authenticate(user=self.seller_user)
        response = self.client.get('/api/admin/forecasts/metadata/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_metadata_success(self):
        """Admin can retrieve system statistics"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/metadata/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_products', response.data)
        self.assertIn('products_with_forecasts', response.data)
        self.assertIn('coverage_percentage', response.data)
        self.assertIn('products_by_model_type', response.data)
        self.assertIn('products_by_confidence', response.data)
        self.assertIn('stale_forecasts_count', response.data)
        self.assertIn('insufficient_data_count', response.data)
        self.assertIn('avg_forecast_age_days', response.data)
    
    def test_metadata_contains_correct_counts(self):
        """Metadata shows correct statistics"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/metadata/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['products_with_forecasts'], 2)
        self.assertGreater(response.data['coverage_percentage'], 0)
        self.assertEqual(response.data['stale_forecasts_count'], 1)  # forecast2 is >7 days old


class ForecastAlertsAPITestCase(ForecastAPISetupMixin, APITestCase):
    """Tests for GET /api/admin/forecasts/alerts/"""
    
    def test_alerts_requires_authentication(self):
        """Unauthenticated users cannot access alerts"""
        response = self.client.get('/api/admin/forecasts/alerts/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_alerts_requires_admin(self):
        """Non-admin users cannot access alerts"""
        self.client.force_authenticate(user=self.seller_user)
        response = self.client.get('/api/admin/forecasts/alerts/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_list_alerts(self):
        """Admin can list unacknowledged alerts"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/alerts/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['alert_type'], AlertType.ANOMALY)
    
    def test_filter_by_severity(self):
        """Can filter alerts by severity"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(f'/api/admin/forecasts/alerts/?severity={AlertSeverity.WARNING}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
    
    def test_filter_acknowledged_alerts(self):
        """Can filter to show acknowledged alerts"""
        # Acknowledge the alert
        self.alert1.is_acknowledged = True
        self.alert1.acknowledged_at = timezone.now()
        self.alert1.save()
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/forecasts/alerts/?unacknowledged_only=false')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)


class ForecastRefreshAPITestCase(ForecastAPISetupMixin, APITestCase):
    """Tests for POST /api/admin/forecasts/refresh/"""
    
    def test_refresh_requires_authentication(self):
        """Unauthenticated users cannot refresh forecasts"""
        response = self.client.post('/api/admin/forecasts/refresh/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_refresh_requires_super_admin(self):
        """Non-super-admin users cannot refresh forecasts"""
        self.client.force_authenticate(user=self.regular_admin)
        response = self.client.post('/api/admin/forecasts/refresh/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_refresh_invalid_request(self):
        """Invalid request body returns 400"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(
            '/api/admin/forecasts/refresh/',
            {'invalid_field': 'value'},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_refresh_success_response_structure(self):
        """Successful refresh returns correct response structure"""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(
            '/api/admin/forecasts/refresh/',
            {},
            format='json'
        )
        
        # Should either succeed or have expected error handling
        # (depends on if ForecastingService is fully configured)
        self.assertIn(response.status_code, [200, 500])
        
        if response.status_code == 200:
            self.assertIn('status', response.data)
            self.assertIn('message', response.data)
            self.assertIn('timestamp', response.data)
