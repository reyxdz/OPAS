# 🚀 Buyer-to-Seller Registration Workflow Implementation Plan

## 📋 Overview
This document outlines the comprehensive implementation plan for enabling buyers to convert to sellers with admin review and approval workflow. The system already has foundational models (SellerRegistrationRequest, SellerDocumentVerification, SellerApprovalHistory), and we need to integrate them with buyer-to-seller conversion and admin oversight.

---

## 🏗️ Architecture Overview

```
Buyer User Flow:
┌─────────────────┐
│  Buyer Profile  │  "Become a Seller" button
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Seller Registration Form Screen │  Collects farm/store info & documents
└────────┬────────────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Submit Registration Req  │  Creates SellerRegistrationRequest
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ Admin Panel - Pending Registrations List │
└────────┬─────────────────────────────────┘
         │
    ┌────┴─────┐
    │           │
    ▼           ▼
┌────────┐ ┌────────┐
│Approve │ │ Reject │  Admin reviews & makes decision
└────┬───┘ └───┬────┘
     │         │
     ▼         ▼
User Role    User Role
Changed to   Kept as
SELLER       BUYER
```

---

## 📦 Phase 1: Backend API Endpoints (Django)

### 1.1 Seller Registration API Endpoints

**Endpoint 1: Submit Seller Registration**
```
POST /api/sellers/register-application/
Required: Current authenticated buyer user
Payload:
  {
    "farm_name": string,
    "farm_location": string,
    "farm_size": string,
    "products_grown": string,
    "store_name": string,
    "store_description": string,
    "documents": [
      {
        "document_type": "TAX_ID | BUSINESS_PERMIT | ID_PROOF",
        "file": FileField
      }
    ]
  }
Response:
  {
    "id": int,
    "status": "PENDING",
    "seller_id": int,
    "submitted_at": datetime,
    "farm_name": string,
    ...
  }
```

**Endpoint 2: Get Registration Details**
```
GET /api/sellers/registrations/{id}/
Response: Complete registration details with documents
```

**Endpoint 3: Get My Registration Status (Buyer)**
```
GET /api/sellers/my-registration/
Response: Current user's registration request status
```

### 1.2 Admin Management Endpoints

**Endpoint 4: List Pending Registrations (Admin Only)**
```
GET /api/admin/sellers/?status=PENDING
Filters: status, submitted_date_range, search
Response: List of pending registration requests
```

**Endpoint 5: Get Registration Details for Admin Review**
```
GET /api/admin/sellers/registrations/{id}/
Response: Full details including documents and history
```

**Endpoint 6: Approve Registration (Admin)**
```
POST /api/admin/sellers/registrations/{id}/approve/
Payload:
  {
    "approval_notes": string
  }
Response: Updated registration with APPROVED status
```

**Endpoint 7: Reject Registration (Admin)**
```
POST /api/admin/sellers/registrations/{id}/reject/
Payload:
  {
    "rejection_reason": string,
    "rejection_notes": string
  }
Response: Updated registration with REJECTED status
```

**Endpoint 8: Request More Information (Admin)**
```
POST /api/admin/sellers/registrations/{id}/request-info/
Payload:
  {
    "required_info": string,
    "deadline_days": int
  }
Response: Updated registration with REQUEST_MORE_INFO status
```

---

## 📱 Phase 2: Flutter Frontend - Buyer Side

### 2.1 New Flutter Screens & Models

**New Dart Files to Create:**
```
lib/features/profile/screens/
  └── seller_registration_screen.dart

lib/features/profile/widgets/
  ├── registration_form_section.dart
  ├── document_upload_widget.dart
  ├── registration_status_widget.dart
  └── farm_info_form_widget.dart

lib/features/profile/models/
  ├── seller_registration_model.dart
  ├── seller_document_model.dart
  └── registration_status_enum.dart

lib/features/profile/services/
  └── seller_registration_service.dart
```

### 2.2 Buyer Profile Screen Enhancement

**Changes to buyer_profile_screen.dart:**
1. Add "Become a Seller" section/button in profile
2. Check current user's registration status
3. Show status indicator (Not Applied / Pending / Approved / Rejected)
4. Navigation to registration form or status view

### 2.3 Seller Registration Form Screen

Features:
- Multi-step form or single comprehensive form
- Sections:
  1. Farm Information (name, location, size, products)
  2. Store Information (store name, description)
  3. Document Upload (TAX_ID, BUSINESS_PERMIT, ID_PROOF)
  4. Terms & Conditions acceptance
- File picker integration for documents
- Form validation (already has FormValidators utility)
- Loading states during submission
- Success/error handling

### 2.4 Registration Status Widget

- Display current registration status
- Show submission date and last update date
- Display rejection reason if rejected
- Show admin notes if available
- Button to resubmit if rejected
- Button to update information if info requested

---

## 🛠️ Phase 3: Flutter Frontend - Admin Side

### 3.1 Admin Panel Enhancement

