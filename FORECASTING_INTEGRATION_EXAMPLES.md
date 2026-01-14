# Forecasting System Integration: Code Examples

## Overview
This file contains ready-to-use code snippets for integrating the new hybrid forecasting system into your Django backend and Flutter frontend.

---

## Django Backend Integration

### Option 1: Minimal Change (Recommended for Testing)

Add this to your `seller_views.py` ForecastingViewSet:

```python
# In apps/users/seller_views.py

from django.views.decorators.cache import cache_page
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm

class ForecastingViewSet(viewsets.ViewSet):
    """Enhanced forecasting with hybrid statistical + ML methods"""
    
    # ... existing code ...
    
    def _generate_forecast_for_product(self, product):
        """Generate comprehensive forecast using hybrid strategy"""
        
        # Initialize forecasters
        hybrid_forecaster = create_hybrid_forecaster()
        stat_forecaster = ForecastingAlgorithm()
        
        # Get historical sales
        sales_data = self._get_historical_sales(product)
        
        # Generate forecast (automatically selects best method)
        forecast_data = hybrid_forecaster.generate_hybrid_forecast(
            sales_data=sales_data,
            current_stock=product.stock_level,
            min_stock=product.minimum_stock,
            forecast_algorithm=stat_forecaster
        )
        
        # Log the method used for monitoring
        logger.info(
            f"Forecast generated for product {product.id}: "
            f"Method={forecast_data.get('forecasting_method')}, "
            f"Confidence={forecast_data.get('confidence_score')}%"
        )
        
        return forecast_data, sales_data
```

---

### Option 2: Full Integration with Model Training

Replace `_generate_forecast_for_product` completely:

```python
from apps.users.hybrid_forecasting import create_hybrid_forecaster, HybridForecastingStrategy
from apps.users.forecasting_ml import LSTMForecaster, XGBoostForecaster
import json

def _generate_forecast_for_product_advanced(self, product):
    """Advanced forecasting with ML model training and storage"""
    
    # Get historical sales
    sales_data = self._get_historical_sales(product)
    
    if not sales_data or len(sales_data) < 3:
        return self._generate_default_forecast(product)
    
    # Initialize hybrid system
    hybrid_forecaster = create_hybrid_forecaster()
    stat_forecaster = ForecastingAlgorithm()
    
    # Generate forecast
    forecast_data = hybrid_forecaster.generate_hybrid_forecast(
        sales_data=sales_data,
        current_stock=product.stock_level,
        min_stock=product.minimum_stock,
        forecast_algorithm=stat_forecaster
    )
    
    # If using ML methods, extract and store metrics
    if 'ml_metrics' in forecast_data:
        forecast_data['ml_model_accuracy'] = {
            'lstm': forecast_data['ml_metrics'].get('lstm', {}).get('test_mape'),
            'xgboost': forecast_data['ml_metrics'].get('xgboost', {}).get('test_mape'),
        }
    
    # Store ML predictions for comparison with actual later
    if 'ml_predictions' in forecast_data:
        forecast_data['weekly_ml_predictions'] = forecast_data['ml_predictions']
    
    return forecast_data, sales_data

def _generate_default_forecast(self, product):
    """Fallback when insufficient data"""
    return {
        'forecasted_demand': product.average_daily_sales * 7,
        'confidence_score': 20,
        'forecasting_method': 'DEFAULT',
        'status': 'INSUFFICIENT_DATA',
        'recommendations': [
            'Collect more sales data (need 30+ days)',
            'Manually adjust forecasts based on experience'
        ]
    }, []
```

---

### Option 3: Background Task with Model Caching

For production deployments:

