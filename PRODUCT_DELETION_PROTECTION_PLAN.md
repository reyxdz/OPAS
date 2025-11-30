# Product Deletion Protection Implementation Plan

## Overview
Implement Option 2: Only allow sellers to delete products if no orders exist for that product. This prevents orphaned orders while giving sellers flexibility to clean up old products.

## Business Rules
- ✅ Products with **NO orders** → Can be deleted
- ❌ Products with **ANY orders** (pending, confirmed, fulfilled, delivered, cancelled) → Cannot be deleted
- Clear error message to seller explaining why deletion failed

## Implementation Plan

### Phase 1: Backend - Add Order Check Logic✅

#### 1.1 Add Helper Method to SellerProduct Model✅
**File:** `OPAS_Django/apps/users/seller_models.py`

```python
def has_orders(self):
    """Check if product has any associated orders"""
    return SellerOrder.objects.filter(product=self).exists()

def get_order_count(self):
    """Get count of orders for this product"""
    return SellerOrder.objects.filter(product=self).count()
```

#### 1.2 Add Delete Validation to Product Deletion Endpoint✅
**File:** `OPAS_Django/apps/sellers/seller_views.py`

Location: Product delete/destroy endpoint (SellerProductViewSet)

**Logic:**
```python
def destroy(self, request, *args, **kwargs):
    """Override destroy to check for orders before deletion"""
    instance = self.get_object()
    
    # Check if product has orders
    if instance.has_orders():
        order_count = instance.get_order_count()
        return Response(
            {
                'detail': f'Cannot delete product with active orders',
                'order_count': order_count,
                'message': f'This product has {order_count} order(s). Please complete or cancel the orders first.'
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Safe to delete
    self.perform_destroy(instance)
    return Response(status=status.HTTP_204_NO_CONTENT)
```

### Phase 2: Frontend - Handle Deletion Errors✅

#### 2.1 Update Product Deletion Dialog✅
**File:** `OPAS_Flutter/lib/features/products/screens/product_management_screen.dart`

**Changes:**
- Show error dialog if deletion fails with order count
- Display helpful message: "This product has X order(s)"
- Suggest next steps: "Complete or cancel orders first"

**Example Dialog:**
```dart
// In delete confirmation success/error handler
if (response.statusCode == 400) {
  final data = jsonDecode(response.body);
  final orderCount = data['order_count'] ?? 0;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cannot Delete Product'),
      content: Text(
        'This product has $orderCount active order(s).\n\n'
        'Please complete or cancel these orders first before deleting.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

#### 2.2 Update Product List Item Actions✅
**File:** `OPAS_Flutter/lib/features/products/widgets/product_item_card.dart`

**Changes:**
- Disable delete button if product has orders
- Show tooltip: "Cannot delete - has active orders"
- Or show order count badge: "🔒 5 orders"

### Phase 3: Database - Add Index for Performance✅

#### 3.1 Add Database Index✅
**File:** `OPAS_Django/apps/users/seller_models.py` - In SellerOrder model

```python
class Meta:
    indexes = [
        models.Index(fields=['product', 'status']),  # For order queries
        models.Index(fields=['product', 'buyer']),   # For buyer queries
    ]
```

This makes `product.has_orders()` query fast even with many orders.

### Phase 4: Testing✅

#### 4.1 Test Cases✅

**Test 1: Delete product with no orders**
- ✅ Create product
- ✅ Try to delete immediately
- ✅ Should succeed (204 No Content)

**Test 2: Delete product with pending order**
- ✅ Create product
- ✅ Create order for product
- ✅ Try to delete
- ✅ Should fail (400) with message "has 1 order(s)"

**Test 3: Delete product with multiple orders**
- ✅ Create product
- ✅ Create 3 different orders
- ✅ Try to delete
- ✅ Should fail (400) with message "has 3 order(s)"

**Test 4: Delete product after order cancelled**
- ✅ Create product
- ✅ Create order, then cancel it
- ✅ Try to delete
- ✅ Should fail (400) - cancelled orders still protect (business decision)

### Phase 5: API Documentation✅

#### 5.1 Update API Docs✅
**Endpoint:** `DELETE /api/users/seller/products/{id}/`

**Success Response (204):**
```json
// No content - product deleted
```

**Error Response (400):**
```json
{
  "detail": "Cannot delete product with active orders",
  "order_count": 5,
  "message": "This product has 5 order(s). Please complete or cancel the orders first."
}
```

**Error Response (404):**
```json
{
  "detail": "Product not found"
}
```

**Documentation Created:** ✅
- File: `OPAS_Django/PRODUCT_DELETION_API_DOCUMENTATION.md`
- Comprehensive API reference with:
  - Complete endpoint specification
  - Request/response formats with examples
  - All error scenarios documented
  - Status codes reference
  - Frontend integration guide (Flutter)
  - Backend implementation details
  - Database optimization info
  - Testing guide
  - Deployment checklist
  - Performance metrics

## Implementation Timeline

| Phase | Task | Estimated Time |
|-------|------|-----------------|
| 1 | Backend - Add validation | 30 mins |
| 2 | Frontend - Update UI | 45 mins |
| 3 | Database - Add indexes | 15 mins |
| 4 | Testing | 30 mins |
| 5 | Documentation | 15 mins |
| **Total** | | **2 hours** |

## Rollback Plan

If issues occur:
1. Revert seller_models.py (remove `has_orders()` method)
2. Revert seller_views.py (remove validation logic)
3. Revert Flutter UI (remove error handling)
4. Products can be deleted as before

## Benefits

✅ **Data Integrity:** No orphaned orders with deleted products
✅ **Better UX:** Clear feedback why deletion failed
✅ **Flexibility:** Sellers can still delete old products
✅ **Scalability:** Indexed queries ensure fast performance
✅ **Business Logic:** Enforces order lifecycle management

## Future Enhancements

- Add "soft delete" option to archive products instead
- Bulk delete products (with order checking)
- Automated email to seller: "X orders exist for your product"
- Dashboard widget: "X products ready to delete"
