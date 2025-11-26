# SellerProduct & ProductImage - Quick Reference Guide

## 🚀 Quick Start

### 1. Create a Product

```python
from apps.users.seller_models import SellerProduct
from apps.users.models import User

seller = User.objects.get(email='farmer@example.com')
product = SellerProduct.objects.create(
    seller=seller,
    name='Tomato',
    product_type='VEGETABLE',
    description='Fresh red tomatoes',
    price=50.00,
    stock_level=100,
    unit='kg',
    quality_grade='PREMIUM',
    status='ACTIVE'
)
```

### 2. Add Product Images

```python
from apps.users.seller_models import ProductImage
from django.core.files.storage import default_storage

image_file = request.FILES['image']
product_image = ProductImage.objects.create(
    product=product,
    image=image_file,
    is_primary=True,
    order=1,
    alt_text='Fresh tomatoes'
)
```

### 3. Query Products

```python
# Get all products for a seller
seller_products = SellerProduct.objects.filter(seller=seller)

# Get active products only
active_products = SellerProduct.objects.filter(
    seller=seller, 
    status='ACTIVE'
)

# Get with images prefetched
products = SellerProduct.objects.filter(
    seller=seller
).prefetch_related('product_images')

# Using custom manager
active = SellerProduct.objects.active()
compliant = SellerProduct.objects.compliant()
non_compliant = SellerProduct.objects.non_compliant()
```

### 4. Check Product Properties

```python
product = SellerProduct.objects.get(id=123)

# Check if product is active
if product.is_active:
    print("Product is active")

# Check if expired
if product.is_expired:
    print("Product listing has expired")

# Check price compliance
if product.price_exceeds_ceiling:
    print("Price violates ceiling")

# Check stock level
if product.is_low_stock:
    print("Stock is low")
```

### 5. Update Product

```python
product.price = 55.00
product.stock_level = 80
product.save()
```

### 6. Delete Product (Soft Delete)

```python
# Soft delete with reason
product.soft_delete(reason='Product discontinued')

# Restore if needed
product.restore()
```

### 7. Get Product Images

```python
# Get primary image
primary_image = product.product_images.filter(is_primary=True).first()
if primary_image:
    print(primary_image.image.url)

# Get all images ordered
all_images = product.product_images.all().order_by('order')
```

---

## 📊 Available QuerySet Methods

### Custom Manager Methods

```python
# Active products (not deleted, active status)
SellerProduct.objects.active()

# Deleted products
SellerProduct.objects.deleted()

# Non-deleted products
SellerProduct.objects.not_deleted()

# Compliant products (within price ceiling)
SellerProduct.objects.compliant()

# Non-compliant products (exceed price ceiling)
SellerProduct.objects.non_compliant()

# Filter by seller
SellerProduct.objects.by_seller(seller)
```

### QuerySet Methods

```python
# Chaining filters
products = SellerProduct.objects.filter(
    product_type='VEGETABLE'
).active().compliant()

# With relationships optimized
products = SellerProduct.objects.filter(
    seller=seller
).select_related('seller').prefetch_related('product_images')
```

---

## 🔌 API Endpoints Usage

### List Seller Products

```bash
GET /api/seller/products/
```

Response:
```json
[
  {
    "id": 123,
    "name": "Tomato",
    "product_type": "VEGETABLE",
    "price": "50.00",
    "ceiling_price": "75.00",
    "stock_level": 100,
    "unit": "kg",
    "quality_grade": "PREMIUM",
    "status": "ACTIVE",
    "is_active": true,
    "is_low_stock": false,
    "price_exceeds_ceiling": false,
    "created_at": "2025-11-26T10:30:00Z"
  }
]
```

### Create Product

```bash
POST /api/seller/products/
Content-Type: application/json

{
  "name": "Tomato",
  "product_type": "VEGETABLE",
  "description": "Fresh red tomatoes",
  "price": "50.00",
  "ceiling_price": "75.00",
  "stock_level": 100,
  "unit": "kg",
  "quality_grade": "PREMIUM"
}
```

### Get Product Details

```bash
GET /api/seller/products/123/
```

### Update Product

```bash
PUT /api/seller/products/123/
Content-Type: application/json

{
  "price": "55.00",
  "stock_level": 80
}
```

### Delete Product

```bash
DELETE /api/seller/products/123/
```

Response: 204 No Content

### List Active Products

```bash
GET /api/seller/products/active/
```

### List Expired Products

```bash
GET /api/seller/products/expired/
```

### Check Ceiling Price

```bash
POST /api/seller/products/check_ceiling_price/
Content-Type: application/json

{
  "product_id": 123
}
```

Response:
```json
{
  "product_id": 123,
  "price": "50.00",
  "ceiling_price": "75.00",
  "exceeds_ceiling": false,
  "message": "Price is within limits"
}
```

### Check Stock Availability

```bash
POST /api/seller/products/check_stock_availability/
Content-Type: application/json

{
  "product_id": 123,
  "quantity_required": 50
}
```

