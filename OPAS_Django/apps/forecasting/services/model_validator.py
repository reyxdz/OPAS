"""
Model Validator Service - Validates forecasting models using time-series cross-validation.

Provides:
1. Train/Test split for time series (respecting temporal order)
2. Walk-forward cross-validation (multiple folds across time)
3. Model performance metrics (MAPE, RMSE, MAE)
4. Model comparison (test all 3 models, pick best)
5. Confidence scoring based on validation results
"""

import logging
import numpy as np
import pandas as pd
from typing import Dict, Tuple, List, Optional
from enum import Enum
from datetime import timedelta

from statsmodels.tsa.statespace.sarimax import SARIMAX
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.holtwinters import ExponentialSmoothing

logger = logging.getLogger(__name__)


class ValidationMetric(Enum):
    """Validation metrics for model evaluation"""
    MAPE = 'MAPE'      # Mean Absolute Percentage Error
    RMSE = 'RMSE'      # Root Mean Squared Error
    MAE = 'MAE'        # Mean Absolute Error
    SMAPE = 'SMAPE'    # Symmetric Mean Absolute Percentage Error


class ModelValidationResult:
    """
    Container for model validation results.
    
    Stores performance metrics and recommendations for model selection.
    """
    def __init__(self, model_type: str, series_name: str):
        self.model_type = model_type
        self.series_name = series_name
        self.mape = None          # Mean Absolute Percentage Error (%)
        self.rmse = None          # Root Mean Squared Error
        self.mae = None           # Mean Absolute Error
        self.smape = None         # Symmetric MAPE (%)
        self.predictions = []     # Predicted values
        self.actuals = []         # Actual values
        self.is_successful = False
        self.error_message = None
        self.training_time = 0
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for storage"""
        return {
            'model_type': self.model_type,
            'mape': round(self.mape, 2) if self.mape else None,
            'rmse': round(self.rmse, 2) if self.rmse else None,
            'mae': round(self.mae, 2) if self.mae else None,
            'smape': round(self.smape, 2) if self.smape else None,
            'is_successful': self.is_successful,
            'error_message': self.error_message,
        }
    
    def __str__(self):
        return (f"{self.model_type}: MAPE={self.mape:.2f}%, "
                f"RMSE={self.rmse:.2f}, MAE={self.mae:.2f}")


class ModelComparison:
    """
    Stores results of comparing multiple models.
    
    Determines which model performs best based on validation metrics.
    """
    def __init__(self, series_name: str):
        self.series_name = series_name
        self.results: Dict[str, ModelValidationResult] = {}
        self.best_model = None
        self.best_mape = float('inf')
    
    def add_result(self, validation_result: ModelValidationResult):
        """Add a model's validation result"""
        self.results[validation_result.model_type] = validation_result
        
        # Track best model by MAPE (lower is better)
        if (validation_result.is_successful and 
            validation_result.mape < self.best_mape):
            self.best_mape = validation_result.mape
            self.best_model = validation_result.model_type
    
    def get_ranking(self) -> List[Tuple[str, float]]:
        """Get models ranked by MAPE (best to worst)"""
        successful = [
            (model_type, result.mape)
            for model_type, result in self.results.items()
            if result.is_successful
        ]
        return sorted(successful, key=lambda x: x[1])
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for storage"""
        return {
            'series_name': self.series_name,
            'best_model': self.best_model,
            'best_mape': round(self.best_mape, 2) if self.best_mape != float('inf') else None,
            'results': {
                model_type: result.to_dict()
                for model_type, result in self.results.items()
            },
            'ranking': [
                {'model': model, 'mape': round(mape, 2)}
                for model, mape in self.get_ranking()
            ]
        }


class ModelValidator:
    """
    Validates forecasting models using time-series specific techniques.
    
    Features:
    - Train/test split respecting temporal order
    - Walk-forward cross-validation (multiple splits)
    - Performance metric calculation
    - Model comparison and ranking
    - Confidence scoring
    """
    
    @staticmethod
    def train_test_split(series: pd.Series, test_size: float = 0.2) -> Tuple[pd.Series, pd.Series]:
        """
        Split time series into train and test sets.
        
        IMPORTANT: Respects temporal order (no random shuffling)
        
        Args:
            series: Time series data
            test_size: Fraction of data to use for testing (default: 20%)
        
        Returns:
            Tuple of (train_series, test_series)
            
        Example:
            >>> series = pd.Series([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
            >>> train, test = ModelValidator.train_test_split(series, test_size=0.2)
            >>> print(len(train), len(test))
            8 2
            >>> print(train.values, test.values)
            [1 2 3 4 5 6 7 8] [9 10]  # Order preserved!
        """
        split_point = int(len(series) * (1 - test_size))
        return series[:split_point], series[split_point:]
    
    @staticmethod
    def walk_forward_split(series: pd.Series, 
                          initial_train_size: int = 10,
                          step_size: int = 1) -> List[Tuple[pd.Series, pd.Series]]:
        """
        Generate multiple train/test splits for walk-forward cross-validation.
        
        Used for time series because it respects temporal order and tests
        at different points in time.
        
        Args:
            series: Time series data
            initial_train_size: Minimum training data points (default: 10)
            step_size: Points to move forward for each fold (default: 1)
        
        Returns:
            List of (train_series, test_series) tuples
            
        Example:
            >>> series = pd.Series(range(20))
            >>> splits = ModelValidator.walk_forward_split(series, initial_train_size=10, step_size=3)
            >>> for i, (train, test) in enumerate(splits):
            ...     print(f"Fold {i}: train={len(train)}, test={len(test)}")
            Fold 0: train=10, test=3
            Fold 1: train=13, test=3
            Fold 2: train=16, test=3
        """
        folds = []
        train_end = initial_train_size
        
        while train_end + step_size <= len(series):
            train = series[:train_end]
            test = series[train_end:train_end + step_size]
            folds.append((train, test))
            train_end += step_size
        
        logger.info(f"Generated {len(folds)} walk-forward folds for series of length {len(series)}")
        return folds
    
    @staticmethod
    def calculate_mape(actual: np.ndarray, predicted: np.ndarray) -> float:
        """
        Calculate Mean Absolute Percentage Error.
        
        MAPE = mean(|actual - predicted| / |actual|) * 100
        
        Measures average error as percentage of actual values.
        Good for comparing across different scales.
        
        Args:
            actual: Actual values
            predicted: Predicted values
        
        Returns:
            MAPE percentage (0-100+)
            
        Example:
            >>> actual = np.array([100, 200, 300])
            >>> predicted = np.array([95, 210, 290])
            >>> mape = ModelValidator.calculate_mape(actual, predicted)
            >>> print(f"{mape:.2f}%")
            4.76%
        """
        mask = actual != 0  # Avoid division by zero
        return np.mean(np.abs((actual[mask] - predicted[mask]) / actual[mask])) * 100
    
    @staticmethod
    def calculate_rmse(actual: np.ndarray, predicted: np.ndarray) -> float:
        """
        Calculate Root Mean Squared Error.
        
        RMSE = sqrt(mean((actual - predicted)^2))
        
        Penalizes large errors more than small ones.
        Uses same units as the data.
        
        Args:
            actual: Actual values
            predicted: Predicted values
        
        Returns:
            RMSE
        """
        return np.sqrt(np.mean((actual - predicted) ** 2))
    
    @staticmethod
    def calculate_mae(actual: np.ndarray, predicted: np.ndarray) -> float:
        """
        Calculate Mean Absolute Error.
        
        MAE = mean(|actual - predicted|)
        
        Average error magnitude in same units as data.
        More interpretable than RMSE.
        
        Args:
            actual: Actual values
            predicted: Predicted values
        
        Returns:
            MAE
        """
        return np.mean(np.abs(actual - predicted))
    
    @staticmethod
    def calculate_smape(actual: np.ndarray, predicted: np.ndarray) -> float:
        """
        Calculate Symmetric Mean Absolute Percentage Error.
        
        SMAPE = mean(2 * |actual - predicted| / (|actual| + |predicted|)) * 100
        
        Similar to MAPE but more symmetric.
        Better when actuals can be near zero.
        
        Args:
            actual: Actual values
            predicted: Predicted values
        
        Returns:
            SMAPE percentage (0-200)
        """
        denominator = np.abs(actual) + np.abs(predicted)
        mask = denominator != 0
        return np.mean(2 * np.abs((actual[mask] - predicted[mask]) / denominator[mask])) * 100
    
    @staticmethod
    def validate_model_sarima(series: pd.Series, 
                             order: Tuple[int, int, int],
                             seasonal_order: Tuple[int, int, int, int],
                             test_series: pd.Series) -> ModelValidationResult:
        """
        Validate SARIMA model on test set.
        
        Args:
            series: Training series
            order: ARIMA order (p, d, q)
            seasonal_order: Seasonal order (P, D, Q, s)
            test_series: Test data to validate against
        
        Returns:
            ModelValidationResult with performance metrics
        """
        result = ModelValidationResult('SARIMA', series.name or 'Data')
        
        try:
            logger.info(f"Validating SARIMA with order={order}, seasonal_order={seasonal_order}")
            
            # Train model on training data
            model = SARIMAX(
                series,
                order=order,
                seasonal_order=seasonal_order,
                enforce_stationarity=False,
                enforce_invertibility=False
            )
            fitted = model.fit(disp=False, maxiter=200)
            
            # Generate predictions for test period
            predictions = fitted.forecast(steps=len(test_series))
            actuals = test_series.values
            
            # Calculate metrics
            result.mape = ModelValidator.calculate_mape(actuals, predictions)
            result.rmse = ModelValidator.calculate_rmse(actuals, predictions)
            result.mae = ModelValidator.calculate_mae(actuals, predictions)
            result.smape = ModelValidator.calculate_smape(actuals, predictions)
            result.predictions = predictions.tolist()
            result.actuals = actuals.tolist()
            result.is_successful = True
            
            logger.info(f"SARIMA validation result: {result}")
            
        except Exception as e:
            logger.error(f"SARIMA validation failed: {str(e)}")
            result.is_successful = False
            result.error_message = str(e)
        
        return result
    
    @staticmethod
    def validate_model_arima(series: pd.Series,
                            order: Tuple[int, int, int],
                            test_series: pd.Series) -> ModelValidationResult:
        """
        Validate ARIMA model on test set.
        
        Args:
            series: Training series
            order: ARIMA order (p, d, q)
            test_series: Test data to validate against
        
        Returns:
            ModelValidationResult with performance metrics
        """
        result = ModelValidationResult('ARIMA', series.name or 'Data')
        
        try:
            logger.info(f"Validating ARIMA with order={order}")
            
            # Train model
            model = ARIMA(series, order=order)
            fitted = model.fit()
            
            # Generate predictions
            predictions = fitted.forecast(steps=len(test_series))
            actuals = test_series.values
            
            # Calculate metrics
            result.mape = ModelValidator.calculate_mape(actuals, predictions)
            result.rmse = ModelValidator.calculate_rmse(actuals, predictions)
            result.mae = ModelValidator.calculate_mae(actuals, predictions)
            result.smape = ModelValidator.calculate_smape(actuals, predictions)
            result.predictions = predictions.tolist()
            result.actuals = actuals.tolist()
            result.is_successful = True
            
            logger.info(f"ARIMA validation result: {result}")
            
        except Exception as e:
            logger.error(f"ARIMA validation failed: {str(e)}")
            result.is_successful = False
            result.error_message = str(e)
        
        return result
    
    @staticmethod
    def validate_model_simple(series: pd.Series,
                             test_series: pd.Series) -> ModelValidationResult:
        """
        Validate Simple (Exponential Smoothing) model on test set.
        
        Args:
            series: Training series
            test_series: Test data to validate against
        
        Returns:
            ModelValidationResult with performance metrics
        """
        result = ModelValidationResult('SIMPLE', series.name or 'Data')
        
        try:
            logger.info("Validating SIMPLE (Exponential Smoothing)")
            
            # Use exponential smoothing
            model = ExponentialSmoothing(
                series,
                trend='add' if len(series) >= 5 else None,
                seasonal=None
            )
            fitted = model.fit(optimized=True)
            
            # Generate predictions
            predictions = fitted.forecast(steps=len(test_series))
            actuals = test_series.values
            
            # Calculate metrics
            result.mape = ModelValidator.calculate_mape(actuals, predictions)
            result.rmse = ModelValidator.calculate_rmse(actuals, predictions)
            result.mae = ModelValidator.calculate_mae(actuals, predictions)
            result.smape = ModelValidator.calculate_smape(actuals, predictions)
            result.predictions = predictions.tolist()
            result.actuals = actuals.tolist()
            result.is_successful = True
            
            logger.info(f"SIMPLE validation result: {result}")
            
        except Exception as e:
            logger.error(f"SIMPLE validation failed: {str(e)}")
            result.is_successful = False
            result.error_message = str(e)
        
        return result
    
    @staticmethod
    def compare_all_models(series: pd.Series,
                          test_series: pd.Series,
                          sarima_params: Optional[Tuple] = None,
                          arima_params: Optional[Tuple] = None) -> ModelComparison:
        """
        Compare SARIMA, ARIMA, and SIMPLE models on the same test set.
        
        This is the key improvement: test all 3 models and pick the best one
        based on MAPE, not just using the model selector's rules.
        
        Args:
            series: Training series
            test_series: Test data
            sarima_params: Optional pre-determined SARIMA parameters
            arima_params: Optional pre-determined ARIMA parameters
        
        Returns:
            ModelComparison with results for all 3 models
            
        Example:
            >>> train, test = ModelValidator.train_test_split(data_series, test_size=0.2)
            >>> comparison = ModelValidator.compare_all_models(train, test)
            >>> print(f"Best model: {comparison.best_model}")
            Best model: ARIMA
            >>> for model, mape in comparison.get_ranking():
            ...     print(f"{model}: {mape:.2f}%")
            ARIMA: 5.32%
            SARIMA: 6.15%
            SIMPLE: 12.43%
        """
        comparison = ModelComparison(series.name or 'Data')
        
        logger.info(f"Comparing all models for {series.name or 'Data'}")
        logger.info(f"Training size: {len(series)}, Test size: {len(test_series)}")
        
        # Test SARIMA if parameters provided
        if sarima_params:
            order, seasonal_order = sarima_params
            result = ModelValidator.validate_model_sarima(
                series, order, seasonal_order, test_series
            )
            comparison.add_result(result)
        
        # Test ARIMA if parameters provided
        if arima_params:
            result = ModelValidator.validate_model_arima(
                series, arima_params, test_series
            )
            comparison.add_result(result)
        
        # Always test SIMPLE
        result = ModelValidator.validate_model_simple(series, test_series)
        comparison.add_result(result)
        
        logger.info(f"Model comparison complete. Best: {comparison.best_model} "
                   f"(MAPE: {comparison.best_mape:.2f}%)")
        
        return comparison
    
    @staticmethod
    def get_confidence_score(mape: float) -> str:
        """
        Convert MAPE to confidence level.
        
        Args:
            mape: Mean Absolute Percentage Error
        
        Returns:
            Confidence level: 'HIGH', 'MEDIUM', or 'LOW'
        """
        if mape <= 10:
            return 'HIGH'      # Excellent accuracy
        elif mape <= 20:
            return 'MEDIUM'    # Good accuracy
        else:
            return 'LOW'       # Poor accuracy
