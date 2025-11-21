# OPAS Admin Panel - Implementation Guide

## Overview
This guide provides comprehensive documentation for the newly implemented OPAS Admin Panel. The admin side has been built with a uniform navbar design matching the buyer/seller sides and includes all 5 major administrative sections.

## ✅ What's Been Implemented

### Flutter Frontend

#### 1. Admin Home Screen (`admin_home_screen.dart`)✅
- **Purpose:** Main dashboard with tabbed interface
- **Navigation:** Bottom navbar with 5 sections
- **Features:**
  - Dashboard & Analytics tab
  - User & Seller Management tab
  - Price & Market Regulation tab
  - OPAS Purchasing & Inventory tab
  - Notifications & Announcements tab

#### 2. Admin Profile Screen (`admin_profile_screen.dart`)✅
- Displays admin user information
- Edit profile functionality
- Logout button
- Loads from SharedPreferences (same as buyer side)

#### 3. Admin Layout (`admin_layout.dart`)✅
- Wrapper for admin screens
- Uniform with buyer side structure

#### 4. Admin Profile Model (`admin_profile.dart`)✅
- Stores admin user data
- JSON serialization support

### Django Backend

#### 1. Updated User Model (`models.py`)✅
New fields for seller/admin management:
```python
seller_status = CharField(choices=['PENDING', 'APPROVED', 'SUSPENDED', 'REJECTED'])
seller_approval_date = DateTimeField(nullable)
seller_documents_verified = BooleanField()
suspension_reason = TextField(nullable)
suspended_at = DateTimeField(nullable)
```

#### 2. Admin Serializers (`admin_serializers.py`)✅
- `SellerListSerializer` - List sellers with status
- `ApproveSellerSerializer` - Seller approval data
- `SuspendUserSerializer` - User suspension
- `UserManagementSerializer` - User info
- `DashboardStatsSerializer` - Dashboard metrics
- `AnnouncementSerializer` - Announcement data
- `CeilingPriceSerializer` - Price management
- `InventorySerializer` - Stock management

#### 3. Admin Views (`admin_views.py`)✅
Five main viewsets with full CRUD operations:

**AdminDashboardView:**
- `/admin/dashboard/stats/` - Dashboard statistics

**SellerManagementViewSet:**
- `/admin/sellers/pending_approvals/` - List pending sellers
- `/admin/sellers/{id}/approve/` - Approve seller
- `/admin/sellers/{id}/suspend/` - Suspend user
- `/admin/sellers/{id}/verify_documents/` - Verify docs
- `/admin/sellers/list_sellers/` - All sellers

**UserManagementViewSet:**
- `/admin/users/list_users/` - All users (with role filter)
- `/admin/users/statistics/` - User statistics

**PriceRegulationViewSet:**
- `/admin/pricing/set_ceiling_price/` - Set max price
- `/admin/pricing/post_advisory/` - Post advisory
- `/admin/pricing/violations/` - List violations

**InventoryManagementViewSet:**
- `/admin/inventory/current_stock/` - Current stock
- `/admin/inventory/low_stock/` - Low stock items
- `/admin/inventory/accept_sell_to_opas/` - Accept submission

**AnnouncementViewSet:**
- `/admin/announcements/create_announcement/` - Create
- `/admin/announcements/list_announcements/` - List

#### 4. Admin URLs (`urls.py`)
- Registered all viewsets with DefaultRouter
- All endpoints under `/api/users/` path

#### 5. Database Migration (`0003_add_seller_management_fields.py`)
- Adds all new fields to User model
- Ready to run with `python manage.py migrate`

### Flutter Services & Routing

#### 1. Admin Service (`admin_service.dart`)
- Comprehensive API service for all admin operations
- All endpoint implementations
- Token management with SharedPreferences
- Error handling

#### 2. Admin Router (`admin_router.dart`)
- Navigation helpers
- Admin role checking
- Route definitions
- AdminRoutes static configuration

### Configuration & Integration

#### 1. Updated main.dart
- Import admin routes
- Added AdminLayout to route map
- HomeRouteWrapper to detect admin role
- Automatic admin/buyer routing on login

#### 2. Permission Class (`IsOPASAdmin`)
- Checks for OPAS_ADMIN or SYSTEM_ADMIN role
- Applied to all admin endpoints

## 🚀 Running the Application

### Backend Setup

1. **Apply migrations:**
```bash
cd OPAS_Django
python manage.py migrate
```

2. **Create admin user (optional):**
```bash
python manage.py createsuperuser
```

3. **Start development server:**
```bash
python manage.py runserver 0.0.0.0:8000
```

### Frontend Setup

1. **Run Flutter app:**
```bash
cd OPAS_Flutter
flutter run
```

2. **Login with admin account** (if you created one)
   - The app will automatically route to AdminLayout instead of BuyerHomeScreen

3. **Test admin features** from the dashboard

## 📋 Admin User Roles

### OPAS_ADMIN
- Full access to admin dashboard
- Can approve/reject sellers
- Can manage prices
- Can send announcements
- Cannot suspend other admins (only users/sellers)

### SYSTEM_ADMIN
- Super user with all permissions
- Can manage other admins
- Full system control

### BUYER / SELLER
- No admin access
- Redirected to buyer home screen

## 🔌 API Endpoints Reference

### Authentication Required
All endpoints require:
- Authorization Header: `Bearer {access_token}`
- Admin Role: OPAS_ADMIN or SYSTEM_ADMIN

### Dashboard
```
GET /api/users/admin/dashboard/stats/
```

