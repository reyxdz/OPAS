# ✅ Developer Checklist: SellerProduct & ProductImage Models

## Pre-Development Setup

- [ ] Clone repository
- [ ] Install dependencies: `pip install -r requirements.txt`
- [ ] Configure Django settings
- [ ] Apply migrations: `python manage.py migrate`
- [ ] Create superuser: `python manage.py createsuperuser`
- [ ] Verify no issues: `python manage.py check`

---

## Model Implementation Verification

### SellerProduct Model
- [x] Model created in `seller_models.py`
- [x] All required fields present
- [x] Custom QuerySet implemented
- [x] Custom Manager implemented
- [x] Helper properties defined
- [x] Soft delete methods added
- [x] Database indexes created
- [x] Migration created (0006_seller_models)
- [x] Admin class created
- [x] Serializers created (3 types)
- [x] ViewSet created with endpoints
- [x] URL routing configured

### ProductImage Model
- [x] Model created in `seller_models.py`
- [x] All required fields present
- [x] Foreign key to SellerProduct
- [x] Database indexes created
- [x] Migration created (0007_product_image)
- [x] Admin class created ✅ NEW
- [x] Serializer created
- [x] URL routing configured

---

## Database Verification

```bash
# Check for errors
python manage.py check

# Show migration status
python manage.py showmigrations users | grep -E "0006|0007"

# Apply migrations if needed
# New migration added for seller product lifecycle: `apps/users/migrations/0023_add_previous_status_field.py`
python manage.py migrate

# Expected output:
# [X] 0006_seller_models
# [X] 0007_product_image
```

---

## API Endpoint Testing

### 1. List Products
```bash
GET /api/seller/products/
Authorization: Bearer {seller_token}
```
Expected: 200 OK with product list

### 2. Create Product
```bash
POST /api/seller/products/
Authorization: Bearer {seller_token}
Content-Type: application/json

{
  "name": "Tomato",
  "product_type": "VEGETABLE",
  "description": "Fresh tomatoes",
  "price": "50.00",
  "ceiling_price": "75.00",
  "stock_level": 100,
  "unit": "kg",
  "quality_grade": "PREMIUM"
}
```
Expected: 201 Created

### 3. Get Product Details
```bash
GET /api/seller/products/{id}/
Authorization: Bearer {seller_token}
```
Expected: 200 OK with full product details

### 4. Update Product
```bash
PUT /api/seller/products/{id}/
Authorization: Bearer {seller_token}
Content-Type: application/json

{
  "price": "55.00",
  "stock_level": 80
}
```
Expected: 200 OK

### 5. Delete Product
```bash
DELETE /api/seller/products/{id}/
Authorization: Bearer {seller_token}
```
Expected: 204 No Content

### 6. List Active Products
```bash
GET /api/seller/products/active/
Authorization: Bearer {seller_token}
```
Expected: 200 OK with active products only

### 7. Check Ceiling Price
```bash
POST /api/seller/products/check_ceiling_price/
Authorization: Bearer {seller_token}
Content-Type: application/json

{
  "product_id": 123
}
```
Expected: 200 OK with price compliance info

### 8. Check Stock Availability
```bash
POST /api/seller/products/check_stock_availability/
Authorization: Bearer {seller_token}
Content-Type: application/json

{
  "product_id": 123,
  "quantity_required": 50
}
```
Expected: 200 OK with stock info

---

## Admin Interface Testing

### Access Django Admin
- [ ] Navigate to `http://localhost:8000/admin/`
- [ ] Login with superuser credentials
- [ ] Verify "Seller Products" listed
- [ ] Verify "Product Images" listed ✅ NEW

### Test SellerProduct Admin
- [ ] Click "Seller Products"
- [ ] Verify list displays: name, seller, status, price, ceiling_price, stock_level, created_at
- [ ] Click a product to edit
- [ ] Verify fieldsets are organized correctly
- [ ] Test search functionality (name, email, product_type)
- [ ] Test filters (status, product_type, quality_grade, created_at)

### Test ProductImage Admin ✅
- [ ] Click "Product Images"
- [ ] Verify list displays: product, is_primary, order, uploaded_at
- [ ] Click an image to edit
- [ ] Verify fieldsets are organized correctly
- [ ] Test search functionality (product name, alt_text)
- [ ] Test filters (is_primary, uploaded_at)

---

## Performance Testing

### Query Optimization Verification

```python
# Test: Avoid N+1 queries
from django.test.utils import CaptureQueriesContext
from django.db import connection

with CaptureQueriesContext(connection) as queries:
    products = SellerProduct.objects.select_related('seller').prefetch_related('product_images')
    for p in products:
        print(p.seller.email)
        for img in p.product_images.all():
            print(img.image.url)

# Expected: ~3 queries (1 for products, 1 for sellers, 1 for images)
# Not good: 1 + N_products + sum(N_images) queries
print(f"Queries executed: {len(queries)}")
```

### Index Verification

```bash
# Get indexes on SellerProduct table
python manage.py dbshell
SELECT * FROM sqlite_master WHERE type='index' AND tbl_name='seller_products';

# Expected indexes:
# - seller_id + status
# - product_type
# - expiry_date
# - is_deleted
# - seller_id + is_deleted
```

---

## Security Testing

### Permission Verification

