"""
Unit Tests for Data Aggregator Service (Phase 7.1)

Tests for data collection, aggregation to different time periods,
data quality validation, and anomaly detection.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from decimal import Decimal
from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model

from apps.forecasting.services.data_aggregator import DataAggregator
from apps.forecasting.models import HistoricalTransactions
from apps.users.models import Category, SellerProduct
from apps.seller.models import SellerOrder, Seller

User = get_user_model()


class DataAggregatorCollectionTestCase(TestCase):
    """Test data collection from SellerOrder"""
    
    def setUp(self):
        """Set up test data"""
        # Create test user and seller
        self.user = User.objects.create_user(
            email='farmer@test.com',
            password='testpass123',
            first_name='Test',
            last_name='Farmer'
        )
        
        self.seller = Seller.objects.create(
            user=self.user,
            seller_type='FARMER'
        )
        
        # Create category
        self.category = Category.objects.create(
            name='Vegetables',
            description='Test Category'
        )
        
        # Create product
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Test Product',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            is_deleted=False,
            status='ACTIVE'
        )
    
    def test_collect_product_transactions_empty(self):
        """Test collecting transactions for product with no orders"""
        df = DataAggregator.collect_product_transactions(self.product.id)
        
        self.assertIsInstance(df, pd.DataFrame)
        self.assertTrue(df.empty)
    
    def test_collect_product_transactions_with_orders(self):
        """Test collecting transactions with fulfilled orders"""
        # Create sample orders
        base_date = timezone.now()
        
        for i in range(5):
            order_date = base_date - timedelta(days=30-i)
            order = SellerOrder.objects.create(
                product=self.product,
                quantity_kg=Decimal('50.00'),
                unit_price=Decimal('50.00'),
                total_price=Decimal('2500.00'),
                order_date=order_date,
                status='FULFILLED'
            )
        
        # Collect transactions
        df = DataAggregator.collect_product_transactions(self.product.id)
        
        self.assertEqual(len(df), 5)
        self.assertIn('quantity_kg', df.columns)
        self.assertIn('price_per_kg', df.columns)
        self.assertEqual(df['quantity_kg'].sum(), 250)
    
    def test_collect_excludes_incomplete_orders(self):
        """Test that only FULFILLED/DELIVERED orders are included"""
        base_date = timezone.now()
        
        # Create fulfilled order
        SellerOrder.objects.create(
            product=self.product,
            quantity_kg=Decimal('50.00'),
            unit_price=Decimal('50.00'),
            total_price=Decimal('2500.00'),
            order_date=base_date,
            status='FULFILLED'
        )
        
        # Create pending order
        SellerOrder.objects.create(
            product=self.product,
            quantity_kg=Decimal('100.00'),
            unit_price=Decimal('50.00'),
            total_price=Decimal('5000.00'),
            order_date=base_date,
            status='PENDING'
        )
        
        df = DataAggregator.collect_product_transactions(self.product.id)
        
        # Should only include fulfilled order
        self.assertEqual(len(df), 1)
        self.assertEqual(df['quantity_kg'].sum(), 50)


class DataAggregatorAggregationTestCase(TestCase):
    """Test data aggregation to different time periods"""
    
    def setUp(self):
        """Set up test data"""
        # Create sample time series
        dates = pd.date_range(start='2025-01-01', periods=52, freq='W')
        self.df = pd.DataFrame({
            'quantity_kg': np.random.normal(100, 20, 52),
            'price_per_kg': np.random.normal(50, 5, 52),
        }, index=dates)
    
    def test_aggregate_to_weekly(self):
        """Test weekly aggregation"""
        weekly = DataAggregator.aggregate_to_weekly(self.df.copy())
        
        self.assertIsInstance(weekly, pd.DataFrame)
        self.assertLessEqual(len(weekly), len(self.df))
        self.assertIn('quantity_kg', weekly.columns)
        self.assertEqual(weekly['quantity_kg'].sum(), 
                        self.df['quantity_kg'].sum())
    
    def test_aggregate_to_monthly(self):
        """Test monthly aggregation"""
        monthly = DataAggregator.aggregate_to_monthly(self.df.copy())
        
        self.assertIsInstance(monthly, pd.DataFrame)
        # 52 weeks ≈ 12 months
        self.assertLessEqual(len(monthly), 13)
        self.assertIn('quantity_kg', monthly.columns)
        # Sum should be approximately equal
        self.assertAlmostEqual(
            monthly['quantity_kg'].sum(),
            self.df['quantity_kg'].sum(),
            delta=1.0
        )
    
    def test_aggregation_preserves_direction(self):
        """Test that aggregation preserves trend direction"""
        # Create strictly increasing data
        increasing_df = pd.DataFrame({
            'quantity_kg': np.linspace(100, 200, 52),
            'price_per_kg': np.linspace(40, 60, 52),
        }, index=pd.date_range(start='2025-01-01', periods=52, freq='W'))
        
        monthly = DataAggregator.aggregate_to_monthly(increasing_df)
        
        # Check that trend is preserved
        first_qty = monthly['quantity_kg'].iloc[0]
        last_qty = monthly['quantity_kg'].iloc[-1]
        self.assertLess(first_qty, last_qty)


class DataAggregatorValidationTestCase(TestCase):
    """Test data quality validation"""
    
    def test_validate_good_quality_data(self):
        """Test validation of high-quality data"""
        # Create complete data with no gaps
        df = pd.DataFrame({
            'quantity_kg': np.random.normal(100, 10, 26),
            'price_per_kg': np.random.normal(50, 3, 26),
        }, index=pd.date_range(start='2025-01-01', periods=26, freq='W'))
        
        quality_score = DataAggregator.validate_data_quality(df)
        
        self.assertGreaterEqual(quality_score, 90)
        self.assertLessEqual(quality_score, 100)
    
    def test_validate_sparse_data(self):
        """Test validation of sparse data"""
        # Create data with many gaps
        df = pd.DataFrame({
            'quantity_kg': [100, None, 105, None, None, 110],
            'price_per_kg': [50, None, 51, None, None, 52],
        })
        
        quality_score = DataAggregator.validate_data_quality(df)
        
        # Should have lower quality score due to gaps
        self.assertLess(quality_score, 90)
    
    def test_validate_insufficient_data_points(self):
        """Test validation rejects data with too few points"""
        # Only 3 data points (minimum is 5)
        df = pd.DataFrame({
            'quantity_kg': [100, 105, 102],
            'price_per_kg': [50, 51, 50],
        })
        
        quality_score = DataAggregator.validate_data_quality(df)
        
        # Should be marked as unreliable
        self.assertLess(quality_score, 50)
    
    def test_validate_outlier_detection(self):
        """Test that outliers affect quality score"""
        # Create data with outliers
        normal_data = np.random.normal(100, 5, 25)
        with_outlier = np.append(normal_data, 500)  # Extreme outlier
        
        df = pd.DataFrame({
            'quantity_kg': with_outlier,
            'price_per_kg': np.random.normal(50, 2, 26),
        })
        
        quality_score = DataAggregator.validate_data_quality(df)
        
        # Quality should be reduced due to outlier
        self.assertLess(quality_score, 90)


class DataAggregatorAnomalyDetectionTestCase(TestCase):
    """Test anomaly detection in sales data"""
    
    def test_detect_anomalies_in_quantity(self):
        """Test detecting unusual quantity anomalies"""
        # Create baseline data with sudden spike
        baseline = [100] * 10 + [500] + [100] * 5  # Spike on day 11
        
        df = pd.DataFrame({
            'quantity_kg': baseline,
            'price_per_kg': [50] * 16,
        }, index=pd.date_range(start='2025-01-01', periods=16, freq='D'))
        
        anomalies = DataAggregator.detect_anomalies(df)
        
        self.assertGreater(len(anomalies), 0)
        # Should detect the spike
        anomaly_types = [a['type'] for a in anomalies]
        self.assertIn('quantity_spike', anomaly_types)
    
    def test_detect_anomalies_in_price(self):
        """Test detecting unusual price anomalies"""
        # Create data with price drop
        baseline = [50] * 10 + [20] + [50] * 5  # Price drop on day 11
        
        df = pd.DataFrame({
            'quantity_kg': [100] * 16,
            'price_per_kg': baseline,
        }, index=pd.date_range(start='2025-01-01', periods=16, freq='D'))
        
        anomalies = DataAggregator.detect_anomalies(df)
        
        self.assertGreater(len(anomalies), 0)
        anomaly_types = [a['type'] for a in anomalies]
        self.assertIn('price_drop', anomaly_types)
    
    def test_no_anomalies_in_normal_data(self):
        """Test that normal data has no anomalies"""
        # Create normal, stable data
        df = pd.DataFrame({
            'quantity_kg': np.random.normal(100, 5, 30),
            'price_per_kg': np.random.normal(50, 2, 30),
        }, index=pd.date_range(start='2025-01-01', periods=30, freq='D'))
        
        anomalies = DataAggregator.detect_anomalies(df)
        
        # Should detect very few or no anomalies
        self.assertLessEqual(len(anomalies), 2)


class DataAggregatorStorageTestCase(TestCase):
    """Test aggregation and storage workflow"""
    
    def setUp(self):
        """Set up test data"""
        # Create test user, seller, category, and product
        self.user = User.objects.create_user(
            email='farmer@test.com',
            password='testpass123'
        )
        
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        
        self.category = Category.objects.create(
            name='Vegetables',
            description='Test'
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Test',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
    
    def test_aggregate_and_store(self):
        """Test complete aggregation and storage workflow"""
        # Create sample orders
        base_date = timezone.now()
        for i in range(10):
            SellerOrder.objects.create(
                product=self.product,
                quantity_kg=Decimal('50.00'),
                unit_price=Decimal('50.00'),
                total_price=Decimal('2500.00'),
                order_date=base_date - timedelta(days=30-i),
                status='FULFILLED'
            )
        
        # Aggregate and store
        records_created, quality_score = DataAggregator.aggregate_and_store(
            product_id=self.product.id,
            aggregation_period='W'
        )
        
        self.assertGreater(records_created, 0)
        self.assertGreater(quality_score, 0)
        
        # Check that records were stored
        stored_records = HistoricalTransactions.objects.filter(
            product=self.product
        )
        self.assertEqual(stored_records.count(), records_created)


class DataAggregatorCoverageTestCase(TestCase):
    """Test data coverage statistics"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(email='farmer@test.com', password='testpass123')
        self.seller = Seller.objects.create(user=self.user, seller_type='FARMER')
        self.category = Category.objects.create(name='Vegetables', description='Test')
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            category=self.category,
            name='Talong',
            description='Test',
            price_per_kg=Decimal('50.00'),
            total_stock_kg=Decimal('1000.00'),
            status='ACTIVE',
            is_deleted=False
        )
    
    def test_get_data_coverage_stats(self):
        """Test data coverage statistics calculation"""
        # Create historical data for 12 months
        base_date = timezone.now()
        for month in range(12):
            for week in range(4):
                HistoricalTransactions.objects.create(
                    product=self.product,
                    transaction_date=base_date - timedelta(days=30*month + 7*week),
                    quantity_sold_kg=Decimal('100.00'),
                    average_price_per_kg=Decimal('50.00'),
                    total_revenue=Decimal('5000.00'),
                    transaction_count=5,
                    data_quality_score=95
                )
        
        stats = DataAggregator.get_data_coverage_stats(self.product.id)
        
        self.assertGreater(stats['total_periods'], 0)
        self.assertGreater(stats['coverage_percentage'], 80)
        self.assertEqual(stats['product_id'], self.product.id)
