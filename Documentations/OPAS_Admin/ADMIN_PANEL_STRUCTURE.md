# OPAS Admin Panel - Visual Structure & Summary

## 📱 UI Layout

```
┌─────────────────────────────────────┐
│         OPAS Admin            🔔    │ ← AppBar
├─────────────────────────────────────┤
│                                     │
│   ┌─ Dashboard Content ──────────┐ │
│   │                              │ │
│   │  [Dashboard] [Users] [Price] │ │
│   │  [Inventory] [Announce]      │ │
│   │                              │ │
│   │  Content Area (scrollable)   │ │
│   │  - Stats Cards               │ │
│   │  - Recent Actions            │ │
│   │  - Management Sections       │ │
│   │                              │ │
│   └──────────────────────────────┘ │
│                                     │
│  ┌─ Navigation Navbar ────────────┐ │ ← Bottom Nav
│  │ ▤ Dash │ 👥 Users│ 📈 Price │  │
│  │ 📦 Inv │ 🔔 Ann  │             │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 🗂️ File Structure

```
OPAS_Flutter/
├── lib/
│   ├── main.dart (UPDATED: Added admin routing & role detection)
│   ├── core/
│   │   ├── services/
│   │   │   ├── api_service.dart (Existing)
│   │   │   └── admin_service.dart (NEW)
│   │   └── routing/
│   │       └── admin_router.dart (NEW)
│   └── features/
│       └── admin_panel/ (NEW FOLDER)
│           ├── __init__.dart
│           ├── ADMIN_PANEL_README.md
│           ├── models/
│           │   └── admin_profile.dart
│           └── screens/
│               ├── admin_layout.dart
│               ├── admin_home_screen.dart
│               └── admin_profile_screen.dart

OPAS_Django/
├── manage.py
├── apps/
│   └── users/
│       ├── models.py (UPDATED: Added seller status fields)
│       ├── views.py (Existing)
│       ├── admin_serializers.py (NEW)
│       ├── admin_views.py (NEW)
│       ├── urls.py (UPDATED: Added admin routes)
│       └── migrations/
│           └── 0003_add_seller_management_fields.py (NEW)
└── core/
    └── settings.py (Existing config)
```

## 🔄 User Flow

### Login Flow
```
User enters credentials
         ↓
AuthWrapper checks authentication
         ↓
HomeRouteWrapper checks admin role
         ↓
Is Admin? ─── YES ──→ AdminLayout
              │
              NO ──→ BuyerHomeScreen
```

### Admin Navigation
```
AdminHomeScreen (State Management)
         ↓
    _selectedIndex = 0-4
         ↓
_buildBody() ──┬─→ DashboardTab (0)
               ├─→ UserManagementTab (1)
               ├─→ PriceRegulationTab (2)
               ├─→ InventoryTab (3)
               └─→ AnnouncementsTab (4)