```bash
# Test: Unauthorized access (no token)
curl -X GET http://localhost:8000/api/seller/products/

# Expected: 401 Unauthorized

# Test: Non-seller user
# Login as buyer, try to access seller endpoints
curl -H "Authorization: Bearer {buyer_token}" \
  http://localhost:8000/api/seller/products/

# Expected: 403 Forbidden

# Test: Seller accessing own products only
# Create products under seller1
# Login as seller2, verify can't see seller1's products
```

### Data Validation Testing

```bash
# Test: Invalid price (negative)
POST /api/seller/products/
{
  "price": "-50.00"  # Should be rejected
}

# Test: Stock below zero
POST /api/seller/products/
{
  "stock_level": -10  # Should be rejected
}

# Test: Price exceeds ceiling
POST /api/seller/products/
{
  "price": "100.00",
  "ceiling_price": "75.00"  # Should be rejected
}
```

---

## Serializer Testing

### Test SellerProductListSerializer

```python
from apps.users.seller_serializers import SellerProductListSerializer
from apps.users.seller_models import SellerProduct

product = SellerProduct.objects.first()
serializer = SellerProductListSerializer(product)

# Verify all fields are present
fields = serializer.data.keys()
expected = ['id', 'name', 'product_type', 'price', 'status', ...]
assert all(f in fields for f in expected)
```

### Test SellerProductCreateUpdateSerializer

```python
from apps.users.seller_serializers import SellerProductCreateUpdateSerializer

data = {
    'name': 'Test Product',
    'product_type': 'VEGETABLE',
    'price': '50.00',
    'ceiling_price': '75.00',
    'stock_level': 100,
    'unit': 'kg'
}

serializer = SellerProductCreateUpdateSerializer(data=data)
assert serializer.is_valid(), serializer.errors
```

### Test ProductImageSerializer

```python
from apps.users.seller_serializers import ProductImageSerializer

# Test image URL generation
image = ProductImage.objects.first()
serializer = ProductImageSerializer(
    image,
    context={'request': mock_request}
)

# Verify image_url is present and valid
assert serializer.data['image_url']
assert serializer.data['image_url'].startswith('http')
```

---

## Integration Testing

### Test Product Creation Flow

```python
# 1. Create seller
seller = User.objects.create_user(
    username='farmer',
    email='farmer@example.com',
    password='test123',
    role='SELLER',
    seller_status='APPROVED'
)

# 2. Create product
product = SellerProduct.objects.create(
    seller=seller,
    name='Tomato',
    product_type='VEGETABLE',
    price=50.00,
    ceiling_price=75.00,
    stock_level=100,
    unit='kg',
    quality_grade='PREMIUM'
)

# 3. Add image
image = ProductImage.objects.create(
    product=product,
    image=test_image_file,
    is_primary=True,
    order=1,
    alt_text='Fresh tomatoes'
)

# 4. Query and verify
retrieved = SellerProduct.objects.get(id=product.id)
assert retrieved.is_active == True
assert retrieved.product_images.count() == 1
```

---

## Documentation Testing

- [ ] Quick reference guide is clear: `SELLER_PRODUCT_QUICK_REFERENCE.md`
- [ ] Implementation status is accurate: `SELLER_PRODUCT_IMPLEMENTATION_COMPLETE.md`
- [ ] API examples are correct
- [ ] Code snippets are tested

---

## Deployment Checklist

Before deploying to production:

```bash
# 1. Run all checks
python manage.py check

# 2. Run tests (ensure migrations are applied first)
python manage.py migrate --noinput
python manage.py test

# 3. Verify migrations
python manage.py migrate --plan

# 4. Collect static files
python manage.py collectstatic --no-input

# 5. Check for security issues
python manage.py check --deploy

# 6. Run coverage
coverage run --source='.' manage.py test
coverage report

# 7. Load test
# Use Apache Bench or similar tool to verify performance
```

---

## Common Issues & Solutions

### Issue: ProductImage not showing in admin
**Solution:**
```python
# Ensure ProductImage is imported and registered
from .seller_models import ProductImage

@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    ...
```

### Issue: N+1 query problem
**Solution:**
```python
# Use select_related and prefetch_related
products = SellerProduct.objects.select_related('seller').prefetch_related('product_images')
```

### Issue: Image upload failing
**Solution:**
```python
# Ensure MEDIA_ROOT and MEDIA_URL are configured
# MEDIA_ROOT = BASE_DIR / 'media'
# MEDIA_URL = '/media/'

# Add to urlpatterns in production settings
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### Issue: Permission denied when creating products
**Solution:**
```python
# Verify user is approved seller
user.role == 'SELLER'
user.seller_status == 'APPROVED'
```

---

## Performance Optimization Tasks

- [ ] Add Redis caching for popular products
- [ ] Implement image CDN for faster image delivery
- [ ] Add database query monitoring
- [ ] Set up automated performance tests
- [ ] Monitor query performance in production
- [ ] Optimize image storage and compression

---

## Future Enhancement Tasks

- [ ] Add product reviews system
- [ ] Implement demand forecasting
- [ ] Add bulk product operations
- [ ] Create product analytics dashboard
- [ ] Implement AI-powered recommendations
- [ ] Add product versioning
- [ ] Create inventory forecasting

---

## Sign-Off

- [ ] All checklist items completed
- [ ] Code reviewed and approved
- [ ] Tests passing
- [ ] Documentation updated
- [ ] Ready for deployment

---

**Checklist Last Updated:** November 26, 2025  
**Implementation Version:** 1.0  
**Status:** Production Ready ✅
