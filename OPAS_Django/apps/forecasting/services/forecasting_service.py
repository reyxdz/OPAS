"""
Forecasting Service - Main orchestrator for demand and price forecasting.

This service:
1. Fetches historical transaction data
2. Validates data quality with DataValidator
3. Selects appropriate model (SARIMA/ARIMA/Simple)
4. Trains the model with fallback support
5. Generates forecasts with confidence intervals
6. Stores results in ProductForecast with graceful degradation
7. Detects and flags stale forecasts
8. Provides robust error handling

Author: OPAS System
Created: December 2025
"""

import logging
import numpy as np
import pandas as pd
from decimal import Decimal
from datetime import datetime, timedelta
from typing import Dict, Tuple, Optional

from django.utils import timezone
from django.db import transaction
from statsmodels.tsa.statespace.sarimax import SARIMAX
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from pmdarima import auto_arima

from apps.users.models import SellerProduct
from apps.forecasting.models import (
    ProductForecast,
    ForecastMetadata,
    HistoricalTransactions,
    ModelType,
    ConfidenceLevel,
    AlertType,
    AlertSeverity,
    ForecastAlert,
)
from apps.forecasting.services.data_aggregator import DataAggregator
from apps.forecasting.services.model_selector import ModelSelector
from apps.forecasting.services.data_validator import DataValidator
from apps.forecasting.services.stale_forecast_manager import StaleForecastManager
from apps.forecasting.services.forecast_fallback_manager import ForecastFallbackManager

logger = logging.getLogger(__name__)


class ForecastResult:
    """
    Data class to hold forecast results for a product.
    """
    def __init__(self, product_id: int, product_name: str, model_type: str,
                 demand_forecast: float, demand_bounds: Tuple[float, float],
                 price_forecast: float, price_bounds: Tuple[float, float],
                 confidence_level: str, data_points: int, forecast_period: str):
        self.product_id = product_id
        self.product_name = product_name
        self.model_type = model_type
        self.demand_forecast = demand_forecast
        self.demand_lower = demand_bounds[0]
        self.demand_upper = demand_bounds[1]
        self.price_forecast = price_forecast
        self.price_lower = price_bounds[0]
        self.price_upper = price_bounds[1]
        self.confidence_level = confidence_level
        self.data_points = data_points
        self.forecast_period = forecast_period
        self.created_at = timezone.now()


