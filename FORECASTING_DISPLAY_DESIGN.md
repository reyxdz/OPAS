# Forecasting Dashboard - Display Design

**Date:** December 3, 2025  
**Version:** Final Design Plan

---

## 📋 Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│ Forecasting Dashboard                          [←] [⟳]  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Search: [Search by product name........................]│
│  Confidence: [All ▼] | Sort: [Trend ▼]                 │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📈 DEMAND FORECASTING TABLE                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Product    │ Current │ W1   │ W2   │ W3   │ W4  │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ Talong     │ 150kg   │ 180↑ │ 165  │ 190↑ │ 175 │   │
│  │ Papaya     │ 120kg   │ 130↑ │ 125  │ 135↑ │ 140 │   │
│  │ Tomato     │ 200kg   │ 190↓ │ 185  │ 180↓ │ 175 │   │
│  │ ...        │ ...     │ ...  │ ...  │ ...  │ ... │   │
│  └─────────────────────────────────────────────────┘   │
│  Confidence: HIGH | Model: SARIMA                       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  💰 PRICE FORECASTING TABLE                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Product    │ Current │ W1    │ W2    │ W3   │ W4 │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ Talong     │ ₱45/kg  │ ₱47↑  │ ₱46   │ ₱48↑ │ ₱45│   │
│  │ Papaya     │ ₱32/kg  │ ₱33↑  │ ₱32   │ ₱34↑ │ ₱35│   │
│  │ Tomato     │ ₱25/kg  │ ₱24↓  │ ₱23   │ ₱22↓ │ ₱21│   │
│  │ ...        │ ...     │ ...   │ ...   │ ...  │ ...│   │
│  └─────────────────────────────────────────────────┘   │
│  Confidence: MEDIUM | Model: ARIMA                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Features Breakdown

### **1. Search by Product Name**
- **Input Field:** Text search at top
- **Behavior:** Real-time filtering (as user types)
- **Case-insensitive:** "talong" = "Talong" = "TALONG"
- **Applied to:** Both tables simultaneously

### **2. Filter by Confidence Level**
- **Dropdown Options:**
  - All (default)
  - HIGH
  - MEDIUM
  - LOW
- **Visual Indicator:** Color-coded
  - GREEN = HIGH confidence
  - YELLOW = MEDIUM confidence
  - RED = LOW confidence
- **Applied to:** Both tables simultaneously

### **3. Sort by Trend**
- **Dropdown Options:**
  - None (default order)
  - Trending Up (↑)
  - Trending Down (↓)
  - Stable (→)
- **Calculation:** Compare forecast Week 4 vs Current
  - If W4 > Current: Trending Up
  - If W4 < Current: Trending Down
  - If W4 ≈ Current: Stable
- **Applied to:** Both tables simultaneously

---

## 📊 DEMAND FORECASTING TABLE

### Columns (Left to Right)

| Column | Width | Content | Example |
|--------|-------|---------|---------|
| **Product** | 20% | Product name | Talong |
| **Current** | 12% | Latest actual demand | 150 kg |
| **Week 1** | 13% | Forecast W1 | 180 kg |
| **Week 2** | 13% | Forecast W2 | 165 kg |
| **Week 3** | 13% | Forecast W3 | 190 kg |
| **Week 4** | 13% | Forecast W4 | 175 kg |
| **Trend** | 8% | Arrow direction | ↑ / ↓ / → |
| **Details** | 8% | [View] button | Tap to expand |

### Row Details (When Tapped)

Shows:
- Full model info: SARIMA(1,1,1)(0,1,0)_12
- Confidence level with percentage: HIGH (95%)
- Data points used: 26 weeks
- RMSE error metric
- Chart: Historical + Forecast line
- 95% confidence interval bands

---

## 💰 PRICE FORECASTING TABLE

### Columns (Left to Right)

| Column | Width | Content | Example |
|--------|-------|---------|---------|
| **Product** | 20% | Product name | Talong |
| **Current** | 12% | Latest actual price | ₱45/kg |
| **Week 1** | 13% | Forecast W1 | ₱47/kg |
| **Week 2** | 13% | Forecast W2 | ₱46/kg |
| **Week 3** | 13% | Forecast W3 | ₱48/kg |
| **Week 4** | 13% | Forecast W4 | ₱45/kg |
| **Trend** | 8% | Arrow direction | ↑ / ↓ / → |
| **Details** | 8% | [View] button | Tap to expand |