```python
# In apps/users/tasks.py (Celery tasks)

from celery import shared_task
from django.core.cache import cache
from apps.users.models import Product, SellerForecast
from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm
import json
import logging

logger = logging.getLogger(__name__)

@shared_task
def generate_and_cache_forecasts_for_seller(seller_id):
    """
    Background task to generate forecasts for all seller products
    Caches results for 24 hours to improve API response time
    """
    try:
        seller = Seller.objects.get(id=seller_id)
        products = seller.products.filter(is_active=True)
        
        hybrid_forecaster = create_hybrid_forecaster()
        stat_forecaster = ForecastingAlgorithm()
        
        forecasts_generated = 0
        
        for product in products:
            try:
                # Get sales data (from helper method)
                sales_data = get_historical_sales(product, days=90)
                
                if len(sales_data) < 3:
                    continue
                
                # Generate forecast
                forecast_data = hybrid_forecaster.generate_hybrid_forecast(
                    sales_data=sales_data,
                    current_stock=product.stock_level,
                    min_stock=product.minimum_stock,
                    forecast_algorithm=stat_forecaster
                )
                
                # Cache for 24 hours
                cache_key = f"forecast:product:{product.id}"
                cache.set(cache_key, forecast_data, 86400)
                
                # Store in database for historical tracking
                SellerForecast.objects.create(
                    seller=seller,
                    product=product,
                    forecasted_demand=forecast_data['forecasted_demand'],
                    confidence_score=forecast_data['confidence_score'],
                    surplus_probability=forecast_data.get('surplus_probability', 0),
                    stockout_probability=forecast_data.get('stockout_probability', 0),
                    recommended_stock=forecast_data.get('recommended_stock', 0),
                    algorithm_used=forecast_data['forecasting_method'],
                    algorithm_data=json.dumps(forecast_data)
                )
                
                forecasts_generated += 1
                
            except Exception as e:
                logger.error(f"Error generating forecast for product {product.id}: {e}")
                continue
        
        logger.info(f"Generated {forecasts_generated} forecasts for seller {seller_id}")
        return forecasts_generated
        
    except Seller.DoesNotExist:
        logger.error(f"Seller {seller_id} not found")
        return 0
    except Exception as e:
        logger.error(f"Error in forecast generation task: {e}")
        return 0


@shared_task
def retrain_ml_models_for_seller(seller_id):
    """
    Periodically retrain ML models with latest data
    Schedule: Daily or weekly
    """
    try:
        seller = Seller.objects.get(id=seller_id)
        products = seller.products.filter(is_active=True)
        
        hybrid_forecaster = create_hybrid_forecaster()
        
        models_trained = 0
        
        for product in products:
            sales_data = get_historical_sales(product, days=180)
            
            if len(sales_data) >= 60:  # Only train if sufficient data
                try:
                    if hybrid_forecaster.ml_ensemble:
                        results = hybrid_forecaster.ml_ensemble.train_all_models(sales_data)
                        
                        # Store training metrics
                        cache_key = f"ml_metrics:product:{product.id}"
                        cache.set(cache_key, results, 86400 * 7)  # Cache for 7 days
                        
                        models_trained += 1
                except Exception as e:
                    logger.warning(f"ML training failed for product {product.id}: {e}")
        
        logger.info(f"Retrained ML models for {models_trained} products from seller {seller_id}")
        return models_trained
        
    except Exception as e:
        logger.error(f"ML retraining task error: {e}")
        return 0


# In your Django settings or beat schedule:
# CELERY_BEAT_SCHEDULE = {
#     'generate-forecasts': {
#         'task': 'apps.users.tasks.generate_and_cache_forecasts_for_seller',
#         'schedule': crontab(hour=0, minute=0),  # Daily at midnight
#         'kwargs': {}
#     },
#     'retrain-ml-models': {
#         'task': 'apps.users.tasks.retrain_ml_models_for_seller',
#         'schedule': crontab(hour=2, minute=0, day_of_week='sun'),  # Weekly on Sunday
#         'kwargs': {}
#     },
# }
```

---

### Option 4: API Endpoint for Manual Training

Add a new endpoint to trigger model training:

