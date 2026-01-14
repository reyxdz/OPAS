# Product Grouping Implementation: Quick Reference

## What Was Implemented

### 1. **Database Schema Updates** ✅
Added to `SellerProduct` model in `seller_models.py`:
```python
category_forecast = CharField()      # LIVESTOCK, VEGETABLES, FRUITS, etc.
product_type = CharField()            # Fish, Poultry, Meat, Leafy, etc.
product_subtype = CharField()         # Bangus, Chicken, Tomato, etc.
```

**Example:**
- Product: "Bangus sa Kawayan" → LIVESTOCK > Fish > Bangus
- Product: "Bangus Fresh" → LIVESTOCK > Fish > Bangus
- Both grouped together for smart forecasting!

---

### 2. **Product Grouping Service** ✅
New file: `forecasting_grouping.py` (400+ lines)

**Key Classes:**
- `ProductGroupingService`: Core grouping logic
- `ProductClassificationHelper`: Hierarchy management

**Key Methods:**
```python
ProductGroupingService.get_product_group_key(product)
# Returns: "LIVESTOCK:Fish:Bangus"

ProductGroupingService.get_products_in_group(product)
# Returns: All products with same category:type:subtype

ProductGroupingService.get_combined_sales_data(product)
# Returns: (combined_sales, product_weights)

ProductGroupingService.forecast_with_grouping(product)
# Returns: Individual forecast with group multiplier applied
```

---

### 3. **Admin API Endpoints** ✅
New file: `admin_forecasting_views.py`

**Endpoints:**

1. **Get Product Hierarchy**
   ```
   GET /api/admin/forecasting/product-classifications/
   ```
   Returns full category:type:subtype hierarchy

2. **Get Types for Category**
   ```
   GET /api/admin/forecasting/types-for-category/?category=LIVESTOCK
   ```
   Returns: ['Fish', 'Poultry', 'Meat', 'Dairy']

3. **Get Subtypes for Type**
   ```
   GET /api/admin/forecasting/subtypes-for-type/?category=LIVESTOCK&type=Fish
   ```
   Returns: ['Bangus', 'Tilapia', 'Catfish', 'Tuna', 'Lapu-lapu']

4. **List All Product Groups**
   ```
   GET /api/admin/forecasting/products-by-group/
   ```
   Shows all groups with status, data points, products

5. **Get Group Forecast**
   ```
   GET /api/admin/forecasting/group-forecast/?category=LIVESTOCK&type=Fish&subtype=Bangus
   ```
   Returns combined forecast + individual product breakdown

6. **Get Product Detail**
   ```
   GET /api/admin/forecasting/product-forecast-detail/?product_id=123
   ```
   Individual product forecast with group info

7. **Forecast Readiness Dashboard**
   ```
   GET /api/admin/forecasting/forecast-readiness-dashboard/
   ```
   High-level view of all groups by readiness

---

## How Product Grouping Works

### Example Scenario: Bangus

```
Day 1: OPAS posts "Bangus sa Kawayan"
- 0 days of data
- Status: NO_FORECAST

Day 1: OPAS posts "Bangus Fresh from Bohol"
- 0 days of data + Kawayan's 0 = 0 combined
- Status: NO_FORECAST
- But they're in same group now!

Day 20: Both have 10 days each
- Combined: 20 days ✅ BASIC_FORECAST UNLOCKED!
- Hybrid forecasting now available
- Uses combined data to train ML

Day 60: Both have 30 days each
- Combined: 60 days ✅ ADVANCED_FORECAST UNLOCKED!
- Full LSTM + XGBoost ensemble now active
- Both products benefit from all 60 days of group data

Forecast Multiplier:
- Bangus sa Kawayan: sells 150 kg/day avg
- Bangus Fresh from Bohol: sells 100 kg/day avg
- Group average: 125 kg/day

If group forecasts 1000 kg:
- Kawayan: 1000 × (150/125) = 1200 kg
- Bohol: 1000 × (100/125) = 800 kg
```

---

## Data Flow

```
Add Product "Bangus sa Kawayan"
    ↓
Select Classification:
  Category: LIVESTOCK
  Type: Fish
  Subtype: Bangus
    ↓
Store: category_forecast='LIVESTOCK', product_type='Fish', product_subtype='Bangus'
    ↓
Generate group_key = "LIVESTOCK:Fish:Bangus"
    ↓
When Forecasting:
  → Get ALL products with same group_key
  → Combine their sales data
  → Train models on combined data (faster to 60 days!)
  → Calculate product multiplier (Kawayan sells more than Bohol)
  → Apply multiplier to group forecast
  → Return individual forecast
```

---

## Product Hierarchy

### VEGETABLES
- Leafy: Kale, Lettuce, Spinach, Cabbage, Pechay
- Root: Carrot, Radish, Turnip, Potato, Onion
- Fruiting: Tomato, Eggplant, Talong, Pepper, Chili

### FRUITS
- Citrus: Calamansi, Orange, Lemon, Lime
- Tropical: Banana, Mango, Pineapple, Papaya, Avocado
- Berries: Strawberry, Blueberry, Blackberry

### LIVESTOCK
- Fish: Bangus, Tilapia, Catfish, Tuna, Lapu-lapu
- Poultry: Chicken, Duck, Quail, Turkey
- Meat: Pork, Beef, Goat, Lamb
- Dairy: Milk, Cheese, Yogurt

### GRAINS
- Cereals: Rice, Corn, Wheat, Barley
- Legumes: Beans, Lentils, Peanuts, Chickpeas

