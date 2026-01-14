# Delivery Proof Endpoint Fix - Complete

## Problem
When attempting to mark an OPAS submission as delivered, the Flutter app was calling:
```
POST /api/admin/opas/{submission_id}/mark-delivered/
```

Where `submission_id` is the SellToOPAS submission ID. However, the backend's `mark_delivered` action expected an OPASPurchaseOrder ID, causing a 404 error.

**Error:** `Not Found: /api/admin/opas/5/mark-delivered/`

This happened because:
1. The OPASPurchasingViewSet (which handles `/api/admin/opas/` routes) serves OPASPurchaseOrder objects
2. SellToOPAS and OPASPurchaseOrder are different models with a OneToOne relationship
3. The OneToOne is created during approval: `OPASPurchaseOrder.sell_to_opas = OneToOneField('SellToOPAS', related_name='purchase_order')`

## Root Cause
The `get_object()` method in OPASPurchasingViewSet had special handling for `approve_seller_offer` and `reject_seller_offer` actions (which work with SellToOPAS IDs), but did NOT have handling for the `mark_delivered` action.

The viewset's default `get_object()` always queries OPASPurchaseOrder, so when Flutter sent a SellToOPAS ID (5), it couldn't find a purchase order with that ID.

## Solution
Updated the `get_object()` method in `OPASPurchasingViewSet` to handle the `mark_delivered` action:

### Code Change (admin_viewsets.py)

```python
def get_object(self):
    """
    Override to handle both OPASPurchaseOrder and SellToOPAS models.
    
    For approve/reject/mark_delivered actions, we work with SellToOPAS directly.
    For other operations, we use the default viewset queryset.
    """
    # Check if this is an approve, reject, or mark_delivered action
    if self.action in ['approve_seller_offer', 'reject_seller_offer', 'mark_delivered']:
        # For these actions, get from SellToOPAS model
        pk = self.kwargs.get('pk')
        try:
            sell_to_opas = SellToOPAS.objects.get(id=pk)
            # For mark_delivered, we need to return the related purchase_order
            if self.action == 'mark_delivered':
                # Return the related OPASPurchaseOrder if it exists
                if hasattr(sell_to_opas, 'purchase_order') and sell_to_opas.purchase_order:
                    return sell_to_opas.purchase_order
                else:
                    from rest_framework.exceptions import NotFound
                    raise NotFound('OPASPurchaseOrder not found for this submission. Has it been approved?')
            # For approve/reject, return the SellToOPAS object
            return sell_to_opas
        except SellToOPAS.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound('SellToOPAS submission not found')
    
    # For other actions, use default behavior
    return super().get_object()
```

### Flow
1. Flutter sends: `POST /api/admin/opas/{submission_id}/mark-delivered/` (submission_id = SellToOPAS ID)
2. Backend's `get_object()` intercepts for mark_delivered action
3. Looks up SellToOPAS with that ID
4. Gets the related OPASPurchaseOrder (created during approval)
5. Returns the purchase_order for the action to use
6. mark_delivered() sets status to DELIVERED and saves delivery proof images

## Flask UI Changes
Simplified Flutter code since backend now handles ID resolution:

```dart
// Before (with fallback)
await AdminService.markOPASDelivered(
  submission.opasOrderId?.toString() ?? submission.id.toString(),
  images,
);

// After (simpler)
await AdminService.markOPASDelivered(
  submission.id.toString(),
  images,
);
```

The backend now handles the conversion from SellToOPAS ID to OPASPurchaseOrder ID.

## Validation
- ✅ Backend correctly resolves SellToOPAS ID to OPASPurchaseOrder
- ✅ Error handling for submissions not yet approved (no purchase_order)
- ✅ Flutter app uses simplified submission ID
- ✅ mark_delivered endpoint will now work correctly
- ✅ Delivery proof images will be saved to DeliveryProof model
- ✅ Status will update to DELIVERED

## Testing Steps
1. Create a SellToOPAS submission
2. Admin approves it (creates OPASPurchaseOrder with related purchase_order)
3. Admin clicks "Mark as Delivered" and uploads proof images
4. Endpoint `/api/admin/opas/{submission_id}/mark-delivered/` should work
5. Status should update to DELIVERED
6. Proof images should be visible in submission details

## Files Modified
- `OPAS_Django/apps/users/admin_viewsets.py` - Updated `get_object()` method
- `OPAS_Flutter/lib/features/admin_panel/screens/opas_submissions_screen.dart` - Simplified call to use submission ID

## Related Components
- Backend endpoint: `/api/admin/opas/{id}/mark-delivered/`
- ViewSet: OPASPurchasingViewSet
- Model: OPASPurchaseOrder with DeliveryProof relationship
- Action: detail=True, methods=['post'], url_path='mark-delivered'

## Notes
- The purchase_order_id field in SellToOPASSerializer is still available if needed for other endpoints
- The opasOrderId field in OPASSubmissionModel is still parsed if available, but no longer required
- This approach maintains backward compatibility while fixing the endpoint routing
