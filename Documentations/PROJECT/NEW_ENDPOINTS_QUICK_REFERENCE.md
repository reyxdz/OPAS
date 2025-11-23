# 🚀 NEW ENDPOINTS - QUICK API REFERENCE

**Date**: November 22, 2025  
**Status**: ✅ LIVE  

---

## 📍 ENDPOINT 1: Price History List

### Basic Info
```
GET /api/admin/prices/history/
Content-Type: application/json
Authorization: Bearer <token>
```

### Minimal Request
```bash
curl -H "Authorization: Bearer <token>" \
  "http://api.opas.local/api/admin/prices/history/"
```

### Response (Default)
```json
{
  "count": 150,
  "results": [
    {
      "id": 1,
      "product_name": "Rice",
      "old_price": 450.00,
      "new_price": 500.00,
      "change_reason": "MARKET_ADJUSTMENT",
      "reason_notes": "Supply shortage",
      "affected_sellers_count": 45,
      "non_compliant_count": 12,
      "admin_name": "John Admin",
      "changed_at": "2025-11-22T10:30:00Z"
    }
  ],
  "limit": 20,
  "offset": 0
}
```

### Filter Examples

**By Product**:
```
/api/admin/prices/history/?product_id=123
```

**By Date Range**:
```
/api/admin/prices/history/?start_date=2025-11-01&end_date=2025-11-30
```

**By Admin**:
```
/api/admin/prices/history/?admin_id=5
```

**Search**:
```
/api/admin/prices/history/?search=Rice
```

**Pagination**:
```
/api/admin/prices/history/?limit=50&offset=100
```

**Multiple Filters**:
```
/api/admin/prices/history/?product_id=123&start_date=2025-11-01&limit=50
```

### All Parameters

| Parameter | Type | Example | Notes |
|-----------|------|---------|-------|
| `product_id` | int | `123` | Filter by product |
| `admin_id` | int | `5` | Filter by admin |
| `change_reason` | string | `MARKET_ADJUSTMENT` | See enum below |
| `start_date` | ISO date | `2025-11-01T00:00:00Z` | Start of range |
| `end_date` | ISO date | `2025-11-30T23:59:59Z` | End of range |
| `search` | string | `Rice` | Search product/admin |
| `ordering` | string | `-changed_at` | Sort order |
| `limit` | int | `50` | Records per page |
| `offset` | int | `100` | Skip first N records |

### Change Reason Enum
- `MARKET_ADJUSTMENT`
- `REGULATION`
- `DEMAND`
- `OTHER`

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | History record ID |
| `product_name` | string | Product name |
| `old_price` | decimal | Previous price |
| `new_price` | decimal | New price |
| `change_reason` | string | Reason for change |
| `reason_notes` | string | Additional notes |
| `affected_sellers_count` | int | Sellers affected |
| `non_compliant_count` | int | Non-compliant sellers |
| `admin_name` | string | Admin who made change |
| `changed_at` | ISO datetime | When change was made |

---

## 📁 ENDPOINT 2: Price Export

### Basic Info
```
GET /api/admin/prices/export/
Content-Type: application/csv or application/json
Authorization: Bearer <token>
```

### CSV Export (Default)
```bash
curl -H "Authorization: Bearer <token>" \
  "http://api.opas.local/api/admin/prices/export/?format=csv" \
  -o prices.csv
```

**Response**: Downloaded file `price_export.csv`

### JSON Export
```bash
curl -H "Authorization: Bearer <token>" \
  "http://api.opas.local/api/admin/prices/export/?format=json" \
  -o prices.json
```

**Response**: Downloaded file `price_export.json`

### Export Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `format` | csv, json | csv | File format |
| `include_history` | true, false | false | Include history |
| `include_violations` | true, false | false | Include violations |
| `product_type` | string | - | Filter product type |

### Filter Examples

**CSV Format (Default)**:
```
/api/admin/prices/export/?format=csv
```

**JSON Format**:
```
/api/admin/prices/export/?format=json
```

**With History**:
```
/api/admin/prices/export/?format=json&include_history=true
```

**With Violations**:
```
/api/admin/prices/export/?format=csv&include_violations=true
```

**Specific Product Type**:
```
/api/admin/prices/export/?format=json&product_type=STAPLE
```

**Full Export**:
```
/api/admin/prices/export/?format=json&include_history=true&include_violations=true
```

### CSV Format Example

**Headers**:
```
Product ID,Product Name,Product Type,Ceiling Price,Previous Ceiling,Effective From,Effective Until,Set By,Created At,Updated At,[Price History Count],[Active Violations Count]
```

**Sample Data**:
```
123,Rice,STAPLE,500.00,450.00,2025-11-22T10:30:00,2025-12-22T10:30:00,Admin Name,2025-11-22T10:30:00,2025-11-22T10:30:00,5,2
```

### JSON Format Example

