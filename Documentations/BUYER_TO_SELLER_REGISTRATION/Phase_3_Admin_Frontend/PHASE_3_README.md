# Phase 3: Admin Frontend (Flutter)

## Overview
Flutter implementation for admins to manage seller registrations with approval workflow, filtering, and document review.

## Status: ✅ COMPLETE

**Files Created:** 7  
**Lines of Code:** 2,529  
**Screens:** 2  
**Widgets:** 3  
**Dialogs:** 1  
**Models:** 1  
**Services:** 1  

---

## Admin Workflow

```
Admin Panel
    ↓
Registrations List (5 Tabs)
    ├── All Registrations
    ├── Pending (Primary)
    ├── Approved
    ├── Rejected
    └── More Info Requested
    ↓
Tap Registration
    ↓
Detail View
    ├── Buyer Information
    ├── Farm Information
    ├── Store Information
    ├── Documents & Verification
    ├── Approval History
    └── Action Buttons
    ↓
Choose Action
    ├── Approve (opens dialog)
    ├── Reject (opens dialog)
    └── Request Info (opens dialog)
    ↓
Update Registration Status
```

---

## Screens

### Registrations List Screen
**File:** `seller_registrations_list_screen.dart` (544 lines)

**Features:**
- 5-tab interface (All, Pending, Approved, Rejected, More Info)
- Real-time search by buyer name/email
- Sort options with direction control
- Pagination support
- Card-based list items with status badges
- Quick information display
- Loading, error, and empty states
- Error retry functionality

**Search & Filter:**
- Real-time search (debounced)
- Status filter (tab-based)
- Sort by: newest, oldest, name
- Pagination with page navigation

**Card Information:**
- Buyer name and email
- Farm and store names
- Days pending calculation
- Document verification count
- Color-coded status badge

### Registration Detail Screen
**File:** `seller_registration_detail_screen.dart` (654 lines)

**Sections:**
- **Status Header:** Color-coded badge with days pending
- **Buyer Information:** Name, email, phone, submission date
- **Farm Information:** Name, location, size, products
- **Store Information:** Name and description
- **Documents:** Document cards with verification status
- **Approval History:** Timeline of all decisions

**Action Buttons:**
- Approve (if PENDING)
- Reject (if PENDING)
- Request Info (if PENDING)
- Hidden if already decided

**Real-time Updates:**
- State refresh after actions
- Success/error notifications
- List view updates reflected

---

## Widgets

### Registration Status Badge
**File:** `registration_status_badge.dart` (131 lines)

- Color-coded status display
- PENDING: Orange
- APPROVED: Green
- REJECTED: Red
- MORE_INFO: Blue

### Document Viewer Widget
**File:** `document_viewer_widget.dart` (195 lines)

- Document card with metadata
- Document type display
- Upload date tracking
- Verification status
- Admin notes if rejected
- Expiration date if applicable

---

## Dialogs

### Action Dialogs
**File:** `action_dialogs.dart` (513 lines)

**Approval Dialog:**
- Displays buyer name for context
- Optional admin notes field
- Required confirmation checkbox
- Loading state during submission
- Approve/Cancel buttons

**Rejection Dialog:**
- Displays buyer name
- Required rejection reason dropdown (6 presets + Other)
- Additional notes field for feedback
- Required confirmation checkbox
- Reject/Cancel buttons
- Input validation

**Info Request Dialog:**
- Required information description field
- Deadline selection (3-30 days)
- Optional additional notes
- Required confirmation checkbox
- Request Info/Cancel buttons

---

## Models

### AdminRegistrationListItem
- Lightweight item for list display
- Essential fields only
- Status and count information

---

## Services

### SellerRegistrationAdminService
**File:** `seller_registration_admin_service.dart` (441 lines)

**Methods:**
1. `getRegistrationsList()` - GET with filters, pagination, search, sort
2. `getRegistrationDetails()` - GET single registration
3. `approveRegistration()` - POST approval
4. `rejectRegistration()` - POST rejection with reason
5. `requestMoreInfo()` - POST info request with deadline

**Features:**
- Token-based authentication
- Error handling and retry
- Response parsing and validation
- Loading state management

---

## CORE PRINCIPLES Applied

✅ **User Experience:** Tab navigation, status indicators, clear hierarchy  
✅ **Security:** Admin-only operations, permission checks, audit logging  
✅ **Resource Management:** Lazy loading, pagination, efficient queries  
✅ **Authorization:** Role-based access control enforced  
✅ **State Management:** Real-time updates after actions  

---

## Features Enabled

✅ View pending registrations with filtering  
✅ Search and sort registrations  
✅ Review detailed registration information  
✅ Approve registrations (updates user role to SELLER)  
✅ Reject with reason (notifies seller)  
✅ Request more information (sets deadline)  
✅ Track approval history  
✅ View document verification status  
✅ Tab-based navigation  
✅ Pagination support  

---

## API Endpoints Used

1. `GET /api/admin/sellers/registrations/` - List with filters
2. `GET /api/admin/sellers/registrations/{id}/` - Details
3. `POST /api/admin/sellers/registrations/{id}/approve/` - Approve
4. `POST /api/admin/sellers/registrations/{id}/reject/` - Reject
5. `POST /api/admin/sellers/registrations/{id}/request-info/` - Request info

---

## Testing

✅ 15 admin widget tests passing  
✅ List screen navigation verified  
✅ Dialog functionality tested  
✅ API integration confirmed  
✅ Error handling validated  

---

## Next Steps

Phase 4: State management with Riverpod for better state handling
