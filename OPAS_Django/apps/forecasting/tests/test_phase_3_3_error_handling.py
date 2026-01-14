"""
Tests for Phase 3.3: Error Handling & Robustness

Tests for:
- Data validation with outlier detection and NaN handling
- Stale forecast detection and alerting
- Graceful fallback to previous forecasts on model training failure
"""

import logging
from decimal import Decimal
from datetime import datetime, timedelta
from django.test import TestCase
from django.utils import timezone

import pandas as pd
import numpy as np

from apps.users.models import User
from apps.forecasting.models import (
    ProductForecast,
    ForecastMetadata,
    HistoricalTransactions,
    ForecastAlert,
    AlertType,
    AlertSeverity,
    ModelType,
)
from apps.users.seller_models import SellerProduct, ProductCategory
from apps.forecasting.services import (
    DataValidator,
    StaleForecastManager,
    ForecastFallbackManager,
    ForecastingService,
)

logger = logging.getLogger(__name__)


class DataValidatorTestCase(TestCase):
    """Tests for DataValidator service"""
    
    def test_validate_clean_dataframe(self):
        """Test validation of clean, valid data"""
        df = pd.DataFrame({
            'quantity_kg': [10.0, 15.0, 12.0, 18.0, 20.0, 16.0],
            'average_price': [50.0, 52.0, 48.0, 55.0, 60.0, 51.0]
        })
        
        df_clean, report = DataValidator.validate_dataframe(df)
        
        self.assertTrue(report['is_valid'])
        self.assertEqual(report['rows_before'], 6)
        self.assertEqual(report['rows_after'], 6)
        self.assertEqual(report['null_count'], 0)
        self.assertGreater(report['quality_score'], 80)
    
    def test_validate_dataframe_with_nan(self):
        """Test handling of NaN values"""
        df = pd.DataFrame({
            'quantity_kg': [10.0, np.nan, 12.0, 18.0, 20.0, 16.0],
            'average_price': [50.0, 52.0, np.nan, 55.0, 60.0, 51.0]
        })
        
        df_clean, report = DataValidator.validate_dataframe(df)
        
        # Should have some NaN removed (2 out of 12 values = 16.7%, which is < 40%)
        self.assertEqual(report['null_count'], 2)
        self.assertGreater(report['rows_before'], report['rows_after'])
        self.assertGreater(report['rows_after'], 0)  # Should have remaining data
    
    def test_validate_dataframe_too_many_nan(self):
        """Test rejection when too many NaN values"""
        df = pd.DataFrame({
            'quantity_kg': [10.0, np.nan, np.nan, np.nan, 20.0, 16.0],
            'average_price': [50.0, np.nan, np.nan, np.nan, 60.0, 51.0]
        })
        
        df_clean, report = DataValidator.validate_dataframe(df)
        
        # Should fail due to excessive NaN
        self.assertFalse(report['is_valid'])
        self.assertIn('too high', str(report['issues']).lower())
    
    def test_validate_dataframe_insufficient_data(self):
        """Test rejection with insufficient data points"""
        df = pd.DataFrame({
            'quantity_kg': [10.0, 15.0],
            'average_price': [50.0, 52.0]
        })
        
        df_clean, report = DataValidator.validate_dataframe(df)
        
        self.assertFalse(report['is_valid'])
        self.assertIn('Insufficient data', str(report['issues']))
    
    def test_detect_outliers(self):
        """Test outlier detection using IQR method"""
        series = pd.Series([10, 12, 11, 13, 12, 11, 100])  # 100 is outlier
        
        outliers = DataValidator.detect_and_flag_outliers(series)
        
        self.assertGreater(len(outliers), 0)
        # Outlier index should be identified
        self.assertIn(6, outliers)  # Index 6 is the value 100
    
    def test_check_data_consistency(self):
        """Test data consistency checks"""
        dates = pd.date_range('2025-01-01', periods=5, freq='D')
        df = pd.DataFrame({
            'transaction_date': dates,
            'quantity_kg': [10, 12, 11, 13, 12],
            'average_price': [50, 52, 48, 55, 60]
        })
        
        consistency = DataValidator.check_data_consistency(df)
        
        self.assertTrue(consistency['is_consistent'])
        self.assertEqual(consistency['duplicate_dates'], 0)
    
    def test_check_data_consistency_duplicates(self):
        """Test detection of duplicate dates"""
        df = pd.DataFrame({
            'transaction_date': [
                pd.Timestamp('2025-01-01'),
                pd.Timestamp('2025-01-02'),
                pd.Timestamp('2025-01-02'),  # Duplicate
                pd.Timestamp('2025-01-03'),
            ],
            'quantity_kg': [10, 12, 15, 13],
            'average_price': [50, 52, 51, 55]
        })
        
        consistency = DataValidator.check_data_consistency(df)
        
        self.assertFalse(consistency['is_consistent'])
        self.assertEqual(consistency['duplicate_dates'], 1)


