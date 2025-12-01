# Stock Status Implementation Plan

## Overview
Implement a three-tier stock status system (Low, Moderate, High) based on percentage of current baseline stock. The system will track initial stock for analytics and use a dynamic baseline that resets on restocking.

---

## Database Changes (Django Backend)

### 1. Update SellerProduct Model✅
**File:** `OPAS_Django/apps/users/seller_models.py`

Add three new fields to the `SellerProduct` model:

```python
# ==================== STOCK TRACKING ====================
initial_stock = models.IntegerField(
    default=0,
    help_text='Original stock amount when product was first created (for analytics)'
)

baseline_stock = models.IntegerField(
    default=0,
    help_text='Current baseline stock for percentage calculation (updates on restock)'
)

stock_baseline_updated_at = models.DateTimeField(
    auto_now_add=True,
    help_text='Timestamp when baseline stock was last updated (on restock)'
)
```

### 2. Update Product Creation ✅
**File:** `OPAS_Django/apps/users/seller_views.py`

When creating a product, set `initial_stock` and `baseline_stock` to the input stock level:

```python
def create(self, request):
    # ... existing code ...
    stock_level = request.data.get('stock_level', 0)
    product = serializer.save(
        seller=request.user,
        initial_stock=stock_level,
        baseline_stock=stock_level
    )
```

### 3. Update Stock Update Logic ✅
**File:** `OPAS_Django/apps/users/seller_views.py`

Modify the stock update endpoint to detect restocking and update baseline:

```python
def update(self, request, pk=None):
    product = SellerProduct.objects.get(id=pk, seller=request.user)
    old_stock = product.stock_level
    new_stock = request.data.get('stock_level')
    
    # Detect restock: new stock > old stock (seller added stock)
    if new_stock is not None and isinstance(new_stock, int) and new_stock > old_stock:
        serializer.save(
            baseline_stock=new_stock,
            stock_baseline_updated_at=timezone.now()
        )
```

---

## API Serializer Changes ✅

### 1. Add Stock Percentage Field ✅
**File:** `OPAS_Django/apps/users/seller_serializers.py`

Update `SellerProductListSerializer` to include calculated fields:

```python
class SellerProductListSerializer(serializers.ModelSerializer):
    # ... existing fields ...
    
    stock_percentage = serializers.SerializerMethodField()
    stock_status = serializers.SerializerMethodField()
    
    class Meta:
        model = SellerProduct
        fields = [
            # ... existing fields ...
            'initial_stock',
            'baseline_stock',
            'stock_baseline_updated_at',
            'stock_percentage',
            'stock_status',
        ]
    
    def get_stock_percentage(self, obj):
        """Calculate stock percentage based on baseline"""
        if obj.baseline_stock == 0:
            return 100
        return round((obj.stock_level / obj.baseline_stock) * 100, 2)
    
    def get_stock_status(self, obj):
        """Determine stock status based on percentage thresholds"""
        if obj.baseline_stock == 0:
            percentage = 100
        else:
            percentage = (obj.stock_level / obj.baseline_stock) * 100
        
        if percentage < 40:
            return 'LOW'
        elif percentage < 70:
            return 'MODERATE'
        else:
            return 'HIGH'
```

---

## Flutter Frontend Changes

### 1. Update Product Model ✅
**File:** `OPAS_Flutter/lib/features/products/models/product_model.dart`

Add fields to the Product model:

```dart
final int initialStock;
final int baselineStock;
final DateTime stockBaselineUpdatedAt;
final double stockPercentage;
final String stockStatus;

const Product({
    // ... existing parameters ...
    required this.initialStock,
    required this.baselineStock,
    required this.stockBaselineUpdatedAt,
    required this.stockPercentage,
    required this.stockStatus,
});

factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        // ... existing fields ...
        initialStock: json['initial_stock'] ?? 0,
        baselineStock: json['baseline_stock'] ?? 0,
        stockBaselineUpdatedAt: DateTime.parse(json['stock_baseline_updated_at'] ?? DateTime.now().toIso8601String()),
        stockPercentage: (json['stock_percentage'] ?? 100).toDouble(),
        stockStatus: json['stock_status'] ?? 'HIGH',
    );
}
```

### 2. Create Stock Status Widget ✅
**File:** `OPAS_Flutter/lib/features/products/widgets/stock_status_widget.dart` (New)

```dart
import 'package:flutter/material.dart';

class StockStatusWidget extends StatelessWidget {
  final String status; // 'LOW', 'MODERATE', 'HIGH'
  final double percentage;
  final int currentStock;
  final String unit;

  const StockStatusWidget({
    super.key,
    required this.status,
    required this.percentage,
    required this.currentStock,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Label with Color
        Text(
          '${status[0]}${status.substring(1).toLowerCase()} Stock',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getStatusColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
        ),
        const SizedBox(height: 4),
        // Percentage Text
        Text(
          '$currentStock ${unit}s (${percentage.toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'LOW':
        return Colors.red;
      case 'MODERATE':
        return Colors.orange;
      case 'HIGH':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
```

