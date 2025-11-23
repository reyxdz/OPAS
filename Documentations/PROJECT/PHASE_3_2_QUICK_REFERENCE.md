# Phase 3.2: Quick Reference Guide

## Endpoint Access

**Route**: `/api/admin/dashboard/stats/`  
**Method**: `GET`  
**Authentication**: Required (Bearer token)  
**Authorization**: Admin role + CanViewAnalytics permission  

## Response Structure

```
{
  "timestamp": ISO 8601 timestamp,
  "seller_metrics": { ... },
  "market_metrics": { ... },
  "opas_metrics": { ... },
  "price_compliance": { ... },
  "alerts": { ... },
  "marketplace_health_score": 0-100
}
```

## Seller Metrics
- `total_sellers`: Total count
- `pending_approvals`: Waiting for approval
- `active_sellers`: Approved sellers
- `suspended_sellers`: Temporarily suspended
- `new_this_month`: New registrations
- `approval_rate`: Approval percentage

## Market Metrics
- `active_listings`: Active products
- `total_sales_today`: Today's revenue
- `total_sales_month`: Monthly revenue
- `avg_price_change`: Price movement %
- `avg_transaction`: Average order value

## OPAS Metrics
- `pending_submissions`: Waiting for review
- `approved_this_month`: Approved this month
- `total_inventory`: Total units in stock
- `low_stock_count`: Below threshold
- `expiring_count`: Expiring soon
- `total_inventory_value`: Inventory value

## Price Compliance
- `compliant_listings`: Within price ceiling
- `non_compliant`: Above ceiling
- `compliance_rate`: Compliance percentage

## Alerts
- `price_violations`: Price breaches
- `seller_issues`: Seller problems
- `inventory_alerts`: Stock issues
- `total_open_alerts`: Total open

## Health Score Calculation
```
Score = (compliance_rate * 0.4) +
        (seller_rating * 0.3) +
        (order_fulfillment * 0.3)

Range: 0-100
```

## Example cURL
```bash
curl -X GET "http://localhost:8000/api/admin/dashboard/stats/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Example Response
```json
{
  "timestamp": "2025-11-23T10:54:48.476890Z",
  "seller_metrics": {
    "total_sellers": 102,
    "pending_approvals": 1,
    "active_sellers": 101,
    "suspended_sellers": 0,
    "new_this_month": 102,
    "approval_rate": 100.0
  },
  "market_metrics": {
    "active_listings": 1500,
    "total_sales_today": 1000000.0,
    "total_sales_month": 1000000.0,
    "avg_price_change": 0.0,
    "avg_transaction": 1000.0
  },
  "opas_metrics": {
    "pending_submissions": 0,
    "approved_this_month": 0,
    "total_inventory": 600,
    "low_stock_count": 0,
    "expiring_count": 0,
    "total_inventory_value": 67110.0
  },
  "price_compliance": {
    "compliant_listings": 1500,
    "non_compliant": 0,
    "compliance_rate": 100.0
  },
  "alerts": {
    "price_violations": 15,
    "seller_issues": 0,
    "inventory_alerts": 0,
    "total_open_alerts": 15
  },
  "marketplace_health_score": 83
}
```

## Error Responses

**401 Unauthorized**
```json
{"detail": "Authentication credentials were not provided."}
```

**403 Forbidden**
```json
{"detail": "You do not have permission to perform this action."}
```

**500 Internal Server Error**
```json
{"error": "Failed to retrieve dashboard statistics: [error details]"}
```

## Performance
- **Response Time**: < 2 seconds
- **Database Queries**: ~14-15 optimized
- **Cache**: 60 seconds (recommended for production)

## Testing
```bash
# Run manual test
python test_dashboard_simple.py

# Expected output: ✓ Phase 3.2 Implementation SUCCESSFUL!
```

## Related Documentation
- Main Implementation: `IMPLEMENTATION_ROADMAP.md` (Section 3.2)
- Completion Report: `PHASE_3_2_COMPLETION_REPORT.md`
- Admin Models: `apps/users/admin_models.py`
- Serializers: `apps/users/admin_serializers.py`
- ViewSet: `apps/users/admin_viewsets.py`