**New Admin Screens:**
```
lib/features/admin_panel/screens/
  ├── seller_registrations_list_screen.dart
  ├── seller_registration_detail_screen.dart
  └── seller_registration_review_dialog.dart

lib/features/admin_panel/widgets/
  ├── registration_status_badge.dart
  ├── document_viewer_widget.dart
  ├── approval_form_widget.dart
  └── rejection_form_widget.dart

lib/features/admin_panel/models/
  ├── admin_registration_model.dart
  └── admin_registration_list_model.dart

lib/features/admin_panel/services/
  └── admin_registration_service.dart
```

### 3.2 Admin Registrations List Screen

Features:
- Tabbed view: All / Pending / Approved / Rejected / Info Requested
- Filterable list by:
  - Status
  - Submission date range
  - Search by buyer name/email
  - Sort by submission date
- List item shows:
  - Buyer name & email
  - Farm name
  - Status badge with color
  - Submission date
  - Quick action buttons (View, Approve, Reject)

### 3.3 Admin Registration Detail Screen

Features:
- Display full registration information
- Show submitted documents with preview
- Document verification checklist
- Approval history
- Action buttons:
  - Approve button → opens approval dialog
  - Reject button → opens rejection dialog
  - Request Info button → opens request info dialog
  - View Seller Profile button

### 3.4 Approval/Rejection Dialogs

**Approval Dialog:**
- Admin notes text field (optional)
- Confirmation checkbox
- Approve button
- Loading state handling

**Rejection Dialog:**
- Rejection reason dropdown/text (required)
- Additional notes field
- Confirmation
- Reject button

**Info Request Dialog:**
- List required information
- Deadline in days (dropdown)
- Additional instructions
- Send button

---

## 🔌 Phase 4: API Integration

### 4.1 Service Layer (Dart)

**SellerRegistrationService:**
```dart
class SellerRegistrationService {
  // Buyer-side methods
  Future<SellerRegistrationModel> submitRegistration(
    RegistrationFormData data
  )
  
  Future<SellerRegistrationModel> getMyRegistration()
  
  Future<void> resubmitRegistration(
    RegistrationFormData data
  )
  
  // Document upload
  Future<void> uploadDocument(File file, String documentType)
  
  // Admin-side methods
  Future<List<SellerRegistrationModel>> getPendingRegistrations()
  
  Future<SellerRegistrationModel> getRegistrationDetails(int registrationId)
  
  Future<SellerRegistrationModel> approveRegistration(
    int registrationId, 
    String notes
  )
  
  Future<SellerRegistrationModel> rejectRegistration(
    int registrationId, 
    String reason, 
    String notes
  )
  
  Future<SellerRegistrationModel> requestMoreInfo(
    int registrationId, 
    String requiredInfo, 
    int deadlineDays
  )
}
```

### 4.2 State Management (Provider/Riverpod)

**Providers to create:**
```dart
// Buyer side
final myRegistrationProvider = FutureProvider<SellerRegistrationModel>
final registrationFormProvider = StateNotifierProvider<RegistrationFormNotifier>
final registrationStatusProvider = StreamProvider<RegistrationStatus>

// Admin side  
final pendingRegistrationsProvider = FutureProvider<List<SellerRegistrationModel>>
final registrationDetailsProvider = FutureProvider.family<SellerRegistrationModel, int>
final registrationFiltersProvider = StateNotifierProvider<RegistrationFiltersNotifier>
final approvalActionProvider = FutureProvider<OperationResult>
```

---

## 🗄️ Phase 5: Database & Models Verification

### 5.1 Django Models (Already Exist - Verify Completeness)

**SellerRegistrationRequest** ✅
- ✅ seller (OneToOne User)
- ✅ status (PENDING, APPROVED, REJECTED, REQUEST_MORE_INFO)
- ✅ farm_name, farm_location, farm_size, products_grown
- ✅ store_name, store_description
- ✅ submitted_at, reviewed_at, approved_at, rejected_at
- ✅ rejection_reason
- ✅ approve() and reject() methods
- ✅ Custom manager with pending(), approved() querysets

**SellerDocumentVerification** ✅
- ✅ registration_request (FK to SellerRegistrationRequest)
- ✅ document_type (TAX_ID, BUSINESS_PERMIT, ID_PROOF)
- ✅ file_url
- ✅ status (PENDING, VERIFIED, REJECTED)
- ✅ verified_by (FK to AdminUser, nullable)
- ✅ verification_notes
- ✅ uploaded_at, verified_at, expires_at

**SellerApprovalHistory** ✅
- ✅ seller (FK to User)
- ✅ admin (FK to AdminUser)
- ✅ registration_request (FK)
- ✅ decision (APPROVED, REJECTED)
- ✅ decision_reason
- ✅ admin_notes
- ✅ created_at, effective_from

---

## 🔐 Phase 6: Security & Permissions

### 6.1 Permission Checks

