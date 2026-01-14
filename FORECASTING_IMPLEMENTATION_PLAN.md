# Demand & Price Forecasting Feature - Implementation Plan

**Last Updated:** December 3, 2025  
**Status:** Planning Phase  
**Scope:** Complete integration from backend to frontend

---

## 🎯 Project Overview

Implement a production-ready demand and price forecasting feature for OPAS admins that:
- Analyzes historical sales and price data for all products
- Automatically selects appropriate forecasting models (SARIMA/ARIMA/Simple) based on data availability
- Provides month-ahead predictions for each product
- Displays forecasts in admin dashboard with confidence levels
- Updates forecasts periodically using background tasks

**Key Constraint:** Currently only Talong has sufficient historical data (~20+ weeks). Other products will use fallback models as data accumulates.

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        ADMIN DASHBOARD (Flutter)               │
│              [Forecasting View] [Product Selector]              │
└────────────────┬──────────────────────────────────────────────┘
                 │ HTTP Requests
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DJANGO REST API                            │
│  • GET /api/admin/forecasts/ - List forecasts                   │
│  • GET /api/admin/forecasts/{product_id}/ - Detail forecast    │
│  • POST /api/admin/forecasts/refresh/ - Trigger refresh        │
│  • GET /api/admin/forecasts/metadata/ - Model info & coverage  │
└────────────────┬──────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│            FORECASTING SERVICE LAYER (core/forecasting_service) │
│  • ForecastingService - Main orchestrator                       │
│  • ModelSelector - Auto-select SARIMA/ARIMA/Simple             │
│  • DataAggregator - Collect transaction data                    │
└────────────────┬──────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE MODELS                              │
│  • ProductForecast - Stores forecast results                    │
│  • ForecastMetadata - Model type, confidence, data_count       │
│  • HistoricalTransactions - Aggregated sales data              │
└────────────────┬──────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              BACKGROUND TASKS (Celery)                          │
│  • Weekly forecast refresh                                      │
│  • Data aggregation task                                        │
│  • Alert generation for anomalies                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Phase-by-Phase Implementation

### **PHASE 1: Backend Setup (Django Models & Infrastructure)**

#### 1.1 Create New Django App✅
```bash
cd Opas_Django
python manage.py startapp forecasting
```

#### 1.2 Database Models✅
Location: `apps/forecasting/models.py`

**Models to Create:**

a) **MarketHistoricalData** - External market reference data (NEW)
   - `product_name` (CharField - not FK, since external data)
   - `category_name` (CharField - from external source)
   - `market_date` (DateField - when this market data is from)
   - `quantity_kg` (Decimal - market traded quantity)
   - `price_per_kg` (Decimal - average market price)
   - `total_value` (Decimal - quantity × price)
   - `source` (CharField - "CSV Import", "Market Bureau", etc.)
   - `data_quality_score` (IntegerField 0-100 - 100 for imported data)
   - `notes` (TextField - additional context)
   - `created_at`, `updated_at`
   - **Purpose:** Store external market data for benchmarking and opportunity identification
   - **NOT tied to SellerProduct** - exists independently
   - **Used for:** Market trend analysis, pricing comparisons, identifying market opportunities

b) **ProductForecast** - Main forecast results
   - `product` (ForeignKey → SellerProduct)
   - `forecast_date` (DateTime - when forecast was generated)
   - `forecast_period` (Month/Period being forecasted, e.g., "2025-01")
   - `demand_forecast_kg` (Predicted quantity)
   - `demand_lower_bound` (95% confidence interval)
   - `demand_upper_bound` (95% confidence interval)
   - `price_forecast` (Predicted price per unit)
   - `price_lower_bound` (95% confidence interval)
   - `price_upper_bound` (95% confidence interval)
   - `confidence_level` (ENUM: HIGH/MEDIUM/LOW)
   - `model_type` (ENUM: SARIMA/ARIMA/SIMPLE/INSUFFICIENT_DATA)
   - `rmse_demand` (Model error metric)
   - `rmse_price` (Model error metric)
   - `is_current` (Boolean - is this the latest forecast?)
   - `created_at`, `updated_at`

c) **ForecastMetadata** - Model information & statistics
   - `product` (ForeignKey → SellerProduct)
   - `data_points_count` (How many historical records)
   - `last_training_date` (When model was last trained)
   - `model_type` (SARIMA/ARIMA/SIMPLE)
   - `model_parameters` (JSONField: stores order, seasonal_order, etc.)
   - `data_coverage_percentage` (% of months with data)
   - `is_reliable` (Boolean - enough data?)
   - `notes` (Text about model limitations)
   - `updated_at`

