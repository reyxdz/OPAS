# CRITICAL FIX: Forecasting Data Source Correction

## The Problem

The forecasting system was using **SellerOrder table** (marketplace seller orders) to generate demand forecasts for **OPAS Products** (admin historical sales data).

This is fundamentally incorrect because:

1. **SellerOrder** = Regular seller marketplace transactions between sellers and buyers
2. **OPASProduct** = Admin-owned products for forecasting using historical CSV data
3. **OPASProductSale** = Admin historical sales data for OPAS products
4. **SellerProduct** = Regular seller marketplace product listings

### What Was Happening

The `ProductGroupingService` had mixed concerns:
- Method `get_products_in_group()` was querying `SellerProduct` (regular seller products)
- Method `get_combined_sales_data()` was querying `SellerOrder` (regular marketplace orders)
- But it was being used in OPAS Admin context with `OPASProduct` objects
- This caused the forecasting dashboard to display regular seller orders instead of OPAS historical sales data

## The Solution

### Updated Method: `get_products_in_group()`

**Before:**
```python
from apps.users.seller_models import Product

return Product.objects.filter(
    category=product.category,
    product_type=product.product_type,
    product_subtype=product.product_subtype,
    is_active=True
).select_related('seller')  # ❌ Regular seller products
```

**After:**
```python
from apps.users.opas_models import OPASProduct

return OPASProduct.objects.filter(
    category_forecast=product.category_forecast,  # ✅ OPASProduct field name
    product_type=product.product_type,
    product_subtype=product.product_subtype,
    is_active=True
)
```

### Updated Method: `get_combined_sales_data()`

**Before:**
```python
from apps.users.seller_models import SellerOrder

# Get all fulfilled/delivered orders for this product
orders = SellerOrder.objects.filter(  # ❌ Marketplace seller orders
    product=prod,
    status__in=['FULFILLED', 'DELIVERED'],
    created_at__date__gte=cutoff_date
)
```

**After:**
```python
from apps.users.opas_models import OPASProductSale

# Query OPASProductSale (OPAS admin historical sales) NOT SellerOrder
sales_records = OPASProductSale.objects.filter(  # ✅ OPAS historical sales
    opas_product=prod,
    sale_date__date__gte=cutoff_date
)
```

### Updated Field References

Changed all references from `product.category` to `product.category_forecast` because:
- `OPASProduct` uses `category_forecast` field
- `SellerProduct` uses `category` field

Files Updated:
- `apps/users/forecasting_grouping.py`
  - `get_product_group_key()` - Updated to use `category_forecast`
  - `get_products_in_group()` - Now queries OPASProduct
  - `get_combined_sales_data()` - Now queries OPASProductSale
  - `get_group_data_summary()` - Updated field references

## Impact

### Data Flow After Fix

```
OPAS Admin Forecasting Dashboard
    ↓
ProductGroupingService.forecast_with_grouping(opas_product)
    ↓
get_combined_sales_data(opas_product)
    ↓
OPASProductSale.objects.filter(opas_product=prod)  ✅ Correct
    ↓
Returns: Admin historical sales data (from CSV imports)
```

### What Now Happens

1. ✅ OPAS forecasts use **OPASProductSale** data (admin historical data)
2. ✅ Regular seller forecasts use **SellerOrder** data (marketplace orders)
3. ✅ Data is properly segregated and doesn't mix
4. ✅ Forecasting dashboard displays OPAS historical sales only

## Key Tables

| Table | Used By | Data Source | Purpose |
|-------|---------|-------------|---------|
| **OPASProduct** | OPAS Admin | CSV imports | Product definitions for forecasting |
| **OPASProductSale** | OPAS Admin forecasting | Historical sales data | Demand data for OPAS forecasts |
| **SellerProduct** | Regular sellers | Marketplace listings | Product catalog for marketplace |
| **SellerOrder** | Regular seller forecasting | Marketplace orders | Sales data for seller forecasts |
| **ProductForecast** | Both | Forecast results | Generated demand/price predictions |

## Testing Recommendations

1. Verify that `ProductGroupingService.get_combined_sales_data()` now returns OPASProductSale records
2. Check that forecasting dashboard shows OPAS historical sales data only
3. Ensure SellerOrder data is not mixed into OPAS forecasts
4. Validate that product grouping by category:type:subtype works correctly

## Code Architecture Now

The system properly separates:

```
OPAS System                          Regular Seller System
├─ OPASProduct                       ├─ SellerProduct
├─ OPASProductSale (historical)      ├─ SellerOrder (marketplace)
├─ ProductForecast (OPAS)            ├─ SellerForecast (seller)
└─ Forecasting uses OPASProductSale  └─ Forecasting uses SellerOrder
```

This ensures clean data separation and prevents the incorrect mixing of marketplace seller orders with OPAS administrative products.
