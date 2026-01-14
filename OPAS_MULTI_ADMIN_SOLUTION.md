# OPAS Multi-Admin Product Upload Solution

## Problem
The initial implementation only worked with a single OPAS admin using a hardcoded phone number (`0000000000`). When multiple OPAS admins with different phone numbers posted products, the system couldn't handle them properly.

## Solution
Instead of tying products to individual admins, we created a **shared OPAS system seller account** that all OPAS admins use when uploading products. This ensures:
- ✅ All OPAS admins can post products regardless of their phone number
- ✅ All products use the same seller account (OPAS System)
- ✅ Seller account is always APPROVED for immediate visibility
- ✅ Products appear immediately on buyer's marketplace

## Implementation Details

### 1. Helper Function: `get_or_create_opas_seller()`
**Location:** `apps/users/admin_serializers.py`

```python
def get_or_create_opas_seller():
    """
    Get or create the shared OPAS seller account for product uploads.
    
    All OPAS admins use this shared account when posting products to the marketplace.
    This ensures products are centrally managed and always visible to buyers.
    """
    from apps.users.models import SellerStatus
    
    opas_seller, created = User.objects.get_or_create(
        phone_number='OPAS_SYSTEM',
        defaults={
            'username': 'opas_system_seller',
            'first_name': 'OPAS',
            'last_name': 'System',
            'email': 'system@opas.local',
            'role': 'SELLER',
            'seller_status': SellerStatus.APPROVED,
        }
    )
    
    # Ensure always APPROVED
    if opas_seller.seller_status != SellerStatus.APPROVED:
        opas_seller.seller_status = SellerStatus.APPROVED
        opas_seller.save()
    
    return opas_seller
```

**Key Features:**
- Creates or retrieves the shared OPAS system seller account
- Uses unique phone number `OPAS_SYSTEM` as identifier
- Always ensures seller_status is APPROVED
- Safe to call multiple times (idempotent)

### 2. Updated `OPASProductUploadSerializer.create()`
**Location:** `apps/users/admin_serializers.py` (lines ~365-410)

**Changes:**
```python
# OLD: Hardcoded phone number
opas_user, _ = User.objects.get_or_create(
    phone_number='0000000000',
    defaults={...}
)

# NEW: Use helper function
opas_user = get_or_create_opas_seller()
```

### 3. Updated `OPASProductManagementViewSet.list()`
**Location:** `apps/users/admin_viewsets.py` (lines ~3210-3240)

**Changes:**
```python
# OLD: Hardcoded phone number lookup
opas_user = User.objects.filter(phone_number='0000000000').first()

# NEW: Use helper function
opas_user = get_or_create_opas_seller()
```

### 4. Updated Imports
**Location:** `apps/users/admin_viewsets.py` (line ~48)

Added import of the helper function:
```python
from .admin_serializers import (
    ...,
    get_or_create_opas_seller,
)
```

## How It Works

### Product Upload Flow (Any OPAS Admin)
1. Admin makes POST request to `/api/admin/opas-products/`
2. `OPASProductManagementViewSet.create()` is called
3. `OPASProductUploadSerializer.save()` is invoked
4. Serializer calls `get_or_create_opas_seller()` to get the shared account
5. Product is created with:
   - `seller` = OPAS System (shared account)
   - `status` = ACTIVE (immediate visibility)
   - `is_opas_managed` = True (tracking flag)
   - `product_type` & `product_subtype` from request
6. OPASInventory entry is created
7. Product appears on buyer marketplace immediately

### Buyer Visibility Flow
1. Buyer requests `/api/products/` (marketplace listing)
2. `MarketplaceViewSet.get_queryset()` filters for:
   - `status=ProductStatus.ACTIVE` ✓
   - `seller__seller_status=SellerStatus.APPROVED` ✓
   - `is_deleted=False` ✓
   - `stock_level > 0` ✓
3. OPAS products meet all criteria
4. Products appear in buyer's marketplace

## OPAS Seller Account Details

| Field | Value |
|-------|-------|
| **Username** | opas_system_seller |
| **Phone** | OPAS_SYSTEM |
| **Email** | system@opas.local |
| **Name** | OPAS System |
| **Role** | SELLER |
| **Seller Status** | APPROVED |
| **Purpose** | Shared account for all OPAS admin uploads |

## Benefits

1. **Multi-Admin Support**: Any number of OPAS admins can upload products
2. **Centralized Management**: All OPAS products in one account
3. **Immediate Visibility**: Products go ACTIVE immediately (no approval needed)
4. **Consistency**: Same seller status across all OPAS products
5. **Flexibility**: Easy to modify seller account properties globally
6. **Scalability**: Works with unlimited number of admin users

## Testing

### Verify Setup
```python
from apps.users.admin_serializers import get_or_create_opas_seller

opas_seller = get_or_create_opas_seller()
print(f"Seller: {opas_seller.full_name}")
print(f"Status: {opas_seller.seller_status}")  # Should be APPROVED
```

### Test Product Creation
```python
from apps.users.admin_serializers import OPASProductUploadSerializer

data = {
    'product_name': 'Test Product',
    'price': '100.00',
    'stock_level': 50,
    'category_forecast': 'FRUIT',
    'product_type': 'Apple',
    'product_subtype': 'Red'
}

serializer = OPASProductUploadSerializer(data=data)
if serializer.is_valid():
    result = serializer.save()
    print("✓ Product created successfully")
```

### Verify Marketplace Visibility
```python
from apps.users.seller_models import SellerProduct, ProductStatus
from apps.users.models import SellerStatus

visible = SellerProduct.objects.filter(
    seller__phone_number='OPAS_SYSTEM',
    status=ProductStatus.ACTIVE,
    seller__seller_status=SellerStatus.APPROVED
)
print(f"Visible OPAS products: {visible.count()}")
```

## Migration Notes

If you have existing OPAS products from the old `phone_number='0000000000'` account:

1. **Option A**: Leave them as-is (they'll still be visible if seller is approved)
2. **Option B**: Migrate them to the new account:
```python
from apps.users.models import User
from apps.users.admin_serializers import get_or_create_opas_seller

old_seller = User.objects.get(phone_number='0000000000')
new_seller = get_or_create_opas_seller()

from apps.users.seller_models import SellerProduct
SellerProduct.objects.filter(seller=old_seller).update(seller=new_seller)
```

## Future Enhancements

- Create a management command to ensure OPAS seller account exists on startup
- Add logging to track which admin uploaded which product
- Create separate OPAS admin profile linked to uploads (while using shared seller account)

