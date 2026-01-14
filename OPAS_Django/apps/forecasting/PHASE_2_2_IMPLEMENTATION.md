"""
Forecasting App - Phase 2.2: Historical Data Indexing

Implementation of signal handlers and Celery tasks for automatic
HistoricalTransactions population when SellerOrders are fulfilled.
"""

# ============================================================================
# PHASE 2.2: HISTORICAL DATA INDEXING IMPLEMENTATION
# ============================================================================

## Overview

Phase 2.2 implements two complementary mechanisms for maintaining HistoricalTransactions:

1. **Signal Handlers** - Real-time updates when individual orders are fulfilled
2. **Celery Tasks** - Batch aggregation and background maintenance

---

## Signal Handlers (`signals.py`)

### Purpose
Automatically update HistoricalTransactions when SellerOrder status changes to 
FULFILLED or DELIVERED.

### Implementation

#### `update_historical_transactions_on_order_fulfilled`
Triggered on: `post_save` signal for SellerOrder

**Workflow:**
```
SellerOrder saved with status=FULFILLED or DELIVERED
    ↓
Signal triggered (post_save)
    ↓
Extract order date (fulfilled_at or created_at)
    ↓
Get product, quantity, price
    ↓
update_or_create HistoricalTransactions record
    ↓
Set data_quality_score = 100 (individual transactions are complete)
```

**Example:**
```python
# When this order is saved:
order = SellerOrder(
    product=talong_product,
    quantity=50,  # 50 units/pcs
    price_per_unit=Decimal('45.00'),  # ₱45 per unit
    status=OrderStatus.FULFILLED,
    fulfilled_at=datetime(2025-01-15 14:30:00)
)
order.save()  # Triggers signal

# This creates/updates HistoricalTransactions:
HistoricalTransactions.objects.update_or_create(
    product=talong_product,
    transaction_date=2025-01-15,  # Extracted from fulfilled_at
    defaults={
        'quantity_sold_kg': 50,
        'average_price_per_kg': 45.00,
        'total_revenue': 2250.00,
        'data_quality_score': 100,
        'is_complete': True,
    }
)
```

**Key Features:**
- Uses `update_or_create` to handle duplicate orders gracefully
- Extracts transaction_date (date only, no time)
- Handles missing `fulfilled_at` by falling back to `created_at`
- Comprehensive error logging without breaking signal chain

#### `cleanup_historical_transactions_on_order_delete`
Triggered on: `post_delete` signal for SellerOrder

**Workflow:**
```
SellerOrder deleted
    ↓
Signal triggered (post_delete)
    ↓
Check if other orders exist for same product/date
    ↓
If no remaining orders:
    → Delete HistoricalTransactions record
    
If orders remain:
    → Recalculate aggregates (sum quantity, avg price)
    → Update HistoricalTransactions
```

**Example:**
```
Two orders on 2025-01-15 for Talong:
  - Order #1: 50 units @ ₱45 each
  - Order #2: 30 units @ ₱46 each

HistoricalTransactions record exists:
  - quantity_sold_kg: 80
  - average_price_per_kg: 45.50
  - total_revenue: 3640.00

Delete Order #1
    ↓
Signal calculates remaining aggregate:
  - 1 order remains (Order #2): 30 units @ ₱46
    
HistoricalTransactions updated to:
  - quantity_sold_kg: 30
  - average_price_per_kg: 46.00
  - total_revenue: 1380.00

If both orders are deleted:
    → HistoricalTransactions record deleted entirely
```

---

## Celery Tasks (`tasks.py`)

### Purpose
Background jobs for batch data aggregation and maintenance.

### Task 1: `aggregate_recent_transactions`

**Trigger:** Daily at 1:00 AM UTC (configurable in settings.py)

**Process:**
```
1. Query all active SellerProducts
2. For each product:
   - collect_product_transactions() - Query recent FULFILLED/DELIVERED orders
   - aggregate_to_weekly() - Resample to weekly aggregates
   - validate_data_quality() - Calculate quality score (0-100)
   - Store/update in HistoricalTransactions
3. Log results with retry logic (max 3 attempts)
```

**Returns:**
```python
{
    'status': 'success' | 'partial' | 'failed',
    'total_products': int,
    'products_updated': int,
    'records_created': int,
    'errors': [list of error messages],
}
```

**Example Output:**
```
{
    'status': 'partial',
    'total_products': 15,
    'products_updated': 12,
    'records_created': 47,
    'errors': [
        'Error aggregating product 5: Connection timeout',
    ]
}
```

