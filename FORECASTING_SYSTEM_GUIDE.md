# OPAS Forecasting System: Learning Types & Implementation

## Overview

The OPAS forecasting system implements a **hybrid approach** combining multiple learning types:

### 1. **Unsupervised Learning (Current System)**
**Module:** `forecasting_algorithm.py`

**Type:** Statistical Time Series Analysis

**Methods:**
- Moving Average (MA)
- Exponential Smoothing
- Seasonality Detection (unsupervised pattern recognition)
- Trend Analysis

**Characteristics:**
- No labeled training data required
- Learns patterns directly from historical data
- Low computational overhead
- Works with limited data (30+ days)
- Deterministic and interpretable

**Pros:**
- ✅ Works with sparse data
- ✅ Fast predictions
- ✅ Explainable results
- ✅ No dependencies on ML libraries

**Cons:**
- ❌ Limited to statistical patterns
- ❌ Cannot capture complex non-linear relationships
- ❌ Less accurate with highly volatile data

---

### 2. **Supervised Learning (New: ML Module)**
**Module:** `forecasting_ml.py`

**Type:** Neural Networks & Gradient Boosting

#### **A. LSTM (Long Short-Term Memory)**
**Learning Paradigm:** Supervised Deep Learning

**How it works:**
```
Input: Historical sequences (14 days of sales)
    ↓
LSTM Layer 1 (64 units) → Learns temporal dependencies
    ↓
LSTM Layer 2 (32 units) → Learns hierarchical patterns
    ↓
Dense Layer (16 units) → Combines features
    ↓
Output: Predicted demand for next day
```

**What it learns:**
- Temporal dependencies (how past sales influence future)
- Complex non-linear patterns
- Seasonal cycles at multiple scales
- Peak/valley patterns

**Training:**
- Requires labeled data: (historical_sequence → target_sales)
- Uses 80-20 train-test split
- Optimizes for minimum MSE (Mean Squared Error)
- Metrics: MAE, RMSE, MAPE

**Pros:**
- ✅ Captures complex temporal patterns
- ✅ Handles multiple time scales
- ✅ Better accuracy on volatile data
- ✅ Learns non-linear relationships

**Cons:**
- ❌ Requires 60+ days of data
- ❌ Slower inference time
- ❌ Black-box predictions
- ❌ Needs TensorFlow dependency

#### **B. XGBoost (eXtreme Gradient Boosting)**
**Learning Paradigm:** Supervised Ensemble Learning

**How it works:**
```
Feature Engineering:
  - Temporal: day_of_week, month, quarter, is_weekend
  - Lag features: sales from 1, 7, 14, 30 days ago
  - Statistics: rolling mean, std, min, max
  - Trend: EMA (Exponential Moving Average)
    ↓
Gradient Boosting:
  Decision Tree 1 (residuals from mean)
    ↓
  Decision Tree 2 (residuals from Tree 1)
    ↓
  Decision Tree N (iterative refinement)
    ↓
Output: Combined predictions from all trees
```

**What it learns:**
- Feature importance (which factors matter most)
- Non-linear feature interactions
- Local patterns and exceptions
- Robust to outliers

**Training:**
- Engineered 20+ features from sales data
- 100 decision trees with max depth 6
- Optimizes for minimum MAE
- Metrics: MAE, RMSE, MAPE + Feature Importance

**Pros:**
- ✅ Excellent generalization
- ✅ Fast predictions (tree-based)
- ✅ Feature importance transparency
- ✅ Robust to outliers
- ✅ Works with 30+ days of data

**Cons:**
- ❌ Still requires significant data
- ❌ Requires XGBoost library
- ❌ Feature engineering needed

---

### 3. **Hybrid Learning (New: Integration Strategy)**
**Module:** `hybrid_forecasting.py`

**Strategy:** Intelligent method selection + weighted ensemble

```
Decision Tree:

IF data_points < 20 days:
  └─ Use STATISTICAL_ONLY (best for sparse data)

ELSE IF data_points < 30 days:
  └─ Use STATISTICAL_ONLY with high uncertainty

ELSE IF data_points < 60 days AND ML available:
  └─ Use HYBRID_WEIGHTED:
     ├─ 60% Statistical (stable, proven)
     └─ 40% ML models (learning signal)

ELSE IF data_points >= 60 days AND ML available:
  └─ Use ML_ENSEMBLE with STATISTICAL_BASELINE:
     ├─ Ensemble: 40% LSTM + 40% XGBoost
     └─ Validate against: Statistical baseline
```

**Confidence Scoring:**
```python
IF method == 'STATISTICAL_ONLY':
    confidence = base_score (30-80) based on volatility & trend

IF method == 'HYBRID_WEIGHTED':
    confidence = (stat_confidence + 10) capped at 100

IF method == 'ML_ENSEMBLE':
    confidence = (ML_confidence + Statistical_confidence) / 2
```

