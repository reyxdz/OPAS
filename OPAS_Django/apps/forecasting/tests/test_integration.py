"""
Integration Tests for Forecasting Pipeline (Phase 7.2)

Tests for full end-to-end forecasting pipeline including:
- Data aggregation → Model selection → Forecast generation → Storage → API retrieval
- Celery task execution
- API responses with various product scenarios
"""

from django.test import TestCase, TransactionTestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from decimal import Decimal
from datetime import timedelta
import json

from rest_framework.test import APITestCase
from rest_framework import status

from apps.forecasting.services.data_aggregator import DataAggregator
from apps.forecasting.services.forecasting_service import ForecastingService
from apps.forecasting.services.model_selector import ModelSelector
from apps.forecasting.models import (
    ProductForecast,
    ForecastMetadata,
    HistoricalTransactions,
    ForecastAlert
)
from apps.forecasting.tasks import (
    refresh_all_forecasts,
    aggregate_recent_transactions_phase6,
    check_forecast_alerts_phase6
)
from apps.users.models import Category, SellerProduct, Admin
from apps.seller.models import Seller, SellerOrder

User = get_user_model()


class ForecastingPipelineIntegrationTestCase(TransactionTestCase):
    """Test full forecasting pipeline from data to API"""
    
    def setUp(self):
        """Set up test data"""
        # Create user, seller, category, product
        self.user = User.objects.create_user(
            email='farmer@test.com',
            password='testpass123'
        )
        self.seller = Seller.objects.create(
            user=self.user,
            seller_type='FARMER'
        )
        self.category = Category.objects.create(
            name='Vegetables',
            description='Test'
        )
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Eggplant',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
    
    def test_complete_forecasting_pipeline(self):
        """Test complete pipeline: orders → aggregation → forecast → storage"""
        # Step 1: Create historical orders
        base_date = timezone.now()
        for week in range(30):  # 30 weeks of data
            for day in range(7):
                order_date = base_date - timedelta(days=210-week*7-day)
                SellerOrder.objects.create(
                    product=self.product,
                    quantity_kg=Decimal('50.00'),
                    unit_price=Decimal('50.00'),
                    total_price=Decimal('2500.00'),
                    order_date=order_date,
                    status='FULFILLED'
                )
        
        # Step 2: Aggregate data
        records_created, quality_score = DataAggregator.aggregate_and_store(
            product_id=self.product.id,
            aggregation_period='W'
        )
        
        self.assertGreater(records_created, 0)
        self.assertGreater(quality_score, 0)
        
        # Step 3: Verify historical transactions were created
        hist_txns = HistoricalTransactions.objects.filter(product=self.product)
        self.assertGreater(hist_txns.count(), 0)
        
        # Step 4: Select model and generate forecast
        forecasting_service = ForecastingService()
        forecast_result = forecasting_service.generate_forecast(
            product_id=self.product.id,
            forecast_steps=4,
            forecast_period='W'
        )
        
        self.assertIsNotNone(forecast_result)
        self.assertTrue(forecast_result['success'])
        
        # Step 5: Verify forecast was stored
        forecasts = ProductForecast.objects.filter(
            product=self.product,
            is_current=True
        )
        self.assertEqual(forecasts.count(), 1)
        
        forecast = forecasts.first()
        self.assertGreater(forecast.demand_forecast_kg, 0)
        self.assertGreater(forecast.price_forecast, 0)
        self.assertIn(forecast.confidence_level, ['HIGH', 'MEDIUM', 'LOW'])
        self.assertIn(forecast.model_type, ['SARIMA', 'ARIMA', 'SIMPLE'])
        
        # Step 6: Verify metadata was created
        metadata = ForecastMetadata.objects.filter(product=self.product)
        self.assertEqual(metadata.count(), 1)
        self.assertGreater(metadata.first().data_points_count, 0)


class MultiProductForecastingIntegrationTestCase(TransactionTestCase):
    """Test forecasting with multiple products of varying data quality"""
    
    def setUp(self):
        """Set up test data with multiple products"""
        # Create seller and category
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
        
        # Create products with different data patterns
        self.products = {}
        
        # Product 1: Sufficient data (SARIMA eligible)
        self.products['sufficient'] = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Eggplant',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
        
        # Product 2: Moderate data (ARIMA eligible)
        self.products['moderate'] = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Tomato',
            description='Tomato',
            price_per_kg=Decimal('40.00'),
            total_stock_kg=Decimal('800.00'),
            status='ACTIVE',
            is_deleted=False
        )
        
        # Product 3: Sparse data (SIMPLE eligible)
        self.products['sparse'] = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Pepper',
            description='Pepper',
            price_per_kg=Decimal('60.00'),
            total_stock_kg=Decimal('500.00'),
            status='ACTIVE',
            is_deleted=False
        )
    
    def test_batch_generate_all_products(self):
        """Test batch generation with multiple products"""
        base_date = timezone.now()
        
        # Create different amounts of data for each product
        # Sufficient data: 30 weeks
        for week in range(30):
            for day in [0]:  # One order per week
                SellerOrder.objects.create(
                    product=self.products['sufficient'],
                    quantity_kg=Decimal('50.00'),
                    unit_price=Decimal('50.00'),
                    total_price=Decimal('2500.00'),
                    order_date=base_date - timedelta(days=210-week*7-day),
                    status='FULFILLED'
                )
        
        # Moderate data: 15 weeks
        for week in range(15):
            SellerOrder.objects.create(
                product=self.products['moderate'],
                quantity_kg=Decimal('40.00'),
                unit_price=Decimal('40.00'),
                total_price=Decimal('1600.00'),
                order_date=base_date - timedelta(days=105-week*7),
                status='FULFILLED'
            )
        
        # Sparse data: 5 weeks
        for week in range(5):
            SellerOrder.objects.create(
                product=self.products['sparse'],
                quantity_kg=Decimal('30.00'),
                unit_price=Decimal('60.00'),
                total_price=Decimal('1800.00'),
                order_date=base_date - timedelta(days=35-week*7),
                status='FULFILLED'
            )
        
        # Aggregate for all products
        for product in self.products.values():
            DataAggregator.aggregate_and_store(
                product_id=product.id,
                aggregation_period='W'
            )
        
        # Batch generate forecasts
        forecasting_service = ForecastingService()
        batch_results = forecasting_service.batch_generate_all_products()
        
        self.assertGreater(batch_results['successful_forecasts'], 0)
        
        # Verify appropriate models were selected
        sufficient_forecast = ProductForecast.objects.filter(
            product=self.products['sufficient'],
            is_current=True
        ).first()
        
        # Should use SARIMA or ARIMA for sufficient data
        if sufficient_forecast:
            self.assertIn(sufficient_forecast.model_type, ['SARIMA', 'ARIMA'])


