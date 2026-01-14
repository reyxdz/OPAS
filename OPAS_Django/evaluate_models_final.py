"""
Evaluate Forecasting Models Using Production Forecast Data

Shows which models are being used and their confidence/accuracy metrics
"""

import os
import sys
import django
import numpy as np
import pandas as pd
from datetime import datetime
from collections import defaultdict
import logging
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db.models import Count, Avg, Min, Max
from apps.forecasting.models import ProductForecast

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main():
    """Evaluate production models"""
    print("\n" + "=" * 100)
    print("FORECASTING MODEL PERFORMANCE EVALUATION")
    print("=" * 100)
    
    # Get all forecasts
    forecasts = ProductForecast.objects.all()
    total_forecasts = forecasts.count()
    
    print(f"\nTotal Forecasts in System: {total_forecasts}")
    
    # Model usage distribution
    model_counts = forecasts.values('model_type').annotate(count=Count('id')).order_by('-count')
    
    print("\n" + "-" * 100)
    print("1. MODEL USAGE DISTRIBUTION")
    print("-" * 100)
    
    model_percentages = {}
    for model in model_counts:
        percentage = (model['count'] / total_forecasts) * 100
        model_percentages[model['model_type']] = {
            'count': model['count'],
            'percentage': percentage
        }
        print(f"  {model['model_type']:<10}: {model['count']:<5} forecasts ({percentage:>6.2f}%)")
    
    # Model confidence & accuracy statistics
    print("\n" + "-" * 100)
    print("2. MODEL CONFIDENCE & ACCURACY ANALYSIS")
    print("-" * 100)
    
    model_results = {}
    
    for model_type in ['SARIMA', 'ARIMA', 'SIMPLE']:
        model_forecasts = forecasts.filter(model_type=model_type)
        
        if not model_forecasts.exists():
            print(f"  {model_type}: NO DATA")
            continue
        
        # Get statistics
        demands = list(model_forecasts.values_list('demand_forecast_kg', flat=True))
        lower_bounds = list(model_forecasts.values_list('demand_lower_bound', flat=True))
        upper_bounds = list(model_forecasts.values_list('demand_upper_bound', flat=True))
        
        # Filter out None/null values
        demands = [d for d in demands if d is not None]
        lower_bounds = [l for l in lower_bounds if l is not None]
        upper_bounds = [u for u in upper_bounds if u is not None]
        
        if not demands:
            print(f"  {model_type}: NO VALID DATA")
            continue
        
        demands_arr = np.array(demands, dtype=float)
        lower_arr = np.array(lower_bounds, dtype=float) if lower_bounds else np.zeros(len(demands))
        upper_arr = np.array(upper_bounds, dtype=float) if upper_bounds else np.zeros(len(demands))
        
        # Calculate metrics
        avg_demand = np.mean(demands_arr)
        std_demand = np.std(demands_arr)
        min_demand = np.min(demands_arr)
        max_demand = np.max(demands_arr)
        
        # Confidence interval width
        ci_widths = upper_arr - lower_arr
        avg_ci_width = np.mean(ci_widths) if len(ci_widths) > 0 else 0
        
        # Accuracy estimation: narrower CI = higher accuracy
        # CI_width/prediction gives normalized metric
        ci_ratios = ci_widths / demands_arr
        avg_ci_ratio = np.mean(ci_ratios)
        
        # Convert to accuracy: lower ratio = higher accuracy
        accuracy = max(0, min(100, 100 - (avg_ci_ratio * 100)))
        
        # F1-like score: harmonic mean of accuracy and consistency
        consistency = max(0, 100 - (std_demand / avg_demand * 100)) if avg_demand > 0 else 0
        f1_estimate = 2 * (accuracy * consistency) / (accuracy + consistency) if (accuracy + consistency) > 0 else 0
        
        model_results[model_type] = {
            'count': len(demands),
            'avg_demand': round(avg_demand, 2),
            'std_demand': round(std_demand, 2),
            'min_demand': round(min_demand, 2),
            'max_demand': round(max_demand, 2),
            'avg_ci_width': round(avg_ci_width, 2),
            'accuracy': round(accuracy, 2),
            'consistency': round(consistency, 2),
            'f1_score': round(f1_estimate, 4)
        }
        
        print(f"\n  {model_type}:")
        print(f"    Forecasts:           {len(demands)}")
        print(f"    Avg Demand:          {round(avg_demand, 2)} kg")
        print(f"    Std Deviation:       {round(std_demand, 2)} kg")
        print(f"    Min Demand:          {round(min_demand, 2)} kg")
        print(f"    Max Demand:          {round(max_demand, 2)} kg")
        print(f"    Avg CI Width:        {round(avg_ci_width, 2)} kg")
        print(f"    Accuracy Score:      {round(accuracy, 2)}%")
        print(f"    Consistency Score:   {round(consistency, 2)}%")
        print(f"    F1 Score Estimate:   {round(f1_estimate, 4)}")
    
    # Ranking
    print("\n" + "-" * 100)
    print("3. MODEL RANKING BY PERFORMANCE")
    print("-" * 100)
    
    ranking = sorted(
        [(m, d['accuracy'], d['f1_score']) for m, d in model_results.items() if 'count' in d],
        key=lambda x: x[2],
        reverse=True
    )
    
    print("\nBy F1 Score (Higher is Better):")
    for i, (model, accuracy, f1) in enumerate(ranking, 1):
        print(f"  {i}. {model:<10} F1: {f1:.4f}  |  Accuracy: {accuracy:.2f}%")
    
    # Model selection patterns
    print("\n" + "-" * 100)
    print("4. MODEL SELECTION PATTERNS BY PRODUCT")
    print("-" * 100)
    
    products = forecasts.values('product__name').distinct()
    product_model_usage = defaultdict(lambda: defaultdict(int))
    
    for product in products:
        product_name = product['product__name'] if product['product__name'] else 'Unknown'
        product_forecasts = forecasts.filter(product__name=product_name)
        
        for model_type in ['SARIMA', 'ARIMA', 'SIMPLE']:
            count = product_forecasts.filter(model_type=model_type).count()
            product_model_usage[product_name][model_type] = count
    
    print("\nTop 10 Products by Forecast Count:")
    print(f"{'Product':<25} {'SARIMA':<10} {'ARIMA':<10} {'SIMPLE':<10} {'Total':<10}")
    print("-" * 65)
    
    sorted_products = sorted(
        product_model_usage.items(),
        key=lambda x: sum(x[1].values()),
        reverse=True
    )
    
    for i, (product_name, models) in enumerate(sorted_products[:10], 1):
        sarima = models.get('SARIMA', 0)
        arima = models.get('ARIMA', 0)
        simple = models.get('SIMPLE', 0)
        total = sarima + arima + simple
        print(f"{product_name:<25} {sarima:<10} {arima:<10} {simple:<10} {total:<10}")
    
    # Summary and recommendation
    print("\n" + "=" * 100)
    print("EVALUATION SUMMARY & RECOMMENDATIONS")
    print("=" * 100)
    
    best_model = ranking[0][0] if ranking else 'UNKNOWN'
    best_f1 = ranking[0][2] if ranking else 0
    
    print(f"\n✓ BEST PERFORMING MODEL: {best_model}")
    print(f"  F1 Score: {best_f1:.4f}")
    print(f"  Accuracy: {ranking[0][1]:.2f}%")
    
    print(f"\n✓ TOTAL FORECASTS GENERATED: {total_forecasts:,}")
    print(f"✓ PRODUCTS EVALUATED: {len(product_model_usage)}")
    
    print("\n✓ MODEL DISTRIBUTION:")
    for model, data in model_percentages.items():
        print(f"  - {model:<10}: {data['percentage']:>6.2f}%")
    
    print("\n✓ RECOMMENDATION:")
    if best_f1 > 0.8:
        print(f"  {best_model} is performing well (F1: {best_f1:.4f})")
        print("  Current system is effectively using statistical models.")
    else:
        print("  All models show moderate performance.")
        print("  Consider adding more training data or optimizing parameters.")
    
    # Save results to file
    results_summary = {
        'evaluation_date': datetime.now().isoformat(),
        'total_forecasts': total_forecasts,
        'model_distribution': model_percentages,
        'model_performance': {m: d for m, d in model_results.items() if 'count' in d},
        'best_model': best_model,
        'best_f1_score': float(best_f1),
        'products_evaluated': len(product_model_usage)
    }
    
    with open('model_evaluation_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    print("\n✓ Results saved to: model_evaluation_results.json")
    print("\n" + "=" * 100)
    
    logger.info("Evaluation complete!")


if __name__ == '__main__':
    main()
