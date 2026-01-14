"""
Forecast Fallback Manager - Handles graceful degradation when model training fails.

Functionality:
- Store previous forecast version when generating new one
- Automatically revert to previous forecast if training fails
- Track failed training attempts
- Create alerts when fallback is used

Author: OPAS System
Created: December 2025
"""

import logging
from typing import Dict, Optional, Tuple
from datetime import datetime
from decimal import Decimal
from django.utils import timezone

from apps.forecasting.models import (
    ProductForecast,
    ForecastAlert,
    AlertType,
    AlertSeverity,
)
from apps.users.models import SellerProduct

logger = logging.getLogger(__name__)


class ForecastFallbackManager:
    """
    Manages graceful degradation when model training fails.
    
    Strategy:
    1. When generating new forecast, mark previous as non-current (not deleted)
    2. If model training fails, revert the change and keep using previous forecast
    3. Create alert for admin about training failure
    4. Log failure details for debugging
    """
    
    @staticmethod
    def save_forecast_atomically(
        product: SellerProduct,
        new_forecast_data: Dict,
        model_type: str
    ) -> Tuple[bool, Optional[ProductForecast], str]:
        """
        Atomically save new forecast with fallback to previous on failure.
        
        Args:
            product: SellerProduct instance
            new_forecast_data: Dictionary with forecast data:
                - demand_forecast_kg
                - demand_lower_bound
                - demand_upper_bound
                - price_forecast
                - price_lower_bound
                - price_upper_bound
                - confidence_level
                - forecast_period
                - rmse_demand (optional)
                - rmse_price (optional)
                - mape_demand (optional)
                - mape_price (optional)
            model_type: Type of model used
            
        Returns:
            Tuple of (success: bool, forecast: ProductForecast or None, message: str)
        """
        try:
            # Get previous current forecast for fallback reference
            previous_forecast = ProductForecast.objects.filter(
                product=product,
                is_current=True
            ).first()
            
            # Mark previous as non-current
            if previous_forecast:
                previous_forecast.is_current = False
                previous_forecast.save(update_fields=['is_current', 'updated_at'])
                logger.info(
                    f"Marked previous forecast {previous_forecast.id} as non-current "
                    f"for product {product.name}"
                )
            
            # Create new forecast
            new_forecast = ProductForecast.objects.create(
                product=product,
                model_type=model_type,
                is_current=True,
                demand_forecast_kg=Decimal(str(new_forecast_data['demand_forecast_kg'])),
                demand_lower_bound=Decimal(str(new_forecast_data['demand_lower_bound'])),
                demand_upper_bound=Decimal(str(new_forecast_data['demand_upper_bound'])),
                price_forecast=Decimal(str(new_forecast_data['price_forecast'])),
                price_lower_bound=Decimal(str(new_forecast_data['price_lower_bound'])),
                price_upper_bound=Decimal(str(new_forecast_data['price_upper_bound'])),
                confidence_level=new_forecast_data['confidence_level'],
                forecast_period=new_forecast_data['forecast_period'],
                rmse_demand=Decimal(str(new_forecast_data.get('rmse_demand', 0))),
                rmse_price=Decimal(str(new_forecast_data.get('rmse_price', 0))),
                mape_demand=Decimal(str(new_forecast_data.get('mape_demand', 0))),
                mape_price=Decimal(str(new_forecast_data.get('mape_price', 0))),
            )
            
            logger.info(
                f"Successfully created new forecast {new_forecast.id} for product "
                f"{product.name} using model {model_type}"
            )
            
            return True, new_forecast, f"Forecast created successfully (model: {model_type})"
        
        except Exception as e:
            # FALLBACK: Revert previous forecast to current if new creation failed
            if previous_forecast:
                try:
                    previous_forecast.is_current = True
                    previous_forecast.save(update_fields=['is_current', 'updated_at'])
                    
                    logger.warning(
                        f"Model training failed for product {product.name}. "
                        f"Reverted to previous forecast {previous_forecast.id}. "
                        f"Error: {str(e)}"
                    )
                    
                    # Create alert about fallback
                    ForecastFallbackManager.create_fallback_alert(
                        product=product,
                        previous_forecast=previous_forecast,
                        reason=str(e),
                        used_fallback=True
                    )
                    
                    return False, previous_forecast, (
                        f"Model training failed. Using previous forecast as fallback. "
                        f"Error: {str(e)}"
                    )
                
                except Exception as revert_error:
                    logger.error(
                        f"Failed to revert to previous forecast: {str(revert_error)}"
                    )
                    return False, None, f"Critical error: {str(revert_error)}"
            else:
                # No previous forecast to fall back to
                logger.error(
                    f"Model training failed and no previous forecast available for "
                    f"product {product.name}: {str(e)}"
                )
                
                ForecastFallbackManager.create_fallback_alert(
                    product=product,
                    previous_forecast=None,
                    reason=str(e),
                    used_fallback=False
                )
                
                return False, None, (
                    f"Model training failed. No previous forecast available. "
                    f"Product marked as INSUFFICIENT_DATA. Error: {str(e)}"
                )
    
    @staticmethod
    def create_fallback_alert(
        product: SellerProduct,
        previous_forecast: Optional[ProductForecast],
        reason: str,
        used_fallback: bool
    ) -> Optional[ForecastAlert]:
        """
        Create alert when model training fails and fallback is used/unavailable.
        
        Args:
            product: SellerProduct that failed
            previous_forecast: Previous forecast being used as fallback (or None)
            reason: Error message/reason for failure
            used_fallback: Whether fallback was successfully used
            
        Returns:
            Created ForecastAlert or None if creation fails
        """
        try:
            if used_fallback:
                alert_message = (
                    f"Model training failed for {product.name}. "
                    f"Using previous forecast from {previous_forecast.forecast_date.date()}. "
                    f"Error: {reason}. "
                    f"Manual refresh recommended."
                )
                severity = AlertSeverity.WARNING
            else:
                alert_message = (
                    f"Model training failed for {product.name} and no previous forecast available. "
                    f"Forecast marked as unavailable. Error: {reason}. "
                    f"Please check data quality and retry manually."
                )
                severity = AlertSeverity.CRITICAL
            
            alert = ForecastAlert.objects.create(
                product=product,
                alert_type=AlertType.MODEL_FAILURE,
                severity=severity,
                message=alert_message,
                related_forecast=previous_forecast,
                metadata={
                    'reason': reason,
                    'used_fallback': used_fallback,
                    'previous_forecast_id': previous_forecast.id if previous_forecast else None,
                    'previous_forecast_date': (
                        previous_forecast.forecast_date.isoformat() 
                        if previous_forecast else None
                    )
                }
            )
            
            logger.info(
                f"Created fallback alert {alert.id} for product {product.name}"
            )
            
            return alert
        
        except Exception as e:
            logger.error(
                f"Failed to create fallback alert for product {product.name}: "
                f"{str(e)}"
            )
            return None
    
    @staticmethod
    def mark_product_unavailable(
        product: SellerProduct,
        reason: str
    ) -> ProductForecast:
        """
        Mark a product as INSUFFICIENT_DATA (no forecast available).
        
        Used when:
        - Model training fails
        - No previous forecast to fall back to
        - Data quality is critically low
        
        Args:
            product: SellerProduct to mark as unavailable
            reason: Reason for marking as unavailable
            
        Returns:
            ProductForecast with INSUFFICIENT_DATA model type
        """
        # Mark previous as non-current
        ProductForecast.objects.filter(
            product=product,
            is_current=True
        ).update(is_current=False)
        
        # Create unavailable forecast
        unavailable_forecast = ProductForecast.objects.create(
            product=product,
            model_type='INSUFFICIENT_DATA',
            is_current=True,
            demand_forecast_kg=Decimal('0'),
            demand_lower_bound=Decimal('0'),
            demand_upper_bound=Decimal('0'),
            price_forecast=Decimal('0'),
            price_lower_bound=Decimal('0'),
            price_upper_bound=Decimal('0'),
            confidence_level='LOW',
            forecast_period='N/A'
        )
        
        logger.warning(
            f"Marked {product.name} as INSUFFICIENT_DATA: {reason}"
        )
        
        return unavailable_forecast
    
    @staticmethod
    def get_fallback_status(product: SellerProduct) -> Dict[str, any]:
        """
        Get fallback/degradation status for a product.
        
        Returns info about:
        - Is current forecast using fallback?
        - When was the last successful model training?
        - How old is the current forecast?
        
        Args:
            product: SellerProduct to check
            
        Returns:
            Dictionary with status information
        """
        current_forecast = ProductForecast.objects.filter(
            product=product,
            is_current=True
        ).first()
        
        if not current_forecast:
            return {
                'product_id': product.id,
                'product_name': product.name,
                'has_forecast': False,
                'using_fallback': False,
                'status': 'No forecast available'
            }
        
        # Check if this is a fallback (INSUFFICIENT_DATA)
        is_unavailable = current_forecast.model_type == 'INSUFFICIENT_DATA'
        
        # Find last successful forecast
        last_successful = ProductForecast.objects.filter(
            product=product,
            is_current=False
        ).exclude(
            model_type='INSUFFICIENT_DATA'
        ).order_by('-forecast_date').first()
        
        return {
            'product_id': product.id,
            'product_name': product.name,
            'has_forecast': True,
            'using_fallback': is_unavailable,
            'current_model_type': current_forecast.model_type,
            'current_forecast_date': current_forecast.forecast_date.isoformat(),
            'last_successful_forecast_date': (
                last_successful.forecast_date.isoformat() if last_successful else None
            ),
            'status': (
                'No forecast available (insufficient data)' if is_unavailable
                else 'Using current forecast'
            )
        }
