# API Testing Guide - Enhanced Forecasting with Validation

**Date:** December 4, 2025  
**Purpose:** Test the enhanced forecasting API endpoints that now include validation metrics

---

## 🎯 Overview

The forecasting API now returns validation metrics for each forecast:
- `validation_mape` - Mean Absolute Percentage Error (model accuracy)
- `validation_confidence` - Confidence level (HIGH/MEDIUM/LOW) based on real MAPE
- `model_accuracy_info` - Full model comparison results (all 3 models ranked)
- `validation_date` - When the forecast was validated

---

## 📋 Prerequisites

1. Django development server running: `python manage.py runserver`
2. Admin user logged in with authentication token
3. Forecasts already generated in database

---

## 🔧 Test Commands

### **Test 1: Get Auth Token (if needed)**

```bash
# Get authentication token for admin user
curl -X POST http://localhost:8000/api/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin_user",
    "password": "admin_password"
  }'

# Response will include: {"token": "abc123..."}
# Store the token for subsequent requests
```

### **Test 2: List All Forecasts (Lightweight)**

```bash
# List all current forecasts with pagination
curl -H "Authorization: Token YOUR_TOKEN" \
  http://localhost:8000/api/admin/forecasts/?page_size=10

# Response includes:
# - id, product_name, demand_quantity, price, confidence_level
# - does NOT include validation metrics (lightweight)
```

### **Test 3: Get Detailed Forecast WITH Validation Metrics** ⭐

```bash
# Get a single forecast with full validation details
curl -H "Authorization: Token YOUR_TOKEN" \
  http://localhost:8000/api/admin/forecasts/1/

# Expected Response:
{
  "id": 1,
  "product_id": 5,
  "product_name": "Talong",
  "demand_quantity": 250,
  "price": 45.50,
  "confidence_level": "HIGH",
  "model_type": "ARIMA",
  "forecast_date": "2025-12-04T10:00:00Z",
  
  "validation_mape": 4.2,                    # ← Accuracy percentage
  "validation_confidence": "HIGH",            # ← Based on real MAPE
  "validation_date": "2025-12-04T09:30:00Z", # ← When validated
  
  "model_accuracy_info": {                   # ← All 3 models compared
    "demand": {
      "best_model": "ARIMA",
      "models": [
        {"model": "ARIMA", "mape": 4.2, "rmse": 25.3, "mae": 18.5},
        {"model": "SARIMA", "mape": 5.8, "rmse": 30.1, "mae": 21.2},
        {"model": "SIMPLE", "mape": 12.1, "rmse": 55.2, "mae": 42.1}
      ]
    },
    "price": {
      "best_model": "ARIMA",
      "models": [
        {"model": "ARIMA", "mape": 3.8, "rmse": 2.2, "mae": 1.8},
        {"model": "SARIMA", "mape": 4.5, "rmse": 2.8, "mae": 2.1},
        {"model": "SIMPLE", "mape": 8.3, "rmse": 5.1, "mae": 4.2}
      ]
    }
  },
  
  "created_at": "2025-12-04T09:00:00Z",
  "updated_at": "2025-12-04T10:00:00Z"
}
```

### **Test 4: Filter Forecasts by Confidence**

```bash
# Get only HIGH confidence forecasts
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?confidence=HIGH"

# Get MEDIUM confidence forecasts
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?confidence=MEDIUM"

# Get LOW confidence forecasts (needs more data)
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?confidence=LOW"
```

### **Test 5: Filter by Model Type**

```bash
# Get forecasts using ARIMA model (best by validation)
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?model_type=ARIMA"

# Get forecasts using SARIMA
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?model_type=SARIMA"

# Get forecasts using SIMPLE (fallback for sparse data)
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?model_type=SIMPLE"
```

### **Test 6: Search Forecasts by Product Name**

```bash
# Search for Talong forecasts
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?search=Talong"

# Search for Papaya forecasts
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?search=Papaya"
```

### **Test 7: Get Only Reliable Forecasts**

```bash
# Exclude INSUFFICIENT_DATA forecasts
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?reliable=true"
```

### **Test 8: Get Stale Forecasts (>7 days old)**

```bash
# Find forecasts that need refresh
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?stale=true"
```

