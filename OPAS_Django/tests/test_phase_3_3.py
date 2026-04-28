"""
Test Phase 3.3 - Enhanced Demand Forecasting Algorithm
Tests the new forecasting endpoints and algorithm implementation
"""

import os
import django
import sys
import json
from datetime import datetime, timedelta

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.users.seller_models import SellerProduct, SellerOrder, SellerForecast
from apps.users.forecasting_algorithm import ForecastingAlgorithm

User = get_user_model()

print("=" * 80)
print("PHASE 3.3 - ENHANCED DEMAND FORECASTING ALGORITHM TEST")
print("=" * 80)

# Get or create test seller
try:
    seller = User.objects.filter(role='SELLER').first()
    if not seller:
        print("✗ No sellers found in database")
        sys.exit(1)
    print(f"✓ Using test seller: {seller.email} (ID: {seller.id})")
except Exception as e:
    print(f"✗ Error fetching seller: {str(e)}")
    sys.exit(1)

# Get seller's products
products = SellerProduct.objects.filter(seller=seller, status='ACTIVE')[:3]
print(f"\n✓ Found {len(products)} active products for testing")

# Test forecasting algorithm
print("\n" + "-" * 80)
print("TESTING FORECASTING ALGORITHM")
print("-" * 80)

algorithm = ForecastingAlgorithm()

for product in products:
    print(f"\n📦 Testing forecast for: {product.name}")
    
    # Get historical sales data
    from django.db.models import Sum
    sales_data = []
    
    # Generate mock historical data for testing (if none exists)
    recent_orders = SellerOrder.objects.filter(
        seller=seller,
        product=product,
        status__in=['FULFILLED', 'DELIVERED']
    ).values('created_at__date').annotate(quantity=Sum('quantity'))[:30]
    
    if recent_orders.exists():
        sales_data = [
            {
                'date': order['created_at__date'],
                'quantity': order['quantity'],
                'price': float(product.price)
            }
            for order in recent_orders
        ]
        print(f"  ✓ Found {len(sales_data)} historical orders")
    else:
        # Create mock data for testing
        print("  ⚠ No historical orders. Using mock data for testing...")
        for i in range(30):
            date = datetime.now().date() - timedelta(days=30-i)
            quantity = 10 + (i % 5) + (5 if i % 7 == 0 else 0)  # Some seasonality
            sales_data.append({
                'date': date,
                'quantity': quantity,
                'price': float(product.price)
            })
    
    # Generate forecast
    forecast_data = algorithm.forecast_demand(
        sales_data,
        product.stock_level,
        product.minimum_stock
    )
    
    print(f"  ✓ Forecast Generated:")
    print(f"    - Forecasted Demand: {forecast_data['forecasted_demand']} units")
    print(f"    - Confidence Score: {forecast_data['confidence_score']:.1f}%")
    print(f"    - Trend: {forecast_data['trend']}")
    print(f"    - Volatility: {forecast_data['volatility']:.1f}%")
    print(f"    - Growth Rate: {forecast_data['growth_rate']:.1f}%")
    print(f"    - Surplus Risk: {forecast_data['surplus_probability']:.1f}%")
    print(f"    - Stockout Risk: {forecast_data['stockout_probability']:.1f}%")
    print(f"    - Recommended Stock: {forecast_data['recommended_stock']} units")
    print(f"    - Recommendations: {len(forecast_data['recommendations'])} generated")
    
    # Generate trend data
    trend_data = algorithm.generate_trend_data(sales_data, forecast_data)
    print(f"  ✓ Trend Data Generated:")
    print(f"    - Total data points: {trend_data['total_points']}")
    print(f"    - Historical points: {len([p for p in trend_data['trend_points'] if p['type'] == 'historical'])}")
    print(f"    - Forecast points: {len([p for p in trend_data['trend_points'] if p['type'] == 'forecast'])}")

print("\n" + "-" * 80)
print("TESTING DATABASE MODELS")
print("-" * 80)

# Create or update a forecast record
try:
    product = products[0] if products else None
    if not product:
        print("✗ No products available for testing")
    else:
        forecast_date = datetime.now().date()
        forecast_start = forecast_date + timedelta(days=1)
        forecast_end = forecast_start + timedelta(days=30)
        
        forecast, created = SellerForecast.objects.update_or_create(
            seller=seller,
            product=product,
            forecast_date=forecast_date,
            defaults={
                'forecast_start': forecast_start,
                'forecast_end': forecast_end,
                'forecasted_demand': 150,
                'confidence_score': 85.5,
                'surplus_probability': 25.0,
                'stockout_probability': 15.0,
                'recommended_stock': 200,
                'trend': 'UPTREND',
                'volatility': 22.5,
                'growth_rate': 8.5,
                'trend_multiplier': 1.08,
                'seasonality_detected': True,
                'historical_sales_count': 30,
                'average_daily_sales': 5.0,
                'recommendations': [
                    '✅ Demand is increasing. Increase procurement.',
                    '📦 Recommended stock level: 200 units.',
                    '💡 Monitor weekly for demand changes.',
                ],
            }
        )
        
        action = "Created" if created else "Updated"
        print(f"\n✓ {action} forecast record:")
        print(f"  - ID: {forecast.id}")
        print(f"  - Product: {forecast.product.name}")
        print(f"  - Forecasted Demand: {forecast.forecasted_demand} units")
        print(f"  - Confidence: {forecast.confidence_score}%")
        print(f"  - Trend: {forecast.trend}")
        print(f"  - Risk Level: {'HIGH' if max(forecast.surplus_probability, forecast.stockout_probability) >= 70 else 'MEDIUM' if max(forecast.surplus_probability, forecast.stockout_probability) >= 40 else 'LOW'}")
        
except Exception as e:
    print(f"✗ Error creating forecast record: {str(e)}")

print("\n" + "=" * 80)
print("✅ PHASE 3.3 TESTING COMPLETE")
print("=" * 80)
print("\nNEXT STEPS:")
print("1. Run Django server: python manage.py runserver")
print("2. Test API endpoints with Flutter app or Postman")
print("3. Test endpoints:")
print("   - GET /api/users/seller/forecast/next_month/")
print("   - POST /api/users/seller/forecast/generate/ (with product_id)")
print("   - GET /api/users/seller/forecast/trend_data/?product_id=X")
print("   - GET /api/users/seller/forecast/insights/")
