"""
Evaluate Forecasting Models Performance Using Actual Forecast Data

This script evaluates model performance by:
1. Comparing predicted values (from ProductForecast) with actual historical data
2. Calculating MAPE, RMSE, MAE accuracy metrics
3. Computing F1 scores for demand classification
4. Ranking models by performance

Data sources:
- ProductForecast: Contains model predictions (SARIMA, ARIMA, SIMPLE)
- MarketHistoricalData: Historical market data for comparison

Usage:
    python evaluate_models_with_actual_data.py
"""

import os
import sys
import django
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Tuple, List
import logging
import json

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.utils import timezone
from django.db.models import Count, Avg
from apps.forecasting.models import ProductForecast, MarketHistoricalData
from sklearn.metrics import f1_score

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ModelPerformanceEvaluator:
    """Evaluate forecasting models using actual forecast data"""
    
    def __init__(self):
        self.results = {}
        self.all_results = []
    
    @staticmethod
    def calculate_mape(actual: np.ndarray, predicted: np.ndarray) -> float:
        """Calculate Mean Absolute Percentage Error"""
        actual = np.array(actual, dtype=float)
        predicted = np.array(predicted, dtype=float)
        
        # Avoid division by zero
        mask = actual != 0
        if np.sum(mask) == 0:
            return 0.0
        
        mape = np.mean(np.abs((actual[mask] - predicted[mask]) / actual[mask])) * 100
        return float(mape)
    
    @staticmethod
    def calculate_rmse(actual: np.ndarray, predicted: np.ndarray) -> float:
        """Calculate Root Mean Squared Error"""
        actual = np.array(actual, dtype=float)
        predicted = np.array(predicted, dtype=float)
        rmse = np.sqrt(np.mean((actual - predicted) ** 2))
        return float(rmse)
    
    @staticmethod
    def calculate_mae(actual: np.ndarray, predicted: np.ndarray) -> float:
        """Calculate Mean Absolute Error"""
        actual = np.array(actual, dtype=float)
        predicted = np.array(predicted, dtype=float)
        mae = np.mean(np.abs(actual - predicted))
        return float(mae)
    
    @staticmethod
    def calculate_f1(actual: np.ndarray, predicted: np.ndarray, threshold=None) -> float:
        """
        Calculate F1 score for demand classification.
        Binary classification: Above or below threshold (median)
        """
        actual = np.array(actual, dtype=float)
        predicted = np.array(predicted, dtype=float)
        
        if threshold is None:
            threshold = np.median(actual)
        
        # Binary classification
        actual_binary = (actual >= threshold).astype(int)
        predicted_binary = (predicted >= threshold).astype(int)
        
        try:
            f1 = f1_score(actual_binary, predicted_binary, zero_division=0)
            return float(f1)
        except Exception as e:
            logger.warning(f"Error calculating F1: {e}")
            return 0.0
    
    def evaluate_by_market_product(self) -> Dict:
        """
        Evaluate models for each market product.
        Compare forecasts with historical market data.
        """
        print("\n" + "=" * 100)
        print("EVALUATING MODELS BY MARKET PRODUCT")
        print("=" * 100)
        
        # Get unique market products
        market_products = MarketHistoricalData.objects.values_list(
            'product_name', flat=True
        ).distinct().order_by('product_name')
        
        logger.info(f"Found {market_products.count()} market products")
        
        results = []
        
        for product_name in market_products:
            try:
                logger.info(f"Evaluating {product_name}...")
                
                # Get market data
                market_data = MarketHistoricalData.objects.filter(
                    product_name=product_name
                ).order_by('market_date').values('market_date', 'quantity_kg', 'price_per_kg')
                
                if not market_data.exists():
                    logger.warning(f"No market data for {product_name}")
                    continue
                
                market_df = pd.DataFrame(list(market_data))
                actual_demand = market_df['quantity_kg'].values
                
                if len(actual_demand) < 5:
                    logger.warning(f"{product_name} has only {len(actual_demand)} data points")
                    continue
                
                # Get forecasts
                forecasts = ProductForecast.objects.filter(
                    product__name__icontains=product_name
                ).values('model_type', 'demand_forecast_kg').order_by('forecast_date')
                
                if not forecasts.exists():
                    # Try to find by exact name in market historical data
                    logger.info(f"No direct forecasts found for {product_name}")
                    continue
                
                # Evaluate each model
                model_results = {}
                
                for model_type in ['SARIMA', 'ARIMA', 'SIMPLE']:
                    model_forecasts = list(
                        forecasts.filter(model_type=model_type)
                        .values_list('demand_forecast_kg', flat=True)[:len(actual_demand)]
                    )
                    
                    if len(model_forecasts) < 3:
                        logger.warning(f"Not enough {model_type} forecasts for {product_name}")
                        model_results[model_type] = {
                            'status': 'insufficient_data',
                            'count': len(model_forecasts)
                        }
                        continue
                    
                    # Pad if necessary
                    if len(model_forecasts) < len(actual_demand):
                        model_forecasts += [np.mean(model_forecasts)] * (len(actual_demand) - len(model_forecasts))
                    else:
                        model_forecasts = model_forecasts[:len(actual_demand)]
                    
                    # Calculate metrics
                    mape = self.calculate_mape(actual_demand, model_forecasts)
                    rmse = self.calculate_rmse(actual_demand, model_forecasts)
                    mae = self.calculate_mae(actual_demand, model_forecasts)
                    f1 = self.calculate_f1(actual_demand, model_forecasts)
                    accuracy = max(0, 100 - mape)  # Accuracy = 100 - MAPE
                    
                    model_results[model_type] = {
                        'mape': round(mape, 2),
                        'accuracy': round(accuracy, 2),
                        'rmse': round(rmse, 2),
                        'mae': round(mae, 2),
                        'f1_score': round(f1, 4),
                        'forecast_count': len(model_forecasts),
                        'status': 'success'
                    }
                
                # Find best model
                successful_models = {
                    m: r for m, r in model_results.items()
                    if r.get('status') == 'success'
                }
                
                if successful_models:
                    best_model = min(
                        successful_models.items(),
                        key=lambda x: x[1]['mape']
                    )
                    
                    result = {
                        'product_name': product_name,
                        'data_points': len(actual_demand),
                        'evaluation_date': datetime.now().isoformat(),
                        'models': model_results,
                        'best_model': best_model[0],
                        'best_mape': best_model[1]['mape'],
                        'best_accuracy': best_model[1]['accuracy'],
                        'best_f1': best_model[1]['f1_score']
                    }
                    
                    results.append(result)
            
            except Exception as e:
                logger.error(f"Error evaluating {product_name}: {e}")
        
        return results
    
    def print_results(self, results: List[Dict]):
        """Print evaluation results"""
        print("\n" + "=" * 100)
        print("MODEL PERFORMANCE EVALUATION RESULTS")
        print("=" * 100)
        
        if not results:
            print("No evaluation results available.")
            return
        
        print(f"\nTotal Products Evaluated: {len(results)}")
        
        # Print individual results
        for result in results:
            print("\n" + "-" * 100)
            print(f"Product: {result['product_name']}")
            print(f"Data Points: {result['data_points']}")
            print(f"Best Model: {result['best_model']} (MAPE: {result['best_mape']}%)")
            
            print("\nDETAILED MODEL COMPARISON:")
            print(f"{'Model':<10} {'MAPE (%)':<12} {'Accuracy (%)':<15} {'RMSE':<10} {'MAE':<10} {'F1 Score':<10}")
            print("-" * 70)
            
            for model_name, metrics in result['models'].items():
                if metrics.get('status') == 'success':
                    print(f"{model_name:<10} {metrics['mape']:<12.2f} {metrics['accuracy']:<15.2f} "
                          f"{metrics['rmse']:<10.2f} {metrics['mae']:<10.2f} {metrics['f1_score']:<10.4f}")
                else:
                    print(f"{model_name:<10} {'N/A':<12} {'N/A':<15} {'N/A':<10} {'N/A':<10} {'N/A':<10}")
        
        # Print aggregate statistics
        print("\n" + "=" * 100)
        print("AGGREGATE STATISTICS")
        print("=" * 100)
        
        for model_name in ['SARIMA', 'ARIMA', 'SIMPLE']:
            mapes = [
                r['models'][model_name]['mape']
                for r in results
                if model_name in r['models'] and r['models'][model_name].get('status') == 'success'
            ]
            
            accuracies = [
                r['models'][model_name]['accuracy']
                for r in results
                if model_name in r['models'] and r['models'][model_name].get('status') == 'success'
            ]
            
            f1_scores = [
                r['models'][model_name]['f1_score']
                for r in results
                if model_name in r['models'] and r['models'][model_name].get('status') == 'success'
            ]
            
            if mapes:
                print(f"\n{model_name}:")
                print(f"  Avg MAPE:     {np.mean(mapes):.2f}%")
                print(f"  Avg Accuracy: {np.mean(accuracies):.2f}%")
                print(f"  Avg F1 Score: {np.mean(f1_scores):.4f}")
                print(f"  Min MAPE:     {np.min(mapes):.2f}%")
                print(f"  Max MAPE:     {np.max(mapes):.2f}%")
    
    def save_to_file(self, results: List[Dict], filename: str = 'model_evaluation_results.json'):
        """Save results to JSON file"""
        with open(filename, 'w') as f:
            json.dump(results, f, indent=2, default=str)
        logger.info(f"Results saved to {filename}")


def main():
    """Main execution"""
    logger.info("Starting Model Performance Evaluation...")
    
    evaluator = ModelPerformanceEvaluator()
    
    # Evaluate by market product
    results = evaluator.evaluate_by_market_product()
    
    # Print results
    evaluator.print_results(results)
    
    # Save to file
    evaluator.save_to_file(results)
    
    logger.info("Evaluation complete!")


if __name__ == '__main__':
    main()