### Task 2: `aggregate_all_products_batch`

**Trigger:** Manual trigger or weekly batch

**Purpose:** 
- Complete historical rebuild (not incremental)
- Recovery from data issues
- Initial setup with historical CSV data

**Process:**
```
1. Query ALL SellerOrders (not just recent)
2. For each active product:
   - collect_product_transactions() - All historical orders
   - aggregate_to_weekly() or monthly() - Based on data density
   - validate_data_quality()
   - Store in HistoricalTransactions
3. Log comprehensive results
```

**More aggressive than daily task** - rebuilds complete time series.

### Task 3: `cleanup_old_historical_transactions`

**Trigger:** Weekly on Sunday at 3:00 AM UTC

**Purpose:** Archive or delete very old transaction records

**Default:** Keeps 365 days, deletes older

**Returns:**
```python
{
    'status': 'success' | 'failed',
    'deleted_count': int,
}
```

### Task 4: `validate_data_quality_reports`

**Trigger:** Weekly on Sunday at 4:00 AM UTC

**Purpose:** Generate analytics on data readiness for forecasting

**Returns:**
```python
{
    'timestamp': '2025-01-12T04:00:00Z',
    'total_products': 18,
    'sufficient_data': [
        {'product_id': 1, 'product_name': 'Talong', 'data_points': 26, 'coverage': 100.0},
        ...
    ],
    'approaching_sufficiency': [
        {'product_id': 3, 'product_name': 'Tomato', 'data_points': 15, 'coverage': 75.5},
        ...
    ],
    'high_quality': [
        {'product_id': 1, 'product_name': 'Talong', 'avg_quality_score': 95.2},
        ...
    ],
    'low_quality': [
        {'product_id': 12, 'product_name': 'Onion', 'avg_quality_score': 42.3},
        ...
    ]
}
```

---

## Celery Configuration (`settings.py` & `celery.py`)

### Redis as Message Broker

```python
# settings.py
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
```

**Why Redis?**
- Fast message queue
- Handles task persistence
- Stores task results
- Used by both Celery and caching layer

### Beat Schedule (Periodic Tasks)

```python
CELERY_BEAT_SCHEDULE = {
    'aggregate_recent_transactions': {
        'task': 'apps.forecasting.tasks.aggregate_recent_transactions',
        'schedule': crontab(hour=1, minute=0),  # 1:00 AM UTC daily
    },
    'cleanup_old_historical_transactions': {
        'task': 'apps.forecasting.tasks.cleanup_old_historical_transactions',
        'schedule': crontab(day_of_week=0, hour=3, minute=0),  # Sunday 3 AM UTC
    },
    'validate_data_quality_reports': {
        'task': 'apps.forecasting.tasks.validate_data_quality_reports',
        'schedule': crontab(day_of_week=0, hour=4, minute=0),  # Sunday 4 AM UTC
    },
}
```

### Running Celery

**Worker (processes tasks):**
```bash
celery -A core worker -l info
```

**Beat (schedules periodic tasks):**
```bash
celery -A core beat -l info
```

**Both in one (development):**
```bash
celery -A core worker -l info --beat
```

---

## Signal Registration

Signal handlers are automatically registered when the forecasting app is loaded.

**In `apps.py`:**
```python
class ForecastingConfig(AppConfig):
    def ready(self):
        """Import signal handlers when app is ready"""
        import apps.forecasting.signals  # noqa
```

This ensures signal handlers are available without manual imports.

---

## Data Flow Examples

### Example 1: Single Order Fulfillment (Real-time)

**Trigger:** Admin marks SellerOrder as FULFILLED

```
1. SellerOrder.save() called with status=FULFILLED

2. Signal handler triggered:
   - Extract date: 2025-01-20
   - Extract quantity: 100 kg
   - Extract price: ₱50/kg
   
3. HistoricalTransactions updated:
   - transaction_date: 2025-01-20
   - quantity_sold_kg: 100
   - average_price_per_kg: 50.00
   - total_revenue: 5000.00
   - data_quality_score: 100
   
4. Result: HistoricalTransactions has fresh data within seconds
```

### Example 2: Daily Batch Aggregation

**Trigger:** 1:00 AM UTC daily (Celery Beat)

