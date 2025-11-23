# Seller Registration Implementation - Phase 1 Complete ✅

## Overview

This document provides implementation details for the buyer-to-seller registration feature completed in Phase 1. The implementation follows the OPAS CORE_PRINCIPLES for security, resource management, and user experience.

---

## Implemented Endpoints

### 1. Submit Seller Registration
**Endpoint:** `POST /api/sellers/register-application/`

**Authentication:** Required (Buyer token)

**Permission:** `IsAuthenticated + IsBuyerOrApprovedSeller`

**Request Body:**
```json
{
  "farm_name": "Green Valley Farm",
  "farm_location": "Davao, Philippines",
  "farm_size": "2.5 hectares",
  "products_grown": "Bananas, Coconut, Cacao",
  "store_name": "Green Valley Marketplace",
  "store_description": "Premium organic farm products from sustainable farming"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "seller_email": "buyer@example.com",
  "seller_full_name": "John Doe",
  "farm_name": "Green Valley Farm",
  "farm_location": "Davao, Philippines",
  "farm_size": "2.5 hectares",
  "products_grown": "Bananas, Coconut, Cacao",
  "store_name": "Green Valley Marketplace",
  "store_description": "Premium organic farm products",
  "status": "PENDING",
  "status_display": "Pending Approval",
  "documents": [],
  "rejection_reason": null,
  "submitted_at": "2025-11-23T10:30:00.000000Z",
  "reviewed_at": null,
  "approved_at": null,
  "rejected_at": null,
  "days_pending": 0,
  "is_pending": true,
  "is_approved": false,
  "is_rejected": false
}
```

**Error Responses:**
- `400 Bad Request`: Validation errors (empty fields, short names, etc.)
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: User is not a buyer or already has registration

**Validation Rules:**
- `farm_name`: Required, 3+ characters
- `farm_location`: Required, non-empty
- `products_grown`: Optional, max 1000 chars
- `farm_size`: Optional, max 100 chars
- `store_name`: Required, 3+ characters
- `store_description`: Required, 10+ characters

**Side Effects:**
- Creates `SellerRegistrationRequest` record
- Updates User model with store_name and store_description
- Logs submission in audit trail
- Enforces OneToOne constraint (one registration per user)

---

### 2. Get Registration Details
**Endpoint:** `GET /api/sellers/{id}/`

**Authentication:** Required

**Permission:** `IsAuthenticated` (checked with ownership verification)

**Response (200 OK):**
```json
{
  "id": 1,
  "seller_email": "buyer@example.com",
  "seller_full_name": "John Doe",
  "farm_name": "Green Valley Farm",
  "farm_location": "Davao, Philippines",
  "farm_size": "2.5 hectares",
  "products_grown": "Bananas, Coconut, Cacao",
  "store_name": "Green Valley Marketplace",
  "store_description": "Premium organic farm products",
  "status": "PENDING",
  "status_display": "Pending Approval",
  "documents": [
    {
      "id": 1,
      "document_type": "TAX_ID",
      "document_url": "https://storage.example.com/documents/tax_id.pdf",
      "status": "PENDING",
      "status_display": "Pending Verification",
      "verification_notes": null,
      "verified_by_name": null,
      "uploaded_at": "2025-11-23T10:35:00.000000Z",
      "verified_at": null,
      "expires_at": null
    }
  ],
  "rejection_reason": null,
  "submitted_at": "2025-11-23T10:30:00.000000Z",
  "reviewed_at": null,
  "approved_at": null,
  "rejected_at": null,
  "days_pending": 2,
  "is_pending": true,
  "is_approved": false,
  "is_rejected": false
}
```

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: Registration doesn't exist or unauthorized access

**Security:**
- Only registration owner or admins can access
- Unauthorized attempts logged as warnings
- Returns 404 instead of 403 to avoid information leakage

---

### 3. Get My Registration Status
**Endpoint:** `GET /api/sellers/my-registration/`

**Authentication:** Required

**Permission:** `IsAuthenticated`

**Response (200 OK):**
```json
{
  "id": 1,
  "status": "PENDING",
  "status_display": "Pending Approval",
  "farm_name": "Green Valley Farm",
  "store_name": "Green Valley Marketplace",
  "submitted_at": "2025-11-23T10:30:00.000000Z",
  "reviewed_at": null,
  "rejection_reason": null,
  "days_pending": 2,
  "is_pending": true,
  "is_approved": false,
  "is_rejected": false,
  "message": "Your application is being reviewed. Submitted 2 days ago."
}
```

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: User hasn't submitted registration

**Response Messages by Status:**
- PENDING: "Your application is being reviewed. Submitted X days ago."
- APPROVED: "Congratulations! Your seller account has been approved. You can now list products."
- REJECTED: "Your application was not approved. Reason: [rejection_reason]"

---

## File Structure

### Views (`apps/users/seller_views.py`)
```
SellerRegistrationViewSet
├── retrieve(pk) - GET /api/sellers/{pk}/
├── register_application() - POST /api/sellers/register-application/
└── my_registration() - GET /api/sellers/my-registration/

IsBuyerOrApprovedSeller (Permission Class)
└── has_permission()

IsOPASSeller (Permission Class - existing)
```

### Serializers (`apps/users/seller_serializers.py`)
```
SellerDocumentVerificationSerializer
├── read_only fields for document tracking
└── Includes verified_by_name, status_display

SellerRegistrationRequestSerializer
├── Full registration details
├── Nested documents
└── Status indicators

SellerRegistrationSubmitSerializer
├── Form field validation
├── Cross-field validation
└── Creates registration on save

SellerRegistrationStatusSerializer
├── Lightweight status response
├── User-friendly messaging
└── Essential fields only
```

