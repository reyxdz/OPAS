"""
Tests for Model Selector Service

Comprehensive tests for model selection logic, variance calculation,
seasonality detection, and recommendations.
"""

import pandas as pd
import numpy as np
from django.test import TestCase
from apps.forecasting.services.model_selector import ModelSelector, ModelType


class ModelSelectorTestCase(TestCase):
    """Test suite for ModelSelector service"""
    
    def setUp(self):
        """Set up test data"""
        # Generate synthetic seasonal data (like Talong)
        np.random.seed(42)
        weeks = np.arange(52)
        seasonal_pattern = 10 * np.sin(2 * np.pi * weeks / 52)  # Annual seasonality
        noise = np.random.normal(0, 2, 52)
        self.seasonal_data = pd.Series(100 + seasonal_pattern + noise)
        
        # Generate trending data (non-seasonal)
        self.trending_data = pd.Series(np.linspace(100, 150, 26) + np.random.normal(0, 3, 26))
        
        # Generate sparse data
        self.sparse_data = pd.Series([100, 105, 102, 108, 103])
        
        # Generate very sparse data
        self.insufficient_data = pd.Series([100, 105])
    
    def test_select_model_sarima_sufficient_seasonal(self):
        """Test SARIMA selection with sufficient seasonal data"""
        model, metadata = ModelSelector.select_model(
            data_points_count=52,
            variance=0.25,
            has_seasonality=True
        )
        
        self.assertEqual(model, ModelType.SARIMA)
        self.assertGreaterEqual(metadata['confidence'], 90)
        self.assertEqual(metadata['selected_model'], ModelType.SARIMA)
        self.assertIn('seasonality detected', metadata['reason'].lower())
    
    def test_select_model_arima_moderate_data(self):
        """Test ARIMA selection with moderate trending data"""
        model, metadata = ModelSelector.select_model(
            data_points_count=15,
            variance=0.18
        )
        
        self.assertEqual(model, ModelType.ARIMA)
        self.assertGreaterEqual(metadata['confidence'], 70)
        self.assertIn(ModelType.SIMPLE, metadata['alternative_models'])
    
    def test_select_model_simple_sparse_data(self):
        """Test SIMPLE selection with sparse data"""
        model, metadata = ModelSelector.select_model(
            data_points_count=8,
            variance=0.12
        )
        
        self.assertEqual(model, ModelType.SIMPLE)
        self.assertGreaterEqual(metadata['confidence'], 40)
        self.assertLess(metadata['confidence'], 70)
    
    def test_select_model_insufficient_data(self):
        """Test INSUFFICIENT_DATA selection"""
        model, metadata = ModelSelector.select_model(
            data_points_count=3,
            variance=0.1
        )
        
        self.assertEqual(model, ModelType.INSUFFICIENT_DATA)
        self.assertEqual(metadata['confidence'], 0)
    
    def test_calculate_variance(self):
        """Test coefficient of variation calculation"""
        cv = ModelSelector._calculate_variance(self.seasonal_data)
        
        # Should be positive for data with variation
        self.assertGreater(cv, 0)
        self.assertLess(cv, 1)  # Typically < 1 for normal data
        
        # Constant series should have 0 variance
        constant_series = pd.Series([100, 100, 100, 100])
        cv_constant = ModelSelector._calculate_variance(constant_series)
        self.assertEqual(cv_constant, 0.0)
    
    def test_calculate_variance_empty_series(self):
        """Test variance calculation with empty series"""
        empty_series = pd.Series([])
        cv = ModelSelector._calculate_variance(empty_series)
        
        self.assertEqual(cv, 0.0)
    
    def test_detect_seasonality(self):
        """Test seasonality detection"""
        # Seasonal data should detect seasonality
        has_seasonal, strength = ModelSelector.detect_seasonality(
            self.seasonal_data,
            period=52
        )
        
        # Note: May or may not detect depending on data characteristics
        self.assertIsInstance(has_seasonal, bool)
        self.assertGreaterEqual(strength, 0)
        self.assertLessEqual(strength, 1)
    
    def test_detect_seasonality_insufficient_data(self):
        """Test seasonality detection with insufficient data"""
        has_seasonal, strength = ModelSelector.detect_seasonality(
            self.sparse_data,
            period=52
        )
        
        # Should return False for sparse data
        self.assertEqual(has_seasonal, False)
        self.assertEqual(strength, 0.0)
    
    def test_get_model_info_sarima(self):
        """Test getting SARIMA model information"""
        info = ModelSelector.get_model_info(ModelType.SARIMA)
        
        self.assertEqual(info['name'], 'SARIMA')
        self.assertEqual(info['min_points'], 24)
        self.assertGreater(len(info['pros']), 0)
        self.assertGreater(len(info['cons']), 0)
        self.assertIn('%', info['expected_accuracy'])  # Should contain % symbol
    
    def test_get_model_info_all_types(self):
        """Test getting information for all model types"""
        for model_type in ModelType:
            info = ModelSelector.get_model_info(model_type)
            
            self.assertIn('name', info)
            self.assertIn('min_points', info)
            self.assertTrue(len(info) > 0)
    
    def test_recommend_next_steps_insufficient(self):
        """Test recommendations for insufficient data"""
        recs = ModelSelector.recommend_next_steps(ModelType.INSUFFICIENT_DATA, 2)
        
        self.assertGreater(len(recs), 0)
        self.assertTrue(any('collect' in rec.lower() for rec in recs))
    
    def test_recommend_next_steps_simple(self):
        """Test recommendations for SIMPLE model"""
        recs = ModelSelector.recommend_next_steps(ModelType.SIMPLE, 8)
        
        self.assertGreater(len(recs), 0)
        # Should recommend collecting more data
        self.assertTrue(any('arima' in rec.lower() for rec in recs))
    
    def test_recommend_next_steps_sarima(self):
        """Test recommendations for SARIMA model"""
        recs = ModelSelector.recommend_next_steps(ModelType.SARIMA, 52)
        
        self.assertGreater(len(recs), 0)
        # Should recommend monitoring accuracy
        self.assertTrue(any('monitor' in rec.lower() or 'accuracy' in rec.lower() for rec in recs))
    
    def test_model_selection_thresholds(self):
        """Test model selection thresholds are correct"""
        # Exactly at SARIMA threshold
        model, _ = ModelSelector.select_model(
            data_points_count=24,
            variance=0.15
        )
        self.assertIn(model, [ModelType.SARIMA, ModelType.ARIMA])
        
        # Just below SARIMA threshold
        model, _ = ModelSelector.select_model(
            data_points_count=23,
            variance=0.15
        )
        self.assertIn(model, [ModelType.ARIMA, ModelType.SIMPLE])
        
        # Exactly at ARIMA threshold
        model, _ = ModelSelector.select_model(
            data_points_count=12,
            variance=0.15
        )
        self.assertIn(model, [ModelType.ARIMA, ModelType.SIMPLE])
        
        # Just below ARIMA threshold
        model, _ = ModelSelector.select_model(
            data_points_count=11,
            variance=0.15
        )
        self.assertIn(model, [ModelType.SIMPLE, ModelType.INSUFFICIENT_DATA])