class ForecastingService:
    """
    Main forecasting orchestrator service.
    
    Handles:
    - Data collection and validation
    - Model selection
    - Model training (SARIMA/ARIMA/Simple)
    - Forecast generation
    - Confidence interval calculation
    - Results storage
    """
    
    def __init__(self):
        self.data_aggregator = DataAggregator()
        self.model_selector = ModelSelector()
    
    def generate_forecast(self, product_id: int, forecast_steps: int = 4,
                         forecast_period: str = 'W') -> Optional[ForecastResult]:
        """
        Generate demand and price forecast for a specific product.
        
        Includes comprehensive error handling and robustness features:
        - Data validation with outlier detection
        - Fallback to previous forecast on training failure
        - Stale forecast detection
        - NaN/null value handling
        
        Args:
            product_id: ID of the SellerProduct to forecast
            forecast_steps: Number of periods to forecast (default 4 weeks)
            forecast_period: Period type - 'W' for weekly, 'M' for monthly
            
        Returns:
            ForecastResult object with predictions, or None if failed
        """
        try:
            # Step 1: Get the product
            product = SellerProduct.objects.filter(
                id=product_id,
                is_deleted=False
            ).first()
            
            if not product:
                logger.warning(f"Product {product_id} not found or deleted")
                return None
            
            logger.info(f"Generating forecast for {product.name} (ID: {product_id})")
            
            # Step 2: Collect historical transactions
            transactions = HistoricalTransactions.objects.filter(
                product=product
            ).order_by('transaction_date')
            
            if not transactions.exists():
                logger.warning(f"No historical transactions for {product.name}")
                return None
            
            # Step 3: Convert to DataFrame
            df = self._transactions_to_dataframe(transactions)
            
            if df.empty:
                logger.warning(f"Empty DataFrame for {product.name}")
                return None
            
            # Step 4: VALIDATE DATA QUALITY - NEW
            # Detect and handle NaN, outliers, consistency issues
            df_clean, validation_report = DataValidator.validate_dataframe(df)
            
            logger.info(
                f"Data validation for {product.name}: {validation_report['rows_after']} valid records, "
                f"quality_score={validation_report['quality_score']}"
            )
            
            # If validation failed or data is insufficient after cleaning
            if not validation_report['is_valid']:
                logger.warning(
                    f"Data validation failed for {product.name}: "
                    f"{', '.join(validation_report['issues'])}"
                )
                return None
            
            if len(df_clean) < 5:
                logger.warning(
                    f"Insufficient clean data for {product.name}: {len(df_clean)} points after validation"
                )
                return None
            
            # Step 5: Check data consistency
            consistency = DataValidator.check_data_consistency(df_clean)
            if not consistency['is_consistent']:
                logger.warning(
                    f"Data consistency issues for {product.name}: "
                    f"{', '.join(consistency['issues'])}"
                )
            
            # Step 6: Calculate statistics from cleaned data
            data_points_count = len(df_clean)
            variance = self._calculate_variance(df_clean['quantity_kg'])
            completeness = self._calculate_completeness(df_clean)
            
            # Step 7: Select appropriate model
            model_info = self.model_selector.select_model(
                data_points_count=data_points_count,
                variance=variance,
                data_completeness=completeness,
                has_seasonality=self._detect_seasonality(df_clean),
                series_data=df_clean['quantity_kg'].values
            )
            
            model_type = model_info['model_type']
            confidence_score = model_info.get('confidence_score', 0)
            
            # Adjust confidence based on data quality
            if validation_report['quality_score'] < 70:
                confidence_score = min(confidence_score, 50)  # Cap confidence if data quality is poor
            
            confidence_level = self._map_confidence_level(confidence_score)
            
            logger.info(
                f"Selected model: {model_type} (confidence: {confidence_level}, "
                f"quality_score: {validation_report['quality_score']})"
            )
            
            # Step 8: Train models and generate forecasts
            if model_type == ModelType.INSUFFICIENT_DATA:
                logger.warning(f"Insufficient data for {product.name}")
                return None
            
            # Step 9: Train models and generate forecasts using CLEANED data
            demand_series = df_clean['quantity_kg']
            price_series = df_clean['average_price']
            
            # Train demand forecast with error handling
            demand_forecast, demand_bounds = self._train_and_forecast(
                demand_series,
                model_type,
                forecast_steps,
                series_name=f"{product.name} - Demand"
            )
            
            # Train price forecast with error handling
            price_forecast, price_bounds = self._train_and_forecast(
                price_series,
                model_type,
                forecast_steps,
                series_name=f"{product.name} - Price"
            )
            
            if demand_forecast is None or price_forecast is None:
                logger.error(f"Model training failed for {product.name}")
                return None
            
            # Step 7: Generate period label
            last_date = transactions.last().transaction_date
            forecast_date_label = self._get_forecast_period_label(
                last_date, forecast_steps, forecast_period
            )
            
            # Step 8: Create result object
            result = ForecastResult(
                product_id=product_id,
                product_name=product.name,
                model_type=model_type,
                demand_forecast=demand_forecast,
                demand_bounds=demand_bounds,
                price_forecast=price_forecast,
                price_bounds=price_bounds,
                confidence_level=confidence_level,
                data_points=data_points_count,
                forecast_period=forecast_date_label
            )
            
            logger.info(f"Forecast generated for {product.name}: "
                       f"Demand {demand_forecast:.2f}kg, Price {price_forecast:.2f}")
            
            return result
        
        except Exception as e:
            logger.error(f"Error generating forecast for product {product_id}: {str(e)}")
            return None
    
    def _train_and_forecast(self, series: pd.Series, model_type: str,
                           forecast_steps: int, series_name: str = "Data"
                           ) -> Tuple[Optional[float], Optional[Tuple[float, float]]]:
        """
        Train appropriate model and generate forecast with confidence intervals.
        
        Includes robust error handling:
        - NaN value removal
        - Graceful fallback to simpler models
        - Detailed error logging
        
        Args:
            series: Time series data to forecast (should be pre-cleaned)
            model_type: Type of model to use
            forecast_steps: Number of periods to forecast
            series_name: Name of series for logging (e.g., "Product Name - Demand")
            
        Returns:
            Tuple of (forecast_value, (lower_bound, upper_bound)) or (None, None) if failed
        """
        try:
            # Remove any remaining NaN values
            series_clean = series.dropna()
            
            if len(series_clean) < 5:
                logger.warning(
                    f"Insufficient data for {series_name} after NaN removal: {len(series_clean)} points"
                )
                return None, None
            
            logger.info(f"Training {model_type} model for {series_name} with {len(series_clean)} points")
            
            if model_type == ModelType.SARIMA:
                return self._forecast_sarima(series_clean, forecast_steps, series_name)
            elif model_type == ModelType.ARIMA:
                return self._forecast_arima(series_clean, forecast_steps, series_name)
            elif model_type == ModelType.SIMPLE:
                return self._forecast_simple(series_clean, forecast_steps, series_name)
            else:
                logger.error(f"Unknown model type: {model_type}")
                return None, None
        
        except Exception as e:
            logger.error(f"Error in model training for {series_name}: {str(e)}")
            return None, None
    
    def _forecast_sarima(self, series: pd.Series, forecast_steps: int, series_name: str = "Data"
                        ) -> Tuple[Optional[float], Optional[Tuple[float, float]]]:
        """
        Train SARIMA model and generate forecast.
        
        Uses auto_arima to determine optimal parameters with fallback to ARIMA on failure.
        """
        try:
            logger.info(f"Training SARIMA model for {series_name}")
            
            # Auto-select parameters
            try:
                auto_model = auto_arima(
                    series,
                    seasonal=True,
                    m=4 if len(series) >= 16 else 1,  # Monthly seasonality if enough data
                    stepwise=True,
                    suppress_warnings=True,
                    error_action='ignore',
                    max_p=3,
                    max_d=2,
                    max_q=3,
                    trace=False
                )
                
                order = auto_model.order
                seasonal_order = auto_model.seasonal_order
                
                logger.info(f"SARIMA selected parameters: order={order}, seasonal_order={seasonal_order}")
            
            except Exception as auto_error:
                logger.warning(f"Auto-ARIMA parameter selection failed for {series_name}: {str(auto_error)}")
                logger.info("Using fallback ARIMA (non-seasonal)")
                return self._forecast_arima(series, forecast_steps, series_name)
            
            # Fit SARIMA model with error handling
            try:
                model = SARIMAX(
                    series,
                    order=order,
                    seasonal_order=seasonal_order,
                    enforce_stationarity=False,
                    enforce_invertibility=False
                )
                
                results = model.fit(disp=False, maxiter=200)
                
                # Generate forecast with confidence intervals
                forecast = results.get_forecast(steps=forecast_steps)
                forecast_mean = forecast.predicted_mean.iloc[-1]
                forecast_ci = forecast.conf_int(alpha=0.05)
                
                lower_bound = forecast_ci.iloc[-1, 0]
                upper_bound = forecast_ci.iloc[-1, 1]
                
                logger.info(f"SARIMA model trained successfully for {series_name}")
                return float(forecast_mean), (float(lower_bound), float(upper_bound))
            
            except Exception as sarima_error:
                logger.warning(
                    f"SARIMA training failed for {series_name}: {str(sarima_error)}. "
                    f"Falling back to ARIMA (non-seasonal)"
                )
                return self._forecast_arima(series, forecast_steps, series_name)
        
        except Exception as e:
            logger.error(f"Error in SARIMA forecast for {series_name}: {str(e)}")
            return self._forecast_arima(series, forecast_steps, series_name)
    
    def _forecast_arima(self, series: pd.Series, forecast_steps: int, series_name: str = "Data"
                       ) -> Tuple[Optional[float], Optional[Tuple[float, float]]]:
        """
        Train ARIMA (non-seasonal) model and generate forecast.
        
        Includes fallback to Simple forecasting if ARIMA fails.
        """
        try:
            logger.info(f"Training ARIMA model for {series_name}")
            
            # Auto-select ARIMA parameters with error handling
            try:
                auto_model = auto_arima(
                    series,
                    seasonal=False,
                    stepwise=True,
                    suppress_warnings=True,
                    error_action='ignore',
                    max_p=3,
                    max_d=2,
                    max_q=3,
                    trace=False
                )
                
                order = auto_model.order
                logger.info(f"ARIMA selected parameters: order={order} for {series_name}")
            
            except Exception as auto_error:
                logger.warning(
                    f"Auto-ARIMA parameter selection failed for {series_name}: {str(auto_error)}. "
                    f"Using fallback Simple forecasting"
                )
                return self._forecast_simple(series, forecast_steps, series_name)
            
            # Fit ARIMA model with error handling
            try:
                model = ARIMA(series, order=order)
                results = model.fit()
                
                # Generate forecast with confidence intervals
                forecast = results.get_forecast(steps=forecast_steps)
                forecast_mean = forecast.predicted_mean.iloc[-1]
                forecast_ci = forecast.conf_int(alpha=0.05)
                
                lower_bound = forecast_ci.iloc[-1, 0]
                upper_bound = forecast_ci.iloc[-1, 1]
                
                logger.info(f"ARIMA model trained successfully for {series_name}")
                return float(forecast_mean), (float(lower_bound), float(upper_bound))
            
            except Exception as arima_error:
                logger.warning(
                    f"ARIMA training failed for {series_name}: {str(arima_error)}. "
                    f"Using fallback Simple forecasting"
                )
                return self._forecast_simple(series, forecast_steps, series_name)
        
        except Exception as e:
            logger.error(f"Error in ARIMA forecast for {series_name}: {str(e)}")
            return self._forecast_simple(series, forecast_steps, series_name)
    
    def _forecast_simple(self, series: pd.Series, forecast_steps: int, series_name: str = "Data"
                        ) -> Tuple[Optional[float], Optional[Tuple[float, float]]]:
        """
        Simple exponential smoothing fallback for sparse data.
        
        Uses exponential smoothing or mean/std when data is too small.
        Ensures graceful degradation when complex models fail.
        """
        try:
            logger.info(f"Using Simple (Exponential Smoothing) forecasting for {series_name}")
            
            # Use exponential smoothing if enough data
            if len(series) >= 2:
                try:
                    model = ExponentialSmoothing(
                        series,
                        trend='add' if len(series) >= 5 else None,
                        seasonal=None
                    )
                    results = model.fit(optimized=True)
                    
                    # Generate forecast
                    forecast_mean = results.forecast(steps=forecast_steps)[-1]
                    
                    logger.info(f"Exponential Smoothing succeeded for {series_name}")
                except Exception as smoothing_error:
                    logger.warning(
                        f"Exponential Smoothing failed for {series_name}: {str(smoothing_error)}. "
                        f"Using mean/std fallback"
                    )
                    mean_val = series.mean()
                    std_val = series.std() if series.std() > 0 else mean_val * 0.1
                    
                    return float(mean_val), (
                        float(mean_val - 1.96 * std_val),
                        float(mean_val + 1.96 * std_val)
                    )
            else:
                # Ultra-simple fallback for very small datasets
                mean_val = series.mean()
                std_val = series.std() if series.std() > 0 else mean_val * 0.1
                
                return float(mean_val), (
                    float(mean_val - 1.96 * std_val),
                    float(mean_val + 1.96 * std_val)
                )
            
            # Calculate confidence interval from series
            std_val = series.std()
            if std_val <= 0:
                # If no variation, use 10% of mean as std
                std_val = abs(mean_val) * 0.1 if mean_val != 0 else 1.0
            
            lower_bound = forecast_mean - 1.96 * std_val
            upper_bound = forecast_mean + 1.96 * std_val
            
            return float(forecast_mean), (float(lower_bound), float(upper_bound))
        
        except Exception as e:
            logger.error(f"Simple model failed for {series_name}: {str(e)}")
            
            # Ultimate fallback: use mean and standard deviation
            mean_val = float(series.mean())
            std_val = float(series.std()) if series.std() > 0 else abs(mean_val) * 0.1
            
            logger.warning(f"Using ultimate fallback (mean/std) for {series_name}")
            return mean_val, (mean_val - 1.96 * std_val, mean_val + 1.96 * std_val)
    
    def save_forecast(self, result: ForecastResult, model_type: str) -> bool:
        """
        Save forecast result to database with graceful fallback support.
        
        Automatically reverts to previous forecast if save fails.
        Creates alerts when fallback is used.
        
        Args:
            result: ForecastResult object
            model_type: Type of model used
            
        Returns:
            True if successful, False otherwise
        """
        try:
            product = SellerProduct.objects.get(id=result.product_id)
            
            # Prepare forecast data for atomic save
            forecast_data = {
                'demand_forecast_kg': result.demand_forecast,
                'demand_lower_bound': result.demand_lower,
                'demand_upper_bound': result.demand_upper,
                'price_forecast': result.price_forecast,
                'price_lower_bound': result.price_lower,
                'price_upper_bound': result.price_upper,
                'confidence_level': result.confidence_level,
                'forecast_period': result.forecast_period,
                'rmse_demand': 0,  # Will be calculated during training
                'rmse_price': 0,
                'mape_demand': 0,
                'mape_price': 0,
            }
            
            # Save with fallback support
            success, forecast, message = ForecastFallbackManager.save_forecast_atomically(
                product=product,
                new_forecast_data=forecast_data,
                model_type=model_type
            )
            
            if success:
                logger.info(f"Forecast saved successfully for product {result.product_id}")
                
                # Update metadata
                metadata, created = ForecastMetadata.objects.update_or_create(
                    product_id=result.product_id,
                    defaults={
                        'model_type': model_type,
                        'data_points_count': result.data_points,
                        'is_reliable': result.confidence_level in [ConfidenceLevel.HIGH, ConfidenceLevel.MEDIUM],
                        'last_training_date': timezone.now(),
                        'last_successful_forecast_date': timezone.now(),
                        'notes': f'Forecast generated with {result.data_points} data points'
                    }
                )
                return True
            else:
                logger.warning(
                    f"Forecast save failed for product {result.product_id}. "
                    f"Fallback status: {message}"
                )
                return False
        
        except SellerProduct.DoesNotExist:
            logger.error(f"Product {result.product_id} not found when saving forecast")
            return False
        
        except Exception as e:
            logger.error(f"Error saving forecast for product {result.product_id}: {str(e)}")
            return False
    
    def batch_generate_all_products(self) -> Dict:
        """
        Generate forecasts for all active SellerProducts.
        
        Includes:
        - Stale forecast detection and alerting
        - Error handling with fallback support
        - Comprehensive statistics collection
        
        Returns:
            Dictionary with statistics:
            {
                'total_products': int,
                'forecasts_generated': int,
                'forecasts_failed': int,
                'products_with_no_data': int,
                'stale_forecasts_detected': int,
                'alerts_created': int,
                'results': [ForecastResult, ...]
            }
        """
        logger.info("Starting batch forecast generation for all products")
        
        stats = {
            'total_products': 0,
            'forecasts_generated': 0,
            'forecasts_failed': 0,
            'products_with_no_data': 0,
            'stale_forecasts_detected': 0,
            'alerts_created': 0,
            'results': []
        }
        
        try:
            products = SellerProduct.objects.filter(is_deleted=False)
            stats['total_products'] = products.count()
            
            for product in products:
                try:
                    result = self.generate_forecast(product.id)
                    
                    if result is None:
                        # Determine reason
                        if not HistoricalTransactions.objects.filter(product=product).exists():
                            stats['products_with_no_data'] += 1
                        else:
                            stats['forecasts_failed'] += 1
                        continue
                    
                    # Save to database
                    if self.save_forecast(result, result.model_type):
                        stats['forecasts_generated'] += 1
                        stats['results'].append(result)
                    else:
                        stats['forecasts_failed'] += 1
                
                except Exception as e:
                    logger.error(f"Error processing product {product.id}: {str(e)}")
                    stats['forecasts_failed'] += 1
            
            # After generating new forecasts, detect and flag stale forecasts
            logger.info("Checking for stale forecasts...")
            stale_result = StaleForecastManager.mark_stale_forecasts()
            stats['stale_forecasts_detected'] = stale_result['stale_count']
            stats['alerts_created'] = stale_result['alerts_created']
            
            logger.info(
                f"Batch forecast complete: {stats['forecasts_generated']} generated, "
                f"{stats['forecasts_failed']} failed, "
                f"{stats['products_with_no_data']} no data, "
                f"{stats['stale_forecasts_detected']} stale detected, "
                f"{stats['alerts_created']} alerts created"
            )
            
            return stats
        
        except Exception as e:
            logger.error(f"Error in batch_generate_all_products: {str(e)}")
            return stats
    
    def check_stale_forecasts(self) -> Dict[str, any]:
        """
        Check system for stale forecasts and create alerts.
        
        Returns:
            Report from StaleForecastManager.get_stale_forecast_report()
        """
        logger.info("Checking for stale forecasts in system")
        report = StaleForecastManager.get_stale_forecast_report()
        
        logger.info(
            f"Stale forecast report: {report['stale_percentage']}% stale "
            f"({report['stale_forecasts']} of {report['total_forecasts']})"
        )
        
        return report
    
    def get_forecast_health(self) -> Dict[str, any]:
        """
        Get overall health and status of forecasting system.
        
        Returns:
            Dictionary with:
                - stale_forecast_report: From StaleForecastManager
                - data_quality_issues: List of products with data quality concerns
                - model_failures: Recent forecast model training failures
                - system_status: Overall system health (HEALTHY/CAUTION/WARNING)
        """
        logger.info("Generating forecast system health report")
        
        stale_report = StaleForecastManager.get_stale_forecast_report()
        
        # Check for recent model failures
        recent_failures = ForecastAlert.objects.filter(
            alert_type=AlertType.MODEL_FAILURE,
            is_acknowledged=False,
            created_at__gte=timezone.now() - timedelta(days=7)
        ).count()
        
        # Determine overall status
        if stale_report['stale_percentage'] > 70 or recent_failures > 5:
            system_status = 'CRITICAL'
        elif stale_report['stale_percentage'] > 50 or recent_failures > 2:
            system_status = 'WARNING'
        elif stale_report['stale_percentage'] > 20:
            system_status = 'CAUTION'
        else:
            system_status = 'HEALTHY'
        
        return {
            'system_status': system_status,
            'stale_forecast_report': stale_report,
            'recent_model_failures': recent_failures,
            'recommendations': stale_report['recommendations'],
            'last_checked': timezone.now().isoformat()
        }
    
    # ==================== HELPER METHODS ====================
    
    def _transactions_to_dataframe(self, transactions) -> pd.DataFrame:
        """Convert HistoricalTransactions queryset to DataFrame."""
        data = []
        for t in transactions:
            data.append({
                'transaction_date': t.transaction_date,
                'quantity_kg': float(t.quantity_sold_kg),
                'average_price': float(t.average_price_per_kg),
            })
        
        df = pd.DataFrame(data)
        if not df.empty:
            df.set_index('transaction_date', inplace=True)
            df.sort_index(inplace=True)
        
        return df
    
    def _calculate_variance(self, series: pd.Series) -> float:
        """
        Calculate coefficient of variation (std / mean).
        
        Returns a value between 0 and 1 for normalized variance.
        """
        if series.empty or series.mean() == 0:
            return 0.0
        
        cv = series.std() / abs(series.mean())
        return min(cv, 1.0)  # Cap at 1.0
    
    def _calculate_completeness(self, df: pd.DataFrame) -> float:
        """
        Calculate data completeness as percentage of expected time periods.
        
        Returns value between 0 and 1.
        """
        if df.empty:
            return 0.0
        
        # Expected periods based on date range
        date_range = (df.index[-1] - df.index[0]).days
        expected_weeks = max(1, date_range / 7)
        actual_weeks = len(df)
        
        completeness = actual_weeks / expected_weeks
        return min(completeness, 1.0)
    
    def _detect_seasonality(self, df: pd.DataFrame) -> bool:
        """
        Simple seasonality detection based on data length.
        
        If we have at least 4 periods of data, assume potential seasonality.
        """
        return len(df) >= 16  # At least 4 months/quarters
    
    def _map_confidence_level(self, confidence_score: float) -> str:
        """Map confidence score (0-100) to ConfidenceLevel enum."""
        if confidence_score >= 80:
            return ConfidenceLevel.HIGH
        elif confidence_score >= 50:
            return ConfidenceLevel.MEDIUM
        else:
            return ConfidenceLevel.LOW
    
    def _get_forecast_period_label(self, last_date, forecast_steps: int,
                                   forecast_period: str) -> str:
        """
        Generate a label for the forecast period.
        
        Args:
            last_date: Last date in historical data
            forecast_steps: Number of periods to forecast
            forecast_period: 'W' for weekly, 'M' for monthly
        """
        if forecast_period == 'M':
            next_month = last_date + timedelta(days=31)
            return next_month.strftime('%Y-%m')
        else:  # Weekly
            next_week = last_date + timedelta(days=7)
            week_num = next_week.isocalendar()[1]
            year = next_week.year
            return f"Week {week_num} {year}"


# Singleton instance
_forecasting_service = None


def get_forecasting_service() -> ForecastingService:
    """Get or create the forecasting service singleton."""
    global _forecasting_service
    if _forecasting_service is None:
        _forecasting_service = ForecastingService()
    return _forecasting_service