class StaleForecastManagerTestCase(TestCase):
    """Tests for StaleForecastManager service"""
    
    def setUp(self):
        """Set up test data"""
        self.seller = User.objects.create_user(
            username='seller1',
            email='seller1@test.com',
            password='test123'
        )
        
        self.category = ProductCategory.objects.create(
            name='Vegetables'
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Test Product',
            category=self.category,
            price=Decimal('100.00'),
            stock_level=50
        )
    
    def test_is_forecast_not_stale(self):
        """Test that recent forecast is not marked as stale"""
        forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('120.00'),
            price_lower_bound=Decimal('110.00'),
            price_upper_bound=Decimal('130.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True,
            forecast_date=timezone.now()
        )
        
        is_stale = StaleForecastManager.is_forecast_stale(forecast)
        
        self.assertFalse(is_stale)
    
    def test_is_forecast_stale(self):
        """Test that old forecast is marked as stale"""
        old_date = timezone.now() - timedelta(days=10)
        
        forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('120.00'),
            price_lower_bound=Decimal('110.00'),
            price_upper_bound=Decimal('130.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True,
            forecast_date=old_date
        )
        
        is_stale = StaleForecastManager.is_forecast_stale(forecast)
        
        self.assertTrue(is_stale)
    
    def test_get_staleness_info(self):
        """Test staleness information generation"""
        old_date = timezone.now() - timedelta(days=10)
        
        forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('120.00'),
            price_lower_bound=Decimal('110.00'),
            price_upper_bound=Decimal('130.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True,
            forecast_date=old_date
        )
        
        info = StaleForecastManager.get_staleness_info(forecast)
        
        self.assertTrue(info['is_stale'])
        self.assertTrue(info['needs_refresh'])
        self.assertGreater(info['days_old'], 7)
        self.assertEqual(info['severity'], 'warning')
    
    def test_mark_stale_forecasts(self):
        """Test marking of stale forecasts and alert creation"""
        old_date = timezone.now() - timedelta(days=10)
        
        forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('120.00'),
            price_lower_bound=Decimal('110.00'),
            price_upper_bound=Decimal('130.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True,
            forecast_date=old_date
        )
        
        result = StaleForecastManager.mark_stale_forecasts()
        
        self.assertEqual(result['stale_count'], 1)
        self.assertGreater(result['alerts_created'], 0)
        
        # Check that alert was created
        alerts = ForecastAlert.objects.filter(
            product=self.product,
            alert_type=AlertType.ANOMALY
        )
        self.assertGreater(alerts.count(), 0)
    
    def test_get_stale_forecast_report(self):
        """Test complete stale forecast report generation"""
        # Create one fresh and one stale forecast
        fresh_date = timezone.now()
        old_date = timezone.now() - timedelta(days=15)
        
        fresh_forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('120.00'),
            price_lower_bound=Decimal('110.00'),
            price_upper_bound=Decimal('130.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True,
            forecast_date=fresh_date
        )
        
        report = StaleForecastManager.get_stale_forecast_report()
        
        self.assertGreater(report['total_forecasts'], 0)
        self.assertIn('by_severity', report)
        self.assertIn('recommendations', report)


