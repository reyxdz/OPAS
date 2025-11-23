# 📚 OPAS Admin Panel - API Documentation

**Version**: 1.0  
**Last Updated**: November 23, 2025  
**Status**: Phase 3.5 - Phase A Documentation  

---

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Base URL & Versioning](#base-url--versioning)
4. [Response Format](#response-format)
5. [Error Handling](#error-handling)
6. [API Endpoints](#api-endpoints)
7. [Rate Limiting](#rate-limiting)
8. [Caching Strategy](#caching-strategy)

---

## Overview

The OPAS Admin Panel API provides comprehensive endpoints for managing:
- Seller registration and approval workflow
- Price ceiling management and compliance tracking
- OPAS bulk purchase orders and inventory
- Marketplace oversight and alerts
- Analytics and reporting
- Admin notifications and audit logs
- Dashboard statistics

### Base Features
- ✅ Role-based access control (6 admin roles)
- ✅ Comprehensive audit logging
- ✅ Rate limiting and caching
- ✅ Advanced filtering and search
- ✅ Soft delete support
- ✅ Immutable audit records

---

## Authentication

### Method: Bearer Token (JWT)

All admin endpoints require authentication via Bearer token in the `Authorization` header.

```bash
curl -H "Authorization: Bearer <your_token_here>" \
  https://api.opas.com/api/admin/sellers/
```

### Required Roles

Admin endpoints require one of these roles:
- `OPAS_ADMIN` - System administrator
- `SYSTEM_ADMIN` - Super administrator
- `SELLER_MANAGER` - Seller management specialist
- `PRICE_MANAGER` - Price regulation specialist
- `OPAS_MANAGER` - OPAS bulk purchase manager
- `ANALYTICS_MANAGER` - Analytics and reporting specialist

### Token Expiration

- Access tokens: 24 hours
- Refresh tokens: 7 days
- Expired tokens return `401 Unauthorized`

---

## Base URL & Versioning

### Production
```
https://api.opas.com/api/admin/v1/
```

### Development
```
http://localhost:8000/api/admin/v1/
```

### Versioning Strategy
- API versioned via URL path (`/api/admin/v1/`)
- No backward compatibility guaranteed between major versions
- Latest version always at `/api/admin/v1/`

---

## Response Format

### Success Response (200 OK)
```json
{
  "status": "success",
  "code": 200,
  "timestamp": "2025-11-23T14:35:42.123456Z",
  "data": {
    "id": 1,
    "name": "John Doe",
    ...
  },
  "meta": {
    "request_id": "req_123abc",
    "query_time_ms": 45
  }
}
```

### List Response (200 OK)
```json
{
  "status": "success",
  "code": 200,
  "timestamp": "2025-11-23T14:35:42.123456Z",
  "data": [
    { "id": 1, ... },
    { "id": 2, ... }
  ],
  "pagination": {
    "count": 250,
    "page": 1,
    "page_size": 20,
    "total_pages": 13
  },
  "meta": {
    "request_id": "req_123abc",
    "query_time_ms": 120
  }
}
```

### Error Response (4xx/5xx)
```json
{
  "status": "error",
  "code": 400,
  "timestamp": "2025-11-23T14:35:42.123456Z",
  "error": {
    "type": "ValidationError",
    "message": "Invalid seller status",
    "details": {
      "seller_status": ["Invalid choice: INVALID_STATUS"]
    }
  },
  "meta": {
    "request_id": "req_123abc"
  }
}
```

---

## Error Handling

### Standard HTTP Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | OK | Request successful |
| 201 | Created | Resource created |
| 204 | No Content | Deletion successful |
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Missing/invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Server Error | Internal error |

### Error Response Fields

```json
{
  "error": {
    "type": "string",           // Error category
    "message": "string",        // User-friendly message
    "details": "object",        // Field-specific errors
    "request_id": "string"      // For support tickets
  }
}
```

### Common Error Messages

```json
// 401 - Authentication required
{
  "type": "AuthenticationError",
  "message": "Authentication credentials were not provided"
}

// 403 - Permission denied
{
  "type": "PermissionError",
  "message": "You do not have permission to perform this action"
}

// 404 - Resource not found
{
  "type": "NotFoundError",
  "message": "Seller with ID 999 not found"
}

// 429 - Rate limit exceeded
{
  "type": "RateLimitError",
  "message": "Rate limit exceeded. Maximum 100 requests per hour allowed",
  "retry_after": 3600
}
```

---

## API Endpoints

### 1. SELLER MANAGEMENT

**Base Route**: `/api/admin/v1/sellers/`

#### 1.1 List Sellers
```
GET /api/admin/v1/sellers/
```

**Query Parameters**:
- `status`: Filter by status (PENDING, APPROVED, SUSPENDED, REJECTED)
- `search`: Search by name, email, store name
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 20, max: 100)
- `ordering`: Sort field (created_at, email, seller_status)

**Response**:
```json
{
  "count": 250,
  "results": [
    {
      "id": 1,
      "email": "seller@farm.com",
      "full_name": "John Farmer",
      "phone_number": "+1234567890",
      "store_name": "Green Acres Farm",
      "seller_status": "APPROVED",
      "seller_approval_date": "2025-11-20T10:00:00Z",
      "seller_documents_verified": true,
      "created_at": "2025-11-15T10:00:00Z"
    }
  ]
}
```

**Permissions**: `IsAdmin, CanApproveSellers`  
**Rate Limit**: 100 requests/hour  
**Cache**: 5 minutes  

---

#### 1.2 Get Seller Details
```
GET /api/admin/v1/sellers/{id}/
```

**Response**:
```json
{
  "id": 1,
  "email": "seller@farm.com",
  "full_name": "John Farmer",
  "phone_number": "+1234567890",
  "store_name": "Green Acres Farm",
  "seller_status": "APPROVED",
  "approval_history": [
    {
      "id": 1,
      "decision": "APPROVED",
      "admin_name": "Admin User",
      "admin_notes": "Documents verified",
      "created_at": "2025-11-20T10:00:00Z"
    }
  ],
  "documents": [
    {
      "id": 1,
      "document_type": "BUSINESS_REGISTRATION",
      "status": "VERIFIED",
      "uploaded_at": "2025-11-15T10:00:00Z"
    }
  ],
  "violations": 2,
  "active_listings": 45,
  "total_sales": 125000.00
}
```

**Permissions**: `IsAdmin, CanApproveSellers`  
**Cache**: 5 minutes  

---

#### 1.3 Get Pending Approvals
```
GET /api/admin/v1/sellers/pending-approvals/
```

**Response**: List of sellers with `status=PENDING`

**Permissions**: `IsAdmin, CanApproveSellers`  
**Cache**: 2 minutes  

---

#### 1.4 Approve Seller
```
POST /api/admin/v1/sellers/{id}/approve/
```

**Request Body**:
```json
{
  "admin_notes": "Documents verified and valid",
  "documents_verified": true
}
```

**Response**: Updated seller with `status=APPROVED`

**Permissions**: `IsAdmin, CanApproveSellers`  
**Audit Log**: ✅ Created

---

#### 1.5 Reject Seller
```
POST /api/admin/v1/sellers/{id}/reject/
```

**Request Body**:
```json
{
  "rejection_reason": "Tax ID document is invalid",
  "admin_notes": "Document appears to be expired"
}
```

**Response**: Updated seller with `status=REJECTED`

**Permissions**: `IsAdmin, CanApproveSellers`  
**Audit Log**: ✅ Created

---

#### 1.6 Suspend Seller
```
POST /api/admin/v1/sellers/{id}/suspend/
```

**Request Body**:
```json
{
  "reason": "Repeated price ceiling violations",
  "duration_days": 30,
  "admin_notes": "3 consecutive violations detected"
}
```

**Response**: Updated seller with `status=SUSPENDED`

**Permissions**: `IsAdmin, CanApproveSellers`  
**Audit Log**: ✅ Created

---

#### 1.7 Reactivate Seller
```
POST /api/admin/v1/sellers/{id}/reactivate/
```

**Request Body**:
```json
{
  "admin_notes": "Seller completed compliance training"
}
```

**Response**: Updated seller with `status=APPROVED`

**Permissions**: `IsAdmin, CanApproveSellers`  
**Audit Log**: ✅ Created

---

#### 1.8 Get Approval History
```
GET /api/admin/v1/sellers/{id}/approval-history/
```

**Response**: Array of approval decisions with timestamps

**Permissions**: `IsAdmin`  
**Cache**: 10 minutes  

---

#### 1.9 Get Seller Violations
```
GET /api/admin/v1/sellers/{id}/violations/
```

**Response**: Array of price violations

**Permissions**: `IsAdmin`  
**Cache**: 5 minutes  

---

### 2. PRICE MANAGEMENT

**Base Route**: `/api/admin/v1/prices/`

#### 2.1 List Price Ceilings
```
GET /api/admin/v1/prices/ceilings/
```

**Query Parameters**:
- `search`: Search by product name
- `product_type`: Filter by category
- `page`: Page number

**Response**:
```json
{
  "count": 150,
  "results": [
    {
      "id": 1,
      "product_id": 10,
      "product_name": "Tomatoes",
      "ceiling_price": 500.00,
      "current_market_price": 450.00,
      "effective_from": "2025-11-01T00:00:00Z",
      "effective_until": "2025-12-01T00:00:00Z",
      "set_by": "Price Manager",
      "set_at": "2025-11-01T10:00:00Z",
      "violation_count": 5
    }
  ]
}
```

**Permissions**: `IsAdmin, CanManagePrices`  
**Cache**: 5 minutes  

---

#### 2.2 Create Price Ceiling
```
POST /api/admin/v1/prices/ceilings/
```

**Request Body**:
```json
{
  "product_id": 10,
  "ceiling_price": 500.00,
  "effective_from": "2025-11-23T00:00:00Z",
  "effective_until": "2025-12-23T00:00:00Z",
  "reason": "Market Adjustment"
}
```

**Response**: Created ceiling (201)

**Permissions**: `IsAdmin, CanManagePrices`  
**Audit Log**: ✅ Created  
**Validation**:
- ✅ ceiling_price > 0
- ✅ effective_until >= effective_from
- ✅ product exists
- ✅ no existing ceiling for product

---

#### 2.3 Update Price Ceiling
```
PUT /api/admin/v1/prices/ceilings/{id}/
```

**Request Body**:
```json
{
  "ceiling_price": 550.00,
  "change_reason": "Forecast Update",
  "admin_notes": "Updated based on supply forecast"
}
```

**Response**: Updated ceiling

**Permissions**: `IsAdmin, CanManagePrices`  
**Audit Log**: ✅ Created  

---

#### 2.4 Delete Price Ceiling
```
DELETE /api/admin/v1/prices/ceilings/{id}/
```

**Permissions**: `IsAdmin, CanManagePrices`  
**Audit Log**: ✅ Created  

---

#### 2.5 List Price Advisories
```
GET /api/admin/v1/prices/advisories/
```

**Response**:
```json
{
  "count": 25,
  "results": [
    {
      "id": 1,
      "title": "Tomato Prices Trending Downward",
      "content": "Market analysis shows...",
      "type": "MARKET_ANALYSIS",
      "target_audience": "ALL_SELLERS",
      "posted_by": "Price Manager",
      "posted_at": "2025-11-22T10:00:00Z"
    }
  ]
}
```

**Permissions**: `IsAdmin, CanManagePrices`  
**Cache**: 5 minutes  

---

#### 2.6 Create Price Advisory
```
POST /api/admin/v1/prices/advisories/
```

**Request Body**:
```json
{
  "title": "Tomato Prices Trending Downward",
  "content": "Market analysis shows...",
  "type": "MARKET_ANALYSIS",
  "target_audience": "ALL_SELLERS"
}
```

**Response**: Created advisory (201)

**Permissions**: `IsAdmin, CanManagePrices`  
**Audit Log**: ✅ Created  

---

#### 2.7 List Price Violations
```
GET /api/admin/v1/prices/violations/
```

**Query Parameters**:
- `seller_id`: Filter by seller
- `product_id`: Filter by product
- `status`: ACTIVE, RESOLVED

**Response**:
```json
{
  "count": 120,
  "results": [
    {
      "id": 1,
      "seller_id": 5,
      "seller_name": "John Farmer",
      "product_id": 10,
      "product_name": "Tomatoes",
      "listed_price": 525.00,
      "ceiling_price": 500.00,
      "overage_percent": 5.0,
      "detected_at": "2025-11-23T10:00:00Z",
      "status": "ACTIVE",
      "resolved_at": null,
      "resolution_notes": null
    }
  ]
}
```

**Permissions**: `IsAdmin, CanManagePrices`  
**Cache**: 2 minutes  

---

#### 2.8 Resolve Price Violation
```
POST /api/admin/v1/prices/violations/{id}/resolve/
```

**Request Body**:
```json
{
  "resolution_notes": "Seller corrected price to 490.00",
  "admin_notes": "Violation resolved through seller action"
}
```

**Response**: Updated violation

**Permissions**: `IsAdmin, CanManagePrices`  
**Audit Log**: ✅ Created  

---

### 3. OPAS BULK PURCHASE

**Base Route**: `/api/admin/v1/opas/`

#### 3.1 List OPAS Submissions
```
GET /api/admin/v1/opas/submissions/
```

**Query Parameters**:
- `status`: PENDING, APPROVED, REJECTED, PARTIALLY_APPROVED
- `page`: Page number

**Response**:
```json
{
  "count": 45,
  "results": [
    {
      "id": 1,
      "seller_name": "John Farmer",
      "submission_date": "2025-11-20T10:00:00Z",
      "status": "PENDING",
      "items_count": 5,
      "total_quantity": 1000,
      "estimated_cost": 50000.00,
      "reviewed_by": null,
      "reviewed_at": null
    }
  ]
}
```

**Permissions**: `IsAdmin, CanManageOPAS`  
**Cache**: 3 minutes  

---

#### 3.2 Get Submission Details
```
GET /api/admin/v1/opas/submissions/{id}/
```

**Response**: Detailed submission with items and requirements

**Permissions**: `IsAdmin, CanManageOPAS`  

---

#### 3.3 Approve OPAS Submission
```
POST /api/admin/v1/opas/submissions/{id}/approve/
```

**Request Body**:
```json
{
  "approval_notes": "All requirements met",
  "admin_notes": "Approved by Price Manager"
}
```

**Response**: Updated submission with APPROVED status

**Permissions**: `IsAdmin, CanManageOPAS`  
**Audit Log**: ✅ Created  

---

#### 3.4 Reject OPAS Submission
```
POST /api/admin/v1/opas/submissions/{id}/reject/
```

**Request Body**:
```json
{
  "rejection_reason": "Insufficient supply documentation",
  "admin_notes": "Requested additional proof of supply"
}
```

**Response**: Updated submission with REJECTED status

**Permissions**: `IsAdmin, CanManageOPAS`  
**Audit Log**: ✅ Created  

---

#### 3.5 List Inventory
```
GET /api/admin/v1/opas/inventory/
```

**Query Parameters**:
- `status`: LOW_STOCK, NORMAL, EXPIRING_SOON
- `location`: Storage location filter
- `page`: Page number

**Response**:
```json
{
  "count": 250,
  "results": [
    {
      "id": 1,
      "product_name": "Tomatoes",
      "quantity_on_hand": 500,
      "low_stock_threshold": 100,
      "in_date": "2025-11-01T00:00:00Z",
      "expiry_date": "2025-12-31T00:00:00Z",
      "days_until_expiry": 38,
      "storage_location": "Warehouse A",
      "status": "NORMAL"
    }
  ]
}
```

**Permissions**: `IsAdmin, CanManageOPAS`  
**Cache**: 5 minutes  

---

#### 3.6 Stock In (Receive Inventory)
```
POST /api/admin/v1/opas/inventory/stock-in/
```

**Request Body**:
```json
{
  "product_id": 10,
  "quantity": 500,
  "in_date": "2025-11-23T10:00:00Z",
  "expiry_date": "2025-12-23T00:00:00Z",
  "storage_location": "Warehouse A",
  "receiving_notes": "Received from supplier XYZ"
}
```

**Response**: Created inventory record (201)

**Permissions**: `IsAdmin, CanManageOPAS`  
**Audit Log**: ✅ Created  

---

#### 3.7 Stock Out (Consume Inventory)
```
POST /api/admin/v1/opas/inventory/stock-out/
```

**Request Body**:
```json
{
  "inventory_id": 1,
  "quantity": 100,
  "reason": "CONSUMPTION",
  "consumption_notes": "Used for market distribution"
}
```

**Response**: Created transaction record (201)

**Permissions**: `IsAdmin, CanManageOPAS`  
**Audit Log**: ✅ Created  

---

### 4. MARKETPLACE OVERSIGHT

**Base Route**: `/api/admin/v1/marketplace/`

#### 4.1 List Alerts
```
GET /api/admin/v1/marketplace/alerts/
```

**Query Parameters**:
- `status`: OPEN, RESOLVED
- `severity`: INFO, WARNING, CRITICAL
- `category`: PRICE_VIOLATION, SELLER_ISSUE, INVENTORY_ALERT
- `page`: Page number

**Response**:
```json
{
  "count": 45,
  "results": [
    {
      "id": 1,
      "category": "PRICE_VIOLATION",
      "severity": "WARNING",
      "description": "Seller has 3 price violations",
      "affected_seller": "John Farmer",
      "status": "OPEN",
      "created_at": "2025-11-23T10:00:00Z",
      "resolved_at": null
    }
  ]
}
```

**Permissions**: `IsAdmin`  
**Cache**: 2 minutes  

---

#### 4.2 Create Alert
```
POST /api/admin/v1/marketplace/alerts/
```

**Request Body**:
```json
{
  "category": "PRICE_VIOLATION",
  "severity": "WARNING",
  "description": "Seller has exceeded price ceiling",
  "affected_seller_id": 5,
  "admin_notes": "Monitor this seller for compliance"
}
```

**Response**: Created alert (201)

**Permissions**: `IsAdmin`  
**Audit Log**: ✅ Created  

---

#### 4.3 Resolve Alert
```
POST /api/admin/v1/marketplace/alerts/{id}/resolve/
```

**Request Body**:
```json
{
  "resolution_notes": "Issue was corrected by seller"
}
```

**Response**: Updated alert with RESOLVED status

**Permissions**: `IsAdmin`  
**Audit Log**: ✅ Created  

---

### 5. ANALYTICS & REPORTING

**Base Route**: `/api/admin/v1/analytics/`

#### 5.1 Get Dashboard Statistics
```
GET /api/admin/v1/analytics/dashboard/stats/
```

**Response**:
```json
{
  "timestamp": "2025-11-23T14:35:42.123456Z",
  "seller_metrics": {
    "total_sellers": 250,
    "pending_approvals": 12,
    "active_sellers": 238,
    "suspended_sellers": 2,
    "new_this_month": 15,
    "approval_rate": 95.2
  },
  "market_metrics": {
    "active_listings": 1240,
    "total_sales_today": 45000,
    "total_sales_month": 1250000,
    "avg_price_change": 0.5,
    "avg_transaction": 41666.67
  },
  "opas_metrics": {
    "pending_submissions": 8,
    "approved_this_month": 125,
    "total_inventory": 5000,
    "low_stock_count": 3,
    "expiring_count": 2,
    "total_inventory_value": 250000.00
  },
  "price_compliance": {
    "compliant_listings": 1200,
    "non_compliant": 40,
    "compliance_rate": 96.77
  },
  "alerts": {
    "price_violations": 3,
    "seller_issues": 2,
    "inventory_alerts": 5,
    "total_open_alerts": 10
  },
  "marketplace_health_score": 92
}
```

**Permissions**: `IsAdmin, CanViewAnalytics`  
**Cache**: 1 minute  
**Performance**: < 2 seconds  

---

#### 5.2 Get Trend Analysis
```
GET /api/admin/v1/analytics/trends/
```

**Query Parameters**:
- `metric`: sales, sellers, violations, inventory
- `period`: daily, weekly, monthly (default: daily)
- `days`: 7, 14, 30 (default: 7)

**Response**:
```json
{
  "metric": "sales",
  "period": "daily",
  "data": [
    {
      "date": "2025-11-23",
      "value": 50000,
      "change": 10.5,
      "change_percent": 2.5
    },
    {
      "date": "2025-11-22",
      "value": 45500,
      "change": -1000,
      "change_percent": -2.2
    }
  ]
}
```

**Permissions**: `IsAdmin, CanViewAnalytics`  
**Cache**: 5 minutes  

---

#### 5.3 Export Report
```
GET /api/admin/v1/analytics/export/
```

**Query Parameters**:
- `format`: JSON, CSV, PDF (default: JSON)
- `report_type`: sellers, violations, inventory, audit_log
- `date_from`: Start date
- `date_to`: End date

**Response**: File download or JSON data

**Permissions**: `IsAdmin, CanExportData`  

---

### 6. AUDIT LOGS

**Base Route**: `/api/admin/v1/audit-logs/`

#### 6.1 List Audit Logs
```
GET /api/admin/v1/audit-logs/
```

**Query Parameters**:
- `admin_id`: Filter by admin user
- `action_type`: Type of action
- `date_from`: Start date
- `date_to`: End date
- `page`: Page number

**Response**:
```json
{
  "count": 5000,
  "results": [
    {
      "id": 1,
      "admin": "Admin User",
      "action_type": "SELLER_APPROVED",
      "action_category": "SELLER_APPROVAL",
      "description": "Approved seller registration",
      "affected_seller": "John Farmer",
      "timestamp": "2025-11-23T10:00:00Z",
      "new_value": "APPROVED",
      "old_value": "PENDING"
    }
  ]
}
```

**Permissions**: `IsAdmin, CanAccessAuditLogs`  
**Cache**: Not cached (immutable data)  

---

#### 6.2 Get Audit Log Details
```
GET /api/admin/v1/audit-logs/{id}/
```

**Response**: Detailed audit entry with all fields

**Permissions**: `IsAdmin, CanAccessAuditLogs`  

---

### 7. ADMIN NOTIFICATIONS

**Base Route**: `/api/admin/v1/notifications/`

#### 7.1 List Notifications
```
GET /api/admin/v1/notifications/
```

**Query Parameters**:
- `status`: READ, UNREAD
- `type`: SELLER_APPROVAL, PRICE_ALERT, etc.
- `page`: Page number

**Response**:
```json
{
  "count": 25,
  "unread_count": 5,
  "results": [
    {
      "id": 1,
      "title": "Seller Registration Pending Review",
      "message": "New seller 'Green Acres Farm' pending approval",
      "type": "SELLER_APPROVAL",
      "is_read": false,
      "created_at": "2025-11-23T10:00:00Z"
    }
  ]
}
```

**Permissions**: `IsAdmin`  

---

#### 7.2 Mark as Read
```
POST /api/admin/v1/notifications/{id}/mark-read/
```

**Response**: Updated notification

**Permissions**: `IsAdmin`  

---

#### 7.3 Create Broadcast Notification
```
POST /api/admin/v1/notifications/broadcast/
```

**Request Body**:
```json
{
  "title": "System Maintenance Scheduled",
  "message": "System will be down for 2 hours tonight",
  "type": "SYSTEM_ANNOUNCEMENT",
  "target_roles": ["OPAS_ADMIN", "SELLER_MANAGER"]
}
```

**Response**: Created notification (201)

**Permissions**: `IsAdmin, IsSuperAdmin`  
**Audit Log**: ✅ Created  

---

## Rate Limiting

### Default Limits

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Read (GET) | 100 | 1 hour |
| Write (POST) | 50 | 1 hour |
| Delete | 20 | 1 hour |
| Analytics | 30 | 1 hour |

### Rate Limit Headers

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1700000000
```

### Exceeding Limits

Returns `429 Too Many Requests`:
```json
{
  "type": "RateLimitError",
  "message": "Rate limit exceeded",
  "retry_after": 3600
}
```

---

## Caching Strategy

### Cache Durations

| Data Type | Duration | Strategy |
|-----------|----------|----------|
| Seller list | 5 min | Time-based |
| Price ceilings | 5 min | Time-based |
| Inventory | 5 min | Time-based |
| Dashboard stats | 1 min | Time-based |
| Alerts | 2 min | Time-based |
| Audit logs | No cache | Immutable |

### Cache Invalidation

Caches automatically invalidate when:
- Data is created/updated/deleted
- Admin action is performed
- Permission changes occur

### Manual Cache Invalidation

```bash
POST /api/admin/v1/cache/invalidate/
Content-Type: application/json

{
  "cache_keys": ["seller_list", "dashboard_stats"],
  "pattern": "seller_*"  // Or use wildcard pattern
}
```

---

## Code Examples

### Python (requests)

```python
import requests

# Setup
BASE_URL = "http://localhost:8000/api/admin/v1"
headers = {
    "Authorization": f"Bearer {your_token}",
    "Content-Type": "application/json"
}

# List sellers
response = requests.get(f"{BASE_URL}/sellers/", headers=headers)
sellers = response.json()

# Approve seller
data = {
    "admin_notes": "Documents verified",
    "documents_verified": True
}
response = requests.post(
    f"{BASE_URL}/sellers/1/approve/",
    json=data,
    headers=headers
)
```

### cURL

```bash
# List sellers
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/admin/v1/sellers/?status=PENDING

# Approve seller
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"admin_notes": "Approved"}' \
  http://localhost:8000/api/admin/v1/sellers/1/approve/
```

### JavaScript (fetch)

```javascript
const token = localStorage.getItem('admin_token');

// List sellers
const response = await fetch('/api/admin/v1/sellers/', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

const data = await response.json();
```

---

## Webhook Events

### Available Events

Admin actions trigger webhook events:
- `seller.approved`
- `seller.rejected`
- `seller.suspended`
- `price_ceiling.created`
- `price_ceiling.updated`
- `violation.created`
- `violation.resolved`
- `alert.created`
- `alert.resolved`
- `opas_submission.approved`

### Example Webhook Payload

```json
{
  "event": "seller.approved",
  "timestamp": "2025-11-23T14:35:42.123456Z",
  "data": {
    "seller_id": 1,
    "seller_name": "John Farmer",
    "approved_by": "Admin User",
    "approval_notes": "Documents verified"
  }
}
```

---

## Support & Issues

### Getting Help

1. **Documentation**: Review this API documentation
2. **Code Examples**: Check examples in repository
3. **Support Portal**: Submit ticket at support.opas.com
4. **Slack Channel**: #admin-api-support

### Reporting Bugs

Include:
- Request ID (from response meta.request_id)
- Endpoint and method
- Reproduction steps
- Expected vs actual behavior
- Authentication method

---

**Last Updated**: November 23, 2025  
**API Version**: 1.0  
**Status**: Phase 3.5 - Phase A Documentation
