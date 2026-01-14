"""
Stale Forecast Manager - Detects and handles outdated forecasts.

Functionality:
- Detect forecasts older than 7 days
- Flag stale forecasts in database
- Create alerts for outdated predictions
- Suggest refresh actions to admins

Author: OPAS System
Created: December 2025
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Tuple
from django.utils import timezone

from apps.forecasting.models import (
    ProductForecast,
    ForecastAlert,
    AlertType,
    AlertSeverity,
)

logger = logging.getLogger(__name__)


class StaleForecastManager:
    """
    Manages detection and handling of stale (outdated) forecasts.
    
    A forecast is considered stale if:
    - It was generated more than 7 days ago
    - The forecast period has passed
    - New data suggests significant changes
    """
    
    # Default staleness threshold (days)
    STALENESS_THRESHOLD_DAYS = 7
    
    @staticmethod
    def mark_stale_forecasts(threshold_days: int = None) -> Dict[str, any]:
        """
        Find and mark all stale forecasts in the system.
        
        Args:
            threshold_days: Days before forecast is considered stale (default: 7)
            
        Returns:
            Dictionary with results:
                - stale_count: Number of stale forecasts found
                - alerts_created: Number of alerts created
                - products_affected: List of affected product IDs
        """
        if threshold_days is None:
            threshold_days = StaleForecastManager.STALENESS_THRESHOLD_DAYS
        
        now = timezone.now()
        cutoff_date = now - timedelta(days=threshold_days)
        
        logger.info(f"Checking for stale forecasts (older than {threshold_days} days)")
        
        # Find stale forecasts
        stale_forecasts = ProductForecast.objects.filter(
            forecast_date__lt=cutoff_date,
            is_current=True
        ).select_related('product')
        
        stale_count = stale_forecasts.count()
        alerts_created = 0
        products_affected = []
        
        if stale_count == 0:
            logger.info("No stale forecasts found")
            return {
                'stale_count': 0,
                'alerts_created': 0,
                'products_affected': []
            }
        
        logger.warning(f"Found {stale_count} stale forecasts")
        
        # Create alerts for each stale forecast
        for forecast in stale_forecasts:
            try:
                # Check if alert already exists
                existing_alert = ForecastAlert.objects.filter(
                    product=forecast.product,
                    alert_type=AlertType.ANOMALY,
                    is_acknowledged=False,
                    created_at__date=now.date()
                ).exists()
                
                if not existing_alert:
                    days_old = (now - forecast.forecast_date).days
                    
                    alert = ForecastAlert.objects.create(
                        product=forecast.product,
                        alert_type=AlertType.ANOMALY,
                        severity=AlertSeverity.WARNING if days_old < 14 else AlertSeverity.CRITICAL,
                        message=f'Forecast is {days_old} days old. Please refresh for updated predictions.',
                        related_forecast=forecast,
                        metadata={
                            'days_old': days_old,
                            'forecast_id': forecast.id,
                            'last_update': forecast.forecast_date.isoformat(),
                            'reason': 'stale_forecast'
                        }
                    )
                    
                    alerts_created += 1
                    products_affected.append(forecast.product.id)
                    
                    logger.info(
                        f"Created stale forecast alert for {forecast.product.name} "
                        f"({days_old} days old)"
                    )
            
            except Exception as e:
                logger.error(
                    f"Error creating stale forecast alert for product {forecast.product.id}: "
                    f"{str(e)}"
                )
        
        logger.info(
            f"Stale forecast check complete: {stale_count} stale, "
            f"{alerts_created} alerts created, {len(products_affected)} products affected"
        )
        
        return {
            'stale_count': stale_count,
            'alerts_created': alerts_created,
            'products_affected': list(set(products_affected))  # Deduplicate
        }
    
    @staticmethod
    def is_forecast_stale(forecast: ProductForecast, threshold_days: int = None) -> bool:
        """
        Check if a single forecast is stale.
        
        Args:
            forecast: ProductForecast instance
            threshold_days: Days before considered stale (default: 7)
            
        Returns:
            Boolean indicating if forecast is stale
        """
        if threshold_days is None:
            threshold_days = StaleForecastManager.STALENESS_THRESHOLD_DAYS
        
        now = timezone.now()
        age = (now - forecast.forecast_date).days
        
        return age >= threshold_days
    
    @staticmethod
    def get_staleness_info(forecast: ProductForecast) -> Dict[str, any]:
        """
        Get detailed staleness information for a forecast.
        
        Args:
            forecast: ProductForecast instance
            
        Returns:
            Dictionary with:
                - is_stale: Boolean
                - days_old: Age in days
                - needs_refresh: Boolean (true if older than threshold)
                - suggested_action: String message for admin
                - last_update: Datetime of forecast
        """
        now = timezone.now()
        age = (now - forecast.forecast_date).days
        is_stale = age >= StaleForecastManager.STALENESS_THRESHOLD_DAYS
        
        if age < 3:
            suggested_action = "Recent forecast - no action needed"
            severity = "good"
        elif age < 7:
            suggested_action = "Forecast is getting old. Plan to refresh soon."
            severity = "caution"
        elif age < 14:
            suggested_action = "⚠️ Forecast is stale (> 7 days). Please refresh."
            severity = "warning"
        else:
            suggested_action = "🔴 Forecast is very outdated (> 2 weeks). URGENT REFRESH NEEDED."
            severity = "critical"
        
        return {
            'is_stale': is_stale,
            'days_old': age,
            'needs_refresh': is_stale,
            'suggested_action': suggested_action,
            'severity': severity,
            'last_update': forecast.forecast_date,
            'refresh_recommended_by': (
                forecast.forecast_date + timedelta(days=StaleForecastManager.STALENESS_THRESHOLD_DAYS)
            )
        }
    
    @staticmethod
    def get_stale_forecast_report() -> Dict[str, any]:
        """
        Generate a complete report of all stale forecasts.
        
        Returns:
            Dictionary with:
                - total_forecasts: Total forecasts in system
                - stale_forecasts: Number stale
                - stale_percentage: Percentage stale
                - by_severity: Breakdown by age
                - recommendations: Action items for admin
        """
        now = timezone.now()
        
        # Get all current forecasts
        all_forecasts = ProductForecast.objects.filter(is_current=True)
        total = all_forecasts.count()
        
        if total == 0:
            return {
                'total_forecasts': 0,
                'stale_forecasts': 0,
                'stale_percentage': 0,
                'by_severity': {},
                'recommendations': ['No forecasts exist yet.']
            }
        
        # Categorize by age
        very_old = all_forecasts.filter(
            forecast_date__lt=now - timedelta(days=14)
        ).count()
        
        old = all_forecasts.filter(
            forecast_date__lt=now - timedelta(days=7),
            forecast_date__gte=now - timedelta(days=14)
        ).count()
        
        recent = all_forecasts.filter(
            forecast_date__lt=now - timedelta(days=3),
            forecast_date__gte=now - timedelta(days=7)
        ).count()
        
        fresh = all_forecasts.filter(
            forecast_date__gte=now - timedelta(days=3)
        ).count()
        
        stale_count = very_old + old
        stale_percentage = (stale_count / total * 100) if total > 0 else 0
        
        # Generate recommendations
        recommendations = []
        if very_old > 0:
            recommendations.append(
                f'🔴 URGENT: {very_old} forecasts are >14 days old. Regenerate immediately.'
            )
        if old > 0:
            recommendations.append(
                f'⚠️ {old} forecasts are 7-14 days old. Refresh recommended.'
            )
        if stale_percentage > 50:
            recommendations.append(
                'Consider setting up automatic weekly forecast refreshes via Celery.'
            )
        if len(recommendations) == 0:
            recommendations.append('✅ All forecasts are recent and up-to-date!')
        
        return {
            'total_forecasts': total,
            'stale_forecasts': stale_count,
            'stale_percentage': round(stale_percentage, 1),
            'by_severity': {
                'very_old_gt_14_days': very_old,
                'old_7_to_14_days': old,
                'recent_3_to_7_days': recent,
                'fresh_lt_3_days': fresh
            },
            'recommendations': recommendations,
            'generated_at': now.isoformat()
        }
