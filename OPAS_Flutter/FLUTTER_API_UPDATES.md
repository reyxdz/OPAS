## Flutter API Updates - Complete

All Flask app endpoints have been updated to match the new consolidated URL structure and removed farm_size field.

### Backend Changes (Django):
✅ URL Consolidation:
- Seller endpoints: `/api/users/sellers/*`
- Admin endpoints: `/api/admin/*`
- Removed farm_size field from SellerRegistrationRequest model

### Frontend Changes (Flutter):

#### 1. API Service Endpoints Updated:
- `SellerRegistrationService`:
  - Old: `http://10.113.93.34:8000/api/sellers`
  - New: `http://10.113.93.34:8000/api/users/sellers`
  - Removed: `farmSize` parameter from `submitRegistration()`

#### 2. Admin Endpoints Updated:
- `AdminHomeScreen`:
  - Old: `/api/users/admin/sellers/pending_approvals/`
  - New: `/api/admin/sellers/`

#### 3. Models Updated:
- `SellerRegistration` model - removed `farmSize` property
- `AdminRegistrationDetail` model - removed `farmSize` property

#### 4. UI Components Updated:
- `FarmInfoFormWidget` - removed farm size text field
- `SellerRegistrationScreen` - removed farm size controller and field
- `RegistrationStatusWidget` - removed farm size display
- `SellerRegistrationDetailScreen` - removed farm size display

#### 5. Providers Updated:
- `seller_registration_providers.dart` - removed `farmSize` from submission

### Files Modified:
1. lib/features/profile/services/seller_registration_service.dart
2. lib/features/profile/models/seller_registration_model.dart
3. lib/features/profile/widgets/farm_info_form_widget.dart
4. lib/features/profile/screens/seller_registration_screen.dart
5. lib/features/profile/providers/seller_registration_providers.dart
6. lib/features/profile/widgets/registration_status_widget.dart
7. lib/features/admin_panel/models/admin_registration_list_model.dart
8. lib/features/admin_panel/screens/seller_registration_detail_screen.dart
9. lib/features/admin_panel/screens/admin_home_screen.dart

### Testing:
After rebuilding Flutter app:
1. Seller registration should work WITHOUT farm_size field
2. Admin panel should display pending approvals correctly
3. No more 404 errors in Django terminal

Run: `flutter clean && flutter pub get && flutter run`