### Seller Management
```
GET    /api/users/admin/sellers/pending_approvals/
GET    /api/users/admin/sellers/list_sellers/
POST   /api/users/admin/sellers/{id}/approve/
POST   /api/users/admin/sellers/{id}/suspend/
POST   /api/users/admin/sellers/{id}/verify_documents/
```

### User Management
```
GET    /api/users/admin/users/list_users/
GET    /api/users/admin/users/statistics/
```

### Price Regulation
```
POST   /api/users/admin/pricing/set_ceiling_price/
POST   /api/users/admin/pricing/post_advisory/
GET    /api/users/admin/pricing/violations/
```

### Inventory
```
GET    /api/users/admin/inventory/current_stock/
GET    /api/users/admin/inventory/low_stock/
POST   /api/users/admin/inventory/accept_sell_to_opas/
```

### Announcements
```
POST   /api/users/admin/announcements/create_announcement/
GET    /api/users/admin/announcements/list_announcements/
```

## 🎨 UI/UX Design

### Navbar Design
- **Style:** Card-based bottom navbar (matching buyer side)
- **Colors:** Green (#00B464) primary, grey secondary
- **Icons:** Material design icons with labels
- **Scrollable:** Horizontal scroll on small screens
- **Selected State:** Green background with active icon color

### Screen Layout
- **AppBar:** OPAS Admin title, admin icon, notification bell
- **Body:** Content area with padding, scrollable
- **Bottom Navbar:** Fixed position, 100+ margin for content

### Color Scheme
- **Primary:** #00B464 (Green)
- **Secondary:** Colors.grey
- **Backgrounds:** White with subtle shadows
- **Borders:** Light grey (#e0e0e0)

## 📊 Dashboard Data Flow

```
User Login (with admin role)
    ↓
AuthWrapper detects admin role via AdminRouter.isUserAdmin()
    ↓
HomeRouteWrapper routes to AdminLayout instead of BuyerHomeScreen
    ↓
AdminHomeScreen displays dashboard
    ↓
Bottom navbar allows tab switching
    ↓
Each tab calls AdminService methods
    ↓
AdminService makes API calls with JWT token
    ↓
Django views check IsOPASAdmin permission
    ↓
Data returned and displayed in UI
```

## 🔐 Security Features

1. **Token-based Authentication**
   - JWT access tokens required
   - Tokens stored in SharedPreferences
   - Automatic token refresh on expiration

2. **Role-based Access Control**
   - Admin endpoints check user role
   - Only OPAS_ADMIN and SYSTEM_ADMIN allowed
   - Permission class enforces at Django level

3. **Secure Data Transmission**
   - Bearer token in Authorization header
   - HTTPS ready (just change baseUrl)
   - Content-Type validation

## 📱 Responsive Design

- **Desktop:** Full navbar visible
- **Tablet:** Slightly adjusted spacing
- **Mobile:** Horizontal scrollable navbar
- All sections adapt to screen size

## 🧪 Testing the Admin Panel

### Manual Test Steps

1. **Admin Login:**
   - Login with phone number of admin user
   - Should redirect to AdminLayout

2. **Dashboard Tab:**
   - Check if stats display (hardcoded for now)
   - Click other tabs to ensure switching works

3. **User Management:**
   - Verify seller list displays
   - Check pending approvals section

4. **Price Management:**
   - Test ceiling price form
   - Test advisory posting

5. **Inventory:**
   - Check current stock display
   - View low stock items

6. **Announcements:**
   - Create test announcement
   - Verify form validation

## 🛠️ Database Operations

### Create Admin User (Django Shell)
```python
python manage.py shell

from apps.users.models import User, UserRole

User.objects.create_user(
    email='admin@opas.com',
    username='opas_admin',
    password='secure_password',
    phone_number='09123456789',
    first_name='Admin',
    last_name='User',
    role=UserRole.OPAS_ADMIN
)
```

### Query Sellers by Status
```python
from apps.users.models import User, SellerStatus

pending = User.objects.filter(seller_status=SellerStatus.PENDING)
approved = User.objects.filter(seller_status=SellerStatus.APPROVED)
suspended = User.objects.filter(seller_status=SellerStatus.SUSPENDED)
```

## 📝 Future Enhancements

1. **Product Management Model**
   - Create products table
   - Link inventory to products
   - Add FIFO tracking

2. **Document Verification**
   - File upload system
   - Document storage
   - Verification workflow

3. **Analytics Dashboard**
   - Sales reports
   - Revenue tracking
   - Market trends

4. **Notification System**
   - Real-time announcements
   - Email/SMS integration
   - Notification history

5. **Audit Logging**
   - Track all admin actions
   - Timestamp and user info
   - Compliance reporting

6. **Advanced Filtering**
   - Date range filters
   - Multi-select filters
   - Export to CSV/PDF

## 🐛 Troubleshooting

### Admin Not Seeing Dashboard
- Check user role in database: `role` field must be 'OPAS_ADMIN'
- Clear SharedPreferences and re-login
- Ensure access token is valid

### API Endpoints Not Working
- Verify Django server is running
- Check BaseUrl in admin_service.dart
- Verify token is in Authorization header
- Check admin role with `IsOPASAdmin` permission

### Migration Errors
- Run `python manage.py makemigrations` first
- Check existing migrations aren't broken
- Drop and recreate database if needed

## 📞 Support

For issues or questions about the admin panel:
1. Check logs in console
2. Verify API responses with Postman/Insomnia
3. Check Django debug mode output
4. Verify database state

---

**Implementation Date:** November 18, 2025
**Status:** ✅ Complete and Ready for Testing
**Next Phase:** Integration with actual data models and production deployment