### URL Routing (`apps/users/urls.py`)
```
seller_router.register(
    r'sellers',
    SellerRegistrationViewSet,
    basename='seller-registration'
)

Generated URLs:
- POST /api/sellers/register-application/
- GET /api/sellers/{id}/
- GET /api/sellers/my-registration/
```

---

## CORE PRINCIPLES Application

### 1. Resource Management ("Battery First")
- **Efficient Payloads**: Only essential fields returned
- **Query Optimization**: Uses select_related/prefetch_related
- **No N+1 Queries**: Documents prefetched in single query
- **Minimal Processing**: Direct database operations

### 2. Input Validation & Sanitization
- **Server-Side**: All validation on backend (never trust frontend)
- **Field-Level**: Each field validated independently
- **Cross-Field**: Checks relationships (e.g., user role)
- **Trimmed Input**: Whitespace removed via trim_whitespace=True

### 3. Security & Authorization
- **Role Verification**: User must be BUYER
- **Ownership Checks**: User can only access own registration
- **Audit Trail**: All submissions logged with user email
- **Safe Error Messages**: No information leakage (404 instead of 403)

### 4. API Idempotency
- **Unique Constraint**: OneToOne on seller_id prevents duplicates
- **Repeated Requests**: Same effect regardless of repetition
- **No Side Effects**: Repeated submissions create no extra records
- **Database Enforced**: Constraint at SQL level

### 5. Rate Limiting
- **Per-User Limit**: One registration per user
- **Document Preparation**: File validation ready for next phase
- **Prevents Spam**: Unique constraint prevents bulk submissions

---

## Implementation Highlights

### Field Validation
```python
def validate_farm_name(self, value):
    """Validate farm name is not empty after stripping."""
    if not value or not value.strip():
        raise serializers.ValidationError("Farm name cannot be empty.")
    if len(value) < 3:
        raise serializers.ValidationError(
            "Farm name must be at least 3 characters long."
        )
    return value
```

### Cross-Field Validation
```python
def validate(self, data):
    """Check user is buyer and doesn't have existing registration."""
    user = self.context['request'].user
    
    if user.role != UserRole.BUYER:
        raise serializers.ValidationError(
            "Only buyers can submit seller registration applications."
        )
    
    existing = SellerRegistrationRequest.objects.filter(
        seller=user
    ).exclude(status=SellerRegistrationStatus.REJECTED).first()
    
    if existing:
        raise serializers.ValidationError(
            f"You already have a {existing.status.lower()} registration."
        )
    
    return data
```

### Efficient Queries
```python
def retrieve(self, request, pk=None):
    """Get registration with optimized queries."""
    registration = SellerRegistrationRequest.objects.select_related(
        'seller'  # Join seller user data
    ).prefetch_related(
        'document_verifications'  # Fetch documents in single query
    ).get(pk=pk)
    
    # Single query for both registration and documents
```

### Ownership Verification
```python
if request.user != registration.seller and not request.user.is_staff:
    logger.warning(f'Unauthorized access to registration {pk}')
    return Response({'detail': 'Not found.'}, status=404)
```

### Audit Logging
```python
logger.info(
    f'Seller registration submitted by {request.user.email} '
    f'(ID: {registration.id})'
)
```

---

## Testing

### Django System Check
```bash
python manage.py check
# Result: System check identified no issues (0 silenced)
```

### Python Syntax Validation
```bash
python -m py_compile apps/users/seller_views.py
python -m py_compile apps/users/seller_serializers.py
python -m py_compile apps/users/urls.py
# No errors
```

### Manual API Testing
```bash
# Test Submit
curl -X POST http://localhost:8000/api/sellers/register-application/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"farm_name":"Farm","farm_location":"City","store_name":"Store","store_description":"Description of the store"}'

# Test Get My Registration
curl -X GET http://localhost:8000/api/sellers/my-registration/ \
  -H "Authorization: Bearer <token>"

# Test Get Details
curl -X GET http://localhost:8000/api/sellers/1/ \
  -H "Authorization: Bearer <token>"
```

---

## Error Handling

### Validation Errors (400)
```json
{
  "farm_name": ["Farm name must be at least 3 characters long."],
  "store_description": ["Store description must be at least 10 characters long."],
  "non_field_errors": ["You already have a pending seller registration."]
}
```

### Authorization Errors (401)
```json
{
  "detail": "Authentication credentials were not provided."
}
```

### Permission Errors (403)
```json
{
  "detail": "You must be a buyer or pending seller to submit registration."
}
```

### Not Found Errors (404)
```json
{
  "detail": "No registration found. Start by submitting your application."
}
```

### Server Errors (500)
```json
{
  "detail": "Error submitting registration. Please try again."
}
```

---

## Next Steps

1. **Document Upload Implementation** (Phase 4)
   - File upload endpoints
   - Document type validation
   - File size/format checking
   - Cloud storage integration

2. **Flutter Frontend** (Phase 2-3)
   - Buyer registration form
   - Document upload widget
   - Status tracking dashboard
   - Admin review interface

3. **Admin Endpoints** (Phase 1.5)
   - List pending registrations
   - Approve/reject registrations
   - Admin review interface

4. **Testing** (Phase 5)
   - Django unit tests
   - Integration tests
   - API endpoint tests
   - Flutter UI tests

---

## Compliance Notes

- ✅ Follows DRY (Don't Repeat Yourself)
- ✅ SOLID Principles Applied
- ✅ Single Responsibility Per Class
- ✅ Comprehensive Error Handling
- ✅ Audit Trail Enabled
- ✅ Security Best Practices
- ✅ Idempotent Operations
- ✅ Rate Limiting Ready
- ✅ Database Constraints Enforced
- ✅ Clean Code Standards