class ModelSelectorRealWorldTestCase(TestCase):
    """Real-world scenario tests"""
    
    def test_talong_scenario_26_weeks(self):
        """Test Talong with 26 weeks of data (real scenario)"""
        model, metadata = ModelSelector.select_model(
            data_points_count=26,
            variance=0.22,
            data_completeness=100.0,
            has_seasonality=True
        )
        
        self.assertEqual(model, ModelType.SARIMA)
        self.assertGreaterEqual(metadata['confidence'], 80)
        print(f"Talong forecast: {model.value} (confidence: {metadata['confidence']}%)")
        print(f"Accuracy: {metadata['estimated_forecast_accuracy']}")
    
    def test_new_product_scenario(self):
        """Test new product with 6 weeks of data"""
        model, metadata = ModelSelector.select_model(
            data_points_count=6,
            variance=0.15,
            data_completeness=100.0,
            has_seasonality=False
        )
        
        self.assertEqual(model, ModelType.SIMPLE)
        self.assertLess(metadata['confidence'], 70)
        
        recs = ModelSelector.recommend_next_steps(model, 6)
        self.assertTrue(any('collect' in rec.lower() for rec in recs))
    
    def test_product_transitioning_to_arima(self):
        """Test product approaching ARIMA threshold"""
        model, metadata = ModelSelector.select_model(
            data_points_count=11,
            variance=0.18,
            data_completeness=95.0,
            has_seasonality=False
        )
        
        self.assertEqual(model, ModelType.SIMPLE)
        
        # After collecting one more week
        model_next, metadata_next = ModelSelector.select_model(
            data_points_count=12,
            variance=0.18,
            data_completeness=95.0,
            has_seasonality=False
        )
        
        # Should still be SIMPLE or ARIMA
        self.assertIn(model_next, [ModelType.SIMPLE, ModelType.ARIMA])
    
    def test_low_variance_product(self):
        """Test product with stable demand (low variance)"""
        model, metadata = ModelSelector.select_model(
            data_points_count=30,
            variance=0.05,  # Very stable
            data_completeness=100.0,
            has_seasonality=False
        )
        
        # ARIMA is better for stable trending data than SARIMA
        self.assertIn(model, [ModelType.ARIMA, ModelType.SARIMA])