```json
{
  "export_date": "2025-11-22T10:30:00Z",
  "export_format": "json",
  "price_ceilings": [
    {
      "id": 123,
      "product_id": 456,
      "product_name": "Rice",
      "product_type": "STAPLE",
      "ceiling_price": 500.00,
      "previous_ceiling": 450.00,
      "effective_from": "2025-11-22T10:30:00Z",
      "effective_until": "2025-12-22T10:30:00Z",
      "set_by": "Admin Name",
      "created_at": "2025-11-22T10:30:00Z",
      "updated_at": "2025-11-22T10:30:00Z",
      "price_history": [
        {
          "id": 1,
          "old_price": 450.00,
          "new_price": 500.00,
          "change_reason": "MARKET_ADJUSTMENT",
          "reason_notes": "Supply shortage",
          "affected_sellers": 45,
          "non_compliant_sellers": 12,
          "admin": "John Admin",
          "changed_at": "2025-11-22T10:30:00Z"
        }
      ],
      "violations": [
        {
          "seller_id": 789,
          "seller_name": "Ahmed Store",
          "listed_price": 550.00,
          "ceiling_price": 500.00,
          "overage_percentage": 10.0,
          "status": "NEW",
          "detected_at": "2025-11-22T10:30:00Z"
        }
      ]
    }
  ]
}
```

---

## 🔐 Permission Requirements

Both endpoints require:
- ✅ `IsAuthenticated` - User must be logged in
- ✅ `IsAdmin` - User must be admin user
- ✅ `CanManagePrices` - User must have price management role

**Error Response** (403 Forbidden):
```json
{
  "detail": "You do not have permission to perform this action."
}
```

---

## 📊 Common Use Cases

### Use Case 1: Track Recent Price Changes
```bash
# Get last 10 changes
GET /api/admin/prices/history/?limit=10&ordering=-changed_at
```

### Use Case 2: Audit Trail for Product
```bash
# Get all changes for specific product
GET /api/admin/prices/history/?product_id=123&ordering=-changed_at
```

### Use Case 3: Compliance Report
```bash
# Export with violations for audit
GET /api/admin/prices/export/?format=json&include_violations=true
```

### Use Case 4: Monthly Archive
```bash
# Export month's data
GET /api/admin/prices/export/?format=csv&start_date=2025-11-01&end_date=2025-11-30
```

### Use Case 5: Search by Admin
```bash
# Find changes made by specific admin
GET /api/admin/prices/history/?search=AdminName&ordering=-changed_at
```

---

## ⚠️ Error Handling

### 400 Bad Request
**Invalid date format**:
```json
{
  "detail": "Invalid start_date format. Use ISO 8601 format."
}
```

### 403 Forbidden
**Insufficient permissions**:
```json
{
  "detail": "You do not have permission to perform this action."
}
```

### 404 Not Found
**Resource not found** (if filter returns empty):
```json
{
  "count": 0,
  "results": []
}
```

### 500 Internal Server Error
```json
{
  "detail": "Internal server error."
}
```

---

## 💡 Performance Tips

### For Large Exports
- Use `limit` parameter for pagination on history endpoint
- Filter by date range to reduce data size
- Use CSV format for spreadsheets (smaller file)
- Use JSON format for API integrations

### For Frequent Queries
- Cache the results if possible
- Use specific filters to reduce dataset
- Consider pagination for large results
- Monitor API response times

### Database Optimization
- Indexes exist on: product_id, changed_at
- Queries use select_related() for efficiency
- No N+1 query issues
- Pagination prevents memory issues

---

## 🔄 Integration Examples

### Frontend JavaScript
```javascript
// Fetch history
fetch('/api/admin/prices/history/?product_id=123', {
  headers: { 'Authorization': `Bearer ${token}` }
})
.then(r => r.json())
.then(data => console.log(data.results));

// Download CSV export
fetch('/api/admin/prices/export/?format=csv', {
  headers: { 'Authorization': `Bearer ${token}` }
})
.then(r => r.blob())
.then(blob => {
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'prices.csv';
  a.click();
});
```

### Python Requests
```python
import requests

# Fetch history
headers = {'Authorization': f'Bearer {token}'}
response = requests.get(
    'http://api.opas.local/api/admin/prices/history/?limit=50',
    headers=headers
)
data = response.json()

# Export as JSON
response = requests.get(
    'http://api.opas.local/api/admin/prices/export/?format=json',
    headers=headers
)
export_data = response.json()
```

### cURL Examples
```bash
# Get history with search
curl -H "Authorization: Bearer $TOKEN" \
  "http://api.opas.local/api/admin/prices/history/?search=Rice&limit=20"

# Export CSV
curl -H "Authorization: Bearer $TOKEN" \
  "http://api.opas.local/api/admin/prices/export/?format=csv" \
  -o prices.csv

# Export JSON with history
curl -H "Authorization: Bearer $TOKEN" \
  "http://api.opas.local/api/admin/prices/export/?format=json&include_history=true" \
  -o prices.json
```

---

## 📝 Notes

- All dates in ISO 8601 format (UTC)
- All prices in decimal format
- Pagination: Default limit 20, max 100 (configurable)
- Export formats: CSV with BOM for Excel compatibility
- File downloads: Automatic filename generation

---

## 🆘 Support

**Issues?**
1. Check error message for details
2. Verify permission roles
3. Validate query parameter format
4. Check date ranges (ISO 8601)
5. Review logs in Django admin

**Documentation**:
- Full API specs: `SECTION_1_3_MISSING_ENDPOINTS_IMPLEMENTED.md`
- Admin guide: `ADMIN_API_REFERENCE.md`
- Quick start: `QUICK_START_SECTION_1_3.md`

---

**Last Updated**: November 22, 2025  
**Status**: ✅ ACTIVE  
**Version**: 1.0