```python
# In seller_views.py ForecastingViewSet

@action(detail=False, methods=['post'])
def train_ml_models(self, request):
    """
    Manually trigger ML model training for seller's products
    POST /api/seller/forecast/train_ml_models/
    """
    try:
        seller = request.user.seller
        products = seller.products.filter(is_active=True)
        
        hybrid_forecaster = create_hybrid_forecaster()
        training_results = {}
        
        for product in products:
            sales_data = self._get_historical_sales(product)
            
            if len(sales_data) >= 60:
                results = hybrid_forecaster.ml_ensemble.train_all_models(sales_data)
                training_results[str(product.id)] = {
                    'product_name': product.name,
                    'data_points': len(sales_data),
                    'lstm': results.get('models', {}).get('lstm'),
                    'xgboost': results.get('models', {}).get('xgboost'),
                }
        
        return Response({
            'status': 'success',
            'message': f'Trained models for {len(training_results)} products',
            'training_results': training_results
        })
    
    except Exception as e:
        logger.error(f"ML training endpoint error: {e}")
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=400)


@action(detail=False, methods=['get'])
def forecast_comparison(self, request):
    """
    Get comparison between statistical and ML forecasts
    GET /api/seller/forecast/forecast_comparison/?product_id=123
    
    Useful for validation and debugging
    """
    try:
        product_id = request.query_params.get('product_id')
        product = Product.objects.get(id=product_id, seller=request.user.seller)
        
        sales_data = self._get_historical_sales(product)
        
        if len(sales_data) < 3:
            return Response({
                'error': 'Insufficient data',
                'data_points': len(sales_data)
            })
        
        # Statistical forecast
        stat_forecaster = ForecastingAlgorithm()
        stat_forecast = stat_forecaster.forecast_demand(
            sales_data,
            product.stock_level,
            product.minimum_stock
        )
        
        # Hybrid forecast
        hybrid_forecaster = create_hybrid_forecaster()
        hybrid_forecast = hybrid_forecaster.generate_hybrid_forecast(
            sales_data,
            product.stock_level,
            product.minimum_stock,
            stat_forecaster
        )
        
        return Response({
            'product_id': product.id,
            'product_name': product.name,
            'data_points': len(sales_data),
            'statistical_forecast': {
                'demand': stat_forecast['forecasted_demand'],
                'confidence': stat_forecast['confidence_score'],
                'method': 'STATISTICAL_ONLY'
            },
            'hybrid_forecast': {
                'demand': hybrid_forecast['forecasted_demand'],
                'confidence': hybrid_forecast['confidence_score'],
                'method': hybrid_forecast['forecasting_method'],
                'ml_metrics': hybrid_forecast.get('ml_metrics'),
            },
            'difference_percent': abs(
                (hybrid_forecast['forecasted_demand'] - stat_forecast['forecasted_demand']) /
                max(stat_forecast['forecasted_demand'], 1) * 100
            )
        })
    
    except Product.DoesNotExist:
        return Response({'error': 'Product not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=400)
```

---

## Model Updates

Update your `SellerForecast` model to track algorithm metadata:

```python
# In seller_models.py

from django.db import models
import json

class SellerForecast(models.Model):
    # ... existing fields ...
    
    # NEW: Algorithm tracking
    algorithm_used = models.CharField(
        max_length=100,
        choices=[
            ('STATISTICAL_ONLY', 'Statistical Only'),
            ('HYBRID_WEIGHTED', 'Hybrid Weighted'),
            ('ML_ENSEMBLE', 'ML Ensemble'),
            ('INSUFFICIENT_DATA', 'Insufficient Data'),
        ],
        default='STATISTICAL_ONLY'
    )
    
    # NEW: ML metrics storage
    algorithm_data = models.JSONField(
        default=dict,
        blank=True,
        help_text='Detailed forecast data including ML metrics'
    )
    
    # NEW: Accuracy tracking
    actual_accuracy = models.FloatField(
        null=True,
        blank=True,
        help_text='MAPE after actual sales data is known'
    )
    
    class Meta:
        indexes = [
            models.Index(fields=['seller', 'created_at']),
            models.Index(fields=['algorithm_used']),
        ]
```

---

## Flutter Frontend Updates

### Option 1: Display Forecasting Method

```dart
// In forecast_card.dart

class ForecastCard extends StatelessWidget {
  final ForecastModel forecast;
  final String? algorithmMethod;  // NEW
  
  const ForecastCard({
    required this.forecast,
    this.algorithmMethod,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Existing forecast display
          Text(forecast.productName),
          Text('${forecast.demandForecastKg} kg'),
          
          // NEW: Algorithm badge
          if (algorithmMethod != null)
            _buildAlgorithmBadge(algorithmMethod!),
          
          // Confidence indicator
          _buildConfidenceBadge(forecast.confidenceLevel),
        ],
      ),
    );
  }
  
  Widget _buildAlgorithmBadge(String method) {
    final color = _getMethodColor(method);
    final icon = _getMethodIcon(method);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            method,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getMethodColor(String method) {
    if (method.contains('LSTM')) return Colors.purple;
    if (method.contains('XGBoost')) return Colors.blue;
    if (method.contains('ENSEMBLE')) return Colors.green;
    if (method.contains('HYBRID')) return Colors.orange;
    if (method.contains('STATISTICAL')) return Colors.teal;
    return Colors.grey;
  }
  
  IconData _getMethodIcon(String method) {
    if (method.contains('ML')) return Icons.psychology;
    if (method.contains('ENSEMBLE')) return Icons.layers;
    if (method.contains('STATISTICAL')) return Icons.equalizer;
    return Icons.info;
  }
}
```