### **Test 9: Combined Filters**

```bash
# High confidence ARIMA models for Talong
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?confidence=HIGH&model_type=ARIMA&search=Talong"

# Reliable SARIMA models sorted by date
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/?reliable=true&model_type=SARIMA&ordering=-forecast_date"
```

---

## ✅ What to Look For

### **Validation Metrics in Response**

1. **`validation_mape`**: Should be between 0-100%
   - 0-10%: Excellent accuracy (HIGH confidence)
   - 10-20%: Good accuracy (MEDIUM confidence)
   - >20%: Needs more data (LOW confidence)

2. **`validation_confidence`**: Should match MAPE levels
   - HIGH = MAPE ≤ 10%
   - MEDIUM = 10% < MAPE ≤ 20%
   - LOW = MAPE > 20%

3. **`model_accuracy_info`**: Shows all 3 models tested
   - Should have demand and price sections
   - Should list ARIMA, SARIMA, SIMPLE with MAPE values
   - Best model should match used `model_type`

4. **`validation_date`**: Should be recent
   - Should be close to `forecast_date`
   - Indicates when validation occurred

---

## 🔍 Debugging

### **If validation metrics are NULL/missing:**

```bash
# Check if forecast has metadata
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/admin/forecasts/1/metadata/"

# Check validation task logs
tail -f logs/forecasting.log | grep "validation"

# Run migrations to ensure database has validation fields
python manage.py migrate forecasting
```

### **If confidence doesn't match MAPE:**

- Check if `get_confidence_score()` logic is correct
- Verify threshold values (10%, 20%)
- Check database for correct MAPE values

### **If model_type doesn't match best_model:**

- Run validation tests: `python manage.py test apps.forecasting.tests.test_model_validation`
- Check EnhancedForecastingService is being used
- Verify `use_best_model=True` in Celery task

---

## 📊 Expected Results

### **Before Improvements (Old)**
```json
{
  "id": 1,
  "product_name": "Talong",
  "demand_quantity": 250,
  "confidence_level": "HIGH",
  "model_type": "SARIMA"
  // ← No validation metrics!
  // ← Confidence based only on data availability
  // ← Model chosen by rules, not testing
}
```

### **After Improvements (New)** ✅
```json
{
  "id": 1,
  "product_name": "Talong",
  "demand_quantity": 250,
  "confidence_level": "HIGH",
  "model_type": "ARIMA",           // ← Changed from SARIMA (better by validation)
  
  "validation_mape": 4.2,          // ← Real accuracy!
  "validation_confidence": "HIGH",  // ← Based on actual MAPE
  "validation_date": "2025-12-04T09:30:00Z",
  
  "model_accuracy_info": {         // ← All models compared
    "demand": {
      "best_model": "ARIMA",
      "models": [
        {"model": "ARIMA", "mape": 4.2, ...},
        {"model": "SARIMA", "mape": 5.8, ...},
        {"model": "SIMPLE", "mape": 12.1, ...}
      ]
    },
    ...
  }
}
```

---

## 🚀 Integration Checklist

- [ ] Celery task updated to use `EnhancedForecastingService`
- [ ] Celery task has `validate=True, use_best_model=True`
- [ ] API views updated to use `ForecastDetailedSerializer`
- [ ] Database migrations run: `python manage.py migrate forecasting`
- [ ] Test endpoints return validation metrics
- [ ] Flutter dashboard updated to display metrics
- [ ] Validation metrics displayed in admin UI
- [ ] Tests passing: `python manage.py test apps.forecasting`

---

## 💡 Next Steps

1. ✅ Run migrations: `python manage.py migrate forecasting`
2. ✅ Test API endpoints using curl commands above
3. ✅ Verify validation metrics are in responses
4. ✅ Update Flutter dashboard (see Flutter dashboard update guide)
5. ✅ Monitor first forecast generation with validation
6. ✅ Deploy to production when confident

---

## 📞 Support

If tests fail:
1. Check logs: `tail -f logs/forecasting.log`
2. Run unit tests: `python manage.py test apps.forecasting.tests.test_model_validation`
3. Check database: `python manage.py dbshell`
4. Verify imports in views.py and tasks.py

Good luck! 🎉