**Buyer Operations:**
- Can only submit/view their own registration ✅
- Can only edit if status is PENDING or REQUEST_MORE_INFO
- Prevent role change until approved

**Admin Operations:**
- Only SELLER_MANAGER admin role can approve/reject
- Audit log all admin actions ✅
- Require admin authentication on all endpoints

### 6.2 Validations

- Document file size limits (max 5MB per document)
- Allowed file formats (PDF, JPG, PNG)
- Required documents checklist before approval
- All fields populated before submission

---

## 📊 Phase 7: Notifications & Audit

### 7.1 Notifications

**When Registration Submitted:**
- Notify admin: "New seller registration from [Buyer Name]"
- Show in admin dashboard

**When Registration Approved:**
- Notify buyer: "Your seller registration has been approved"
- Show registration success screen
- Update user role to SELLER

**When Registration Rejected:**
- Notify buyer: "Your registration was rejected - Reason: [reason]"
- Show rejection reason and admin notes
- Offer resubmit option

**When Info Requested:**
- Notify buyer: "Admin requested more information"
- Show deadline and requirements

### 7.2 Audit Logging

✅ Already implemented via AdminAuditLog model
- Log all approvals/rejections with admin info
- Log document verifications
- Track all state changes

---

## 🧪 Phase 8: Testing

### 8.1 Backend Tests (Django)

```python
# tests/test_seller_registration_api.py
- test_buyer_can_submit_registration
- test_buyer_can_view_own_registration
- test_buyer_cannot_view_others_registration
- test_admin_can_approve_registration
- test_admin_can_reject_registration
- test_admin_can_request_more_info
- test_document_upload_validation
- test_only_admin_can_approve
- test_approval_updates_user_role
```

### 8.2 Frontend Tests (Flutter)

```dart
// test/features/profile/seller_registration_test.dart
- test_seller_registration_form_renders
- test_seller_registration_form_validation
- test_seller_registration_submission
- test_registration_status_display
- test_reject_reason_display

// test/features/admin_panel/seller_registrations_test.dart
- test_admin_sees_pending_registrations
- test_admin_can_approve_registration
- test_admin_can_reject_registration
- test_admin_can_filter_registrations
- test_document_preview
```

---

## 📈 Implementation Timeline

| Phase | Component | Duration | Complexity |
|-------|-----------|----------|-----------|
| 1 | Django API Endpoints | 2-3 hours | Medium |
| 2 | Buyer Registration UI | 4-5 hours | High |
| 3 | Admin Review UI | 4-5 hours | High |
| 4 | API Integration (Services) | 2-3 hours | Medium |
| 5 | Testing Backend | 2 hours | Low |
| 6 | Testing Frontend | 3 hours | Medium |
| 7 | Integration Testing | 2 hours | Medium |
| **Total** | | **19-23 hours** | |

---

## ✅ Checklist

### Backend
- [ ] Verify all models are complete and correctly defined
- [ ] Create/update API serializers for registration endpoints
- [ ] Implement ViewSet endpoints for buyer and admin operations
- [ ] Add permission classes for authorization
- [ ] Add API documentation
- [ ] Implement error handling and validation
- [ ] Add rate limiting for file uploads
- [ ] Create Django tests

### Frontend - Buyer
- [ ] Create registration form screen
- [ ] Implement form validation
- [ ] Create document upload widget
- [ ] Create registration status display
- [ ] Integrate with buyer profile
- [ ] Implement API service
- [ ] Create state management providers
- [ ] Add loading/error states
- [ ] Create Flutter tests

### Frontend - Admin
- [ ] Create registrations list screen
- [ ] Create registration detail screen
- [ ] Create approval/rejection dialogs
- [ ] Create document preview widget
- [ ] Implement filters and search
- [ ] Integrate with admin panel navigation
- [ ] Implement API service
- [ ] Create state management
- [ ] Create Flutter tests

### Integration
- [ ] End-to-end testing
- [ ] Mobile responsiveness testing
- [ ] Performance testing
- [ ] Documentation

---

## 🎯 Success Criteria

1. **Buyer Experience:**
   - Buyer can fill registration form with all required fields ✓
   - Buyer can upload required documents ✓
   - Buyer can track registration status ✓
   - Buyer receives notifications on approval/rejection ✓

2. **Admin Experience:**
   - Admin can see list of pending registrations ✓
   - Admin can review registration details and documents ✓
   - Admin can approve/reject registrations ✓
   - Admin can request more information ✓
   - All actions are audited ✓

3. **System Requirements:**
   - User role changes to SELLER on approval ✓
   - Seller account is active and ready to use ✓
   - Rejected applicants can resubmit ✓
   - All data is validated and secure ✓

---

## 📝 Notes

- **Foundation:** SellerRegistrationRequest and related models are already implemented and tested
- **Leverage:** Use existing form validators, error handling patterns, and API service structure
- **Consistency:** Follow existing admin panel UI patterns and buyer profile structure
- **Integration:** Connect with existing notification system and audit logging