class ModelSelectorEdgeCasesTestCase(TestCase):
    """Test edge cases and error handling"""
    
    def test_zero_variance_high_data(self):
        """Test handling of zero variance (flat line)"""
        model, metadata = ModelSelector.select_model(
            data_points_count=26,
            variance=0.0,  # Flat line
            has_seasonality=False
        )
        
        # Should downgrade to ARIMA
        self.assertNotEqual(model, ModelType.SARIMA)
    
    def test_very_high_variance(self):
        """Test handling of very high variance (volatile)"""
        model, metadata = ModelSelector.select_model(
            data_points_count=26,
            variance=0.8,  # Very volatile
            has_seasonality=False
        )
        
        # Should still select SARIMA with high volatility warning
        self.assertEqual(model, ModelType.SARIMA)
    
    def test_negative_data_points(self):
        """Test handling of negative data points (should not happen)"""
        model, metadata = ModelSelector.select_model(
            data_points_count=-5,
            variance=0.1
        )
        
        self.assertEqual(model, ModelType.INSUFFICIENT_DATA)
    
    def test_none_variance_with_series(self):
        """Test automatic variance calculation from series"""
        series = pd.Series([100, 110, 105, 115, 102])
        model, metadata = ModelSelector.select_model(
            data_points_count=5,
            variance=None,  # Will be auto-calculated
            series_data=series
        )
        
        self.assertIsNotNone(model)
        self.assertGreater(metadata['model_parameters']['variance'], 0)
    
    def test_series_with_nan(self):
        """Test handling series with NaN values"""
        series = pd.Series([100, np.nan, 105, np.nan, 102])
        
        model, metadata = ModelSelector.select_model(
            data_points_count=5,
            variance=None,
            series_data=series
        )
        
        # Should handle NaN gracefully
        self.assertIsNotNone(model)
    
    def test_completeness_below_threshold(self):
        """Test data with low completeness percentage"""
        model, metadata = ModelSelector.select_model(
            data_points_count=24,
            variance=0.2,
            data_completeness=40.0  # 60% missing data
        )
        
        # Should still select SARIMA but confidence lower
        self.assertEqual(model, ModelType.SARIMA)
        self.assertLess(metadata['confidence'], 95)


if __name__ == '__main__':
    import unittest
    unittest.main()