d) **HistoricalTransactions** - Aggregated ACTUAL sales data
   - `product` (ForeignKey → SellerProduct) - ONLY actual products being sold
   - `transaction_date` (Date of transaction)
   - `quantity_sold_kg` (Total quantity)
   - `average_price_per_kg` (Average selling price)
   - `total_revenue` (quantity × price)
   - `transaction_count` (Number of individual transactions)
   - `data_quality_score` (0-100, indicates completeness)
   - **Purpose:** Store ACTUAL SellerProduct sales for forecasting
   - **Dynamic data** - updated in real-time via signals and daily Celery tasks
   - **Used ONLY for training forecasting models**

e) **ForecastAlert** - Anomalies & alerts for admins
   - `product` (ForeignKey → SellerProduct)
   - `alert_type` (ENUM: DECLINING_DEMAND/PRICE_SPIKE/LOW_CONFIDENCE)
   - `severity` (ENUM: INFO/WARNING/CRITICAL)
   - `message` (Description of alert)
   - `is_acknowledged` (Boolean)
   - `created_at`, `acknowledged_at`

#### 1.3 Update requirements.txt✅
Add forecasting dependencies:
```
statsmodels>=0.14.0
pmdarima>=2.0.3
pandas>=2.0.0
numpy>=1.24.0
celery>=5.3.0
```

#### 1.4 Register App in settings.py✅
```python
INSTALLED_APPS = [
    ...
    'apps.forecasting',
]
```

---

### **PHASE 2: Data Pipeline (Extract & Aggregate Historical Data)**

#### 2.1 Data Aggregator Service✅
Location: `apps/forecasting/services/data_aggregator.py`

**Functionality:**
```python
class DataAggregator:
    """
    Collects transaction data from SellerOrder, SellerProduct to build
    historical time series data.
    """
    
    def collect_product_transactions(product_id):
        """
        Query SellerOrder records where:
        - product == product_id
        - status IN (FULFILLED, DELIVERED)
        - Extract: order_date, quantity, price
        Return: DataFrame with (date, quantity_kg, price_per_kg)
        """
    
    def aggregate_to_weekly(df):
        """Resample transaction-level data to weekly aggregates"""
        return df.resample('W').agg({
            'quantity_kg': 'sum',
            'price_per_kg': 'mean'
        })
    
    def aggregate_to_monthly(df):
        """Resample to monthly aggregates (if not enough weekly data)"""
        return df.resample('M').agg({
            'quantity_kg': 'sum',
            'price_per_kg': 'mean'
        })
    
    def validate_data_quality(df):
        """
        Check:
        - Minimum 5 data points
        - No more than 40% missing values
        - Return quality score (0-100)
        """
```

---

## 🏗️ Dual-Table Architecture: MarketHistoricalData vs HistoricalTransactions

**KEY DISTINCTION:**

This forecasting system uses **two separate data tables** for different purposes:

### **1. MarketHistoricalData** (External Reference)
- **Source:** CSV imports, market bureaus, agricultural reports
- **Data:** Historical market prices and volumes for ANY product
- **Update Frequency:** Manual (imports only)
- **Linked to Products?** NO - product_name is just a string
- **Purpose:** 
  - Market trend analysis
  - Price benchmarking
  - Identify market opportunities (e.g., "Papaya trending but we don't sell it")
  - Historical context for admin dashboard
- **Example:** "Papaya was trading at ₱50/kg in Jan 2025 across the market"

### **2. HistoricalTransactions** (Actual Sales - ONLY)
- **Source:** Real SellerOrder records (FULFILLED/DELIVERED status)
- **Data:** Actual sales by farmers + OPAS admin
- **Update Frequency:** Real-time signals + daily Celery aggregation
- **Linked to Products?** YES - ForeignKey to SellerProduct
- **Purpose:**
  - Train forecasting models
  - Forecast demand/price for actual inventory
  - Track sales trends
- **Example:** "Our farmers sold 150kg of Papaya at ₱52/kg on 2025-01-15"

### **Why Separate?**

