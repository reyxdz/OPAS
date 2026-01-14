# OPAS Forecasting System - Architecture Summary

## Overview
Complete system for OPAS Admin to post products, track sales, and automatically generate demand & price forecasts every 31 days.

## Database Models

### 1. OPASProduct (39 products from cleaned CSV)
**Purpose:** Master product data for forecasting
- `name` - Unique product name
- `category_forecast` - VEGETABLE, FRUIT, LIVESTOCK, POULTRY, etc.
- `product_type` - Type in English (e.g., Banana, Tomato)
- `product_subtype` - Subtype in original language (e.g., Lakatan)
- `forecast_group_key` - Composite key for grouping: "category:type:subtype"
- `forecasted_demand_next_month` - Predicted quantity (units)
- `forecasted_price_next_month` - Predicted average price (₱)
- `last_aggregated_date` - When forecasts were last updated
- `is_active` - For filtering active products

### 2. SellerProduct (Marketplace products - existing)
**Purpose:** Products posted for sale on marketplace
- `seller` - FK to User (who posted)
- `name, price, stock_level, etc.` - Product details
- **NEW:** `opas_product_id` - Links to OPASProduct if posted by OPAS Admin

### 3. OPASProductSale (NEW - transaction tracking)
**Purpose:** Record each sale for forecasting data
- `opas_product` - FK to OPASProduct
- `seller_product` - FK to SellerProduct (the marketplace product purchased)
- `quantity_sold` - Units in this transaction
- `price_per_unit` - Price at time of sale
- `total_amount` - Auto-calculated (qty × price)
- `sale_date` - When sale occurred
- `recorded_at` - When record was created

## Data Flow

```
1. OPAS Admin posts product
   ↓
   Creates SellerProduct (seller_id=58, category_forecast, product_type, product_subtype)
   ↓
   Auto-linking signal fires:
   - Checks if matching OPASProduct exists (same category:type:subtype)
   - If YES → Links SellerProduct.opas_product_id = OPASProduct.id
   - If NO → Creates new OPASProduct entry
   ↓
   Product visible on marketplace to buyers

2. Buyer purchases OPAS product
   ↓
   SellerOrder created
   ↓
   OPASProductSale record created automatically with:
   - opas_product (linked via SellerProduct)
   - quantity_sold
   - price_per_unit
   - sale_date

3. Every 31 days (scheduled task)
   ↓
   Management command: python manage.py refresh_opas_forecasts
   ↓
   For each OPASProduct:
   - Aggregate sales from last 31 days
   - Calculate average demand (quantity/day) → Scale to 30 days
   - Calculate average price
   - Update forecasted_demand_next_month
   - Update forecasted_price_next_month
   - Set last_aggregated_date = now
   ↓
   Forecasting dashboard auto-refreshes with new predictions
```

## Management Commands

### 1. Populate OPAS Classifications (One-time)
```bash
python manage.py populate_opas_classifications
```
Intelligently infers category:type:subtype from product names using translation logic.

### 2. Display OPAS Products
```bash
python display_opas_products.py
```
Shows all 39 OPAS products with their classifications.

### 3. Apply Categorization Changes (One-time)
```bash
python apply_categorization_changes.py
```
Applied merge/categorization fixes to 45 → 39 products.

### 4. Refresh Forecasts (Scheduled - Every 31 days)
```bash
python manage.py refresh_opas_forecasts
# Or for specific product:
python manage.py refresh_opas_forecasts --product-id 5
# Or different time period:
python manage.py refresh_opas_forecasts --days 14
```
Aggregates sales and updates forecasts.

## Signal Handlers (Auto-linking)

**File:** `apps/users/opas_signals.py`

### Signal 1: auto_link_opas_product
Triggered when SellerProduct is created
```python
@receiver(post_save, sender=SellerProduct)
def auto_link_opas_product(sender, instance, created, **kwargs):
```
- Only processes OPAS Admin products (seller_id=58)
- Matches or creates OPASProduct with same classification
- Sets SellerProduct.opas_product_id for linking

### Function: record_opas_sale
Call when SellerOrder created for OPAS product
```python
def record_opas_sale(seller_product, quantity, price_per_unit, sale_date=None):
```
- Creates OPASProductSale entry
- Links to OPASProduct for forecasting

## Key Features

✅ **Automatic Product Linking** - OPAS postings auto-link to master products
✅ **Sales Tracking** - Every transaction recorded for forecasting
✅ **31-Day Aggregation** - Automatic forecast refresh on schedule
✅ **Hierarchical Classification** - Category → Type → Subtype
✅ **Dual Purpose Products** - Marketplace sales + forecasting data
✅ **Clean Data Separation** - OPAS-only products separate from seller products
✅ **Historical + Live Data** - CSV baseline + current sales for predictions

## Files Modified/Created

**Models:**
- `apps/users/opas_models.py` - Updated OPASProduct, created OPASProductSale
- `apps/users/seller_models.py` - Added opas_product_id field

**Signals:**
- `apps/users/opas_signals.py` - Auto-linking & sale recording (NEW)

**Management Commands:**
- `apps/users/management/commands/refresh_opas_forecasts.py` - Forecast refresh (NEW)

**Configuration:**
- `apps/users/apps.py` - Register signal handlers (NEW)

**Migrations:**
- `0034_opasproduct_forecasting_opasproductsale.py` - Add forecasting fields & OPASProductSale
- `0035_sellerproduct_opas_product_id.py` - Link SellerProduct to OPASProduct

## Next Steps (Optional)

1. **Celery Integration** - Schedule refresh_opas_forecasts to run every 31 days
2. **ML Forecasting** - Integrate ARIMA/XGBoost for advanced predictions
3. **Dashboard Display** - Show forecasts in OPAS admin dashboard
4. **Alerting** - Notify when forecasts change significantly
5. **API Endpoint** - Expose forecasts via REST API