class ForecastFallbackManagerTestCase(TestCase):
    """Tests for ForecastFallbackManager service"""
    
    def setUp(self):
        """Set up test data"""
        self.seller = User.objects.create_user(
            username='seller1',
            email='seller1@test.com',
            password='test123'
        )
        
        self.category = ProductCategory.objects.create(
            name='Vegetables'
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Test Product',
            category=self.category,
            price=Decimal('100.00'),
            stock_level=50
        )
    
    def test_save_forecast_atomically_success(self):
        """Test successful atomic save of new forecast"""
        forecast_data = {
            'demand_forecast_kg': 100.0,
            'demand_lower_bound': 90.0,
            'demand_upper_bound': 110.0,
            'price_forecast': 120.0,
            'price_lower_bound': 110.0,
            'price_upper_bound': 130.0,
            'confidence_level': 'HIGH',
            'forecast_period': '2025-01',
            'rmse_demand': 5.0,
            'rmse_price': 3.0,
            'mape_demand': 5.0,
            'mape_price': 3.0,
        }
        
        success, forecast, message = ForecastFallbackManager.save_forecast_atomically(
            product=self.product,
            new_forecast_data=forecast_data,
            model_type='SARIMA'
        )
        
        self.assertTrue(success)
        self.assertIsNotNone(forecast)
        self.assertEqual(forecast.model_type, 'SARIMA')
        self.assertTrue(forecast.is_current)
    
    def test_save_forecast_with_previous_fallback(self):
        """Test fallback to previous forecast when new save fails"""
        # Create initial forecast
        previous_forecast = ProductForecast.objects.create(
            product=self.product,
            forecast_period='2024-12',
            demand_forecast_kg=Decimal('80.00'),
            demand_lower_bound=Decimal('70.00'),
            demand_upper_bound=Decimal('90.00'),
            price_forecast=Decimal('100.00'),
            price_lower_bound=Decimal('90.00'),
            price_upper_bound=Decimal('110.00'),
            confidence_level='HIGH',
            model_type='ARIMA',
            is_current=True
        )
        
        # Try to save new forecast data
        forecast_data = {
            'demand_forecast_kg': 100.0,
            'demand_lower_bound': 90.0,
            'demand_upper_bound': 110.0,
            'price_forecast': 120.0,
            'price_lower_bound': 110.0,
            'price_upper_bound': 130.0,
            'confidence_level': 'HIGH',
            'forecast_period': '2025-01',
            'rmse_demand': 5.0,
            'rmse_price': 3.0,
            'mape_demand': 5.0,
            'mape_price': 3.0,
        }
        
        success, forecast, message = ForecastFallbackManager.save_forecast_atomically(
            product=self.product,
            new_forecast_data=forecast_data,
            model_type='SARIMA'
        )
        
        # Should succeed
        self.assertTrue(success)
        
        # Previous should be marked non-current
        previous_forecast.refresh_from_db()
        self.assertFalse(previous_forecast.is_current)
        
        # New should be current
        self.assertTrue(forecast.is_current)
    
    def test_mark_product_unavailable(self):
        """Test marking product as INSUFFICIENT_DATA"""
        forecast = ForecastFallbackManager.mark_product_unavailable(
            product=self.product,
            reason='Data quality too low'
        )
        
        self.assertEqual(forecast.model_type, 'INSUFFICIENT_DATA')
        self.assertTrue(forecast.is_current)
    
    def test_get_fallback_status(self):
        """Test fallback status retrieval"""
        # Create a current forecast
        ProductForecast.objects.create(
            product=self.product,
            forecast_period='2025-01',
            demand_forecast_kg=Decimal('100.00'),
            demand_lower_bound=Decimal('90.00'),
            demand_upper_bound=Decimal('110.00'),
            price_forecast=Decimal('120.00'),
            price_lower_bound=Decimal('110.00'),
            price_upper_bound=Decimal('130.00'),
            confidence_level='HIGH',
            model_type='SARIMA',
            is_current=True
        )
        
        status = ForecastFallbackManager.get_fallback_status(self.product)
        
        self.assertEqual(status['product_id'], self.product.id)
        self.assertTrue(status['has_forecast'])
        self.assertFalse(status['using_fallback'])
        self.assertEqual(status['current_model_type'], 'SARIMA')


class ForecastingServiceErrorHandlingTestCase(TestCase):
    """Tests for ForecastingService error handling (Phase 3.3)"""
    
    def setUp(self):
        """Set up test data"""
        self.seller = User.objects.create_user(
            username='seller1',
            email='seller1@test.com',
            password='test123'
        )
        
        self.category = ProductCategory.objects.create(
            name='Vegetables'
        )
        
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Talong',
            category=self.category,
            price=Decimal('100.00'),
            stock_level=50
        )
        
        self.service = ForecastingService()
    
    def test_get_forecast_health(self):
        """Test forecast system health check"""
        health = self.service.get_forecast_health()
        
        self.assertIn('system_status', health)
        self.assertIn('stale_forecast_report', health)
        self.assertIn('recent_model_failures', health)
        self.assertIn('recommendations', health)
    
    def test_check_stale_forecasts(self):
        """Test stale forecast check"""
        report = self.service.check_stale_forecasts()
        
        self.assertIn('total_forecasts', report)
        self.assertIn('stale_percentage', report)
        self.assertIn('by_severity', report)