---

## When to Use Each Method

| Scenario | Data Available | Method | Accuracy | Speed | Complexity |
|----------|----------------|--------|----------|-------|------------|
| Startup phase | <20 days | Manual/Default | Low | Fast | Low |
| Early stage | 20-30 days | Statistical | Medium | Fast | Low |
| Growth phase | 30-60 days | Hybrid Weighted | Medium-High | Medium | Medium |
| Maturity | 60+ days | ML Ensemble | High | Medium | High |
| High volatility | 60+ days | XGBoost primary | High | Fast | Medium |
| Stable patterns | 60+ days | LSTM primary | High | Slower | High |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│         OPAS Forecasting System                          │
└─────────────────────────────────────────────────────────┘
                           ▼
        ┌──────────────────────────────────┐
        │   Hybrid Forecasting Strategy    │
        │  (Data availability detection)   │
        └──────────┬───────────────────────┘
                   ▼
    ┌──────────────────────────────────────────┐
    │  Select appropriate method(s)             │
    └──────┬──────────┬──────────┬─────────────┘
           ▼          ▼          ▼
    ┌─────────┐ ┌──────────┐ ┌──────────────┐
    │STATISTICAL│ │HYBRID   │ │ML_ENSEMBLE  │
    │  ONLY   │ │WEIGHTED │ │(with        │
    │         │ │         │ │ validation) │
    │ • MA    │ │ • 60%   │ │ • LSTM      │
    │ • EXP   │ │   Stat  │ │ • XGBoost   │
    │   SMOOTH│ │ • 40%   │ │ • 40%+40%   │
    │ • Season│ │   ML    │ │   weighted  │
    │ • Trend │ │         │ │             │
    └─────────┘ └──────────┘ └──────────────┘
           ▼          ▼          ▼
    ┌──────────────────────────────────────────┐
    │  Ensemble Prediction & Validation        │
    │  • Sanity checks                          │
    │  • Outlier detection                      │
    │  • Confidence scoring                     │
    └──────────────────────────────────────────┘
           ▼
    ┌──────────────────────────────────────────┐
    │  Final Forecast Output                    │
    │  • Forecasted demand (quantity)           │
    │  • Confidence score (0-100)               │
    │  • Method used                            │
    │  • Risk assessment (surplus/stockout)     │
    │  • Recommendations                        │
    └──────────────────────────────────────────┘
```

---

## Implementation Details

### Feature Engineering (XGBoost)

**Temporal Features:**
- `day_of_week`: 0-6 (captures day-level patterns)
- `day_of_month`: 1-31 (captures monthly patterns)
- `month`: 1-12 (seasonal patterns)
- `is_weekend`: 0/1 (weekend effect)
- `quarter`: 1-4 (quarterly trends)

**Lag Features:**
- `lag_1`, `lag_7`, `lag_14`, `lag_30`: Previous sales values
- Captures auto-correlation in time series

**Rolling Statistics (7, 14, 30 days):**
- `rolling_mean`: Recent average trend
- `rolling_std`: Recent volatility
- `rolling_min`, `rolling_max`: Range bounds

**Exponential Moving Average:**
- `ema_7`, `ema_30`: Weighted recent history

### LSTM Architecture

```
Input Layer
  ↓
LSTM(64, return_sequences=True)  # 64 LSTM cells, pass sequence forward
  ↓
Dropout(0.2)  # Prevent overfitting
  ↓
LSTM(32)  # 32 cells, output single vector
  ↓
Dropout(0.2)
  ↓
Dense(16, activation='relu')  # Feature combination
  ↓
Dense(1)  # Single output: demand prediction
```

**Training Parameters:**
- Optimizer: Adam (adaptive learning)
- Loss: MSE (Mean Squared Error)
- Epochs: 50
- Batch Size: 32
- Sequence Length: 14 days

### XGBoost Configuration

```python
XGBRegressor(
    n_estimators=100,      # 100 decision trees
    max_depth=6,           # Prevent overfitting
    learning_rate=0.1,     # Regularization
    subsample=0.8,         # Use 80% of samples per tree
    colsample_bytree=0.8   # Use 80% of features per tree
)
```

---

## Usage Example

### Basic Usage (Automatic Selection)

```python
from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm

# Initialize
hybrid = create_hybrid_forecaster()
stat_forecaster = ForecastingAlgorithm()

# Generate forecast (system automatically selects method)
forecast = hybrid.generate_hybrid_forecast(
    sales_data=historical_sales,
    current_stock=current_stock,
    min_stock=min_stock,
    forecast_algorithm=stat_forecaster
)