| Aspect | MarketHistoricalData | HistoricalTransactions |
|--------|---------------------|----------------------|
| **Contains** | External market data | Your actual sales |
| **Scope** | Any product name | Only SellerProduct |
| **Purpose** | Market context | Forecasting |
| **Admin Benefit** | "Market trending Papaya - should we grow?" | "We're selling Papaya well - forecast next week" |
| **Updated** | Manually (CSV) | Automatically (signals/tasks) |

### **Data Flow Diagram**

```
CSV File (Market Data)
    ↓
import_historical_csv command
    ↓
MarketHistoricalData table (45 products, ~288 data points)
    ├─ Used for: Market analysis, trend viewing, opportunity ID
    └─ NOT used for forecasting

SellerOrder (Real Sales)
    ↓
    ├─ Signal: order marked FULFILLED
    ├─ Task: aggregate_recent_transactions (daily)
    └─ Task: aggregate_all_products_batch (weekly)
    ↓
HistoricalTransactions table (Only products farmers/admin actually sell)
    ├─ Used for: Training forecasting models
    ├─ ModelSelector picks SARIMA/ARIMA/SIMPLE
    └─ ForecastingService generates predictions
    ↓
ProductForecast + ForecastMetadata
    ↓
Admin Dashboard (Flutter)
    ├─ Shows: "Talong: forecast 250kg next week"
    └─ Also shows: Market context from MarketHistoricalData
```

### **Benefits of This Architecture**

1. **Clean Separation of Concerns**
   - Market data doesn't pollute operational forecasting
   - Forecasts only for products you actually sell
   
2. **Dynamic Updates**
   - HistoricalTransactions auto-updates as orders flow in
   - No need to manually import sales data
   - OPAS admin products update same as farmer products
   
3. **Scalability**
   - MarketHistoricalData can have millions of historical records
   - Doesn't slow down forecasting (different table)
   - Can add more market sources without affecting forecasts
   
4. **Admin Insights**
   - Compare your prices vs. market prices
   - Spot market opportunities
   - See trends without noise

---

---

### **PHASE 3: Forecasting Engine (Model Selection & Prediction)**

#### 3.1 Model Selector Service✅
Location: `apps/forecasting/services/model_selector.py`

**Logic:**
```python
class ModelSelector:
    """
    Intelligently selects forecasting model based on data availability.
    """
    
    def select_model(data_points_count, variance, data_completeness):
        """
        Decision Tree:
        
        IF data_points >= 24 AND variance > threshold:
            return 'SARIMA'  # Full seasonal ARIMA
        ELIF data_points >= 12 AND variance > threshold:
            return 'ARIMA'   # Non-seasonal ARIMA
        ELIF data_points >= 5:
            return 'SIMPLE'  # Exponential smoothing fallback
        ELSE:
            return 'INSUFFICIENT_DATA'
        """
```

#### 3.2 Forecasting Service✅
Location: `apps/forecasting/services/forecasting_service.py`

**Main Features:**
```python
class ForecastingService:
    """Main orchestrator for all forecasting operations"""
    
    def generate_forecast(product_id, forecast_steps=4, forecast_period='W'):
        """
        1. Fetch historical transactions for product
        2. Validate data quality
        3. Select appropriate model (SARIMA/ARIMA/Simple)
        4. Train model
        5. Generate forecast (next 4 weeks/months)
        6. Calculate confidence intervals
        7. Store in ProductForecast model
        Return: ForecastResult object with all predictions
        """
    
    def train_sarima_model(series, order, seasonal_order):
        """Wrap existing SARIMA code from demand_and_price_forecasting/"""
    
    def train_arima_model(series, order):
        """Non-seasonal ARIMA fallback"""
    
    def train_simple_model(series):
        """Exponential smoothing for sparse data"""
    
    def batch_generate_all_products():
        """Generate forecasts for all products with sufficient data"""
        For each SellerProduct:
            Try generate_forecast()
            On failure: Mark as INSUFFICIENT_DATA
        Store ForecastMetadata for each product
    
    def refresh_forecasts():
        """Scheduled task to regenerate all forecasts weekly"""
```

#### 3.3 Error Handling & Robustness✅
- Graceful degradation: If model training fails, use previous forecast or mark as unavailable
- Stale forecast detection: Flag forecasts older than 7 days
- Data validation: Check for outliers, NaN values before model training

---

### **PHASE 4: Admin API & Views**

#### 4.1 Django Views & Serializers✅
Location: `apps/forecasting/views.py` and `apps/forecasting/serializers.py`

