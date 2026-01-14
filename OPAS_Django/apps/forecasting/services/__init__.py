"""
Forecasting Services Package

Provides complete forecasting infrastructure:
- data_aggregator: Collect and aggregate transaction data
- model_selector: Select appropriate forecasting model
- data_validator: Validate data quality, detect outliers, check consistency
- stale_forecast_manager: Detect and flag outdated forecasts
- forecast_fallback_manager: Graceful degradation with fallback to previous forecasts
- forecasting_service: Main orchestrator service
"""

from .data_aggregator import DataAggregator
from .model_selector import ModelSelector
from .data_validator import DataValidator
from .stale_forecast_manager import StaleForecastManager
from .forecast_fallback_manager import ForecastFallbackManager
from .forecasting_service import ForecastingService, ForecastResult

__all__ = [
    'DataAggregator',
    'ModelSelector',
    'DataValidator',
    'StaleForecastManager',
    'ForecastFallbackManager',
    'ForecastingService',
    'ForecastResult',
]
