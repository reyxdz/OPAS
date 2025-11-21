# OPAS Admin Panel Implementation

## Overview
The OPAS Admin Panel is a comprehensive dashboard system designed to manage all administrative functions for the OPAS platform. It features a uniform UI design matching the buyer/seller sides and includes 5 major sections.

## Architecture

### Flutter Frontend Structure
```
OPAS_Flutter/lib/features/admin_panel/
├── models/
│   └── admin_profile.dart          # Admin user profile model
├── screens/
│   ├── admin_layout.dart           # Main admin layout wrapper
│   ├── admin_home_screen.dart      # Admin dashboard with all tabs
│   └── admin_profile_screen.dart   # Admin profile management
└── __init__.dart

OPAS_Flutter/lib/core/
├── services/
│   └── admin_service.dart          # API calls for admin operations
└── routing/
    └── admin_router.dart           # Admin navigation and routing
```

### Django Backend Structure
```
OPAS_Django/apps/users/
├── models.py                       # Updated User model with admin fields
├── admin_serializers.py            # Serializers for admin operations
├── admin_views.py                  # Admin viewsets and endpoints
└── urls.py                         # Admin route configuration
```

## Database Schema Updates

### New User Model Fields
```python
seller_status = CharField(
    choices=['PENDING', 'APPROVED', 'SUSPENDED', 'REJECTED'],
    default='PENDING'
)
seller_approval_date = DateTimeField(nullable)
seller_documents_verified = BooleanField(default=False)
suspension_reason = TextField(nullable)
suspended_at = DateTimeField(nullable)
```

## Admin Dashboard Sections

### 1. Dashboard & Analytics
**Purpose:** Overview of platform activity and key metrics

**Features:**
- Total Users count
- Active Sellers count
- Pending Approvals count
- Total Listings count
- Recent Reports section (Price Trends, Market Activity, Compliance)

**API Endpoint:** `GET /api/users/admin/dashboard/stats/`

**Permissions:** OPAS_ADMIN, SYSTEM_ADMIN only

---

### 2. User & Seller Management
**Purpose:** Manage user registrations, approvals, and suspensions

**Key Functions:**
- **Pending Seller Approvals** - Review and approve new sellers
- **Verify Seller Documents** - Validate seller credentials
- **Manage Suspensions** - Suspend/unsuspend users and sellers
- **User Statistics** - View breakdown by role

**API Endpoints:**
- `GET /api/users/admin/sellers/pending_approvals/` - List pending sellers
- `POST /api/users/admin/sellers/{id}/approve/` - Approve seller
- `POST /api/users/admin/sellers/{id}/suspend/` - Suspend user
- `POST /api/users/admin/sellers/{id}/verify_documents/` - Verify documents
- `GET /api/users/admin/sellers/list_sellers/` - All sellers
- `GET /api/users/admin/users/list_users/` - All users (with role filter)
- `GET /api/users/admin/users/statistics/` - User statistics

---

### 3. Price & Market Regulation
**Purpose:** Ensure fair pricing and marketplace integrity

**Key Functions:**
- **Set Ceiling Prices** - Define maximum prices for products
- **Monitor Listings** - Check for price violations
- **Price Advisories** - Post official price notifications
- **Compliance Management** - Track non-compliant listings

**API Endpoints:**
- `POST /api/users/admin/pricing/set_ceiling_price/` - Set ceiling
- `POST /api/users/admin/pricing/post_advisory/` - Post advisory
- `GET /api/users/admin/pricing/violations/` - List violations

---

### 4. OPAS Purchasing & Inventory
**Purpose:** Manage platform's direct purchasing and stock

**Key Functions:**
- **Sell to OPAS Requests** - Review seller submissions
- **Current Stock** - View inventory with FIFO tracking
- **Restocking Needs** - Monitor low-stock items
- **Inventory Management** - Track stock levels and expiration

**API Endpoints:**
- `GET /api/users/admin/inventory/current_stock/` - Current inventory
- `GET /api/users/admin/inventory/low_stock/` - Low stock items
- `POST /api/users/admin/inventory/accept_sell_to_opas/` - Accept submission

---

### 5. Notifications & Announcements
**Purpose:** Communicate with users across the platform

**Key Functions:**
- **Create Announcements** - Send official notifications
- **Select Recipients** - Target all/sellers/buyers/admins
- **Track Announcements** - View announcement history
- **Send Alerts** - Price changes, maintenance, approvals

**API Endpoints:**
- `POST /api/users/admin/announcements/create_announcement/` - Create
- `GET /api/users/admin/announcements/list_announcements/` - List

---

## UI/UX Design

### Navbar Design (Matching Buyer Side)
- **AppBar:** OPAS Admin title with admin icon and notification bell
- **Bottom Navigation:** Uniform card-based navigation with icons and labels
- **Colors:** Green accent (#00B464) consistent with branding
- **Responsive:** Scrollable horizontal nav for smaller screens

### Navigation Items
1. Dashboard (icons.dashboard)
2. Users (icons.people)
3. Pricing (icons.trending_up)
4. Inventory (icons.inventory)
5. Announcements (icons.notifications)

### Visual Consistency
- Same card styling as buyer side
- Matching color scheme and typography
- Consistent spacing and padding
- Similar state management patterns

## Implementation Status

### ✅ Completed
- [x] Admin home screen with all 5 sections
- [x] Uniform navbar layout (matching buyer side)
- [x] Admin profile screen
- [x] Django models with admin fields
- [x] Admin serializers for all operations
- [x] Admin viewsets and routes
- [x] Flutter admin service with API calls
- [x] Admin routing configuration
- [x] Database migrations

### 🔄 In Progress / To Implement
- [ ] Integration with actual product/inventory models
- [ ] Price violation monitoring system
- [ ] Inventory database model
- [ ] Announcement notification system
- [ ] Document verification workflow
- [ ] FIFO inventory tracking
- [ ] Sell to OPAS submission model

## Usage

### Accessing Admin Panel
1. Admin users (OPAS_ADMIN or SYSTEM_ADMIN role) see admin dashboard
2. Navigate to `/admin` route in Flutter app
3. Use bottom navbar to switch between sections

### API Authentication
All admin endpoints require:
- JWT Bearer Token (access token)
- Admin role verification
- `IsOPASAdmin` permission class

### Example Admin Login Flow
```dart
// Login with admin credentials
await ApiService.loginUser(phoneNumber, password);

// Check if admin
bool isAdmin = await AdminRouter.isUserAdmin();

// Navigate to admin dashboard
if (isAdmin) {
  AdminRouter.navigateToAdminDashboard(context);
}
```

## Permissions & Security

### Permission Classes
- `IsOPASAdmin` - Checks for OPAS_ADMIN or SYSTEM_ADMIN role
- Used on all admin endpoints
- Applied at viewset level

### Role-Based Access
- **OPAS_ADMIN:** Full admin dashboard access
- **SYSTEM_ADMIN:** Full admin dashboard access (super user)
- **SELLER:** Cannot access admin
- **BUYER:** Cannot access admin

## Next Steps
1. Create Product model for inventory management
2. Implement document verification workflow
3. Add price monitoring/violation detection
4. Create Announcement model and notification system
5. Integrate Sell to OPAS submission model
6. Add admin analytics/reporting features
7. Implement admin audit logging
