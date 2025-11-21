# 🔧 Admin API Reference - Quick Reference

**Status**: Phase 1 Backend Infrastructure ✅ 100% Complete  
**API Base**: `/api/admin/`  
**Authentication**: Token-based (Django REST Framework)  
**Permission Model**: Role-based access control with 7 admin roles

---

## 📋 Endpoint Summary

### 1. Seller Management (`/api/admin/sellers/`)
```
GET    /api/admin/sellers/                     - List all sellers
GET    /api/admin/sellers/{id}/                - Get seller details
GET    /api/admin/sellers/pending-approvals/   - List pending approvals
GET    /api/admin/sellers/{id}/documents/      - Get seller documents
POST   /api/admin/sellers/{id}/approve/        - Approve seller
POST   /api/admin/sellers/{id}/reject/         - Reject seller
POST   /api/admin/sellers/{id}/suspend/        - Suspend seller
POST   /api/admin/sellers/{id}/reactivate/     - Reactivate seller
GET    /api/admin/sellers/{id}/approval-history/ - Approval audit trail
GET    /api/admin/sellers/{id}/violations/     - Price violations
```
**Permission**: `CanApproveSellers` (Seller Manager+)

### 2. Price Management (`/api/admin/prices/`)
```
GET    /api/admin/prices/ceilings/             - List price ceilings
POST   /api/admin/prices/ceilings/             - Create ceiling
PUT    /api/admin/prices/ceilings/{id}/        - Update ceiling
GET    /api/admin/prices/ceilings/{id}/history/ - Price history
GET    /api/admin/prices/non-compliant/        - Non-compliant listings
POST   /api/admin/prices/advisories/           - Create advisory
GET    /api/admin/prices/advisories/           - List advisories
DELETE /api/admin/prices/advisories/{id}/      - Delete advisory
POST   /api/admin/prices/flag-violation/       - Flag violation
```
**Permission**: `CanManagePrices` (Price Manager+)

### 3. OPAS Purchasing (`/api/admin/opas/`)
```
GET    /api/admin/opas/submissions/            - List submissions
GET    /api/admin/opas/submissions/{id}/       - Get submission details
POST   /api/admin/opas/submissions/{id}/approve/ - Approve submission
POST   /api/admin/opas/submissions/{id}/reject/ - Reject submission
GET    /api/admin/opas/purchase-orders/        - List purchase orders
GET    /api/admin/opas/purchase-history/       - Purchase history
GET    /api/admin/opas/inventory/              - List inventory
GET    /api/admin/opas/inventory/low-stock/    - Low stock alerts
GET    /api/admin/opas/inventory/expiring/     - Expiring alerts
POST   /api/admin/opas/inventory/adjust/       - Adjust inventory
```
**Permission**: `CanManageOPAS` (OPAS Manager+)

### 4. Marketplace Oversight (`/api/admin/marketplace/`)
```
GET    /api/admin/marketplace/listings/        - List listings
GET    /api/admin/marketplace/alerts/          - Get alerts
POST   /api/admin/marketplace/listings/{id}/flag/ - Flag listing
POST   /api/admin/marketplace/listings/{id}/remove/ - Remove listing
GET    /api/admin/marketplace/activity/        - Activity stats
```
**Permission**: `CanMonitorMarketplace` (Marketplace Monitor+)

### 5. Analytics & Reporting (`/api/admin/analytics/`)
```
GET    /api/admin/analytics/dashboard/         - Dashboard stats
GET    /api/admin/analytics/price-trends/      - Price trends
GET    /api/admin/analytics/demand-forecast/   - Demand forecast
GET    /api/admin/reports/sales-summary/       - Sales report
GET    /api/admin/reports/opas-purchases/      - OPAS report
GET    /api/admin/reports/seller-participation/ - Seller report
GET    /api/admin/reports/generate-pdf/        - Generate PDF
```
**Permission**: `CanViewAnalytics` (Analytics Manager+)

