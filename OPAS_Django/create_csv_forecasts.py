#!/usr/bin/env python
"""
Generate demand and price forecasts for CSV products (MarketHistoricalData)
This script creates test forecasts for all unique products in the historical data.
"""

import os
import sys
import django
from datetime import datetime, timedelta
import random
from decimal import Decimal

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from apps.forecasting.models import ProductForecast, ForecastMetadata, MarketHistoricalData, ModelType, ConfidenceLevel

def get_unique_products():
    """Get all unique products from MarketHistoricalData"""
    products = MarketHistoricalData.objects.values_list('product_name', flat=True).distinct()
    return list(products)

def create_test_forecast(product_name, forecast_date=None, is_current=False):
    """
    Create test demand and price forecasts for a CSV product
    
    Args:
        product_name: Name of the product from CSV
        forecast_date: Optional specific datetime. If None, uses current time
        is_current: Whether this is the current/latest forecast
    
    Returns:
        ProductForecast object or None if creation failed
    """
    try:
        # Generate realistic test data
        demand_base = Decimal(random.randint(50, 500))
        price_base = Decimal(random.randint(100, 1000)) / Decimal(10)  # e.g., 10.0 to 100.0
        trend = random.choice(['increasing', 'decreasing', 'stable'])
        confidence = random.choice([ConfidenceLevel.HIGH, ConfidenceLevel.MEDIUM, ConfidenceLevel.LOW])
        model_type = random.choice([ModelType.ARIMA, ModelType.SARIMA, ModelType.SIMPLE])
        
        # Generate forecast period
        forecast_period = f"Week {random.randint(1, 4)} 2025"
        
        # Create demand forecast with slight variations
        demand_variation = Decimal(random.uniform(0.95, 1.05))
        demand_forecast = demand_base * demand_variation
        demand_lower = demand_forecast * Decimal('0.85')
        demand_upper = demand_forecast * Decimal('1.15')
        
        # Create price forecast with slight variations
        price_variation = Decimal(random.uniform(0.95, 1.05))
        price_forecast = price_base * price_variation
        price_lower = price_forecast * Decimal('0.9')
        price_upper = price_forecast * Decimal('1.1')
        
        # Use provided date or current time
        if forecast_date is None:
            forecast_date = datetime.now()
        
        # Create forecast
        forecast = ProductForecast.objects.create(
            product=None,  # No farmer product, using CSV instead
            product_name=product_name,
            forecast_date=forecast_date,
            forecast_period=forecast_period,
            is_current=is_current,
            
            # Demand data
            demand_forecast_kg=Decimal(str(round(float(demand_forecast), 2))),
            demand_lower_bound=Decimal(str(round(float(demand_lower), 2))),
            demand_upper_bound=Decimal(str(round(float(demand_upper), 2))),
            
            # Price data
            price_forecast=Decimal(str(round(float(price_forecast), 2))),
            price_lower_bound=Decimal(str(round(float(price_lower), 2))),
            price_upper_bound=Decimal(str(round(float(price_upper), 2))),
            
            # Model metadata
            model_type=model_type,
            confidence_level=confidence,
            rmse_demand=Decimal(str(round(random.uniform(2, 10), 2))),
            rmse_price=Decimal(str(round(random.uniform(5, 20), 2))),
            mape_demand=Decimal(str(round(random.uniform(5, 15), 2))),
            mape_price=Decimal(str(round(random.uniform(3, 12), 2))),
        )
        
        return forecast
        
    except Exception as e:
        print(f"  ❌ Error creating forecast for {product_name}: {str(e)}")
        return None

def main():
    print("=" * 70)
    print("CSV PRODUCT FORECAST GENERATOR - WITH HISTORICAL PROGRESSION")
    print("=" * 70)
    
    # Get unique products from MarketHistoricalData
    products = get_unique_products()
    print(f"\n📊 Found {len(products)} unique products in MarketHistoricalData")
    
    if not products:
        print("❌ No products found in MarketHistoricalData!")
        return
    
    # Generate forecasts with different timestamps
    # Create 3-4 forecasts per product with timestamps spanning from September to December
    print("\n📝 Creating forecasts with varied timestamps (historical progression)...")
    
    created_count = 0
    failed_count = 0
    
    # Define historical dates (going back 3 months)
    current_date = datetime.now()
    historical_dates = [
        current_date - timedelta(days=90),  # ~3 months ago
        current_date - timedelta(days=60),  # ~2 months ago
        current_date - timedelta(days=30),  # ~1 month ago
        current_date,                        # Today (current)
    ]
    
    for i, product_name in enumerate(products, 1):
        print(f"\n  {i}. {product_name}")
        
        # Create multiple forecasts for this product with different timestamps
        for date_idx, forecast_date in enumerate(historical_dates, 1):
            is_current = (forecast_date == current_date)  # Only latest is current
            
            forecast = create_test_forecast(
                product_name,
                forecast_date=forecast_date,
                is_current=is_current
            )
            
            if forecast:
                date_str = forecast_date.strftime("%b %d, %Y %H:%M")
                current_badge = " [CURRENT]" if is_current else ""
                print(f"     ✅ Forecast #{date_idx}: {date_str}{current_badge}")
                print(f"        Demand {forecast.demand_forecast_kg}kg, Price ₱{forecast.price_forecast}")
                created_count += 1
            else:
                failed_count += 1
    
    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    total_forecasts = ProductForecast.objects.count()
    total_products = ProductForecast.objects.values('product_name').distinct().count()
    
    print(f"✅ Forecasts created this run: {created_count}")
    print(f"❌ Failed: {failed_count}")
    print(f"📊 Total forecasts in database: {total_forecasts}")
    print(f"   - Unique products: {total_products}")
    print(f"   - Forecasts per product: {total_forecasts // total_products if total_products > 0 else 0}")
    
    print("\n💡 Historical Progression:")
    print(f"   - Oldest forecasts: ~90 days ago (is_current=False)")
    print(f"   - 2nd generation: ~60 days ago (is_current=False)")
    print(f"   - 3rd generation: ~30 days ago (is_current=False)")
    print(f"   - Latest forecasts: Today (is_current=True)")
    
    print("\n✨ Forecast generation complete!")
    print("   The ForecastHistoryScreen will now show proper historical progression.")
    print("=" * 70)

if __name__ == '__main__':
    main()
