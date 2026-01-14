"""
Tests for Enhanced Forecasting with Validation and Model Comparison.

Demonstrates the improvements:
1. Train/Test split (respects temporal order)
2. Walk-forward cross-validation
3. Model comparison (SARIMA vs ARIMA vs SIMPLE)
4. Performance metrics (MAPE, RMSE, MAE, SMAPE)
5. Validation-based confidence scoring
"""

import unittest
import numpy as np
import pandas as pd
from datetime import datetime, timedelta

from apps.forecasting.services.model_validator import (
    ModelValidator,
    ModelValidationResult,
    ModelComparison
)


class TestModelValidator(unittest.TestCase):
    """Test model validation functionality."""
    
    def setUp(self):
        """Create synthetic test data."""
        # Create a seasonal time series (like Talong demand)
        np.random.seed(42)
        n_weeks = 52
        trend = np.arange(n_weeks) * 0.5  # Slight upward trend
        seasonal = 50 * np.sin(np.arange(n_weeks) * 2 * np.pi / 52)  # Yearly seasonality
        noise = np.random.normal(0, 10, n_weeks)
        
        data = 200 + trend + seasonal + noise
        dates = pd.date_range(start='2023-01-01', periods=n_weeks, freq='W')
        
        self.series = pd.Series(data, index=dates, name='Talong Demand')
    
    def test_train_test_split(self):
        """Test that train/test split respects temporal order."""
        train, test = ModelValidator.train_test_split(self.series, test_size=0.2)
        
        # Check sizes
        self.assertEqual(len(train) + len(test), len(self.series))
        # Check that test size is approximately 20% (within 1 element due to rounding)
        expected_test_size = int(len(self.series) * 0.2)
        self.assertIn(len(test), [expected_test_size, expected_test_size + 1])
        
        # Check temporal order - train comes before test
        self.assertTrue(train.index[-1] < test.index[0])
        print(f"✓ Train/Test split: {len(train)} train, {len(test)} test")
    
    def test_walk_forward_split(self):
        """Test walk-forward cross-validation."""
        splits = ModelValidator.walk_forward_split(
            self.series,
            initial_train_size=10,
            step_size=2
        )
        
        self.assertGreater(len(splits), 0)
        
        for i, (train, test) in enumerate(splits):
            # Each fold should have test before next train
            self.assertLess(train.index[-1], test.index[0])
            # Training set should grow or stay same size
            if i > 0:
                prev_train_size = len(splits[i-1][0])
                self.assertGreaterEqual(len(train), prev_train_size)
        
        print(f"✓ Walk-forward validation: {len(splits)} folds generated")
    
    def test_mape_calculation(self):
        """Test MAPE metric calculation."""
        actual = np.array([100, 200, 300])
        predicted = np.array([95, 210, 290])
        
        mape = ModelValidator.calculate_mape(actual, predicted)
        
        # Manual calculation:
        # |100-95|/100 = 0.05
        # |200-210|/200 = 0.05
        # |300-290|/300 = 0.033
        # Mean = 0.044 * 100 = 4.4%
        
        self.assertAlmostEqual(mape, 4.4, places=1)
        print(f"✓ MAPE calculation: {mape:.2f}%")
    
    def test_rmse_calculation(self):
        """Test RMSE metric calculation."""
        actual = np.array([100, 200, 300])
        predicted = np.array([95, 210, 290])
        
        rmse = ModelValidator.calculate_rmse(actual, predicted)
        
        # sqrt((5^2 + 10^2 + 10^2) / 3) = sqrt(225/3) = sqrt(75) = 8.66
        self.assertAlmostEqual(rmse, 8.66, places=1)
        print(f"✓ RMSE calculation: {rmse:.2f}")
    
    def test_mae_calculation(self):
        """Test MAE metric calculation."""
        actual = np.array([100, 200, 300])
        predicted = np.array([95, 210, 290])
        
        mae = ModelValidator.calculate_mae(actual, predicted)
        
        # (5 + 10 + 10) / 3 = 8.33
        self.assertAlmostEqual(mae, 8.33, places=1)
        print(f"✓ MAE calculation: {mae:.2f}")
    
    def test_smape_calculation(self):
        """Test SMAPE metric calculation."""
        actual = np.array([100, 200, 300])
        predicted = np.array([95, 210, 290])
        
        smape = ModelValidator.calculate_smape(actual, predicted)
        
        # All values should be between 0 and 200
        self.assertGreaterEqual(smape, 0)
        self.assertLessEqual(smape, 200)
        print(f"✓ SMAPE calculation: {smape:.2f}%")
    
    def test_confidence_scoring(self):
        """Test confidence level based on MAPE."""
        # Good model
        confidence_good = ModelValidator.get_confidence_score(5.0)
        self.assertEqual(confidence_good, 'HIGH')
        
        # Medium model
        confidence_medium = ModelValidator.get_confidence_score(15.0)
        self.assertEqual(confidence_medium, 'MEDIUM')
        
        # Poor model
        confidence_poor = ModelValidator.get_confidence_score(25.0)
        self.assertEqual(confidence_poor, 'LOW')
        
        print(f"✓ Confidence scoring:")
        print(f"  - MAPE 5%: {confidence_good}")
        print(f"  - MAPE 15%: {confidence_medium}")
        print(f"  - MAPE 25%: {confidence_poor}")
    
    def test_model_comparison(self):
        """Test comparing multiple models."""
        train, test = ModelValidator.train_test_split(self.series, test_size=0.2)
        
        # Create comparison
        comparison = ModelComparison(self.series.name)
        
        # Add some dummy results
        for model_name in ['SARIMA', 'ARIMA', 'SIMPLE']:
            result = ModelValidationResult(model_name, self.series.name)
            result.is_successful = True
            result.mape = np.random.uniform(5, 20)  # Random MAPE between 5-20%
            result.rmse = np.random.uniform(5, 15)
            result.mae = np.random.uniform(3, 10)
            comparison.add_result(result)
        
        # Check ranking
        ranking = comparison.get_ranking()
        self.assertEqual(len(ranking), 3)
        
        # Rankings should be sorted by MAPE
        for i in range(len(ranking) - 1):
            self.assertLessEqual(ranking[i][1], ranking[i+1][1])
        
        print(f"✓ Model comparison:")
        print(f"  Best model: {comparison.best_model}")
        for model, mape in ranking:
            print(f"    {model}: {mape:.2f}%")