# Access results
print(f"Forecast: {forecast['forecasted_demand']} units")
print(f"Method: {forecast['forecasting_method']}")
print(f"Confidence: {forecast['confidence_score']}%")
```

### Advanced Usage (Explicit Control)

```python
from apps.users.forecasting_ml import LSTMForecaster, XGBoostForecaster

# Train individual models
lstm = LSTMForecaster(seq_length=14)
lstm_results = lstm.train(sales_data, epochs=50)

xgb = XGBoostForecaster()
xgb_results = xgb.train(sales_data)

# Generate predictions
lstm_pred = lstm.predict(sales_data, days_ahead=30)
xgb_pred = xgb.predict(sales_data, days_ahead=30)
```

---

## Performance Metrics

### Evaluation Metrics Used

1. **MAE (Mean Absolute Error)**
   - Average absolute difference between predicted and actual
   - Unit: same as target (e.g., kg)

2. **RMSE (Root Mean Squared Error)**
   - Penalizes larger errors more heavily
   - Unit: same as target

3. **MAPE (Mean Absolute Percentage Error)**
   - Percentage error, scale-invariant
   - Good for comparing across products
   - Formula: mean(|actual - predicted| / |actual|) * 100

### Example Results

```
XGBoost Model Performance (30-60 days of data):
  Train MAE:  2.3 kg
  Test MAE:   3.1 kg
  Test RMSE:  4.2 kg
  Test MAPE:  12.5%

LSTM Model Performance (60+ days of data):
  Train MAE:  2.1 kg
  Test MAE:   3.5 kg
  Test MAPE:  14.2%

Ensemble (LSTM + XGBoost):
  Combined Test MAE:  3.2 kg
  Combined Test MAPE: 13.2%
```

---

## Dependencies

### Required (Current)
```
Django 4.2+
Python 3.8+
numpy
pandas
```

### Optional (For ML Features)

```
# XGBoost
xgboost>=1.7.0

# LSTM/Neural Networks
tensorflow>=2.12.0
keras>=2.12.0

# Feature Engineering
scikit-learn>=1.2.0
```

### Installation

```bash
# Statistical only (already installed)
pip install django numpy pandas

# Add ML features
pip install xgboost scikit-learn tensorflow
```

---

## Migration Guide (From Statistical to Hybrid)

### Phase 1: Enable Hybrid Mode (Backward Compatible)
```python
# In seller_views.py ForecastingViewSet

from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm

# Current code remains unchanged
# Add hybrid layer on top
hybrid_forecaster = create_hybrid_forecaster()
stat_forecaster = ForecastingAlgorithm()

# Use hybrid (automatically falls back to statistical if data insufficient)
forecast = hybrid_forecaster.generate_hybrid_forecast(
    sales_data, current_stock, min_stock, stat_forecaster
)
```

### Phase 2: Add ML Model Training
```python
# Schedule periodic model retraining
# E.g., every 7 days via Celery task
from apps.users.hybrid_forecasting import HybridForecastingStrategy

strategy = HybridForecastingStrategy()
strategy.initialize_ml_models()

# Pre-train models with historical data
for seller in Seller.objects.all():
    for product in seller.products.all():
        sales_data = get_historical_sales(product)
        if len(sales_data) >= 60:
            strategy.ml_ensemble.train_all_models(sales_data)
            # Store trained model metadata
```

### Phase 3: Monitor & Optimize
```python
# Track which methods are being used
# Monitor accuracy over time
# Adjust weights based on real performance
```

---

## Troubleshooting

### Issue: "ML models unavailable"
**Cause:** TensorFlow/XGBoost not installed  
**Solution:** `pip install tensorflow xgboost scikit-learn`

### Issue: LSTM taking too long to train
**Cause:** Large dataset or low specs  
**Solution:** Reduce epochs, batch size, or use XGBoost only

### Issue: ML predictions too different from statistical
**Cause:** Model overfitting or poor feature engineering  
**Solution:** System automatically uses weighted average; review logs

### Issue: Low confidence scores
**Cause:** High volatility or insufficient data  
**Solution:** Wait for more data; check for anomalies or external factors

---

## Next Steps

1. **Install ML dependencies** if needed
2. **Test hybrid mode** in development environment
3. **Monitor accuracy** in production
4. **Gather feedback** from sellers
5. **Optimize weights** based on real performance
6. **Consider**: Custom models per product category
7. **Consider**: External data integration (weather, holidays, market trends)

---

## References

- LSTM: Hochreiter & Schmidhuber (1997) - "Long Short-Term Memory"
- XGBoost: Chen & Guestrin (2016) - "XGBoost: A Scalable Tree Boosting System"
- Time Series Forecasting: Box & Jenkins (1970) - "ARIMA models"
- Ensemble Methods: Kuncheva (2014) - "Combining Pattern Classifiers"