```

## 📊 Admin Dashboard Sections

### Section 1: Dashboard & Analytics
```
┌─────────────────────────────────┐
│ Dashboard & Analytics           │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Total Users: 1,234 👥       │ │
│ ├─────────────────────────────┤ │
│ │ Active Sellers: 567 🏪      │ │
│ ├─────────────────────────────┤ │
│ │ Pending Approvals: 12 ⏳    │ │
│ ├─────────────────────────────┤ │
│ │ Total Listings: 2,345 📝    │ │
│ └─────────────────────────────┘ │
│                                 │
│ Recent Reports                  │
│ • Price Trend Report (2h ago)   │
│ • Market Activity (1h ago)      │
│ • Compliance Report (30m ago)   │
└─────────────────────────────────┘
```

### Section 2: User & Seller Management
```
┌─────────────────────────────────┐
│ User & Seller Management        │
├─────────────────────────────────┤
│ • Pending Seller Approvals (12) │
│ • Verify Seller Documents       │
│ • Manage Suspensions (3)        │
│ • User Statistics              │
│                                 │
│ Recent Actions:                 │
│ ✓ Approved: Fresh Produce Co.   │
│ ✗ Suspended: Invalid documents  │
│ ✓ Verified: Green Valley Farm   │
└─────────────────────────────────┘
```

### Section 3: Price & Market Regulation
```
┌─────────────────────────────────┐
│ Price & Market Regulation       │
├─────────────────────────────────┤
│ • Set Ceiling Prices            │
│ • Monitor Listings (5 violations)│
│ • Price Advisories              │
│ • Non-Compliant Listings (3)    │
│                                 │
│ Recent Price Updates:           │
│ Tomato: ₱40/kg (2h ago)        │
│ Onion: ₱25/kg (4h ago)         │
│ Cabbage: ₱15/kg (1d ago)       │
└─────────────────────────────────┘
```

### Section 4: Inventory Management
```
┌─────────────────────────────────┐
│ OPAS Purchasing & Inventory     │
├─────────────────────────────────┤
│ • Sell to OPAS Requests (8)     │
│ • Current Stock (245 items)     │
│ • Restocking Needs (5 items)    │
│ • FIFO Management               │
│                                 │
│ Current Stock:                  │
│ Fresh Tomato: 120 kg (₱4,800)  │
│ Green Onion: 45 kg (₱1,125)    │
│ Cabbage: 200 kg (₱3,000)       │
└─────────────────────────────────┘
```

### Section 5: Announcements
```
┌─────────────────────────────────┐
│ Notifications & Announcements   │
├─────────────────────────────────┤
│ Create Announcement             │
│ ┌─────────────────────────────┐ │
│ │ Title: [_______________]    │ │
│ │ Message: [______________]   │ │
│ │ [Send Announcement]         │ │
│ └─────────────────────────────┘ │
│                                 │
│ Recent Announcements:           │
│ 🔵 Price Advisory: Tomato (2h)  │
│ 🟠 System Maintenance (5h)      │
│ 🟢 Sellers Approved (1d)        │
└─────────────────────────────────┘
```

## 🔗 API Endpoint Tree

```
/api/users/
│
├── admin/
│   ├── dashboard/
│   │   └── stats/ ............................ GET Dashboard stats
│   │
│   ├── sellers/
│   │   ├── pending_approvals/ ............... GET Pending sellers
│   │   ├── list_sellers/ ................... GET All sellers
│   │   └── {id}/
│   │       ├── approve/ .................... POST Approve seller
│   │       ├── suspend/ .................... POST Suspend user
│   │       └── verify_documents/ ........... POST Verify docs
│   │
│   ├── users/
│   │   ├── list_users/ ..................... GET All users
│   │   └── statistics/ ..................... GET User stats
│   │
│   ├── pricing/
│   │   ├── set_ceiling_price/ .............. POST Set price ceiling
│   │   ├── post_advisory/ .................. POST Price advisory
│   │   └── violations/ ..................... GET Price violations
│   │
│   ├── inventory/
│   │   ├── current_stock/ .................. GET Current stock
│   │   ├── low_stock/ ...................... GET Low stock items
│   │   └── accept_sell_to_opas/ ............ POST Accept submission
│   │
│   └── announcements/
│       ├── create_announcement/ ............ POST Create
│       └── list_announcements/ ............. GET List
│
└── upgrade-to-seller/ .......................... POST Seller upgrade
```

## 🎨 Color Palette

| Element | Color | HEX Code | Usage |
|---------|-------|----------|-------|
| Primary Green | Green | #00B464 | Active states, buttons, accents |
| Secondary Grey | Grey | #757575 | Inactive states, text |
| Light Background | White | #FFFFFF | Card backgrounds |
| Border | Light Grey | #E0E0E0 | Dividers, borders |
| Success | Green | #4CAF50 | Success messages |
| Warning | Orange | #FF9800 | Warnings, cautions |
| Error | Red | #F44336 | Errors, suspensions |
| Info | Blue | #2196F3 | Information |

## 🔐 Permission Model

```
User Role
    ├── SYSTEM_ADMIN ─────→ Full Access ✅
    ├── OPAS_ADMIN ─────→ Admin Access ✅
    ├── SELLER ─────→ No Access ❌
    └── BUYER ─────→ No Access ❌

Admin Actions
    ├── View Dashboard ─────→ Required: OPAS_ADMIN
    ├── Manage Sellers ─────→ Required: OPAS_ADMIN
    ├── Set Prices ─────→ Required: OPAS_ADMIN
    ├── Manage Inventory ─────→ Required: OPAS_ADMIN
    └── Send Announcements ─────→ Required: OPAS_ADMIN
```

## 📈 Data Models

### User Model Extensions
```
User
├── email
├── phone_number
├── first_name
├── last_name
├── address
├── role ───────────→ 'BUYER' | 'SELLER' | 'OPAS_ADMIN' | 'SYSTEM_ADMIN'
├── store_name
├── store_description
├── is_seller_approved
├── seller_status ──→ 'PENDING' | 'APPROVED' | 'SUSPENDED' | 'REJECTED'
├── seller_approval_date
├── seller_documents_verified
├── suspension_reason
└── suspended_at
```

## 🚀 Performance Considerations

- **Pagination:** To be implemented for large datasets
- **Caching:** Can add Redis for frequently accessed stats
- **Lazy Loading:** Admin tabs load content on demand
- **Image Optimization:** Profile images compressed
- **API Rate Limiting:** Should be added on Django side

## 📋 Implementation Checklist

- ✅ Flutter UI screens created
- ✅ Django models updated
- ✅ Serializers created
- ✅ Views/ViewSets implemented
- ✅ URLs configured
- ✅ Migrations created
- ✅ Admin service created
- ✅ Routing implemented
- ✅ Main app updated
- ✅ Documentation completed

---

**Status:** Ready for Development & Testing
**Last Updated:** November 18, 2025
