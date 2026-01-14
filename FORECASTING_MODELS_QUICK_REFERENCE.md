# Forecasting Models Quick Reference

## File Locations
```
Opas_Django/
├── apps/forecasting/
│   ├── models.py              ← All 4 models defined here
│   ├── admin.py               ← Admin interface
│   ├── migrations/0001_initial.py ← ✅ Applied
│   └── views.py               ← Placeholder for Phase 4
```

## Model Relationships Diagram

```
SellerProduct (users app)
    │
    ├─→ admin_forecasts (admin_forecasts.all()) 
    │       └── ProductForecast (can have many forecasts over time)
    │           ├─ forecast_date
    │           ├─ forecast_period (e.g., "2025-01-Week1")
    │           ├─ is_current (only one per product)
    │           ├─ demand_forecast_kg ± bounds
    │           ├─ price_forecast ± bounds
    │           └─ model_type, confidence_level, metrics
    │
    ├─→ forecast_metadata (one-to-one)
    │       └── ForecastMetadata (ONE per product)
    │           ├─ data_points_count
    │           ├─ model_type
    │           ├─ is_reliable
    │           └─ model_parameters (JSON)
    │
    └─→ historical_transactions (historical_transactions.all())
            └── HistoricalTransactions (many per product)
                ├─ transaction_date
                ├─ quantity_sold_kg
                ├─ average_price_per_kg
                ├─ total_revenue (auto-calculated)
                └─ data_quality_score

ProductForecast
    └─→ alerts (alerts.all())
            └── ForecastAlert (many alerts per forecast)
                ├─ alert_type (DECLINING_DEMAND, PRICE_SPIKE, etc.)
                ├─ severity (INFO, WARNING, CRITICAL)
                ├─ message
                └─ is_acknowledged
```

## Quick Field Reference

### ProductForecast
- **Demand**: `demand_forecast_kg`, `demand_lower_bound`, `demand_upper_bound`
- **Price**: `price_forecast`, `price_lower_bound`, `price_upper_bound`
- **Quality**: `model_type`, `confidence_level`, `rmse_demand`, `rmse_price`, `mape_demand`, `mape_price`
- **Status**: `is_current` (latest forecast flag)

### ForecastMetadata
- **Model Info**: `model_type`, `data_points_count`, `data_coverage_percentage`, `is_reliable`
- **Parameters**: `model_parameters` (JSON field)
- **Dates**: `last_training_date`, `last_successful_forecast_date`

### HistoricalTransactions
- **Sales**: `quantity_sold_kg`, `average_price_per_kg`, `total_revenue` (auto)
- **Count**: `transaction_count` (# of orders in period)
- **Quality**: `data_quality_score` (0-100), `is_complete` (boolean)

### ForecastAlert
- **Types**: DECLINING_DEMAND, PRICE_SPIKE, LOW_CONFIDENCE, ANOMALY, MODEL_FAILURE
- **Severity**: INFO, WARNING, CRITICAL
- **Status**: `is_acknowledged`, `acknowledged_by`, `acknowledged_at`, `resolved_at`

## Django Admin URLs
```
/admin/forecasting/productforecast/         ← View all forecasts
/admin/forecasting/forecastmetadata/        ← View model stats
/admin/forecasting/historicaltransactions/  ← View transaction history
/admin/forecasting/forecastalert/           ← Manage alerts
```

## Queries Examples

```python
# Get latest forecast for a product
latest = ProductForecast.objects.filter(
    product_id=123, 
    is_current=True
).first()

# Get metadata to check reliability
metadata = ForecastMetadata.objects.get(product_id=123)
if metadata.is_reliable:
    print("Model has enough data")

# Get historical data for a product
history = HistoricalTransactions.objects.filter(
    product_id=123
).order_by('-transaction_date')[:52]  # Last year of data

# Get unacknowledged alerts
alerts = ForecastAlert.objects.filter(
    is_acknowledged=False
).select_related('product')

# Get alerts for specific product
product_alerts = ForecastAlert.objects.filter(
    product_id=123,
    severity='CRITICAL'
).order_by('-created_at')
```

## Enum Choices

```python
ModelType = [
    'SARIMA',            # Seasonal ARIMA (24+ data points)
    'ARIMA',             # Non-seasonal (12-24 points)
    'SIMPLE',            # Exponential smoothing (5-12 points)
    'INSUFFICIENT_DATA'  # <5 points
]

ConfidenceLevel = [
    'HIGH',    # Model has 24+ data points
    'MEDIUM',  # Model has 12-24 data points
    'LOW'      # Model has <12 data points
]

AlertType = [
    'DECLINING_DEMAND',
    'PRICE_SPIKE',
    'LOW_CONFIDENCE',
    'ANOMALY',
    'MODEL_FAILURE'
]

AlertSeverity = [
    'INFO',
    'WARNING', 
    'CRITICAL'
]
```

## Indexes for Performance
```
ProductForecast
├── (product_id, -forecast_date)           ← Get latest per product
├── (product_id, is_current)               ← Get current forecast
├── model_type                             ← Filter by model
└── confidence_level                       ← Filter by confidence

HistoricalTransactions
├── (product_id, transaction_date)         ← Get period data
├── (product_id, -transaction_date)        ← Get recent
└── transaction_date                       ← Date range queries

ForecastMetadata
└── (model_type, is_reliable)              ← Find reliable models

ForecastAlert
├── (product_id, -created_at)              ← Get product alerts
├── (alert_type, is_acknowledged)          ← Find unacknowledged
└── (severity, -created_at)                ← Priority sorting
```

## Testing Tips

```python
from apps.forecasting.models import ProductForecast, HistoricalTransactions
from apps.users.models import SellerProduct
from decimal import Decimal

# Create test data
product = SellerProduct.objects.first()

# Add historical transaction
transaction = HistoricalTransactions.objects.create(
    product=product,
    transaction_date='2025-01-01',
    quantity_sold_kg=Decimal('100.00'),
    average_price_per_kg=Decimal('50.00'),
    data_quality_score=100
)

# Create forecast
forecast = ProductForecast.objects.create(
    product=product,
    forecast_period='2025-02',
    demand_forecast_kg=Decimal('110.00'),
    demand_lower_bound=Decimal('100.00'),
    demand_upper_bound=Decimal('120.00'),
    price_forecast=Decimal('52.00'),
    price_lower_bound=Decimal('50.00'),
    price_upper_bound=Decimal('54.00'),
    model_type='SARIMA',
    confidence_level='HIGH'
)
```

---

**Phase 1.2 Completed! Ready for Phase 2: Data Pipeline** ✅