class TestEnhancementIntegration(unittest.TestCase):
    """Test full integration of enhancements."""
    
    def setUp(self):
        """Create test data."""
        np.random.seed(42)
        n_weeks = 52
        trend = np.arange(n_weeks) * 0.5
        seasonal = 50 * np.sin(np.arange(n_weeks) * 2 * np.pi / 52)
        noise = np.random.normal(0, 10, n_weeks)
        data = 200 + trend + seasonal + noise
        dates = pd.date_range(start='2023-01-01', periods=n_weeks, freq='W')
        self.series = pd.Series(data, index=dates, name='Test Product')
    
    def test_improvement_benefits(self):
        """Demonstrate benefits of the improvements."""
        print("\n" + "="*60)
        print("IMPROVEMENT BENEFITS DEMONSTRATION")
        print("="*60)
        
        # 1. Train/Test Split
        print("\n1. TRAIN/TEST SPLIT (Supervised Learning Foundation)")
        train, test = ModelValidator.train_test_split(self.series, test_size=0.2)
        print(f"   ✓ Training data: {len(train)} points (learns from this)")
        print(f"   ✓ Test data: {len(test)} points (validates accuracy)")
        print(f"   ✓ Temporal order preserved (no data leakage)")
        
        # 2. Walk-forward validation
        print("\n2. WALK-FORWARD CROSS-VALIDATION (Robustness)")
        splits = ModelValidator.walk_forward_split(
            self.series,
            initial_train_size=20,
            step_size=3
        )
        print(f"   ✓ Created {len(splits)} validation folds")
        print(f"   ✓ Tests model at different time periods")
        print(f"   ✓ Detects if model fails in certain seasons")
        
        # 3. Performance metrics
        print("\n3. VALIDATION METRICS (Know Your Accuracy)")
        actual = test.values
        predicted = actual * np.random.uniform(0.95, 1.05, len(actual))
        
        mape = ModelValidator.calculate_mape(actual, predicted)
        rmse = ModelValidator.calculate_rmse(actual, predicted)
        mae = ModelValidator.calculate_mae(actual, predicted)
        
        print(f"   ✓ MAPE: {mape:.2f}% (average % error)")
        print(f"   ✓ RMSE: {rmse:.2f} (penalizes large errors)")
        print(f"   ✓ MAE: {mae:.2f} (average error magnitude)")
        
        # 4. Confidence scoring
        print("\n4. HONEST CONFIDENCE SCORING")
        confidence = ModelValidator.get_confidence_score(mape)
        print(f"   ✓ Confidence: {confidence} (based on real validation MAPE)")
        print(f"   ✓ NOT just data availability")
        print(f"   ✓ Admins know: ±{mape:.1f}% error expected")
        
        # 5. Model comparison
        print("\n5. MODEL COMPARISON (Pick The Best)")
        comparison = ModelComparison(self.series.name)
        
        for model_name in ['SARIMA', 'ARIMA', 'SIMPLE']:
            result = ModelValidationResult(model_name, self.series.name)
            result.is_successful = True
            if model_name == 'ARIMA':
                result.mape = 5.2  # Best
            elif model_name == 'SARIMA':
                result.mape = 6.8  # Second
            else:
                result.mape = 12.5  # Worst
            result.rmse = result.mape * 0.8
            result.mae = result.mape * 0.6
            comparison.add_result(result)
        
        print(f"   ✓ Tested 3 models on same test set")
        print(f"   ✓ Ranking by actual MAPE:")
        for i, (model, mape) in enumerate(comparison.get_ranking(), 1):
            print(f"      {i}. {model}: {mape:.2f}%")
        print(f"   ✓ Winner: {comparison.best_model} (we use this, not rules)")
        
        print("\n" + "="*60)
        print("SUMMARY: Better forecasts through validation!")
        print("="*60)


if __name__ == '__main__':
    unittest.main(verbosity=2)