**API Endpoints:**

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/api/admin/forecasts/` | GET | List all product forecasts | Admin |
| `/api/admin/forecasts/{product_id}/` | GET | Detailed forecast for one product | Admin |
| `/api/admin/forecasts/search/` | GET | Filter by category, confidence level, etc. | Admin |
| `/api/admin/forecasts/metadata/` | GET | Model coverage & statistics | Admin |
| `/api/admin/forecasts/refresh/` | POST | Trigger manual forecast refresh | Super Admin |
| `/api/admin/forecasts/alerts/` | GET | List forecast alerts | Admin |

#### 4.2 Serializers✅
```python
class ForecastSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name')
    product_category = serializers.CharField(source='product.category.name')
    
    class Meta:
        model = ProductForecast
        fields = [
            'id', 'product_id', 'product_name', 'product_category',
            'forecast_date', 'forecast_period',
            'demand_forecast_kg', 'demand_lower_bound', 'demand_upper_bound',
            'price_forecast', 'price_lower_bound', 'price_upper_bound',
            'confidence_level', 'model_type', 'is_current'
        ]

class ForecastMetadataSerializer(serializers.ModelSerializer):
    class Meta:
        model = ForecastMetadata
        fields = [
            'product_id', 'data_points_count', 'model_type',
            'last_training_date', 'is_reliable', 'notes'
        ]
```

#### 4.3 Permission Classes✅
```python
class IsAdminForForecasting(BasePermission):
    """
    Allow Super Admin or Analytics Admin to view forecasts
    """
    def has_permission(self, request, view):
        return (request.user and 
                request.user.is_admin and
                request.user.admin_role in ['SUPER_ADMIN', 'ANALYTICS_ADMIN'])
```

---

### **PHASE 5: Frontend (Flutter Admin Dashboard)**

#### 5.1 New Screens

**a) Forecasting Dashboard Screen** (`lib/features/admin/screens/forecasting_dashboard_screen.dart`)✅
```
┌─────────────────────────────────────────────┐
│          Forecasting Dashboard              │
├─────────────────────────────────────────────┤
│  [Filter by Category] [Last Updated: 1h]    │
│  [Refresh Now] [Export CSV]                 │
├─────────────────────────────────────────────┤
│  Product Forecast Summary Card              │
│  ┌─────────────────────────────────────┐    │
│  │ Talong (Eggplant)                   │    │
│  │ ✅ Model: SARIMA | Confidence: HIGH │    │
│  │ Demand: 250 kg (±15) [Jan 2025]     │    │
│  │ Price: ₱45/kg (±3) [Jan 2025]       │    │
│  │ [View Details] [See History]        │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [More Products...]                        │
└─────────────────────────────────────────────┘
```

**b) Product Forecast Detail Screen** (`lib/features/admin/screens/product_forecast_detail_screen.dart`)✅
```
┌─────────────────────────────────────────────┐
│  Talong Demand & Price Forecast             │
├─────────────────────────────────────────────┤
│  Model Info: SARIMA(1,1,1)(0,1,0)_12       │
│  Data Points: 26 weeks | Last Updated: 2h  │
│  Confidence Level: ⭐⭐⭐⭐⭐ (HIGH)         │
├─────────────────────────────────────────────┤
│  📊 Demand Forecast (Next 4 Weeks)         │
│  [Line Chart: Historical + Forecast]       │
│  Week 1: 250kg ±15kg                       │
│  Week 2: 268kg ±18kg                       │
│  Week 3: 240kg ±12kg                       │
│  Week 4: 275kg ±20kg                       │
├─────────────────────────────────────────────┤
│  💰 Price Forecast (Next 4 Weeks)          │
│  [Line Chart: Historical + Forecast]       │
│  Week 1: ₱45/kg ±₱3                        │
│  Week 2: ₱47/kg ±₱4                        │
│  Week 3: ₱42/kg ±₱2                        │
│  Week 4: ₱50/kg ±₱5                        │
├─────────────────────────────────────────────┤
│  ⚠️ Alerts: None                            │
│  [Export Report] [Email Forecast]          │
└─────────────────────────────────────────────┘
```

#### 5.2 New Widgets ✅ COMPLETE
- `ForecastCard` ✅ - Display forecast summary
- `ForecastChart` ✅ - Line chart with confidence intervals
- `ModelMetadataTag` ✅ - Show model type & confidence level
- `NoForecastPlaceholder` ✅ - When insufficient dataa

#### 5.3 API Integration✅
```dart
class ForecastingApiClient {
  Future<List<ForecastDto>> getAllForecasts() async {
    return _apiClient.get('/api/admin/forecasts/');
  }
  