### 3. Update Product Card Widget ✅
**File:** `OPAS_Flutter/lib/features/products/widgets/product_card.dart`

Replace the stock display in the list view card:

```dart
// In _buildListViewCard, replace the stock text with:
StockStatusWidget(
  status: product.stockStatus,
  percentage: product.stockPercentage,
  currentStock: product.stock,
  unit: product.unit,
),
```

### 4. Update Product Listing Screen ✅
**File:** `OPAS_Flutter/lib/features/seller_panel/screens/product_listing_screen.dart`

Replace the stock display in the product list:

```dart
// Replace the old stock display with:
StockStatusWidget(
  status: product.stockStatus,
  percentage: product.stockPercentage,
  currentStock: product.stock,
  unit: product.unit,
),
```

### 5. Update Inventory Listing Screen ✅
**File:** `OPAS_Flutter/lib/features/seller_panel/screens/inventory_listing_screen.dart`

Update to show the new stock status with visual indicators.

---

## Stock Status Thresholds

| Percentage | Status | Color | Indicator |
|-----------|--------|-------|-----------|
| < 40% | LOW | Red | 🔴 Critical |
| 40% - 69% | MODERATE | Orange | 🟠 Warning |
| ≥ 70% | HIGH | Green | 🟢 Healthy |

---

## Workflow Examples

### Example 1: Initial Creation
```
Seller creates product with 50kg
- initial_stock = 50
- baseline_stock = 50
- stock_level = 50
- stock_percentage = 100%
- stock_status = 'HIGH'
```

### Example 2: Purchase Reduces Stock
```
Buyer purchases 20kg
- stock_level = 30
- baseline_stock = 50 (unchanged)
- stock_percentage = 60%
- stock_status = 'MODERATE'
```

### Example 3: Restocking Updates Baseline
```
Seller adds 40kg (restock)
- stock_level = 70 (30 + 40)
- baseline_stock = 70 (updated!)
- stock_percentage = 100%
- stock_status = 'HIGH'
- stock_baseline_updated_at = now
```

### Example 4: More Purchases
```
Buyer purchases 35kg
- stock_level = 35
- baseline_stock = 70 (unchanged)
- stock_percentage = 50%
- stock_status = 'MODERATE'
```

---

## Database Migration

Create Django migration:

```bash
python manage.py makemigrations
python manage.py migrate
```

For existing products, set initial_stock and baseline_stock to current stock_level:

```python
# Migration forward function
def set_initial_baseline(apps, schema_editor):
    SellerProduct = apps.get_model('users', 'SellerProduct')
    for product in SellerProduct.objects.all():
        if product.initial_stock == 0:
            product.initial_stock = product.stock_level
        if product.baseline_stock == 0:
            product.baseline_stock = product.stock_level
        product.save()
```

---

## Implementation Checklist

### Backend
- [x] Add three new fields to SellerProduct model
- [x] Update product creation to set initial_stock and baseline_stock
- [x] Update product update to detect restock and update baseline
- [x] Add serializer fields for stock_percentage and stock_status
- [x] Create and run database migration
- [x] Test API response includes new fields
- [x] Stock deduction on checkout (buyer creates order)
- [x] Stock restoration on buyer cancellation
- [x] Stock restoration on seller rejection

### Frontend
- [x] Update Product model with new fields
- [x] Create StockStatusWidget
- [x] Update ProductCard widget to use StockStatusWidget
- [x] Update ProductListingScreen to use StockStatusWidget
- [x] Update InventoryListingScreen for consistency
- [x] Update SellerProduct model with stock status fields
- [ ] Test UI displays correct status and colors

### Testing
- [ ] Test initial product creation sets correct baselines
- [ ] Test purchases decrease stock but not baseline
- [ ] Test restocking increases both stock and baseline
- [ ] Test percentage calculations are accurate
- [ ] Test status transitions (HIGH → MODERATE → LOW)
- [ ] Test color indicators display correctly
- [ ] Test checkout deducts stock correctly
- [ ] Test buyer cancellation restores stock
- [ ] Test seller rejection restores stock
- [ ] Test transaction atomicity (no orphaned orders/inconsistent stock)

---

## Notes

- The baseline resets on **every restock** (when new_stock > old_stock)
- Initial stock is **never modified** after creation (for analytics)
- If baseline_stock is 0, default to 100% to avoid division errors
- Consider adding a "Restock History" feature later to track all baseline changes