class CeleryTaskIntegrationTestCase(TransactionTestCase):
    """Test Celery task execution in forecasting pipeline"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Eggplant',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
    
    def test_aggregate_recent_transactions_task(self):
        """Test aggregate_recent_transactions_phase6 task"""
        base_date = timezone.now()
        
        # Create orders from last 24 hours
        for i in range(5):
            SellerOrder.objects.create(
                product=self.product,
                quantity_kg=Decimal('50.00'),
                unit_price=Decimal('50.00'),
                total_price=Decimal('2500.00'),
                order_date=base_date - timedelta(hours=i),
                status='FULFILLED'
            )
        
        # Execute task
        result = aggregate_recent_transactions_phase6()
        
        self.assertEqual(result['status'], 'success')
        self.assertGreater(result['products_updated'], 0)
        self.assertGreater(result['records_created'], 0)
    
    def test_check_forecast_alerts_task(self):
        """Test check_forecast_alerts_phase6 task"""
        # Create forecast and historical data
        base_date = timezone.now()
        
        # Create orders
        for week in range(20):
            SellerOrder.objects.create(
                product=self.product,
                quantity_kg=Decimal('100.00'),
                unit_price=Decimal('50.00'),
                total_price=Decimal('5000.00'),
                order_date=base_date - timedelta(days=140-week*7),
                status='FULFILLED'
            )
        
        # Aggregate data
        DataAggregator.aggregate_and_store(
            product_id=self.product.id,
            aggregation_period='W'
        )
        
        # Generate forecast
        forecasting_service = ForecastingService()
        forecasting_service.generate_forecast(self.product.id)
        
        # Execute alert checking task
        result = check_forecast_alerts_phase6()
        
        self.assertEqual(result['status'], 'success')
        self.assertGreaterEqual(result['total_products_checked'], 0)
    
    def test_refresh_all_forecasts_task(self):
        """Test refresh_all_forecasts task"""
        # Create data
        base_date = timezone.now()
        for week in range(25):
            SellerOrder.objects.create(
                product=self.product,
                quantity_kg=Decimal('80.00'),
                unit_price=Decimal('50.00'),
                total_price=Decimal('4000.00'),
                order_date=base_date - timedelta(days=175-week*7),
                status='FULFILLED'
            )
        
        # Aggregate
        DataAggregator.aggregate_and_store(
            product_id=self.product.id,
            aggregation_period='W'
        )
        
        # Execute refresh task
        result = refresh_all_forecasts()
        
        self.assertEqual(result['status'], 'success')
        self.assertGreater(result['total_products'], 0)


class APIForecastRetrievalIntegrationTestCase(APITestCase):
    """Test API retrieval of forecasts"""
    
    def setUp(self):
        """Set up test data and admin user"""
        # Create admin
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123'
        )
        Admin.objects.create(
            user=self.admin_user,
            admin_role='SUPER_ADMIN'
        )
        
        # Create seller and product
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Eggplant',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
        
        # Create forecast
        self.forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_date=timezone.now(),
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('250.00'),
            demand_lower_bound=Decimal('235.00'),
            demand_upper_bound=Decimal('265.00'),
            price_forecast=Decimal('50.00'),
            price_lower_bound=Decimal('45.00'),
            price_upper_bound=Decimal('55.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            rmse_demand=Decimal('15.00'),
            rmse_price=Decimal('3.00'),
            is_current=True
        )
    
    def test_get_all_forecasts_api(self):
        """Test retrieving all forecasts via API"""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/forecasts/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
    
    def test_get_forecast_detail_api(self):
        """Test retrieving specific forecast via API"""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get(f'/api/admin/forecasts/{self.product.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['product_id'], self.product.id)
    
    def test_forecast_serialization(self):
        """Test forecast data serialization in API response"""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get(f'/api/admin/forecasts/{self.product.id}/')
        
        self.assertIn('demand_forecast_kg', response.data)
        self.assertIn('price_forecast', response.data)
        self.assertIn('confidence_level', response.data)
        self.assertIn('model_type', response.data)
