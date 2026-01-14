"""
Model Selector Service for Forecasting

Intelligently selects the most appropriate forecasting model based on
data availability, variance, and completeness metrics.
"""

from enum import Enum
from typing import Tuple, Optional
import numpy as np
import pandas as pd


class ModelType(Enum):
    """Available forecasting model types"""
    SARIMA = 'SARIMA'              # Seasonal ARIMA - best for seasonal data
    ARIMA = 'ARIMA'                # Non-seasonal ARIMA - for trending data
    SIMPLE = 'SIMPLE'              # Exponential smoothing - fallback
    INSUFFICIENT_DATA = 'INSUFFICIENT_DATA'  # Not enough data


class ModelSelector:
    """
    Selects forecasting model based on data characteristics.
    
    Decision Logic:
    - SARIMA (≥24 points, high variance, seasonal pattern) - Best
    - ARIMA (≥12 points, high variance) - Good
    - SIMPLE (≥5 points, low variance, sparse data) - Fallback
    - INSUFFICIENT_DATA (<5 points) - No model
    
    Ensures we use the best model for available data
    while gracefully degrading for sparse datasets.
    """
    
    # Thresholds for model selection
    SARIMA_MIN_POINTS = 24        # Need 24+ weeks/months for seasonal patterns
    ARIMA_MIN_POINTS = 12         # Need 12+ data points for trend detection
    SIMPLE_MIN_POINTS = 5         # Need at least 5 points
    
    VARIANCE_THRESHOLD = 0.1      # Minimum coefficient of variation
    SEASONALITY_THRESHOLD = 0.15  # Threshold for seasonal component strength
    
    @staticmethod
    def select_model(
        data_points_count: int,
        variance: Optional[float] = None,
        data_completeness: float = 100.0,
        has_seasonality: bool = False,
        series_data: Optional[pd.Series] = None
    ) -> Tuple[ModelType, dict]:
        
        # Calculate variance from series if not provided
        if series_data is not None and variance is None:
            variance = ModelSelector._calculate_variance(series_data)
        
        # Default variance if not available
        if variance is None:
            variance = 0.15
        
        # Decision tree: Select model based on data availability
        
        if data_points_count >= ModelSelector.SARIMA_MIN_POINTS:
            # We have enough data for SARIMA
            if variance > ModelSelector.VARIANCE_THRESHOLD:
                # Good variance + enough data = SARIMA
                if has_seasonality or data_points_count >= 52:
                    # Strong seasonality or 2+ years of data = definitely SARIMA
                    return ModelType.SARIMA, {
                        'selected_model': ModelType.SARIMA,
                        'reason': f'Sufficient data ({data_points_count} ≥ 24) with seasonality detected',
                        'confidence': 95,
                        'alternative_models': [ModelType.ARIMA, ModelType.SIMPLE],
                        'min_points_required': ModelSelector.SARIMA_MIN_POINTS,
                        'estimated_forecast_accuracy': '±8-15%',
                        'model_parameters': {
                            'training_data_points': data_points_count,
                            'data_completeness': data_completeness,
                            'has_seasonality': has_seasonality,
                            'variance': round(variance, 3),
                        }
                    }
                else:
                    # Good data but uncertain seasonality = SARIMA with caution
                    return ModelType.SARIMA, {
                        'selected_model': ModelType.SARIMA,
                        'reason': f'Sufficient data ({data_points_count} ≥ 24) for SARIMA, but no strong seasonality detected',
                        'confidence': 80,
                        'alternative_models': [ModelType.ARIMA, ModelType.SIMPLE],
                        'min_points_required': ModelSelector.SARIMA_MIN_POINTS,
                        'estimated_forecast_accuracy': '±10-18%',
                        'model_parameters': {
                            'training_data_points': data_points_count,
                            'data_completeness': data_completeness,
                            'has_seasonality': has_seasonality,
                            'variance': round(variance, 3),
                        }
                    }
            else:
                # Low variance with enough points = trending but stable
                # ARIMA better than SARIMA for this
                return ModelType.ARIMA, {
                    'selected_model': ModelType.ARIMA,
                    'reason': f'Sufficient data ({data_points_count} ≥ 24) but low variance - using ARIMA',
                    'confidence': 85,
                    'alternative_models': [ModelType.SIMPLE, ModelType.SARIMA],
                    'min_points_required': ModelSelector.ARIMA_MIN_POINTS,
                    'estimated_forecast_accuracy': '±5-12%',
                    'model_parameters': {
                        'training_data_points': data_points_count,
                        'data_completeness': data_completeness,
                        'has_seasonality': has_seasonality,
                        'variance': round(variance, 3),
                    }
                }
        
        elif data_points_count >= ModelSelector.ARIMA_MIN_POINTS:
            # We have enough data for ARIMA (but not SARIMA)
            if variance > ModelSelector.VARIANCE_THRESHOLD:
                return ModelType.ARIMA, {
                    'selected_model': ModelType.ARIMA,
                    'reason': f'Moderate data ({data_points_count} ≥ 12 but < 24) with good variance - using ARIMA',
                    'confidence': 75,
                    'alternative_models': [ModelType.SIMPLE],
                    'min_points_required': ModelSelector.ARIMA_MIN_POINTS,
                    'estimated_forecast_accuracy': '±12-20%',
                    'model_parameters': {
                        'training_data_points': data_points_count,
                        'data_completeness': data_completeness,
                        'has_seasonality': has_seasonality,
                        'variance': round(variance, 3),
                    }
                }
            else:
                # Low variance, moderate data = SIMPLE is safer
                return ModelType.SIMPLE, {
                    'selected_model': ModelType.SIMPLE,
                    'reason': f'Moderate data ({data_points_count}) with low variance - ARIMA risky, using SIMPLE',
                    'confidence': 65,
                    'alternative_models': [ModelType.ARIMA],
                    'min_points_required': ModelSelector.SIMPLE_MIN_POINTS,
                    'estimated_forecast_accuracy': '±15-25%',
                    'model_parameters': {
                        'training_data_points': data_points_count,
                        'data_completeness': data_completeness,
                        'has_seasonality': has_seasonality,
                        'variance': round(variance, 3),
                    }
                }
        
        elif data_points_count >= ModelSelector.SIMPLE_MIN_POINTS:
            # We have just enough data for SIMPLE
            return ModelType.SIMPLE, {
                'selected_model': ModelType.SIMPLE,
                'reason': f'Sparse data ({data_points_count} < 12) - using Simple exponential smoothing',
                'confidence': 50,
                'alternative_models': [],
                'min_points_required': ModelSelector.SIMPLE_MIN_POINTS,
                'estimated_forecast_accuracy': '±20-35%',
                'model_parameters': {
                    'training_data_points': data_points_count,
                    'data_completeness': data_completeness,
                    'has_seasonality': has_seasonality,
                    'variance': round(variance, 3),
                }
            }
        
        else:
            # Insufficient data for any model
            return ModelType.INSUFFICIENT_DATA, {
                'selected_model': ModelType.INSUFFICIENT_DATA,
                'reason': f'Insufficient data ({data_points_count} < 5) - cannot train any model',
                'confidence': 0,
                'alternative_models': [],
                'min_points_required': ModelSelector.SIMPLE_MIN_POINTS,
                'estimated_forecast_accuracy': 'N/A',
                'model_parameters': {
                    'training_data_points': data_points_count,
                    'data_completeness': data_completeness,
                    'has_seasonality': has_seasonality,
                    'variance': round(variance, 3) if variance else 0,
                }
            }
    
    @staticmethod
    def _calculate_variance(series: pd.Series) -> float:
        """
        Calculate coefficient of variation for a time series.
        
        Coefficient of variation = std / mean
        Normalized measure of dispersion that's scale-independent.
        
        Args:
            series: Pandas Series with numerical data
            
        Returns:
            Float between 0 and 1+ (higher = more variance)
            
        Example:
            >>> s = pd.Series([100, 110, 105, 115, 90])
            >>> cv = ModelSelector._calculate_variance(s)
            >>> print(cv)
            0.0825
        """
        if series.empty or series.std() == 0:
            return 0.0
        
        # Remove NaN values
        series = series.dropna()
        
        if len(series) < 2 or series.mean() == 0:
            return 0.0
        
        cv = series.std() / abs(series.mean())
        return float(cv)
    
    @staticmethod
    def detect_seasonality(series: pd.Series, period: int = 52) -> Tuple[bool, float]:
        """
        Detect if a time series has strong seasonal patterns.
        
        Uses autocorrelation analysis to detect periodicity.
        Looks for peaks in the autocorrelation function at the expected period.
        
        Args:
            series: Pandas Series with time series data
            period: Expected seasonality period (default: 52 for weekly data)
                   - 52 for weekly (1 year of weeks)
                   - 12 for monthly (1 year of months)
                   - 4 for quarterly
            
        Returns:
            Tuple of (has_seasonality: bool, strength: float 0-1)
            strength > 0.15 = strong seasonality
            
        Example:
            >>> # Talong data with seasonal demand
            >>> has_seasonal, strength = ModelSelector.detect_seasonality(
            ...     talong_series,
            ...     period=52
            ... )
            >>> print(f"Seasonal: {has_seasonal}, Strength: {strength:.2f}")
            Seasonal: True, Strength: 0.42
        """
        if series.empty or len(series) < period:
            return False, 0.0
        
        # Remove NaN values
        series = series.dropna()
        
        if len(series) < period:
            return False, 0.0
        
        try:
            from statsmodels.graphics.tsaplots import acf
            
            # Calculate autocorrelation function
            acf_values = acf(series, nlags=min(period + 1, len(series) - 1))
            
            # Look for peak at the expected seasonal period
            if len(acf_values) > period:
                seasonal_acf = acf_values[period]
                
                # Strength threshold
                has_seasonality = abs(seasonal_acf) > ModelSelector.SEASONALITY_THRESHOLD
                strength = abs(seasonal_acf)
                
                return has_seasonality, strength
            
        except Exception:
            # If ACF calculation fails, assume no seasonality
            pass
        
        return False, 0.0
    
    @staticmethod
    def get_model_info(model_type: ModelType) -> dict:
        """
        Get detailed information about a specific model type.
        
        Returns:
            Dictionary with model characteristics, pros, cons, and parameters
            
        Example:
            >>> info = ModelSelector.get_model_info(ModelType.SARIMA)
            >>> print(info['name'])
            'SARIMA'
            >>> print(info['min_points'])
            24
        """
        model_info = {
            ModelType.SARIMA: {
                'name': 'SARIMA',
                'full_name': 'Seasonal AutoRegressive Integrated Moving Average',
                'min_points': ModelSelector.SARIMA_MIN_POINTS,
                'pros': [
                    'Captures seasonal patterns',
                    'High accuracy for stable products',
                    'Handles trend + seasonality',
                    'Industry standard for time series',
                ],
                'cons': [
                    'Requires 24+ data points',
                    'Can overfit with sparse data',
                    'Computationally intensive',
                    'Assumes stationarity after differencing',
                ],
                'expected_accuracy': '±8-15%',
                'computation_time': '2-10 seconds per product',
                'best_for': 'Products with strong seasonal demand patterns',
                'example_products': ['Talong (eggplant)', 'Tomato', 'Onion'],
            },
            ModelType.ARIMA: {
                'name': 'ARIMA',
                'full_name': 'AutoRegressive Integrated Moving Average',
                'min_points': ModelSelector.ARIMA_MIN_POINTS,
                'pros': [
                    'Works with moderate data',
                    'Captures trends',
                    'Faster than SARIMA',
                    'Flexible parameter selection',
                ],
                'cons': [
                    'Misses seasonal patterns',
                    'Needs 12+ points',
                    'Poor for highly volatile data',
                    'Parameter selection can be tricky',
                ],
                'expected_accuracy': '±12-20%',
                'computation_time': '0.5-3 seconds per product',
                'best_for': 'Products with trending demand but no strong seasonality',
                'example_products': ['New products', 'Trending items'],
            },
            ModelType.SIMPLE: {
                'name': 'SIMPLE',
                'full_name': 'Exponential Smoothing / Simple Averaging',
                'min_points': ModelSelector.SIMPLE_MIN_POINTS,
                'pros': [
                    'Works with sparse data',
                    'Very fast',
                    'Robust to outliers',
                    'Easy to understand',
                ],
                'cons': [
                    'Low accuracy',
                    'Ignores patterns',
                    'Assumes constant mean',
                    'No confidence intervals',
                ],
                'expected_accuracy': '±20-35%',
                'computation_time': '< 100ms',
                'best_for': 'Products with insufficient data',
                'example_products': ['New products', 'Seasonal items in off-season'],
            },
            ModelType.INSUFFICIENT_DATA: {
                'name': 'INSUFFICIENT_DATA',
                'full_name': 'No Model Available',
                'min_points': ModelSelector.SIMPLE_MIN_POINTS,
                'pros': [
                    'Signals need for data collection',
                    'Prevents bad predictions',
                ],
                'cons': [
                    'No forecasts available',
                    'Must wait for more data',
                    'Reduces admin insights',
                ],
                'expected_accuracy': 'N/A',
                'computation_time': 'N/A',
                'best_for': 'New products or products with no sales',
                'example_products': ['New product launches'],
            },
        }
        
        return model_info.get(model_type, {})
    
    @staticmethod
    def recommend_next_steps(model_type: ModelType, data_points: int) -> list:
        """
        Provide recommendations to improve model selection.
        
        Suggests actions to either use better models or improve data quality.
        
        Args:
            model_type: Currently selected model type
            data_points: Current number of data points
            
        Returns:
            List of actionable recommendations
            
        Example:
            >>> recs = ModelSelector.recommend_next_steps(ModelType.SIMPLE, 8)
            >>> for rec in recs:
            ...     print(f"- {rec}")
            - Collect 4 more data points to enable SIMPLE model (target: 12+)
            - Monitor sales patterns for seasonal trends
            - Consider promoting product to increase data
        """
        recommendations = []
        
        if model_type == ModelType.INSUFFICIENT_DATA:
            gap = ModelSelector.SIMPLE_MIN_POINTS - data_points
            recommendations.append(
                f"Collect {gap} more data points to enable forecasting (target: {ModelSelector.SIMPLE_MIN_POINTS}+)"
            )
            recommendations.append("Track early sales patterns to prepare for future forecasting")
            recommendations.append("Consider bundling with established products for better data")
        
        elif model_type == ModelType.SIMPLE:
            gap_to_arima = ModelSelector.ARIMA_MIN_POINTS - data_points
            recommendations.append(
                f"Collect {gap_to_arima} more data points to enable ARIMA (target: {ModelSelector.ARIMA_MIN_POINTS}+)"
            )
            recommendations.append("Monitor seasonal patterns as data accumulates")
            recommendations.append("Improve data quality (reduce missing values)")
        
        elif model_type == ModelType.ARIMA:
            gap_to_sarima = ModelSelector.SARIMA_MIN_POINTS - data_points
            recommendations.append(
                f"Collect {gap_to_sarima} more data points to enable SARIMA (target: {ModelSelector.SARIMA_MIN_POINTS}+)"
            )
            recommendations.append("Watch for emerging seasonal patterns as 2+ years of data approaches")
            recommendations.append("Ensure consistent data quality across all periods")
        
        elif model_type == ModelType.SARIMA:
            recommendations.append("Monitor forecast accuracy - update model if MAPE > 20%")
            recommendations.append("Continue collecting high-quality data")
            recommendations.append("Review seasonal parameters annually")
        
        # Universal recommendations
        recommendations.append("Address any data gaps or missing values")
        recommendations.append("Watch for market disruptions that invalidate historical patterns")
        
        return recommendations
