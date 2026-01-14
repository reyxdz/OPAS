"""
Hybrid Forecasting Strategy
Combines statistical methods (current) with supervised ML (LSTM/XGBoost)

Strategy:
1. If sufficient data (60+ days): Train ML models + use ensemble
2. If medium data (30-60 days): Use weighted average of statistical + ML
3. If limited data (<30 days): Use statistical methods only with higher uncertainty

This provides a seamless upgrade path from current system to advanced ML.
"""

from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class HybridForecastingStrategy:
    """Intelligently combines statistical and ML forecasting methods"""
    
    # Thresholds for model selection
    MINIMUM_DATA_DAYS = 20
    ML_TRAINING_THRESHOLD = 60  # Min days to train ML models
    STATISTICAL_ONLY_THRESHOLD = 30  # Use only statistical if below this
    
    def __init__(self):
        self.statistical_forecaster = None  # Will use existing ForecastingAlgorithm
        self.ml_ensemble = None  # Will use EnsembleForecaster
        self.ml_available = False
    
    def initialize_ml_models(self):
        """Initialize ML components if available"""
        try:
            from .forecasting_ml import EnsembleForecaster
            self.ml_ensemble = EnsembleForecaster()
            self.ml_available = True
            logger.info("ML forecasting models initialized successfully")
        except Exception as e:
            logger.warning(f"ML models unavailable: {str(e)}")
            self.ml_available = False
    
    def select_forecasting_method(self, sales_data: List[Dict]) -> str:
        """
        Determine which forecasting method(s) to use based on data availability
        
        Args:
            sales_data: Historical sales data
            
        Returns:
            One of: 'ML_ENSEMBLE', 'HYBRID_WEIGHTED', 'STATISTICAL_ONLY', 'INSUFFICIENT_DATA'
        """
        if not sales_data:
            return 'INSUFFICIENT_DATA'
        
        data_points = len(sales_data)
        
        if data_points < self.MINIMUM_DATA_DAYS:
            return 'INSUFFICIENT_DATA'
        elif data_points >= self.ML_TRAINING_THRESHOLD and self.ml_available:
            return 'ML_ENSEMBLE'
        elif data_points >= self.STATISTICAL_ONLY_THRESHOLD:
            return 'STATISTICAL_ONLY'
        else:
            # Between 20-60 days - can try hybrid if ML available
            return 'HYBRID_WEIGHTED' if self.ml_available else 'STATISTICAL_ONLY'
    
    def generate_hybrid_forecast(
        self,
        sales_data: List[Dict],
        current_stock: int,
        min_stock: int,
        forecast_algorithm=None
    ) -> Dict:
        """
        Generate forecast using hybrid strategy
        
        Args:
            sales_data: Historical sales data
            current_stock: Current inventory
            min_stock: Minimum stock level
            forecast_algorithm: Instance of ForecastingAlgorithm
            
        Returns:
            Comprehensive forecast dict
        """
        self.statistical_forecaster = forecast_algorithm
        
        method = self.select_forecasting_method(sales_data)
        
        forecast_result = {
            'forecasting_method': method,
            'data_points_available': len(sales_data),
            'timestamp': datetime.now().isoformat(),
        }
        
        if method == 'INSUFFICIENT_DATA':
            forecast_result.update({
                'forecasted_demand': 0,
                'confidence_score': 0,
                'status': 'INSUFFICIENT_DATA',
                'message': f'Need at least {self.MINIMUM_DATA_DAYS} days of historical data'
            })
        elif method == 'STATISTICAL_ONLY':
            forecast_result.update(
                self.statistical_forecaster.forecast_demand(sales_data, current_stock, min_stock)
            )
            forecast_result['forecasting_method'] = 'STATISTICAL_ONLY'
        elif method == 'HYBRID_WEIGHTED':
            forecast_result.update(
                self._generate_hybrid_weighted_forecast(
                    sales_data, current_stock, min_stock
                )
            )
        elif method == 'ML_ENSEMBLE':
            forecast_result.update(
                self._generate_ml_ensemble_forecast(
                    sales_data, current_stock, min_stock
                )
            )
        
        return forecast_result
    
    def _generate_hybrid_weighted_forecast(
        self,
        sales_data: List[Dict],
        current_stock: int,
        min_stock: int
    ) -> Dict:
        """
        Combine statistical and ML forecasts with weighted averaging
        
        Strategy: 60% statistical (proven), 40% ML (still learning on limited data)
        """
        try:
            # Get statistical forecast
            stat_forecast = self.statistical_forecaster.forecast_demand(
                sales_data, current_stock, min_stock
            )
            
            # Try to get ML forecast
            if self.ml_available and self.ml_ensemble:
                try:
                    self.ml_ensemble.train_all_models(sales_data)
                    ml_pred, model_used = self.ml_ensemble.predict_ensemble(
                        sales_data, 
                        days_ahead=self.statistical_forecaster.forecast_days
                    )
                    
                    if ml_pred:
                        ml_demand = sum(ml_pred)
                        stat_demand = stat_forecast.get('forecasted_demand', 0)
                        
                        # Weighted average: prefer statistical on limited data
                        hybrid_demand = (0.6 * stat_demand + 0.4 * ml_demand)
                        
                        # Increase confidence slightly from ML input
                        stat_confidence = stat_forecast.get('confidence_score', 50)
                        hybrid_confidence = min(100, stat_confidence + 10)
                        
                        return {
                            'forecasted_demand': int(hybrid_demand),
                            'confidence_score': hybrid_confidence,
                            'forecasting_method': f'HYBRID_WEIGHTED(statistical:60%, {model_used}:40%)',
                            'ml_predictions': ml_pred[:7],  # Show first week of ML predictions
                            'statistical_component': stat_demand,
                            'ml_component': ml_demand,
                        } | {k: v for k, v in stat_forecast.items() 
                             if k not in ['forecasted_demand', 'confidence_score', 'forecasting_method']}
                except Exception as e:
                    logger.warning(f"ML ensemble failed in hybrid, using statistical only: {e}")
            
            # Fallback to statistical
            return stat_forecast
        
        except Exception as e:
            logger.error(f"Hybrid forecast generation failed: {e}")
            return {
                'forecasted_demand': 0,
                'confidence_score': 0,
                'status': 'ERROR',
                'message': 'Forecast generation failed'
            }
    
    def _generate_ml_ensemble_forecast(
        self,
        sales_data: List[Dict],
        current_stock: int,
        min_stock: int
    ) -> Dict:
        """
        Generate forecast using ML ensemble with statistical fallback
        
        Strategy: Primary ML ensemble, with statistical as validation baseline
        """
        try:
            if not self.ml_available or not self.ml_ensemble:
                return self.statistical_forecaster.forecast_demand(
                    sales_data, current_stock, min_stock
                )
            
            # Train ML models
            training_results = self.ml_ensemble.train_all_models(sales_data)
            
            # Get ensemble prediction
            ml_pred, model_used = self.ml_ensemble.predict_ensemble(
                sales_data,
                days_ahead=self.statistical_forecaster.forecast_days
            )
            
            if not ml_pred:
                # ML failed, fallback to statistical
                return self.statistical_forecaster.forecast_demand(
                    sales_data, current_stock, min_stock
                )
            
            # Calculate demand from predictions
            ml_demand = sum(ml_pred)
            
            # Get statistical forecast for comparison and validation
            stat_forecast = self.statistical_forecaster.forecast_demand(
                sales_data, current_stock, min_stock
            )
            stat_demand = stat_forecast.get('forecasted_demand', ml_demand)
            
            # Sanity check: if ML prediction differs drastically from statistical,
            # use weighted average instead
            diff_ratio = abs(ml_demand - stat_demand) / max(stat_demand, 1)
            if diff_ratio > 0.5:  # More than 50% difference
                logger.warning(
                    f"ML prediction differs significantly from statistical "
                    f"({ml_demand} vs {stat_demand}), using weighted average"
                )
                ml_demand = (0.7 * ml_demand + 0.3 * stat_demand)
            
            # Extract metrics from training
            ml_metrics = training_results.get('models', {})
            
            # Calculate confidence based on model accuracy
            ml_confidence = self._calculate_ml_confidence(ml_metrics)
            stat_confidence = stat_forecast.get('confidence_score', 50)
            
            # Final confidence is average of both
            final_confidence = (ml_confidence + stat_confidence) / 2
            
            return {
                'forecasted_demand': int(ml_demand),
                'confidence_score': final_confidence,
                'forecasting_method': model_used,
                'ml_metrics': ml_metrics,
                'ml_predictions': ml_pred[:7],  # Show first week
                'statistical_baseline': stat_demand,
                'training_results': training_results,
            } | {k: v for k, v in stat_forecast.items() 
                 if k not in ['forecasted_demand', 'confidence_score', 'forecasting_method']}
        
        except Exception as e:
            logger.error(f"ML ensemble forecast failed: {e}")
            # Fall back to statistical
            return self.statistical_forecaster.forecast_demand(
                sales_data, current_stock, min_stock
            )
    
    @staticmethod
    def _calculate_ml_confidence(ml_metrics: Dict) -> float:
        """
        Calculate confidence score from ML model metrics
        
        Args:
            ml_metrics: Training metrics from ML models
            
        Returns:
            Confidence score (0-100)
        """
        confidence = 70  # Base confidence for ML models
        
        # Adjust based on MAPE (Mean Absolute Percentage Error)
        for model_name, metrics in ml_metrics.items():
            if isinstance(metrics, dict) and metrics.get('status') == 'success':
                mape = metrics.get('test_mape', 0.3)
                
                if mape < 0.1:
                    confidence = min(100, confidence + 15)
                elif mape < 0.2:
                    confidence = min(100, confidence + 10)
                elif mape < 0.5:
                    confidence = min(100, confidence + 5)
                elif mape > 1.0:
                    confidence = max(30, confidence - 20)
        
        return round(confidence, 2)


# Integration helper for existing forecasting views
def create_hybrid_forecaster():
    """Factory function to create hybrid forecaster"""
    strategy = HybridForecastingStrategy()
    strategy.initialize_ml_models()
    return strategy