  Future<ForecastDetailDto> getForecastDetail(int productId) async {
    return _apiClient.get('/api/admin/forecasts/$productId/');
  }
  
  Future<ForecastMetadataDto> getMetadata() async {
    return _apiClient.get('/api/admin/forecasts/metadata/');
  }
}
```

#### 5.4 State Management (Provider/Riverpod)✅
```dart
final forecastProvider = StateNotifierProvider<ForecastNotifier, ForecastState>((ref) {
  return ForecastNotifier(ref.watch(forecastApiClientProvider));
});

class ForecastNotifier extends StateNotifier<ForecastState> {
  Future<void> loadForecasts() async {
    state = ForecastState.loading();
    final forecasts = await _apiClient.getAllForecasts();
    state = ForecastState.success(forecasts);
  }
}
```

---

### **PHASE 6: Background Tasks (Celery)**

#### 6.1 Celery Configuration
Location: `Opas_Django/celery_app.py`

**Tasks:**

a) **Periodic Forecast Refresh** (Weekly, Sunday 2 AM UTC)✅
```python
@periodic_task(run_every=crontab(day_of_week=6, hour=2, minute=0))
def refresh_all_forecasts():
    """
    - Call ForecastingService.batch_generate_all_products()
    - Log generation status
    - Create alerts if models fail
    - Email admins with summary
    """
```

b) **Daily Data Aggregation**✅
```python
@periodic_task(run_every=crontab(hour=1, minute=0))
def aggregate_recent_transactions():
    """
    - Query SellerOrder from last 24 hours
    - Update HistoricalTransactions table
    - Detect anomalies in recent sales
    """
```

c) **Alert Generation**✅
```python
@periodic_task(run_every=crontab(hour=6, minute=0))
def check_forecast_alerts():
    """
    - Compare forecast vs actual (if available)
    - Detect declining demand trends
    - Detect price anomalies
    - Create ForecastAlert records
    """
