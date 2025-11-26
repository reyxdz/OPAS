# PART 2 QUICK REFERENCE - BUYER MARKETPLACE API

## API Endpoints

### 1. List Products (Browse Marketplace)
```
GET /api/products/
```

**Query Parameters:**
- `search=tomato` - Search by name/description
- `product_type=VEGETABLE` - Filter by category
- `min_price=40` - Minimum price
- `max_price=100` - Maximum price
- `ordering=price` - Sort by field (price, -price, -created_at, name)
- `page=1` - Pagination

**Example:**
```
GET /api/products/?product_type=VEGETABLE&min_price=40&max_price=100&search=tomato
```

**Response:**
```json
{
  "count": 50,
  "next": "?page=2",
  "previous": null,
  "results": [
    {
      "id": 123,
      "name": "Fresh Tomatoes",
      "product_type": "VEGETABLE",
      "price": "50.00",
      "seller_name": "Fresh Farm Co.",
      "primary_image": "/media/products/abc.jpg",
      "is_in_stock": true
    }
  ]
}
```

---

### 2. Get Product Details
```
GET /api/products/{id}/
```

**Response:**
```json
{
  "id": 123,
  "name": "Fresh Tomatoes",
  "description": "Fresh red tomatoes...",
  "product_type": "VEGETABLE",
  "price": "50.00",
  "ceiling_price": "75.00",
  "stock_level": 100,
  "seller_info": {
    "id": 5,
    "store_name": "Fresh Farm Co.",
    "seller_rating": 4.8,
    "is_verified": true
  },
  "images": [
    {
      "image_url": "/media/products/abc.jpg",
      "is_primary": true
    }
  ]
}
```

---

### 3. Get Seller Profile
```
GET /api/seller/{id}/
```

**Response:**
```json
{
  "id": 5,
  "full_name": "John Farmer",
  "store_name": "Fresh Farm Co.",
  "store_description": "Quality vegetables and fruits",
  "seller_rating": 4.8,
  "total_products": 25,
  "is_verified": true
}
```

---

### 4. Get Seller's Products
```
GET /api/seller/{id}/products/
```

**Same query parameters as /api/products/**

**Response:** Same as product list, filtered to seller's products

---

## Implementation Files

| File | Changes |
|------|---------|
| `seller_serializers.py` | +4 serializers (~250 lines) |
| `seller_views.py` | +2 viewsets (~230 lines) + imports |
| `urls.py` | +buyer router + routing |
| `core/urls.py` | +buyer endpoints path |
| `test_buyer_api.py` | NEW - 8 tests (100% pass) |

---

## Features

✅ Product browsing for all users (no auth required)  
✅ Filtering by category, price range  
✅ Full-text search  
✅ Sorting capabilities  
✅ Seller profile viewing  
✅ Stock availability display  
✅ Price compliance info  
✅ Query optimization  

---

## Serializers

| Serializer | Purpose | Fields |
|-----------|---------|--------|
| ProductImagePublicSerializer | Images in marketplace | id, image_url, is_primary |
| SellerPublicProfileSerializer | Seller info for buyers | id, name, store, rating, verified |
| ProductListBuyerSerializer | List view optimization | Minimal fields |
| ProductDetailBuyerSerializer | Complete product info | All fields + seller + images |

---

## ViewSets

| ViewSet | Base Class | Methods | Features |
|---------|-----------|---------|----------|
| MarketplaceViewSet | ReadOnlyModelViewSet | list(), retrieve() | Search, filters, ordering |
| SellerPublicViewSet | ReadOnlyModelViewSet | retrieve(), seller_products() | Profile + products |

---

## Testing

```bash
cd OPAS_Django
python test_buyer_api.py
```

**Results:** 8/8 tests passing ✅

---

## Django Checks

```bash
python manage.py check
```

**Result:** System check identified no issues (0 silenced) ✅

---

## Integration Notes

### For Flutter Frontend:
1. Use `/api/products/` for marketplace browse
2. Use `/api/products/{id}/` for product details
3. Use `/api/seller/{id}/` for seller profile
4. Query parameters for filtering/search/pagination

### Database Requirements:
- SellerProduct model (Part 1)
- ProductImage model (Part 1)
- User model with seller_status field

### Performance:
- Queries optimized with select_related, prefetch_related
- Pagination support for large datasets
- Search index recommended for production

---

## Status

**Completion:** 100%  
**Production Ready:** YES  
**Tests Passing:** 8/8 (100%)  
**Documentation:** Complete  

**Next:** Part 3 (Admin Marketplace Features)
