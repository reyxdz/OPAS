"""
Evaluate Forecasting Models Performance - Accuracy and F1 Score Analysis

This script evaluates the performance of SARIMA, ARIMA, and SIMPLE forecasting models
in terms of:
- Accuracy (based on MAPE - Mean Absolute Percentage Error)
- F1 Score (classification-based accuracy if demand is above/below threshold)
- RMSE, MAE metrics
- Model comparison and ranking

Usage:
    python evaluate_forecasting_models.py
    
Or import in Django shell:
    python manage.py shell
    exec(open('evaluate_forecasting_models.py').read())
"""

import os
import sys
import django
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Tuple, List
import logging

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.utils import timezone
from apps.users.models import SellerProduct
from apps.forecasting.models import HistoricalTransactions
from apps.forecasting.services.forecasting_service import ForecastingService
from apps.forecasting.services.model_validator import ModelValidator
from apps.forecasting.services.enhanced_forecasting_service import EnhancedForecastingService
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
from sklearn.metrics import confusion_matrix, classification_report

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ForecastModelEvaluator:
    """Comprehensive evaluation of forecasting models"""
    
    def __init__(self):
        self.forecasting_service = ForecastingService()
        self.enhanced_service = EnhancedForecastingService()
        self.validator = ModelValidator()
        self.results = {}
    
    def calculate_accuracy_from_mape(self, mape: float) -> float:
        """
        Convert MAPE to accuracy percentage.
        
        Accuracy = 100 - MAPE
        - MAPE < 10%: Excellent (90%+ accuracy)
        - MAPE 10-20%: Good (80-90% accuracy)
        - MAPE 20-30%: Fair (70-80% accuracy)
        - MAPE > 30%: Poor (< 70% accuracy)
        
        Args:
            mape: Mean Absolute Percentage Error (0-100)
        
        Returns:
            Accuracy percentage (0-100)
        """
        return max(0, 100 - mape)
    
    def calculate_f1_score(self, actual: np.ndarray, predicted: np.ndarray, 
                          threshold: float = None) -> float:
        """
        Calculate F1 score for demand forecasting.
        
        Classification task: Is demand above or below a threshold?
        - Threshold can be median, mean, or specified value
        
        Args:
            actual: Actual demand values
            predicted: Predicted demand values
            threshold: Classification threshold (default: median of actual)
        
        Returns:
            F1 score (0-1)
        """
        if threshold is None:
            threshold = np.median(actual)
        
        # Binary classification: above/below threshold
        actual_binary = (actual >= threshold).astype(int)
        predicted_binary = (predicted >= threshold).astype(int)
        
        try:
            f1 = f1_score(actual_binary, predicted_binary, zero_division=0)
            return f1
        except Exception as e:
            logger.warning(f"Error calculating F1 score: {e}")
            return 0.0
    
    def evaluate_product(self, product_id: int) -> Dict:
        """
        Evaluate forecasting models for a specific product.
        
        Args:
            product_id: ID of the product to evaluate
        
        Returns:
            Dictionary with evaluation results for all three models
        """
        try:
            product = SellerProduct.objects.get(id=product_id)
            logger.info(f"Evaluating product: {product.name} (ID: {product_id})")
            
            # Get historical data
            cutoff_date = timezone.now().date() - timedelta(days=180)
            transactions = HistoricalTransactions.objects.filter(
                product=product,
                transaction_date__gte=cutoff_date
            ).order_by('transaction_date').values('quantity_sold_kg', 'average_price_per_kg')
            
            if not transactions.exists():
                logger.warning(f"No historical data for product {product_id}")
                return {'error': 'Insufficient data', 'product_id': product_id}
            
            # Convert to series
            df = pd.DataFrame(list(transactions))
            demand_series = pd.Series(df['quantity_sold_kg'].values)
            
            if len(demand_series) < 5:
                logger.warning(f"Product {product_id} has only {len(demand_series)} data points")
                return {
                    'product_id': product_id,
                    'product_name': product.name,
                    'data_points': len(demand_series),
                    'error': 'Insufficient data (need 5+)'
                }
            
            # Split data: 80% train, 20% test
            train_size = int(len(demand_series) * 0.8)
            train_data = demand_series[:train_size]
            test_data = demand_series[train_size:]
            
            logger.info(f"Data split: {len(train_data)} train, {len(test_data)} test")
            
            # Evaluate each model
            models_results = {
                'SARIMA': self._evaluate_sarima(train_data, test_data),
                'ARIMA': self._evaluate_arima(train_data, test_data),
                'SIMPLE': self._evaluate_simple(train_data, test_data),
            }
            
            # Calculate F1 scores
            for model_name, metrics in models_results.items():
                if 'predictions' in metrics and 'actuals' in metrics:
                    f1 = self.calculate_f1_score(
                        np.array(metrics['actuals']),
                        np.array(metrics['predictions'])
                    )
                    metrics['f1_score'] = round(f1, 4)
                    metrics['accuracy'] = round(self.calculate_accuracy_from_mape(
                        metrics.get('mape', 50)
                    ), 2)
            
            # Find best model by MAPE
            best_model = min(
                models_results.items(),
                key=lambda x: x[1].get('mape', float('inf'))
            )
            
            result = {
                'product_id': product_id,
                'product_name': product.name,
                'data_points': len(demand_series),
                'evaluation_date': datetime.now().isoformat(),
                'models': models_results,
                'best_model': best_model[0],
                'best_model_mape': round(best_model[1].get('mape', 0), 2),
                'best_model_accuracy': round(best_model[1].get('accuracy', 0), 2),
                'best_model_f1': round(best_model[1].get('f1_score', 0), 4),
            }
            
            return result
        
        except Exception as e:
            logger.error(f"Error evaluating product {product_id}: {e}")
            return {'error': str(e), 'product_id': product_id}
    
    def _evaluate_sarima(self, train_data: pd.Series, test_data: pd.Series) -> Dict:
        """Evaluate SARIMA model"""
        try:
            logger.info("Evaluating SARIMA model...")
            from pmdarima import auto_arima
            from statsmodels.tsa.statespace.sarimax import SARIMAX
            
            # Auto-select parameters
            auto_model = auto_arima(
                train_data,
                seasonal=True,
                m=4 if len(train_data) >= 16 else 1,
                stepwise=True,
                suppress_warnings=True,
                error_action='ignore',
                max_p=3, max_d=2, max_q=3,
                trace=False
            )
            
            # Fit model
            model = SARIMAX(
                train_data,
                order=auto_model.order,
                seasonal_order=auto_model.seasonal_order,
                enforce_stationarity=False,
                enforce_invertibility=False
            )
            results = model.fit(disp=False, maxiter=200)
            
            # Predict on test set
            predictions = results.forecast(steps=len(test_data))
            actuals = test_data.values
            
            # Calculate metrics
            mape = self._calculate_mape(actuals, predictions)
            rmse = self._calculate_rmse(actuals, predictions)
            mae = self._calculate_mae(actuals, predictions)
            
            return {
                'mape': round(mape, 2),
                'rmse': round(rmse, 2),
                'mae': round(mae, 2),
                'predictions': predictions.tolist(),
                'actuals': actuals.tolist(),
                'status': 'success',
                'parameters': f"order={auto_model.order}, seasonal={auto_model.seasonal_order}"
            }
        
        except Exception as e:
            logger.warning(f"SARIMA evaluation failed: {e}")
            return {'status': 'failed', 'error': str(e), 'mape': 999}
    
    def _evaluate_arima(self, train_data: pd.Series, test_data: pd.Series) -> Dict:
        """Evaluate ARIMA model"""
        try:
            logger.info("Evaluating ARIMA model...")
            from pmdarima import auto_arima
            from statsmodels.tsa.arima.model import ARIMA
            
            # Auto-select parameters
            auto_model = auto_arima(
                train_data,
                seasonal=False,
                stepwise=True,
                suppress_warnings=True,
                error_action='ignore',
                max_p=3, max_d=2, max_q=3,
                trace=False
            )
            
            # Fit model
            model = ARIMA(train_data, order=auto_model.order)
            results = model.fit()
            
            # Predict on test set
            predictions = results.forecast(steps=len(test_data))
            actuals = test_data.values
            
            # Calculate metrics
            mape = self._calculate_mape(actuals, predictions)
            rmse = self._calculate_rmse(actuals, predictions)
            mae = self._calculate_mae(actuals, predictions)
            
            return {
                'mape': round(mape, 2),
                'rmse': round(rmse, 2),
                'mae': round(mae, 2),
                'predictions': predictions.tolist(),
                'actuals': actuals.tolist(),
                'status': 'success',
                'parameters': f"order={auto_model.order}"
            }
        
        except Exception as e:
            logger.warning(f"ARIMA evaluation failed: {e}")
            return {'status': 'failed', 'error': str(e), 'mape': 999}
    
    def _evaluate_simple(self, train_data: pd.Series, test_data: pd.Series) -> Dict:
        """Evaluate Simple Exponential Smoothing model"""
        try:
            logger.info("Evaluating SIMPLE (Exponential Smoothing) model...")
            from statsmodels.tsa.holtwinters import ExponentialSmoothing
            
            # Fit model
            model = ExponentialSmoothing(
                train_data,
                trend='add' if len(train_data) >= 5 else None,
                seasonal=None
            )
            results = model.fit(optimized=True)
            
            # Predict on test set
            predictions = results.forecast(steps=len(test_data))
            actuals = test_data.values
            
            # Calculate metrics
            mape = self._calculate_mape(actuals, predictions)
            rmse = self._calculate_rmse(actuals, predictions)
            mae = self._calculate_mae(actuals, predictions)
            
            return {
                'mape': round(mape, 2),
                'rmse': round(rmse, 2),
                'mae': round(mae, 2),
                'predictions': predictions.tolist(),
                'actuals': actuals.tolist(),
                'status': 'success',
                'parameters': 'Exponential Smoothing'
            }
        
        except Exception as e:
            logger.warning(f"SIMPLE evaluation failed: {e}")
            return {'status': 'failed', 'error': str(e), 'mape': 999}
    
    @staticmethod
    def _calculate_mape(actual: np.ndarray, predicted: np.ndarray) -> float:
        """Calculate Mean Absolute Percentage Error"""
        actual = np.array(actual)
        predicted = np.array(predicted)
        
        # Avoid division by zero
        mask = actual != 0
        if np.sum(mask) == 0:
            return 0.0
        
        mape = np.mean(np.abs((actual[mask] - predicted[mask]) / actual[mask])) * 100
        return mape
    
    @staticmethod
    def _calculate_rmse(actual: np.ndarray, predicted: np.ndarray) -> float:
        """Calculate Root Mean Squared Error"""
        actual = np.array(actual)
        predicted = np.array(predicted)
        rmse = np.sqrt(np.mean((actual - predicted) ** 2))
        return rmse
    
    @staticmethod
    def _calculate_mae(actual: np.ndarray, predicted: np.ndarray) -> float:
        """Calculate Mean Absolute Error"""
        actual = np.array(actual)
        predicted = np.array(predicted)
        mae = np.mean(np.abs(actual - predicted))
        return mae
    
    def evaluate_all_products(self, limit: int = None) -> List[Dict]:
        """
        Evaluate all active products.
        
        Args:
            limit: Maximum number of products to evaluate (None for all)
        
        Returns:
            List of evaluation results
        """
        products = SellerProduct.objects.filter(
            is_deleted=False,
            status='ACTIVE'
        )
        
        if limit:
            products = products[:limit]
        
        logger.info(f"Evaluating {products.count()} products...")
        
        results = []
        for i, product in enumerate(products, 1):
            logger.info(f"[{i}/{products.count()}] Evaluating {product.name}...")
            result = self.evaluate_product(product.id)
            results.append(result)
        
        return results
    
    def print_summary(self, results: List[Dict]):
        """Print evaluation summary"""
        print("\n" + "=" * 100)
        print("FORECASTING MODELS EVALUATION SUMMARY")
        print("=" * 100)
        
        successful = [r for r in results if 'models' in r]
        failed = [r for r in results if 'error' in r]
        
        print(f"\nTotal Evaluated: {len(results)}")
        print(f"Successful: {len(successful)}")
        print(f"Failed: {len(failed)}")
        
        if successful:
            print("\n" + "-" * 100)
            print("DETAILED RESULTS BY PRODUCT")
            print("-" * 100)
            
            for result in successful[:10]:  # Show top 10
                print(f"\nProduct: {result['product_name']} (ID: {result['product_id']})")
                print(f"Data Points: {result['data_points']}")
                print(f"Best Model: {result['best_model']} (MAPE: {result['best_model_mape']}%)")
                print(f"  - Accuracy: {result['best_model_accuracy']}%")
                print(f"  - F1 Score: {result['best_model_f1']}")
                
                print("\nModel Comparison:")
                for model_name, metrics in result['models'].items():
                    if metrics.get('status') == 'success':
                        print(f"  {model_name}:")
                        print(f"    - MAPE: {metrics['mape']}%")
                        print(f"    - Accuracy: {metrics.get('accuracy', 0)}%")
                        print(f"    - F1 Score: {metrics.get('f1_score', 0)}")
                        print(f"    - RMSE: {metrics['rmse']}")
                        print(f"    - MAE: {metrics['mae']}")
        
        print("\n" + "=" * 100)