### Row Details (When Tapped)

Shows:
- Full model info: ARIMA(2,1,1)
- Confidence level with percentage: MEDIUM (85%)
- Data points used: 20 weeks
- RMSE error metric
- Chart: Historical + Forecast line
- 95% confidence interval bands

---

## 🎨 Visual Design

### Colors

**Confidence Levels:**
- 🟢 HIGH: `#4CAF50` (Green)
- 🟡 MEDIUM: `#FF9800` (Orange)
- 🔴 LOW: `#F44336` (Red)

**Trends:**
- ↑ UP: `#00BCD4` (Cyan) with arrow
- ↓ DOWN: `#FF6B6B` (Red) with arrow
- → STABLE: `#9E9E9E` (Gray) with dash

**Table:**
- Header: `#F5F5F5` (Light gray)
- Rows: Alternating white/`#FAFAFA`
- Borders: `#E0E0E0` (Light gray)

---

## 📱 Mobile Responsiveness

**On Small Screens:**
- Hide "Week 2" and "Week 3" columns
- Show only: Product | Current | W1 | W4 | Trend | Details
- Users can swipe left/right to see more

**On Large Screens:**
- Show all columns
- Add filter bar at top
- Tables side-by-side (if space permits)

---

## 🔄 Data Flow

```
Backend API (/api/admin/forecasts/)
    ↓
    └─→ ProductForecast objects
         ├─ id, product_id, product.name
         ├─ demand_forecast_kg (W1-W4)
         ├─ price_forecast (W1-W4)
         ├─ confidence_level (HIGH/MEDIUM/LOW)
         ├─ model_type (SARIMA/ARIMA/SIMPLE)
         └─ is_current (boolean)
    ↓
Flutter Service (ForecastingService)
    ├─ Fetches all forecasts
    ├─ Calculates trends (W4 vs Current)
    ├─ Builds two separate lists:
    │  ├─ demandForecasts (sorted/filtered)
    │  └─ priceForecasts (sorted/filtered)
    ↓
ForecastingDashboardScreen
    ├─ Displays Demand Table (scrollable)
    ├─ Displays Price Table (scrollable)
    ├─ Handles search/filter/sort
    └─ Navigates to detail screen on tap
```

---

## 🛠️ Implementation Steps

### Step 1: Update Forecasting Service
- Add method to fetch all forecasts with data
- Add method to calculate trends
- Add method to filter/search/sort

### Step 2: Create Data Models
- `DemandForecastRow` - data for demand table row
- `PriceForecastRow` - data for price table row
- Include: product name, current, W1-W4, trend, confidence, model

### Step 3: Build UI Components
- `DemandForecastTable` widget
- `PriceForecastTable` widget
- Search/filter/sort controls
- Detail expansion sheets

### Step 4: Wire Everything
- Connect to API
- Implement filtering logic
- Handle loading/error states
- Add refresh capability

---

## 🧪 Test Scenarios

1. **Search "Talong"** → Shows only Talong rows in both tables
2. **Filter "HIGH"** → Shows only HIGH confidence forecasts
3. **Sort "Trending Up"** → Sorts by ascending trend (↓ ↓ ↑ ↑)
4. **Multiple filters** → Search="Papaya" + Confidence="MEDIUM" = filtered results
5. **Tap row** → Opens detail modal with chart
6. **Refresh** → Fetches latest data from API
7. **Empty state** → Shows message when no forecasts match filters

---

## ✅ Deliverables

1. ✅ Two separate scrollable tables (stacked)
2. ✅ Search by product name (real-time)
3. ✅ Filter by confidence level (dropdown)
4. ✅ Sort by trend (dropdown)
5. ✅ Visual indicators (colors, trends, icons)
6. ✅ Click/tap to view details + chart
7. ✅ Responsive design (mobile + desktop)
8. ✅ Loading/error states
9. ✅ Refresh capability
10. ✅ All features work independently and together

---

**Ready to implement?** Let's start with the backend data generation, then build the UI!