### Option 2: Enhanced Forecast Details Screen

```dart
// In product_forecast_detail_screen.dart

class ProductForecastDetailScreen extends StatefulWidget {
  final int productId;
  
  const ProductForecastDetailScreen({
    required this.productId,
    Key? key,
  }) : super(key: key);
  
  @override
  State<ProductForecastDetailScreen> createState() =>
      _ProductForecastDetailScreenState();
}

class _ProductForecastDetailScreenState
    extends State<ProductForecastDetailScreen> {
  late Future<ForecastDetailModel> _forecastDetail;
  
  @override
  void initState() {
    super.initState();
    _forecastDetail = _fetchForecastDetail();
  }
  
  Future<ForecastDetailModel> _fetchForecastDetail() async {
    // Call API endpoint to get detailed forecast with ML metrics
    final response = await ApiService.get(
      '/api/seller/forecast/product/${widget.productId}/',
    );
    return ForecastDetailModel.fromJson(response);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forecast Details')),
      body: FutureBuilder<ForecastDetailModel>(
        future: _forecastDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData) {
            return Center(child: Text('No forecast data'));
          }
          
          final forecast = snapshot.data!;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NEW: Algorithm Method Section
                _buildAlgorithmSection(forecast),
                
                SizedBox(height: 16),
                
                // Demand Forecast
                _buildForecastCard(
                  title: 'Demand Forecast',
                  value: '${forecast.demand} kg',
                  confidence: forecast.confidence,
                  range: '${forecast.demandLower} - ${forecast.demandUpper} kg',
                ),
                
                SizedBox(height: 16),
                
                // NEW: ML Metrics (if available)
                if (forecast.mlMetrics != null)
                  _buildMLMetricsSection(forecast.mlMetrics!),
                
                SizedBox(height: 16),
                
                // Risk Assessment
                _buildRiskAssessment(forecast),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAlgorithmSection(ForecastDetailModel forecast) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecasting Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            _buildMethodChip(forecast.method),
            SizedBox(height: 8),
            Text(
              _getMethodDescription(forecast.method),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMethodChip(String method) {
    final color = _getMethodColor(method);
    final icon = _getMethodIcon(method);
    
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(method),
      backgroundColor: color,
      labelStyle: TextStyle(color: Colors.white),
    );
  }
  
  String _getMethodDescription(String method) {
    if (method.contains('ML_ENSEMBLE')) {
      return 'Uses LSTM (neural network) and XGBoost (gradient boosting) combined for optimal accuracy';
    } else if (method.contains('HYBRID')) {
      return 'Combines statistical methods with machine learning for balanced predictions';
    } else if (method.contains('STATISTICAL')) {
      return 'Statistical methods including moving averages and trend analysis';
    }
    return 'Advanced forecasting algorithm';
  }
  
  Widget _buildMLMetricsSection(MLMetrics metrics) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Accuracy Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            if (metrics.lstm != null)
              _buildMetricRow('LSTM MAPE', metrics.lstm!.mape),
            if (metrics.xgboost != null)
              _buildMetricRow('XGBoost MAPE', metrics.xgboost!.mape),
            SizedBox(height: 8),
            Text(
              'Lower MAPE % = Better accuracy',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(2)}%',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Color _getMethodColor(String method) {
    if (method.contains('LSTM')) return Colors.purple;
    if (method.contains('XGBoost')) return Colors.blue;
    if (method.contains('ENSEMBLE')) return Colors.green;
    if (method.contains('HYBRID')) return Colors.orange;
    if (method.contains('STATISTICAL')) return Colors.teal;
    return Colors.grey;
  }
  
  IconData _getMethodIcon(String method) {
    if (method.contains('ML')) return Icons.psychology;
    if (method.contains('ENSEMBLE')) return Icons.layers;
    if (method.contains('STATISTICAL')) return Icons.equalizer;
    return Icons.info;
  }
}
```

### Option 3: Model to parse ML metrics