def main():
    """Main execution"""
    logger.info("Starting Forecasting Models Evaluation...")
    
    evaluator = ForecastModelEvaluator()
    
    # Evaluate all products (limit to 5 for demo, change to None for all)
    results = evaluator.evaluate_all_products(limit=5)
    
    # Print summary
    evaluator.print_summary(results)
    
    # Save results to file
    import json
    output_file = 'forecast_model_evaluation_results.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    logger.info(f"Evaluation complete. Results saved to {output_file}")
    
    # Calculate aggregate statistics
    successful = [r for r in results if 'models' in r]
    if successful:
        print("\n" + "=" * 100)
        print("AGGREGATE STATISTICS")
        print("=" * 100)
        
        for model_name in ['SARIMA', 'ARIMA', 'SIMPLE']:
            mapes = [r['models'][model_name]['mape'] 
                    for r in successful 
                    if model_name in r['models'] and r['models'][model_name].get('status') == 'success']
            
            f1_scores = [r['models'][model_name].get('f1_score', 0) 
                        for r in successful 
                        if model_name in r['models'] and r['models'][model_name].get('status') == 'success']
            
            if mapes:
                avg_mape = np.mean(mapes)
                avg_accuracy = 100 - avg_mape
                avg_f1 = np.mean(f1_scores) if f1_scores else 0
                
                print(f"\n{model_name}:")
                print(f"  - Avg MAPE: {avg_mape:.2f}%")
                print(f"  - Avg Accuracy: {avg_accuracy:.2f}%")
                print(f"  - Avg F1 Score: {avg_f1:.4f}")


if __name__ == '__main__':
    main()