### 6. Admin Notifications (`/api/admin/notifications/`)
```
GET    /api/admin/notifications/               - List notifications
POST   /api/admin/notifications/{id}/acknowledge/ - Mark as read
POST   /api/admin/announcements/               - Create announcement
GET    /api/admin/announcements/               - List announcements
PUT    /api/admin/announcements/{id}/          - Edit announcement
DELETE /api/admin/announcements/{id}/          - Delete announcement
GET    /api/admin/announcements/broadcast-history/ - History
```
**Permission**: `CanManageNotifications` (Support Admin+)

---

## 🔐 Admin Roles & Permissions

| Role | Sellers | Prices | OPAS | Marketplace | Analytics | Reports | Notifications |
|------|---------|--------|------|-------------|-----------|---------|----------------|
| **Super Admin** | R+W | R+W | R+W | R+W | R+W | R+W | R+W |
| **Seller Manager** | R+W | R | R | R | R | R | R |
| **Price Manager** | R | R+W | R | R | R | R | R |
| **OPAS Manager** | R | R | R+W | R | R | R | R |
| **Marketplace Monitor** | R | R | R | R+W | R | R | R |
| **Analytics Manager** | R | R | R | R | R+W | R+W | R |
| **Support Admin** | R | R | R | R | R | R | R+W |

---

## 📊 Dashboard Endpoint Response

### GET `/api/admin/dashboard/stats/`

**Response Structure**:
```json
{
  "timestamp": "2025-11-18T12:34:56.789Z",
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
    "total_sales_today": 45000.00,
    "total_sales_month": 1250000.00,
    "avg_price_change": 0.5,
    "avg_transaction": 41666.67
  },
  "opas_metrics": {
    "pending_submissions": 8,
    "approved_this_month": 125,
    "total_inventory": 5000.0,
    "low_stock_count": 3,
    "expiring_count": 2,
    "total_inventory_value": 0
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

**Metrics Calculation**:
- **Seller Approval Rate**: (Active Sellers / Total Sellers) × 100
- **Compliance Rate**: (Compliant Listings / Active Listings) × 100
- **Health Score**: 100 - penalties for non-compliance, pending approvals, suspensions, low stock
- **Avg Transaction**: (Total Sales This Month) / 30 days

---

## 🔧 Common Request Patterns

### Approve a Seller
```bash
POST /api/admin/sellers/123/approve/
Content-Type: application/json
Authorization: Token YOUR_ADMIN_TOKEN

{
  "admin_notes": "Documentation verified",
  "documents_verified": true
}
```

### Update Price Ceiling
```bash
PUT /api/admin/prices/ceilings/456/
Content-Type: application/json
Authorization: Token YOUR_ADMIN_TOKEN

{
  "ceiling_price": 550.00,
  "change_reason": "Market Adjustment",
  "reason_notes": "Price increase due to increased demand",
  "effective_from": "2025-11-19T00:00:00Z"
}
```

### Approve OPAS Submission
```bash
POST /api/admin/opas/submissions/789/approve/
Content-Type: application/json
Authorization: Token YOUR_ADMIN_TOKEN

