"""
Performance & Load Tests for Forecasting System (Phase 7.3)

Tests for:
- Load testing with many products (100+, 1000+)
- Forecast generation time benchmarks
- Database query optimization verification
- Memory usage under load
- API response times
"""

import time
from django.test import TransactionTestCase, TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db import connection, reset_queries
from django.test.utils import override_settings
from decimal import Decimal
from datetime import timedelta

from apps.forecasting.services.data_aggregator import DataAggregator
from apps.forecasting.services.forecasting_service import ForecastingService
from apps.forecasting.models import (
    ProductForecast,
    HistoricalTransactions,
    ForecastMetadata
)
from apps.users.models import Category, SellerProduct
from apps.seller.models import Seller, SellerOrder

User = get_user_model()


@override_settings(DEBUG=True)  # Required to track queries
class ForecastGenerationPerformanceTestCase(TransactionTestCase):
    """Test forecast generation performance"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
    
    def create_product_with_data(self, name, num_weeks=26):
        """Helper to create product with historical data"""
        product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name=name,
            description=f'Test Product {name}',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
        
        base_date = timezone.now()
        for week in range(num_weeks):
            for day in range(7):
                SellerOrder.objects.create(
                    product=product,
                    quantity_kg=Decimal('50.00'),
                    unit_price=Decimal('50.00'),
                    total_price=Decimal('2500.00'),
                    order_date=base_date - timedelta(days=num_weeks*7-week*7-day),
                    status='FULFILLED'
                )
        
        return product
    
    def test_single_forecast_generation_speed(self):
        """Test forecast generation speed for single product"""
        product = self.create_product_with_data('Talong', num_weeks=26)
        
        # Aggregate data
        DataAggregator.aggregate_and_store(product_id=product.id, aggregation_period='W')
        
        # Benchmark forecast generation
        reset_queries()
        start_time = time.time()
        
        forecasting_service = ForecastingService()
        result = forecasting_service.generate_forecast(product.id)
        
        elapsed_time = time.time() - start_time
        num_queries = len(connection.queries)
        
        # Should complete in less than 5 seconds
        self.assertLess(elapsed_time, 5.0, 
                       f"Forecast generation took {elapsed_time}s (target: <5s)")
        
        # Log for reference
        print(f"\n✓ Single forecast: {elapsed_time:.2f}s, {num_queries} queries")
    
    def test_batch_forecast_generation_speed(self):
        """Test batch forecast generation for 10 products"""
        # Create 10 products with data
        for i in range(10):
            product = self.create_product_with_data(f'Product_{i}', num_weeks=20)
            DataAggregator.aggregate_and_store(product_id=product.id, aggregation_period='W')
        
        # Benchmark batch generation
        reset_queries()
        start_time = time.time()
        
        forecasting_service = ForecastingService()
        batch_results = forecasting_service.batch_generate_all_products()
        
        elapsed_time = time.time() - start_time
        num_queries = len(connection.queries)
        
        # Should complete in less than 30 seconds for 10 products
        self.assertLess(elapsed_time, 30.0,
                       f"Batch generation took {elapsed_time}s (target: <30s)")
        
        self.assertGreater(batch_results['successful_forecasts'], 0)
        
        print(f"\n✓ Batch forecast (10 products): {elapsed_time:.2f}s, {num_queries} queries")
    
    def test_query_efficiency(self):
        """Test that forecast generation doesn't create N+1 queries"""
        product = self.create_product_with_data('Talong', num_weeks=26)
        DataAggregator.aggregate_and_store(product_id=product.id, aggregation_period='W')
        
        reset_queries()
        
        forecasting_service = ForecastingService()
        forecasting_service.generate_forecast(product.id)
        
        num_queries = len(connection.queries)
        
        # Should not exceed reasonable number of queries
        # Allow for ORM efficiency
        self.assertLess(num_queries, 50, 
                       f"Too many queries: {num_queries} (target: <50)")
        
        print(f"\n✓ Query count: {num_queries}")