```
1. aggregate_recent_transactions() task starts

2. For product "Talong":
   - Query: SellerOrder.filter(
       product=talong,
       status__in=[FULFILLED, DELIVERED],
       created_at__date >= today - 30 days  # Last 30 days
     )
   - Get 15 completed orders
   
3. Aggregate to weekly:
   Week 1 (Jan 13-19): 250 kg @ ₱45.50/kg
   Week 2 (Jan 20-26): 280 kg @ ₱47.00/kg
   Week 3 (Jan 27-Feb 2): 220 kg @ ₱46.20/kg
   
4. Validate quality:
   - 3 data points (< 5 minimum) = 50% score
   - 0% missing = 40 points
   - Has variance = 20 points
   - Total: 91% quality
   
5. Store/update HistoricalTransactions
   - 3 records created for this product
   
6. Result: Database has weekly aggregates ready for forecasting
```

### Example 3: Order Deletion

**Trigger:** Admin deletes SellerOrder

```
Before deletion:
  HistoricalTransactions (2025-01-20):
    - quantity_sold_kg: 150 (2 orders: 100 + 50)
    - average_price_per_kg: 48.50

Delete order with 50 kg @ ₱45
    ↓
Signal handler checks remaining orders:
    → 1 order remains (100 kg @ ₱50)
    
HistoricalTransactions updated:
    - quantity_sold_kg: 100
    - average_price_per_kg: 50.00
    - total_revenue: 5000.00

If both orders deleted:
    → HistoricalTransactions record deleted
```

---

## Error Handling & Resilience

### Signal Errors
- Wrapped in try-except blocks
- Logged to Django logger but don't break signal chain
- Signal failure doesn't prevent order from being saved

### Task Retries
- Max 3 retries with exponential backoff
- Countdown: 60s × (2^retry_count)
  - Attempt 1 fails → Retry after 60s
  - Attempt 2 fails → Retry after 120s
  - Attempt 3 fails → Mark as failed

### Failed Tasks
- Logged to Django logger
- Task result stored in Redis (check with Flower or Redis CLI)
- Weekly quality report shows products with issues

---

## Monitoring & Debugging

### Check Celery Task Status

```python
from apps.forecasting.tasks import aggregate_recent_transactions

# Trigger task manually
result = aggregate_recent_transactions.delay()
print(f"Task ID: {result.id}")
print(f"Status: {result.status}")
print(f"Result: {result.get()}")
```

### View Task Queue

```bash
# Redis CLI
redis-cli
> KEYS "celery*"          # See all Celery keys
> LRANGE celery 0 -1      # View pending tasks
```

### Install Flower (Celery Monitoring)

```bash
pip install flower
celery -A core flower
# Access at http://localhost:5555
```

---

## Testing the Implementation

### Test 1: Signal on Order Fulfillment

```python
from apps.users.models import SellerOrder, OrderStatus
from apps.forecasting.models import HistoricalTransactions
from decimal import Decimal

# Create a test order
order = SellerOrder.objects.create(
    product=product,
    seller=seller,
    buyer=buyer,
    quantity=50,
    price_per_unit=Decimal('45.00'),
    status=OrderStatus.FULFILLED,
)

# Check HistoricalTransactions was created
assert HistoricalTransactions.objects.filter(
    product=product,
    transaction_date=order.fulfilled_at.date()
).exists()
```

### Test 2: Daily Aggregation Task

```python
from apps.forecasting.tasks import aggregate_recent_transactions

result = aggregate_recent_transactions()
print(result)
# Expected: {'status': 'success', 'products_updated': N, ...}
```

---

## Next Steps

**Phase 2.3:** Create database migrations (if needed)

**Phase 3:** Build forecasting engine with model selection and SARIMA/ARIMA training

**Integration:** Data aggregation → Forecasting models → Admin API

---

## File Structure

```
apps/forecasting/
├── signals.py              # Signal handlers for real-time updates
├── tasks.py                # Celery tasks for batch aggregation
├── services/
│   └── data_aggregator.py  # Service for data collection & validation
├── models.py               # Database models
└── apps.py                 # App config with signal registration

core/
├── celery.py               # Celery app configuration
├── settings.py             # Celery beat schedule
└── __init__.py             # Celery app initialization
```

---

## Summary

Phase 2.2 provides two complementary mechanisms:

1. **Signals (Real-time):** Individual orders update HistoricalTransactions immediately
2. **Tasks (Batch):** Daily aggregation, weekly cleanup, quality reports

Together, they ensure:
- ✅ Fresh data in HistoricalTransactions
- ✅ Automatic cleanup and maintenance
- ✅ Quality metrics for forecasting readiness
- ✅ Resilience with retry logic
- ✅ Comprehensive logging and monitoring

Next: Populate with historical CSV data → Phase 3 forecasting engine
