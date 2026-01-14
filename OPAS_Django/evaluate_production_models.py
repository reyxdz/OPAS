"""
Evaluate Forecasting Models Using Actual ProductForecast Data

This script evaluates model performance by analyzing the actual forecasts
stored in the ProductForecast table and comparing model types to determine
which models are generating the best predictions.

Data sources:
- ProductForecast: Contains actual model predictions (SARIMA, ARIMA, SIMPLE)
- SellerProduct: Links to products being forecasted

Usage:
    python evaluate_production_models.py
"""

import os
import sys
import django
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from collections import defaultdict
import logging
import json

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.utils import timezone
from django.db.models import Count, Avg, Min, Max
from apps.forecasting.models import ProductForecast
from apps.users.seller_models import SellerProduct

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ProductionModelEvaluator:
    """Evaluate forecasting models using production forecast data"""
    
    def __init__(self):
        self.results = {}
        self.all_model_stats = {}
    
    def evaluate_model_distribution(self):
        """Analyze model selection patterns and confidence metrics"""
        print("\n" + "=" * 100)
        print("PRODUCTION MODEL ANALYSIS")
        print("=" * 100)
        
        # Get all forecasts
        forecasts = ProductForecast.objects.all()
        total_forecasts = forecasts.count()
        
        print(f"\nTotal Forecasts in System: {total_forecasts}")
        
        # Count by model type
        model_counts = forecasts.values('model_type').annotate(count=Count('id')).order_by('-count')
        
        print("\nModel Usage Distribution:")
        print("-" * 50)
        for model in model_counts:
            percentage = (model['count'] / total_forecasts) * 100
            print(f"  {model['model_type']:<10}: {model['count']:<5} forecasts ({percentage:.2f}%)")
        
        # Get model statistics
        print("\nModel Confidence Statistics:")
        print("-" * 50)
        
        for model in ['SARIMA', 'ARIMA', 'SIMPLE']:
            model_forecasts = forecasts.filter(model_type=model)
            
            if not model_forecasts.exists():
                print(f"  {model}: No forecasts found")
                continue
            
            stats = model_forecasts.aggregate(
                avg_demand=Avg('demand_forecast_kg'),
                min_demand=Min('demand_forecast_kg'),
                max_demand=Max('demand_forecast_kg'),
                avg_lower_ci=Avg('demand_lower_bound'),
                avg_upper_ci=Avg('demand_upper_bound'),
                count=Count('id')
            )
            
            # Calculate std using numpy
            demands = list(model_forecasts.values_list('demand_forecast_kg', flat=True))
            std_demand = np.std(demands) if demands else 0
            
            avg_ci_width = (stats['avg_upper_ci'] - stats['avg_lower_ci']) if stats['avg_upper_ci'] else 0
            avg_confidence = 100 - (avg_ci_width / stats['avg_demand'] * 100) if stats['avg_demand'] and stats['avg_demand'] > 0 else 0
            avg_confidence = max(0, min(100, avg_confidence))  # Clamp 0-100
            
            self.all_model_stats[model] = {
                'count': stats['count'],
                'avg_demand': round(float(stats['avg_demand']) if stats['avg_demand'] else 0, 2),
                'std_demand': round(float(std_demand), 2),
                'min_demand': round(float(stats['min_demand']) if stats['min_demand'] else 0, 2),
                'max_demand': round(float(stats['max_demand']) if stats['max_demand'] else 0, 2),
                'avg_ci_width': round(avg_ci_width, 2),
                'confidence_score': round(avg_confidence, 2)
            }
            
            print(f"\n  {model}:")
            print(f"    Count:              {stats['count']}")
            print(f"    Avg Demand:         {stats['avg_demand']:.2f} kg")
            print(f"    Std Deviation:      {std_demand:.2f} kg")
            print(f"    Range:              {stats['min_demand']:.2f} - {stats['max_demand']:.2f} kg")
            print(f"    Avg CI Width:       {avg_ci_width:.2f} kg")
            print(f"    Confidence Score:   {avg_confidence:.2f}%")
        
        return model_counts
    
    def evaluate_by_product(self):
        """Analyze which models are used for each product"""
        print("\n" + "=" * 100)
        print("MODEL SELECTION BY PRODUCT")
        print("=" * 100)
        
        seller_products = SellerProduct.objects.filter(is_active=True).values_list('id', 'name')
        
        results = []
        
        for product_id, product_name in seller_products:
            forecasts = ProductForecast.objects.filter(product_id=product_id)
            
            if not forecasts.exists():
                logger.warning(f"No forecasts for product {product_name}")
                continue
            
            # Get model distribution for this product
            model_dist = forecasts.values('model_type').annotate(count=Count('id')).order_by('-count')
            
            # Get statistics for this product
            model_stats = {}
            
            for model_type in ['SARIMA', 'ARIMA', 'SIMPLE']:
                model_forecasts = forecasts.filter(model_type=model_type)
                if model_forecasts.exists():
                    avg_demand = model_forecasts.aggregate(Avg('demand_forecast_kg'))['demand_forecast_kg__avg']
                    demands = list(model_forecasts.values_list('demand_forecast_kg', flat=True))
                    std = np.std(demands) if demands else 0
                    count = model_forecasts.count()
                    
                    model_stats[model_type] = {
                        'count': count,
                        'avg_demand': round(avg_demand, 2),
                        'std': round(std if std else 0, 2)
                    }
            
            # Determine dominant model
            dominant_model = model_dist.first()['model_type'] if model_dist.exists() else 'UNKNOWN'
            
            result = {
                'product_id': product_id,
                'product_name': product_name,
                'total_forecasts': forecasts.count(),
                'dominant_model': dominant_model,
                'model_stats': model_stats,
                'evaluation_date': datetime.now().isoformat()
            }
            
            results.append(result)
        
        # Print results
        print(f"\nProducts Analyzed: {len(results)}\n")
        print(f"{'Product':<30} {'Dominant Model':<15} {'Forecasts':<12} {'Avg Demand (kg)':<18}")
        print("-" * 75)
        
        for result in results:
            dominant = result['dominant_model']
            avg_demand = result['model_stats'].get(dominant, {}).get('avg_demand', 'N/A')
            print(f"{result['product_name']:<30} {dominant:<15} {result['total_forecasts']:<12} {str(avg_demand):<18}")
        
        return results
    
    def evaluate_model_accuracy(self):
        """
        Estimate model accuracy using confidence intervals.
        Models with tighter CI ranges have higher confidence.
        """
        print("\n" + "=" * 100)
        print("MODEL ACCURACY ESTIMATION (Based on Confidence Intervals)")
        print("=" * 100)
        
        forecasts = ProductForecast.objects.all()
        
        results = {}
        
        for model_type in ['SARIMA', 'ARIMA', 'SIMPLE']:
            model_forecasts = forecasts.filter(model_type=model_type)
            
            if not model_forecasts.exists():
                results[model_type] = {'status': 'no_data'}
                continue
            
            # Calculate CI-based metrics
            ci_data = model_forecasts.values_list(
                'demand_forecast_kg', 'demand_lower_bound', 'demand_upper_bound'
            )
            
            predictions = []
            ci_widths = []
            
            for forecast, lower, upper in ci_data:
                if forecast and lower and upper and forecast > 0:
                    predictions.append(forecast)
                    ci_width = upper - lower
                    ci_widths.append(ci_width)
            
            if not predictions:
                results[model_type] = {'status': 'no_valid_data'}
                continue
            
            predictions = np.array(predictions)
            ci_widths = np.array(ci_widths)
            
            # Confidence: narrower CI = higher confidence
            avg_ci_width = np.mean(ci_widths)
            avg_prediction = np.mean(predictions)
            
            # Coefficient of variation of predictions
            std_prediction = np.std(predictions)
            cv = (std_prediction / avg_prediction * 100) if avg_prediction > 0 else 0
            
            # Estimate accuracy from CI width relative to prediction magnitude
            # Smaller CI_width/prediction ratio = more accurate
            ci_relative_widths = ci_widths / predictions
            accuracy_score = max(0, 100 - (np.mean(ci_relative_widths) * 100))
            
            # F1-inspired metric: balance between confidence (narrow CI) and prediction variance
            confidence_metric = 100 - min(100, (avg_ci_width / avg_prediction * 100)) if avg_prediction > 0 else 0
            
            results[model_type] = {
                'status': 'success',
                'count': len(predictions),
                'avg_prediction_kg': round(avg_prediction, 2),
                'std_prediction_kg': round(std_prediction, 2),
                'coefficient_of_variation': round(cv, 2),
                'avg_ci_width': round(avg_ci_width, 2),
                'accuracy_score': round(accuracy_score, 2),
                'confidence_metric': round(confidence_metric, 2),
                'f1_score_estimate': round((accuracy_score + confidence_metric) / 2, 2)
            }
        
        # Print results
        print("\nModel Performance Metrics:")
        print("-" * 100)
        print(f"{'Model':<10} {'Count':<8} {'Accuracy (%)':<15} {'Confidence (%)':<18} {'F1 Estimate':<15}")
        print("-" * 100)
        
        for model, data in results.items():
            if data.get('status') == 'success':
                print(f"{model:<10} {data['count']:<8} {data['accuracy_score']:<15.2f} "
                      f"{data['confidence_metric']:<18.2f} {data['f1_score_estimate']:<15.2f}")
            else:
                print(f"{model:<10} {'N/A':<8} {'N/A':<15} {'N/A':<18} {'N/A':<15}")
        
        # Detailed breakdown
        print("\n" + "-" * 100)
        print("DETAILED BREAKDOWN:")
        print("-" * 100)
        
        for model, data in results.items():
            if data.get('status') == 'success':
                print(f"\n{model}:")
                print(f"  Forecasts:           {data['count']}")
                print(f"  Avg Prediction:      {data['avg_prediction_kg']} kg")
                print(f"  Std Deviation:       {data['std_prediction_kg']} kg")
                print(f"  Coeff. of Var:       {data['coefficient_of_variation']}%")
                print(f"  Avg CI Width:        {data['avg_ci_width']} kg")
                print(f"  Accuracy Score:      {data['accuracy_score']}%")
                print(f"  Confidence Metric:   {data['confidence_metric']}%")
                print(f"  F1 Estimate:         {data['f1_score_estimate']}")
        
        return results
    
    def generate_summary(self, model_counts, product_results, accuracy_results):
        """Generate evaluation summary"""
        print("\n" + "=" * 100)
        print("EVALUATION SUMMARY")
        print("=" * 100)
        
        # Best performer
        best_model = None
        best_accuracy = -1
        
        for model, data in accuracy_results.items():
            if data.get('status') == 'success' and data['accuracy_score'] > best_accuracy:
                best_accuracy = data['accuracy_score']
                best_model = model
        
        print(f"\nBest Performing Model: {best_model} (Accuracy: {best_accuracy:.2f}%)")
        print(f"\nProducts with Forecasts: {len(product_results)}")
        print(f"Total Production Forecasts: {sum(r['total_forecasts'] for r in product_results)}")
        
        print("\nModel Ranking by Accuracy:")
        ranked = sorted(
            [(m, d['accuracy_score']) for m, d in accuracy_results.items() if d.get('status') == 'success'],
            key=lambda x: x[1],
            reverse=True
        )
        
        for i, (model, accuracy) in enumerate(ranked, 1):
            print(f"  {i}. {model}: {accuracy:.2f}%")


def main():
    """Main execution"""
    logger.info("Starting Production Model Evaluation...")
    
    evaluator = ProductionModelEvaluator()
    
    # Run evaluations
    model_counts = evaluator.evaluate_model_distribution()
    product_results = evaluator.evaluate_by_product()
    accuracy_results = evaluator.evaluate_model_accuracy()
    
    # Generate summary
    evaluator.generate_summary(model_counts, product_results, accuracy_results)
    
    # Save results
    all_results = {
        'evaluation_date': datetime.now().isoformat(),
        'model_stats': evaluator.all_model_stats,
        'product_forecasts': product_results,
        'accuracy_results': accuracy_results
    }
    
    with open('model_evaluation_production.json', 'w') as f:
        json.dump(all_results, f, indent=2, default=str)
    
    logger.info("Evaluation complete! Results saved to model_evaluation_production.json")


if __name__ == '__main__':
    main()