```

#### 6.2 Celery Beat Configuration✅
```python
# settings.py
CELERY_BEAT_SCHEDULE = {
    'refresh_all_forecasts': {
        'task': 'apps.forecasting.tasks.refresh_all_forecasts',
        'schedule': crontab(day_of_week=6, hour=2, minute=0),
    },
    'aggregate_recent_transactions': {
        'task': 'apps.forecasting.tasks.aggregate_recent_transactions',
        'schedule': crontab(hour=1, minute=0),
    },
    'check_forecast_alerts': {
        'task': 'apps.forecasting.tasks.check_forecast_alerts',
        'schedule': crontab(hour=6, minute=0),
    },
}
```

---

### **PHASE 7: Testing & Deployment**

#### 7.1 Unit Tests
Location: `apps/forecasting/tests/test_*.py`

Tests to Create:
- `test_model_selector.py` - Model selection logic
- `test_data_aggregator.py` - Data collection & validation
- `test_forecasting_service.py` - Forecast generation
- `test_api_endpoints.py` - REST endpoint behavior
- `test_permissions.py` - Admin-only access

#### 7.2 Integration Tests
- Test full forecasting pipeline (data → model → storage → API)
- Test Celery task execution
- Test API with various product/data scenarios

#### 7.3 Performance Tests
- Load test with 1000+ products
- Forecast generation time benchmarks
- Database query optimization

#### 7.4 Production Deployment
- Database migrations
- Update Docker image with new dependencies
- Configure Celery worker & beat scheduler
- Set up monitoring/logging for forecast tasks
- Documentation & admin training

---

## 📋 Dependencies & Requirements✅

### Backend Requirements
```
Django>=4.2.0
djangorestframework>=3.14.0
pandas>=2.0.0
numpy>=1.24.0
statsmodels>=0.14.0
pmdarima>=2.0.3
celery>=5.3.0
redis>=5.0.0
```

### Existing Infrastructure
- ✅ PostgreSQL (already have)
- ✅ Redis (for caching & Celery)
- ✅ Django REST Framework (already have)
- ⚠️ Celery + Celery Beat (need to add/configure)

### Frontend Requirements
- ✅ Flutter (already have)
- ✅ Provider package for state management
- 📊 `fl_chart` package for charts (may need to add)
- 📊 `charts_flutter` alternative

---

## 🎯 Data Flow Example: Talong Forecast

**Existing State:**
- `demand_and_price_forecasting/cleaned data.csv` contains historical market data (~45 products, 288 rows)
- Some farmers grow Talong and have SellerProduct record

**New Workflow:**

1. **Data Ingestion - Market Reference**
   - Run import command: `python manage.py import_historical_csv`
   - Import CSV → MarketHistoricalData table (45 products, ~260 records)
   - Talong market data available for context/analysis
   - Available for admin dashboard market analysis

2. **Data Ingestion - Actual Sales**
   - Farmers start selling Talong products (SellerOrder records)
   - Signal handler auto-updates HistoricalTransactions with each FULFILLED order
   - Or: Celery task daily aggregates orders from last 24 hours
   - HistoricalTransactions now has REAL Talong sales data (separate from CSV)

3. **Weekly Forecast Generation (Sunday 2 AM)**
   - Celery task: `refresh_all_forecasts()`
   - ForecastingService queries HistoricalTransactions for Talong (actual sales only)
   - If 26+ data points: Model Selector chooses SARIMA
   - Auto-ARIMA determines order: (1,1,1)(0,1,0)_12
   - Train SARIMA on Talong HistoricalTransactions data
   - Generate 4-week forecast
   - Store in ProductForecast with confidence intervals
   - Create ForecastMetadata record

4. **Admin Views Forecast**
   - Admin opens Flutter app → Forecasting Dashboard
   - API call: GET `/api/admin/forecasts/`
   - Returns all forecasts based on ACTUAL SALES (HistoricalTransactions)
   - Admin clicks Talong → ProductForecastDetailScreen
   - Shows demand/price charts with confidence bands
   - ALSO shows: Market context (MarketHistoricalData)
   - Can compare forecast vs market prices
   - Admin can export or share forecast

5. **Ongoing Updates**
   - New Talong SellerOrders → HistoricalTransactions updated in real-time
   - Every 7 days: Forecast regenerated with fresh actual sales data
   - Model becomes more accurate as more real data accumulates
   - Market data (MarketHistoricalData) refreshed only when manually imported

---

## 🚀 Quick Start Implementation Order

1. **Week 1: Backend Foundation**
   - Create forecasting app and models
   - Build data aggregator service
   - Test with Talong data from CSV

2. **Week 2: Forecasting Engine**
   - Implement model selector
   - Port existing SARIMA code
   - Add ARIMA/Simple fallbacks

3. **Week 3: API & Admin Views**
   - Create REST endpoints
   - Build permission system
   - Test with real data

4. **Week 4: Frontend**
   - Design forecasting screens
   - Implement charts and display logic
   - Connect to API

5. **Week 5: Background Tasks & Polish**
   - Set up Celery tasks
   - Add monitoring/alerts
   - Full system testing
   - Documentation

---

## ⚠️ Known Challenges & Mitigations

| Challenge | Mitigation |
|-----------|-----------|
| Sparse data for most products | Use hybrid model selection with fallbacks |
| Model training time (SARIMA can be slow) | Cache trained models, async Celery tasks |
| Forecast accuracy depends on data quality | Validate data quality before training, track RMSE |
| Admin UI complexity | Provide clear confidence labels & tooltips |
| Storage of forecasts (predictions grow) | Archive old forecasts, keep only recent 12 months |
| Celery reliability | Use Redis persistence, implement retry logic |

---

## 📊 Success Criteria

✅ **MVP Launch Criteria:**
- [ ] Talong forecasts generating reliably
- [ ] Admin can view forecasts via API
- [ ] Simple Flutter UI displays forecasts
- [ ] Forecasts update weekly via Celery
- [ ] Model selection works (SARIMA/ARIMA/Simple)
- [ ] No crashes with missing data

✅ **v1.0 Criteria:**
- [ ] 5+ products with sufficient data → forecasts available
- [ ] Forecast accuracy within ±20% for validation set
- [ ] Admin dashboard with charts and filtering
- [ ] Alerts for demand/price anomalies
- [ ] Historical forecast accuracy tracking
- [ ] Mobile-responsive Flutter UI

---

## 📞 Next Steps

1. **Confirm Requirements**: Review this plan with stakeholders
2. **Approve Architecture**: Sign off on database schema & API design
3. **Begin Phase 1**: Start with backend models and services
4. **Parallel Work**: Data pipeline can start while frontend team prepares
5. **Integration Testing**: Weekly sync to integrate phases

---

**Questions or clarifications needed before we begin implementation?**
