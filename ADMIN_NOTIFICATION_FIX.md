# Seller Application Admin Notification Fix

## Problem Statement
When a user submitted an application to become a seller, the admin was not receiving it in their admin panel. The application should have been visible to ALL users with OPAS Admin roles.

## Root Causes Identified

### 1. **Notification System Only Sending to Single Email**
- **File**: `apps/core/notifications.py`
- **Issue**: `send_registration_submitted_notification()` was sending notifications to only `settings.ADMIN_EMAIL` (single email)
- **Fix**: Updated to query ALL admin users with OPAS_ADMIN, ADMIN, or SYSTEM_ADMIN roles and send to all of them

### 2. **Missing ADMIN Role in UserRole Enum**
- **File**: `apps/users/models.py`
- **Issue**: The UserRole enum didn't have 'ADMIN' defined, but users were being created with role='ADMIN'
- **Fix**: Added `ADMIN = 'ADMIN', 'Admin'` to the UserRole enum

### 3. **Admin Permission Checks Not Including ADMIN Role**
- **File**: `apps/users/admin_views.py`
- **Issues**:
  - Line 45: Permission check only looked for 'OPAS_ADMIN' or 'SYSTEM_ADMIN'
  - Line 488: Admin user count query didn't include 'ADMIN' role
- **Fixes**: Updated both to include `UserRole.ADMIN` in role checks

### 4. **Admin Endpoint Reading from Wrong Model**
- **File**: `apps/users/admin_views.py`
- **Issue**: Admin endpoints (`pending_approvals` and `pending_applications`) were querying `SellerApplication` model, but the registration system was creating `SellerRegistrationRequest` in `admin_models.py`
- **Fixes**:
  - Updated to query `SellerRegistrationRequest` instead of `SellerApplication`
  - Changed from `SellerApplicationSerializer` to `SellerRegistrationRequestSerializer`
  - Updated foreign key references from `user` to `seller`
  - Changed status checks to use `SellerRegistrationStatus.PENDING` instead of string 'PENDING'

## Files Modified

### 1. `apps/core/notifications.py`
**Change**: Updated `send_registration_submitted_notification()` method to send to ALL admin users

```python
# BEFORE: Single email
to=[settings.ADMIN_EMAIL]

# AFTER: All admin users
admin_users = User.objects.filter(
    role__in=[UserRole.OPAS_ADMIN, UserRole.ADMIN, UserRole.SYSTEM_ADMIN]
).values_list('email', flat=True).distinct()
admin_emails = list(admin_users)
to=admin_emails
```

### 2. `apps/users/models.py`
**Change**: Added ADMIN role to UserRole enum

```python
class UserRole(models.TextChoices):
    BUYER = 'BUYER', 'Buyer'
    SELLER = 'SELLER', 'Seller'
    ADMIN = 'ADMIN', 'Admin'  # ← ADDED
    OPAS_ADMIN = 'OPAS_ADMIN', 'OPAS Admin'
    SYSTEM_ADMIN = 'SYSTEM_ADMIN', 'System Admin'
```

### 3. `apps/users/admin_views.py`
**Changes**:
1. Added imports for SellerRegistrationRequest and SellerRegistrationStatus
2. Added import for SellerRegistrationRequestSerializer
3. Updated IsOPASAdmin.has_permission() to check for ADMIN role
4. Updated dashboard stats query to count ADMIN role
5. Updated pending_approvals() to query SellerRegistrationRequest
6. Updated pending_applications() to query SellerRegistrationRequest

## How It Works Now

### Seller Registration Flow:
1. **Buyer submits form** in Flutter app → calls `/api/sellers/register-application/`
2. **Server creates SellerRegistrationRequest** with status=PENDING
3. **Notification system triggered**:
   - Queries all users with roles: ADMIN, OPAS_ADMIN, SYSTEM_ADMIN
   - Sends email notification to ALL matching admin users
4. **Admin views applications** via `/api/users/admin/sellers/pending_approvals/`
   - Now queries SellerRegistrationRequest (correct model)
   - Uses SellerRegistrationRequestSerializer (correct serializer)
   - Returns all pending applications to all authorized admins

### Admin Access Control:
- Any user with role = 'ADMIN', 'OPAS_ADMIN', or 'SYSTEM_ADMIN' can:
  - Access admin endpoints
  - View pending applications
  - Approve/reject applications
  - See admin dashboard stats

## Testing

All changes were validated:
✓ Found 2 admin users in system (opas@app.ph with OPAS_ADMIN, opas_admin@opas.com with ADMIN)
✓ Notifications configured to send to 2 admin users
✓ Admin endpoints properly configured to retrieve from SellerRegistrationRequest model
✓ Role-based access control includes ADMIN role

## Next Steps for End-to-End Testing

1. Submit a seller application from the Flutter app as a buyer user
2. Check that all admin users receive the notification email
3. Verify the admin can see the application in the admin dashboard at:
   - Endpoint: `/api/users/admin/sellers/pending_approvals/`
4. Test approval/rejection workflow
5. Verify seller role is updated after approval

## Key Improvements

1. **Multi-Admin Support**: Notifications now reach ALL admins, not just one email
2. **Role Consistency**: ADMIN role now properly recognized in the system
3. **Model Alignment**: Admin endpoints now read from the correct application model
4. **Access Control**: Improved to include all admin role variants
5. **Audit Trail**: Each notification is logged for each admin user

## Configuration Required

No additional configuration needed. The system now uses:
- All users with roles: ADMIN, OPAS_ADMIN, SYSTEM_ADMIN
- Default fallback to `settings.ADMIN_EMAIL` if no admin users exist (for safety)

---
Date: November 23, 2025
System: OPAS Application - Phase 8 Complete