{
  "approved_quantity": 1000,
  "final_price": 450.00,
  "quality_grade": "GRADE_A",
  "delivery_terms": "Delivery in 3 days",
  "admin_notes": "Good quality produce"
}
```

### List Price Non-Compliance
```bash
GET /api/admin/prices/non-compliant/?limit=20
Authorization: Token YOUR_ADMIN_TOKEN
```

---

## 📦 Serializer Classes (31 Total)

**Seller Management**:
- SellerManagementSerializer
- SellerDetailsSerializer
- SellerDocumentVerificationSerializer
- SellerApprovalHistorySerializer
- SellerSuspensionSerializer

**Price Management**:
- PriceCeilingSerializer
- PriceCeilingCreateSerializer
- PriceHistorySerializer
- PriceAdvisorySerializer
- PriceAdvisoryCreateSerializer
- PriceNonComplianceSerializer

**OPAS Purchasing**:
- OPASPurchaseOrderSerializer
- OPASPurchaseOrderApprovalSerializer
- OPASPurchaseOrderRejectionSerializer
- OPASInventorySerializer
- OPASInventoryTransactionSerializer
- OPASInventoryAdjustmentSerializer
- OPASPurchaseHistorySerializer

**Marketplace & Analytics**:
- ProductListingSerializer
- ProductListingFlagSerializer
- MarketplaceAlertSerializer
- AdminAuditLogSerializer
- DashboardStatsSerializer
- PriceTrendSerializer
- SalesReportSerializer
- OPASReportSerializer
- SellerParticipationReportSerializer
- SystemNotificationSerializer
- AdminUserSerializer
- AnnouncementSerializer

---

## 🛡️ Permission Classes (16 Total)

**Base Permissions**:
- `IsAdmin` - Any active admin
- `IsSuperAdmin` - Super Admin only

**Role-Based Permissions**:
- `CanApproveSellers`
- `CanManagePrices`
- `CanManageOPAS`
- `CanMonitorMarketplace`
- `CanViewAnalytics`
- `CanManageNotifications`
- `CanViewAdminData` (read-only)
- `CanViewAuditLog`

**Combined Permissions**:
- `IsAdminAndCanApproveSellers`
- `IsAdminAndCanManagePrices`
- `IsAdminAndCanManageOPAS`
- `IsAdminAndCanMonitorMarketplace`
- `IsAdminAndCanViewAnalytics`
- `IsAdminAndCanManageNotifications`

---

## 📁 File Structure

```
apps/users/
├── admin_models.py          (16 models, 1635 lines)
├── admin_viewsets.py        (6 ViewSets, 50+ endpoints, 1461 lines)
├── admin_serializers.py     (31 serializers, 505 lines)
├── admin_permissions.py     (16 permission classes, 268 lines)
├── admin_urls.py            (SimpleRouter registration, 32 lines)
└── models.py                (updated with admin imports)

core/
└── urls.py                  (updated with admin_urls include)
```

---

## ✅ Clean Architecture Principles Applied

1. **Separation of Concerns**
   - Models (admin_models.py)
   - Business Logic (admin_viewsets.py)
   - Data Validation (admin_serializers.py)
   - Access Control (admin_permissions.py)
   - Routing (admin_urls.py)

2. **Reusability**
   - Shared serializer classes
   - Permission decorators reusable across endpoints
   - Common patterns in ViewSet implementations

3. **Maintainability**
   - Comprehensive docstrings on all classes/methods
   - Type hints in serializers
   - Clear naming conventions
   - Organized imports

4. **Scalability**
   - Permission hierarchy for role management
   - Query optimization (select_related, prefetch_related)
   - Bulk operation support
   - Audit logging for compliance

---

## 🚀 Next Steps

**Phase 2**: Frontend Implementation
- Admin Dashboard Screen
- Seller Management Screens
- Price Management Screens
- OPAS Purchasing Screens
- Marketplace Oversight Screens
- Analytics & Reporting Screens
- Notifications & Announcements Screens

---

## 📞 Support & Troubleshooting

**Common Issues**:

1. **401 Unauthorized**: Ensure token is included in `Authorization: Token YOUR_TOKEN` header
2. **403 Forbidden**: Check admin role permissions for the endpoint
3. **404 Not Found**: Verify resource ID exists in database
4. **400 Bad Request**: Check request body matches serializer schema

**Testing**:
```bash
# Test dashboard endpoint
curl -H "Authorization: Token YOUR_TOKEN" http://localhost:8000/api/admin/analytics/dashboard/

# Test seller list
curl -H "Authorization: Token YOUR_TOKEN" http://localhost:8000/api/admin/sellers/

# Test with pagination
curl -H "Authorization: Token YOUR_TOKEN" http://localhost:8000/api/admin/sellers/?limit=20&offset=0
```

---

**Created**: November 18, 2025  
**Last Updated**: Phase 1 Backend Infrastructure Complete  
**Reference**: `ADMIN_IMPLEMENTATION_PLAN.md`