Response:
```json
{
  "product_id": 123,
  "product_name": "Tomato",
  "current_stock": 100,
  "required_quantity": 50,
  "available": true,
  "stock_after_order": 50,
  "minimum_stock_level": 10,
  "would_be_low_stock": false,
  "message": "Stock available"
}
```

---

## 🎨 Serializer Usage

### SellerProductListSerializer

Used for: `GET /api/seller/products/`

**Read-only fields:**
- Optimized for list views
- Excludes images to avoid N+1 queries
- Includes computed properties

### SellerProductCreateUpdateSerializer

Used for: `POST /api/seller/products/`, `PUT /api/seller/products/{id}/`

**Features:**
- Full CRUD operations
- Automatic seller assignment (current user)
- Price validation
- Stock validation
- Ceiling price enforcement

### ProductImageSerializer

Used for: Image management endpoints

**Features:**
- Image file upload
- Automatic URL generation
- Primary image designation
- Display ordering

---

## 📈 Performance Tips

### 1. Use select_related for ForeignKey
```python
# Good: Single query
products = SellerProduct.objects.select_related('seller')

# Bad: N+1 queries
products = SellerProduct.objects.all()
for p in products:
    print(p.seller.email)  # Query per iteration
```

### 2. Use prefetch_related for OneToMany
```python
# Good: Two queries
products = SellerProduct.objects.prefetch_related('product_images')

# Bad: N+1 queries
products = SellerProduct.objects.all()
for p in products:
    images = p.product_images.all()  # Query per iteration
```

### 3. Use only() for selective fields
```python
# Good: Load only needed columns
products = SellerProduct.objects.only('id', 'name', 'price')

# Avoid: Load all columns
products = SellerProduct.objects.all()
```

### 4. Filter early
```python
# Good: Filter first
products = SellerProduct.objects.filter(status='ACTIVE').count()

# Bad: Load then count
all_products = SellerProduct.objects.all()
count = sum(1 for p in all_products if p.status == 'ACTIVE')
```

---

## 🔐 Permissions

All seller product endpoints require:
1. **IsAuthenticated** - User must be logged in
2. **IsOPASSeller** - User must be an approved seller

Example in ViewSet:
```python
permission_classes = [IsAuthenticated, IsOPASSeller]
```

---

## 🧪 Testing Examples

### Test Create Product

```python
def test_create_product(self):
    from apps.users.models import User
    from apps.users.seller_models import SellerProduct
    
    seller = User.objects.create_user(
        username='farmer',
        email='farmer@example.com',
        password='testpass123',
        role='SELLER',
        seller_status='APPROVED'
    )
    
    product = SellerProduct.objects.create(
        seller=seller,
        name='Tomato',
        product_type='VEGETABLE',
        price=50.00,
        stock_level=100,
        unit='kg',
        quality_grade='PREMIUM'
    )
    
    assert product.id is not None
    assert product.is_active is True
    assert product.price_exceeds_ceiling is False
```

### Test Price Ceiling

```python
def test_price_ceiling_validation(self):
    product = SellerProduct.objects.create(
        seller=seller,
        name='Tomato',
        product_type='VEGETABLE',
        price=80.00,
        ceiling_price=75.00,
        stock_level=100
    )
    
    assert product.price_exceeds_ceiling is True
```

### Test Soft Delete

```python
def test_soft_delete(self):
    product = SellerProduct.objects.create(...)
    
    # Soft delete
    product.soft_delete(reason='Discontinued')
    assert product.is_deleted is True
    assert product.deleted_at is not None
    
    # Restore
    product.restore()
    assert product.is_deleted is False
```

---

## 📞 Common Issues & Solutions

### Issue: N+1 Query Problem

**Problem:** Getting seller for each product creates new query
```python
for product in products:
    print(product.seller.email)  # New query each time!
```

**Solution:** Use select_related
```python
products = SellerProduct.objects.select_related('seller')
for product in products:
    print(product.seller.email)  # No new query
```

### Issue: Images Not Loading

**Problem:** Images relationship not loaded
```python
product.product_images.all()  # New query
```

**Solution:** Use prefetch_related
```python
products = SellerProduct.objects.prefetch_related('product_images')
# Now accessing images doesn't create new queries
```

### Issue: Price Validation Fails

**Problem:** Price exceeds ceiling but passes validation

**Solution:** Check data before saving
```python
if product.price <= product.ceiling_price:
    product.save()
else:
    raise ValidationError("Price exceeds ceiling")
```

---

## 🔗 Related Resources

- **Specification Document:** `PRODUCT_POSTING_DISPLAY_IMPLEMENTATION_MAP.md`
- **Implementation Status:** `SELLER_PRODUCT_IMPLEMENTATION_COMPLETE.md`
- **Admin Interface:** Django Admin at `/admin/`
- **API Documentation:** OpenAPI/Swagger at `/api/docs/`

---

**Last Updated:** November 26, 2025  
**Version:** 1.0