```dart
// In forecast models

class ForecastDetailModel {
  final int productId;
  final String productName;
  final double demand;
  final double demandLower;
  final double demandUpper;
  final double confidence;
  final String method;  // NEW
  final MLMetrics? mlMetrics;  // NEW
  
  ForecastDetailModel({
    required this.productId,
    required this.productName,
    required this.demand,
    required this.demandLower,
    required this.demandUpper,
    required this.confidence,
    required this.method,
    this.mlMetrics,
  });
  
  factory ForecastDetailModel.fromJson(Map<String, dynamic> json) {
    return ForecastDetailModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      demand: (json['forecasted_demand'] ?? 0).toDouble(),
      demandLower: (json['demand_lower_bound'] ?? 0).toDouble(),
      demandUpper: (json['demand_upper_bound'] ?? 0).toDouble(),
      confidence: (json['confidence_score'] ?? 0).toDouble(),
      method: json['forecasting_method'] ?? 'UNKNOWN',
      mlMetrics: json['ml_metrics'] != null
          ? MLMetrics.fromJson(json['ml_metrics'])
          : null,
    );
  }
}

class MLMetrics {
  final ModelMetric? lstm;
  final ModelMetric? xgboost;
  
  MLMetrics({this.lstm, this.xgboost});
  
  factory MLMetrics.fromJson(Map<String, dynamic> json) {
    return MLMetrics(
      lstm: json['lstm'] != null
          ? ModelMetric.fromJson(json['lstm'])
          : null,
      xgboost: json['xgboost'] != null
          ? ModelMetric.fromJson(json['xgboost'])
          : null,
    );
  }
}

class ModelMetric {
  final double mae;
  final double rmse;
  final double mape;
  final String status;
  
  ModelMetric({
    required this.mae,
    required this.rmse,
    required this.mape,
    required this.status,
  });
  
  factory ModelMetric.fromJson(Map<String, dynamic> json) {
    return ModelMetric(
      mae: (json['test_mae'] ?? 0).toDouble(),
      rmse: (json['test_rmse'] ?? 0).toDouble(),
      mape: (json['test_mape'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
    );
  }
}
```

---

## Testing & Validation

### Quick Test Script

```python
# Run this to test the hybrid system locally

from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm
from datetime import datetime, timedelta
import random

# Generate mock sales data
def generate_mock_sales(days=60, base_demand=100, seasonality=True):
    sales_data = []
    start_date = datetime.now() - timedelta(days=days)
    
    for i in range(days):
        date = start_date + timedelta(days=i)
        
        # Base demand with trend
        demand = base_demand + i * 0.5
        
        # Add seasonality
        if seasonality:
            demand *= (1 + 0.3 * ((i % 7) / 7))
        
        # Add noise
        demand += random.gauss(0, base_demand * 0.1)
        
        sales_data.append({
            'date': date,
            'quantity': max(1, int(demand)),
            'price': 50.0
        })
    
    return sales_data

# Test different data volumes
print("Testing Hybrid Forecasting System\n")
print("=" * 60)

for days in [15, 30, 60]:
    print(f"\nTest: {days} days of sales data")
    print("-" * 40)
    
    sales_data = generate_mock_sales(days=days)
    
    hybrid = create_hybrid_forecaster()
    stat_algo = ForecastingAlgorithm()
    
    forecast = hybrid.generate_hybrid_forecast(
        sales_data=sales_data,
        current_stock=500,
        min_stock=100,
        forecast_algorithm=stat_algo
    )
    
    print(f"Method: {forecast['forecasting_method']}")
    print(f"Demand: {forecast['forecasted_demand']} units")
    print(f"Confidence: {forecast['confidence_score']}%")
    print(f"Data Points: {len(sales_data)}")
    
    if 'ml_metrics' in forecast:
        print(f"ML Models Trained: {list(forecast['ml_metrics'].keys())}")

print("\n" + "=" * 60)
print("Test Complete!")
```

---

## Deployment Checklist

- [ ] Install ML dependencies: `pip install xgboost scikit-learn tensorflow`
- [ ] Copy `forecasting_ml.py` to Django app
- [ ] Copy `hybrid_forecasting.py` to Django app
- [ ] Update `seller_views.py` with hybrid integration
- [ ] Update `seller_models.py` with algorithm_used, algorithm_data fields
- [ ] Run database migrations
- [ ] Test with development data
- [ ] Configure Celery tasks (if using background training)
- [ ] Deploy to staging
- [ ] Monitor performance metrics
- [ ] Gather feedback
- [ ] Deploy to production
- [ ] Document in team wiki
- [ ] Add to runbooks

---

## Support

For questions or issues:
1. Check `FORECASTING_SYSTEM_GUIDE.md` for detailed documentation
2. Review `FORECASTING_IMPLEMENTATION_SUMMARY.md` for architecture overview
3. Run test script to verify installation
4. Check Django logs for detailed error messages