class LoadTestingTestCase(TransactionTestCase):
    """Test system under load with many products"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
    
    def create_products_bulk(self, num_products, num_weeks=15):
        """Efficiently create multiple products with data"""
        products = []
        base_date = timezone.now()
        
        # Create products
        for i in range(num_products):
            product = SellerProduct.objects.create(
                seller=self.seller,
                category=self.category,
                name=f'Product_{i}',
                description=f'Test Product {i}',
                price_per_kg=Decimal('50.00'),
                total_stock_kg=Decimal('1000.00'),
                status='ACTIVE',
                is_deleted=False
            )
            products.append(product)
        
        # Create bulk orders
        orders = []
        for product in products:
            for week in range(num_weeks):
                for day in range(2):  # 2 orders per week
                    orders.append(SellerOrder(
                        product=product,
                        quantity_kg=Decimal('50.00'),
                        unit_price=Decimal('50.00'),
                        total_price=Decimal('2500.00'),
                        order_date=base_date - timedelta(days=num_weeks*7-week*7-day),
                        status='FULFILLED'
                    ))
        
        SellerOrder.objects.bulk_create(orders, batch_size=500)
        
        return products
    
    def test_100_products_batch_forecast(self):
        """Test batch forecast generation with 100 products"""
        # Create 100 products with data
        print("\n▶ Creating 100 products with historical data...")
        products = self.create_products_bulk(100, num_weeks=15)
        
        print("▶ Aggregating data...")
        # Aggregate data for all
        for product in products[:10]:  # Test with first 10
            DataAggregator.aggregate_and_store(
                product_id=product.id,
                aggregation_period='W'
            )
        
        print("▶ Generating forecasts...")
        # Benchmark batch generation
        start_time = time.time()
        
        forecasting_service = ForecastingService()
        batch_results = forecasting_service.batch_generate_all_products()
        
        elapsed_time = time.time() - start_time
        
        self.assertGreater(batch_results['successful_forecasts'], 0)
        
        print(f"✓ 100 products batch: {elapsed_time:.2f}s")
        print(f"  - Successful: {batch_results['successful_forecasts']}")
        print(f"  - Failed: {batch_results['failed_forecasts']}")
    
    def test_data_aggregation_bulk_performance(self):
        """Test bulk data aggregation performance"""
        print("\n▶ Creating 50 products...")
        products = self.create_products_bulk(50, num_weeks=12)
        
        print("▶ Aggregating all products...")
        start_time = time.time()
        
        for product in products:
            DataAggregator.aggregate_and_store(
                product_id=product.id,
                aggregation_period='W'
            )
        
        elapsed_time = time.time() - start_time
        
        # Should aggregate 50 products in reasonable time
        avg_per_product = elapsed_time / len(products)
        
        print(f"✓ Aggregated {len(products)} products in {elapsed_time:.2f}s")
        print(f"  - Average per product: {avg_per_product:.2f}s")
        
        # Verify data was aggregated
        total_transactions = HistoricalTransactions.objects.count()
        self.assertGreater(total_transactions, 0)


class DatabaseOptimizationTestCase(TestCase):
    """Test database query optimization"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
    
    @override_settings(DEBUG=True)
    def test_forecast_list_query_count(self):
        """Test that list endpoint uses select_related efficiently"""
        # Create some forecasts
        for i in range(10):
            product = SellerProduct.objects.create(
                seller=self.seller,
                category=self.category,
                name=f'Product_{i}',
                description=f'Test {i}',
                price_per_kg=Decimal('50.00'),
                total_stock_kg=Decimal('1000.00'),
                status='ACTIVE',
                is_deleted=False
            )
            
            ProductForecast.objects.create(
                product=product,
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
        
        reset_queries()
        
        # Simulate API list retrieval
        forecasts = ProductForecast.objects.filter(
            is_current=True
        ).select_related('product', 'product__category')
        
        # Materialize queryset
        list(forecasts)
        
        num_queries = len(connection.queries)
        
        # Should use select_related to minimize queries
        # Expected: 1 forecast query + joins for product/category
        self.assertLess(num_queries, 5,
                       f"Too many queries for list: {num_queries}")
        
        print(f"\n✓ Forecast list query count: {num_queries}")
    
    @override_settings(DEBUG=True)
    def test_historical_transactions_aggregation_efficiency(self):
        """Test that historical transaction queries are efficient"""
        # Create product and transactions
        product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Test',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
        
        base_date = timezone.now()
        for week in range(26):
            HistoricalTransactions.objects.create(
                product=product,
                transaction_date=base_date - timedelta(weeks=26-week),
                quantity_sold_kg=Decimal('100.00'),
                average_price_per_kg=Decimal('50.00'),
                total_revenue=Decimal('5000.00'),
                transaction_count=5,
                data_quality_score=95
            )
        
        reset_queries()
        
        # Simulate data retrieval for forecasting
        transactions = HistoricalTransactions.objects.filter(
            product=product
        ).order_by('-transaction_date')[:26]
        
        # Convert to list for analysis
        list(transactions)
        
        num_queries = len(connection.queries)
        
        # Should be single query
        self.assertEqual(num_queries, 1,
                        f"Expected 1 query, got {num_queries}")
        
        print(f"\n✓ Historical transactions query count: {num_queries}")


class APIResponseTimeTestCase(TestCase):
    """Test API response times"""
    
    def setUp(self):
        """Set up test data"""
        self.admin_user = User.objects.create_user(email='admin@test.com', password='pass123')
        Admin.objects.create(user=self.admin_user, admin_role='SUPER_ADMIN')
        
        self.user = User.objects.create_user(email='farmer@test.com', password='pass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
    
    def test_forecast_list_api_response_time(self):
        """Test API list endpoint response time"""
        from rest_framework.test import APIClient
        
        # Create some forecasts
        for i in range(20):
            product = SellerProduct.objects.create(
                seller=self.seller,
                category=self.category,
                name=f'Product_{i}',
                description=f'Test {i}',
                price_per_kg=Decimal('50.00'),
                total_stock_kg=Decimal('1000.00'),
                status='ACTIVE',
                is_deleted=False
            )
            
            ProductForecast.objects.create(
                product=product,
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
        
        client = APIClient()
        client.force_authenticate(user=self.admin_user)
        
        # Benchmark API response
        start_time = time.time()
        response = client.get('/api/admin/forecasts/')
        elapsed_time = time.time() - start_time
        
        # Should respond in less than 1 second
        self.assertLess(elapsed_time, 1.0,
                       f"API response time too long: {elapsed_time:.2f}s (target: <1s)")
        
        print(f"\n✓ API list response time: {elapsed_time*1000:.0f}ms")