### HERBS_SPICES
- Fresh: Basil, Mint, Oregano, Parsley
- Dried: Garlic, Ginger, Turmeric, Black Pepper

---

## Database Migrations Needed

```bash
# After updates to seller_models.py, run:
python manage.py makemigrations
python manage.py migrate
```

**Migration adds:**
- `category_forecast` CharField
- `product_type` CharField
- `product_subtype` CharField
- Index on (category_forecast, product_type, product_subtype)

---

## How to Use in Views

### Simple Usage (Already Grouped)

```python
from apps.users.forecasting_grouping import ProductGroupingService
from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm

# Get individual product forecast (automatically uses grouping)
product = SellerProduct.objects.get(id=1)
forecast = ProductGroupingService.forecast_with_grouping(product)

# Returns dict with:
# - forecasted_demand (adjusted for this product)
# - grouping_info (shows group multiplier, data points, etc.)
```

### Get Group Summary

```python
summary = ProductGroupingService.get_group_data_summary(product)
# Returns:
# {
#   'status': 'BASIC_FORECAST' or 'ADVANCED_FORECAST' or 'NO_FORECAST',
#   'product_count': 3,
#   'total_data_points': 45,
#   'days_until_advanced': 15,
# }
```

### Get All Groups

```python
products = SellerProduct.objects.filter(seller=admin_user)
groups = {}

for product in products:
    group_key = product.get_forecast_group_key()
    if group_key not in groups:
        groups[group_key] = ProductGroupingService.get_group_data_summary(product)

# Now iterate through groups to show dashboard
```

---

## Django URLconf Update

Add to your urls.py:

```python
from apps.users.admin_forecasting_views import AdminForecastingViewSet
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'admin/forecasting', AdminForecastingViewSet, basename='admin-forecasting')

urlpatterns = [
    # ... existing patterns ...
    path('api/', include(router.urls)),
]
```

---

## Next Steps (Frontend Implementation)

1. **Product Form Update**
   - Add cascading dropdowns for category/type/subtype
   - Fetch hierarchy from endpoint 1
   - Show selected classification with human-readable name

2. **Forecast Dashboard**
   - Call endpoint 4 to list all groups
   - Show groups sorted by readiness
   - Color-code: Red (no data), Orange (basic), Green (advanced)

3. **Group Detail View**
   - Call endpoint 5 to get group forecast
   - Show individual product breakdown
   - Highlight multipliers

4. **Product Detail**
   - Call endpoint 6 for individual product
   - Show group context
   - Explain multiplier effect

---

## Key Benefits

✅ **Faster ML Readiness**: Similar products combine data → reach 60 days faster
✅ **Better Accuracy**: More training data = better model
✅ **Smart Multipliers**: Captures that some suppliers sell more than others
✅ **Scalable**: Works with 1 Bangus or 100 Bangus variants
✅ **Market Insights**: See which product variants perform best
✅ **Future-Proof**: Ready for 1000s of product combinations

---

## Example API Responses

### Get Groups Dashboard
```json
{
  "total_groups": 5,
  "groups": [
    {
      "group_key": "LIVESTOCK:Fish:Bangus",
      "category": "LIVESTOCK",
      "type": "Fish",
      "subtype": "Bangus",
      "status": "ADVANCED_FORECAST",
      "status_text": "Advanced AI Forecasting",
      "product_count": 3,
      "combined_data_points": 75,
      "products": [
        {"id": 1, "name": "Bangus sa Kawayan", "price": 150, "data_points": 35},
        {"id": 2, "name": "Bangus Fresh", "price": 145, "data_points": 25},
        {"id": 3, "name": "Bangus Premium", "price": 160, "data_points": 15}
      ]
    },
    ...
  ]
}
```

### Get Group Forecast
```json
{
  "group_key": "LIVESTOCK:Fish:Bangus",
  "category": "LIVESTOCK",
  "type": "Fish",
  "subtype": "Bangus",
  "status": "ADVANCED_FORECAST",
  "product_count": 3,
  "total_data_points": 75,
  "group_total_forecast": 2500,
  "individual_forecasts": [
    {
      "product_id": 1,
      "product_name": "Bangus sa Kawayan",
      "forecasted_demand": 1200,
      "confidence_score": 85,
      "multiplier": 1.20
    },
    {
      "product_id": 2,
      "product_name": "Bangus Fresh",
      "forecasted_demand": 1000,
      "confidence_score": 85,
      "multiplier": 1.00
    },
    {
      "product_id": 3,
      "product_name": "Bangus Premium",
      "forecasted_demand": 300,
      "confidence_score": 80,
      "multiplier": 0.30
    }
  ]
}
```

---

## Testing

```python
# Test script to validate grouping
from apps.users.seller_models import SellerProduct
from apps.users.forecasting_grouping import ProductGroupingService

# Get a test product
product = SellerProduct.objects.filter(category_forecast__isnull=False).first()

if product:
    # Test 1: Get group key
    group_key = product.get_forecast_group_key()
    print(f"Group Key: {group_key}")
    
    # Test 2: Get all products in group
    group_products = ProductGroupingService.get_products_in_group(product)
    print(f"Products in group: {group_products.count()}")
    
    # Test 3: Get combined data
    combined_sales, weights = ProductGroupingService.get_combined_sales_data(product)
    print(f"Combined data points: {len(combined_sales)}")
    print(f"Product weights: {weights}")
    
    # Test 4: Get summary
    summary = ProductGroupingService.get_group_data_summary(product)
    print(f"Status: {summary['status']}")
    print(f"Days until advanced: {summary.get('days_until_advanced', 0)}")
```
