# 🛒 OPAS Product Posting & Display Implementation Map

## 📋 Executive Overview

This document provides a comprehensive implementation map for the seller product posting workflow and product display across all user roles (Sellers, Buyers, Admin) in the OPAS platform.

**Key Statistics:**
- **Seller Product Management:** 5 core endpoints (CRUD + listing)
- **Buyer Product Display:** 2 core endpoints (browse + detail)
- **Admin Marketplace Control:** 4 endpoints (view, filter, violations, audit)
- **Total API Endpoints:** 11 core endpoints
- **Frontend Screens:** 8 key screens
- **Database Models:** 5 interconnected models

---

## 🏗️ PART 1: DATABASE LAYER✅

### 1.1 Core Data Models

#### **SellerProduct Model** (Backend)
```
Location: OPAS_Django/apps/users/seller_models.py

Fields:
├── id (PrimaryKey)
├── seller (ForeignKey → User)
├── name (CharField)
├── product_type (CharField: VEGETABLE, FRUIT, GRAIN, etc.)
├── description (TextField)
├── price (DecimalField)
├── stock_level (IntegerField)
├── unit (CharField: kg, pcs, bundle, etc.)
├── quality_grade (CharField: A, B, C)
├── status (CharField: ACTIVE, EXPIRED, DRAFT)
├── images (OneToMany → ProductImage)
├── created_at (DateTimeField)
├── updated_at (DateTimeField)
├── expires_at (DateTimeField, optional)

Indexes:
- seller_id + status (for filtering seller's products)
- created_at DESC (for sorting)
- product_type (for category filtering)
```

#### **ProductImage Model** (Backend)
```
Location: OPAS_Django/apps/users/seller_models.py

Fields:
├── id (PrimaryKey)
├── product (ForeignKey → SellerProduct)
├── image (ImageField → media/products/)
├── is_primary (BooleanField)
├── created_at (DateTimeField)

Relationship:
- SellerProduct (1 : Many) ProductImage
- One product can have multiple images
- One primary image per product for listings
```

#### **ProductStatus Enum** (Backend)
```
Values:
- ACTIVE: Product is live and available
- EXPIRED: Product listing has expired
- DRAFT: Product saved but not published
- ARCHIVED: Product removed but history kept
```

#### **Product Model** (Frontend)
```
Location: OPAS_Flutter/lib/features/products/models/product_model.dart

Fields:
├── id (int)
├── name (String)
├── category (String)
├── description (String)
├── pricePerKilo (double)
├── opasRegulatedPrice (double)
├── stock (int)
├── unit (String)
├── imageUrl (String)
├── sellerId (int)
├── sellerName (String)
├── sellerRating (double)
├── isAvailable (bool)
├── createdAt (DateTime)

Computed Fields:
- priceComparison = opasRegulatedPrice - pricePerKilo
- isWithinRegulatedPrice = pricePerKilo ≤ opasRegulatedPrice
```

---

## 🔌 PART 2: API ENDPOINTS LAYER✅

### 2.1 Seller Product Management Endpoints

#### **POST /api/users/seller/products/** - Create Product
```
Purpose: Sellers post new products

Request (MultiPart Form):
├── name (String, required)
├── product_type (String, required: VEGETABLE, FRUIT, GRAIN)
├── description (String, optional)
├── price (Decimal, required)
├── stock_level (Integer, required)
├── unit (String, required)
├── quality_grade (String: A, B, C)
├── images (Multiple Files, max 5)

Response (201 Created):
{
  "id": 123,
  "seller": { "id": 5, "email": "farmer@example.com" },
  "name": "Tomato",
  "product_type": "VEGETABLE",
  "price": "50.00",
  "stock_level": 100,
  "unit": "kg",
  "images": [
    { "id": 1, "image": "/media/products/abc123.jpg", "is_primary": true }
  ],
  "status": "ACTIVE",
  "created_at": "2025-11-26T10:30:00Z"
}

Validation Rules:
├── Price validation: price ≤ ceiling_price (by product type)
├── Stock validation: stock_level > 0
├── Images validation: max 5 images, jpg/png only
└── Authorization: User must be approved SELLER

Error Responses:
├── 400: Validation error (price exceeds ceiling, invalid stock)
├── 401: Unauthorized
├── 403: User not approved seller
└── 500: Server error
```

#### **GET /api/users/seller/products/** - List Seller Products
```
Purpose: Seller views all their products

Query Parameters:
├── page (Integer, default: 1)
├── status (String: ACTIVE, EXPIRED, DRAFT, ARCHIVED)
├── search (String: filter by name)
└── ordering (String: -created_at, -price, name)

Response (200 OK):
{
  "count": 50,
  "next": "?page=2",
  "previous": null,
  "results": [
    {
      "id": 123,
      "name": "Tomato",
      "product_type": "VEGETABLE",
      "price": "50.00",
      "stock_level": 100,
      "status": "ACTIVE",
      "primary_image": "/media/products/abc123.jpg",
      "created_at": "2025-11-26T10:30:00Z"
    },
    // ... more products
  ]
}

Optimization:
├── Uses select_related('seller') to avoid N+1 queries
├── Prefetches related product_images
└── Indexes on seller_id + status for fast filtering
```

#### **GET /api/users/seller/products/{id}/** - Get Product Details
```
Purpose: Seller views specific product details

Response (200 OK):
{
  "id": 123,
  "seller": { "id": 5, "email": "farmer@example.com" },
  "name": "Tomato",
  "product_type": "VEGETABLE",
  "description": "Fresh red tomatoes...",
  "price": "50.00",
  "stock_level": 100,
  "unit": "kg",
  "quality_grade": "A",
  "images": [
    {
      "id": 1,
      "image": "/media/products/abc123.jpg",
      "is_primary": true
    },
    {
      "id": 2,
      "image": "/media/products/abc124.jpg",
      "is_primary": false
    }
  ],
  "status": "ACTIVE",
  "created_at": "2025-11-26T10:30:00Z",
  "updated_at": "2025-11-26T10:30:00Z"
}

Error Responses:
├── 404: Product not found
├── 403: Permission denied (not product owner)
└── 401: Unauthorized
```

#### **PUT /api/users/seller/products/{id}/** - Update Product
```
Purpose: Seller updates product details

Request (MultiPart Form):
├── name (String, optional)
├── description (String, optional)
├── price (Decimal, optional)
├── stock_level (Integer, optional)
├── unit (String, optional)
├── quality_grade (String, optional)
└── images (Multiple Files, optional)

Response (200 OK):
{
  "id": 123,
  "name": "Tomato (Updated)",
  "price": "55.00",
  "stock_level": 80,
  // ... full product data
}

Validation Rules:
├── Price: Must not exceed ceiling price
├── Stock: Must be ≥ 0
├── Seller can only update their own products
└── Cannot update product_type

Error Responses:
├── 400: Validation error
├── 404: Product not found
├── 403: Permission denied
└── 401: Unauthorized
```

#### **DELETE /api/users/seller/products/{id}/** - Delete Product
```
Purpose: Seller removes product from marketplace

Response (204 No Content):
- Product marked as ARCHIVED
- Product no longer appears in marketplace
- Historical data retained for audit

Error Responses:
├── 404: Product not found
├── 403: Permission denied
└── 401: Unauthorized

Note: Soft delete to maintain referential integrity with orders
```

#### **GET /api/users/seller/products/active/** - List Active Products
```
Purpose: Quick view of seller's active products

Response (200 OK):
Returns only products with status = ACTIVE

Optimization:
├── Filtered query for fast response
└── Cached at seller dashboard level
```

#### **POST /api/users/seller/products/check_ceiling_price/** - Check Price Ceiling
```
Purpose: Validate product price against OPAS ceiling

Request:
{
  "product_type": "VEGETABLE"
}

Response (200 OK):
{
  "product_type": "VEGETABLE",
  "ceiling_price": "75.00",
  "current_price": "50.00",
  "is_compliant": true
}

Use Case:
- Seller entering product price gets real-time validation
- Prevents data entry errors
- Enforces OPAS price controls
```

---

### 2.2 Buyer Product Discovery Endpoints

#### **GET /api/products/** - Get All Products (Marketplace)
```
Purpose: Buyers browse marketplace products

Query Parameters:
├── page (Integer, default: 1)
├── category (String: VEGETABLE, FRUIT, GRAIN)
├── min_price (Decimal)
├── max_price (Decimal)
├── search (String)
├── seller_id (Integer, optional)
├── ordering (String: price, -price, -created_at, rating)
└── limit (Integer, default: 20)

Response (200 OK):
{
  "count": 1500,
  "next": "?page=2",
  "previous": null,
  "results": [
    {
      "id": 123,
      "name": "Tomato",
      "category": "VEGETABLE",
      "price_per_kilo": "50.00",
      "opas_regulated_price": "75.00",
      "stock": 100,
      "unit": "kg",
      "image_url": "/media/products/abc123.jpg",
      "seller_id": 5,
      "seller_name": "Fresh Farm Co.",
      "seller_rating": 4.8,
      "is_available": true,
      "created_at": "2025-11-26T10:30:00Z"
    },
    // ... more products
  ]
}

Optimization:
├── Pagination to limit query size
├── Elasticsearch for full-text search (optional)
├── Database indexes on category, price, created_at
├── Caching layer for popular categories
└── Returns only ACTIVE products with stock > 0

Filter Logic:
- Only shows products from APPROVED sellers
- Filters by price range
- Searches by name + category
- Sorts by relevance/price/rating
```

#### **GET /api/products/{id}/** - Get Product Detail
```
Purpose: Buyer views detailed product information

Response (200 OK):
{
  "id": 123,
  "name": "Tomato",
  "category": "VEGETABLE",
  "description": "Fresh red tomatoes grown organically...",
  "price_per_kilo": "50.00",
  "opas_regulated_price": "75.00",
  "stock": 100,
  "unit": "kg",
  "images": [
    {
      "id": 1,
      "image": "/media/products/abc123.jpg",
      "is_primary": true
    },
    {
      "id": 2,
      "image": "/media/products/abc124.jpg",
      "is_primary": false
    }
  ],
  "seller_info": {
    "id": 5,
    "name": "Fresh Farm Co.",
    "rating": 4.8,
    "reviews_count": 125,
    "location": "Nueva Ecija",
    "established_since": "2020"
  },
  "reviews": [
    {
      "id": 1,
      "author": "buyer@example.com",
      "rating": 5,
      "comment": "Great quality!",
      "created_at": "2025-11-20T10:00:00Z"
    }
  ],
  "price_history": [
    { "price": "48.00", "date": "2025-11-01" },
    { "price": "50.00", "date": "2025-11-26" }
  ],
  "is_available": true,
  "created_at": "2025-11-26T10:30:00Z"
}

Error Responses:
├── 404: Product not found or unavailable
├── 401: Unauthorized (if access restricted)
└── 500: Server error

Includes:
- All product images
- Seller profile summary
- Recent reviews
- Price history (for price trends)
- Related products (optional)
```

---

### 2.3 Admin Marketplace Control Endpoints

#### **GET /api/admin/marketplace/products/** - View Marketplace Products
```
Purpose: Admin monitors all marketplace products

Query Parameters:
├── status (String: ACTIVE, EXPIRED, FLAGGED)
├── seller_id (Integer)
├── price_range (String)
├── category (String)
└── date_range (String)

Response includes:
├── All product details
├── Seller compliance info
├── Price violation status
├── Review flags
└── Sales metrics

Use for: Market overview, price monitoring, compliance audits
```

#### **GET /api/admin/marketplace/products/{id}/violations/** - Check Price Violations
```
Purpose: Identify products exceeding OPAS ceiling prices

Response:
{
  "product_id": 123,
  "violation_status": "WARNING",
  "ceiling_price": "75.00",
  "current_price": "80.00",
  "excess_amount": "5.00",
  "violation_date": "2025-11-26T10:00:00Z"
}

Actions:
├── Auto-notify seller (warning)
├── Flag for manual review (critical)
└── Auto-adjust price (if policy allows)
```

---

## 🎨 PART 3: FRONTEND LAYER✅

### 3.1 Seller Panel Screens

#### **Screen 1: Product Listing Screen**
```
File: OPAS_Flutter/lib/features/seller_panel/screens/product_listing_screen.dart

Purpose: Seller views all their products

UI Components:
├── Filter Bar
│  ├── Search by name
│  ├── Filter by status (Active, Expired, Draft)
│  └── Sort by (newest, price, stock)
├── Product Cards
│  ├── Product name + category
│  ├── Price display
│  ├── Stock level
│  ├── Primary image
│  └── Status badge
└── Action Buttons
   ├── Add New Product (+)
   ├── Edit (pencil icon)
   └── Delete (trash icon)

Data Flow:
1. User navigates to seller dashboard
2. SellerService.getProducts() called
3. API request: GET /api/users/seller/products/
4. Response parsed into List<SellerProduct>
5. ListView renders with ProductCards
6. Pull-to-refresh enabled for manual sync

State Management:
├── isLoading: Show skeleton/shimmer
├── products: List of seller products
├── error: Error message display
└── selectedFilter: Current filter state

Performance:
- Pagination for >50 products
- Image lazy loading
- Caching of product list
- Debounced search
```

#### **Screen 2: Add Product Screen**
```
File: OPAS_Flutter/lib/features/seller_panel/screens/add_product_screen.dart

Purpose: Seller creates new product

Form Fields:
├── Product Name (required)
├── Category (dropdown: Vegetable, Fruit, Grain)
├── Description (multi-line text)
├── Price per unit (decimal, required)
├── Stock level (integer, required)
├── Unit type (dropdown: kg, pcs, bundle)
├── Quality Grade (dropdown: A, B, C)
└── Product Images (multi-select, max 5)

Validation:
├── Name: 3-100 characters
├── Price: > 0 and ≤ ceiling price
├── Stock: > 0
├── Images: jpg/png only, max 5MB each
└── Category: required

Workflow:
1. Seller fills form
2. Real-time price ceiling check
   - SellerService.checkCeilingPrice()
   - Displays warning if exceeds
3. Seller selects images
   - Image preview with thumbnail
4. Submit button
   - SellerService.createProduct()
   - API: POST /api/users/seller/products/
5. Success confirmation
   - Navigate back to product listing
6. Error handling
   - Display error toast
   - Keep form data

State Management:
├── formData: Form input values
├── selectedImages: List<File>
├── isLoading: Submit button state
├── ceilingPrice: Real-time validation
├── priceExceedsCeiling: Warning flag
└── validationErrors: Field errors
```

#### **Screen 3: Edit Product Screen**
```
File: OPAS_Flutter/lib/features/seller_panel/screens/edit_product_screen.dart

Purpose: Seller updates existing product

Pre-fill Data:
1. GET /api/users/seller/products/{id}/
2. Parse response into form fields
3. Display current images

Editable Fields:
├── Product Name
├── Description
├── Price (with ceiling validation)
├── Stock level
├── Unit type
├── Quality grade
└── Images (add/remove)

Non-editable Fields:
├── Category (cannot change)
└── Created at

Submit:
- PUT /api/users/seller/products/{id}/
- Returns updated product

Optimistic UI:
- Update local state before response
- Revert on error

Difference from Add Product:
- Pre-populated form
- Delete images capability
- Cannot change product type
```

#### **Screen 4: Inventory Management Screen**
```
File: OPAS_Flutter/lib/features/seller_panel/screens/inventory_listing_screen.dart

Purpose: Track product stock levels

Display:
├── List of products with current stock
├── Low stock alerts (red highlight)
├── Reorder suggestions
└── Stock movement history

Quick Actions:
├── Update stock (inline edit)
├── Set reorder level
└── View history

API Calls:
- GET /api/users/seller/inventory/overview/
- GET /api/users/seller/inventory/low_stock/
- POST /api/users/seller/inventory/{id}/update/
```

---

### 3.2 Buyer Marketplace Screens

#### **Screen 5: Marketplace Home Screen**
```
File: OPAS_Flutter/lib/features/home/screens/buyer_home_screen.dart

Purpose: Buyer discovers products

Layout:
├── Header
│  ├── Search bar (redirects to ProductList)
│  └── Location selector
├── Featured Categories (horizontal scroll)
│  ├── Vegetable
│  ├── Fruit
│  ├── Grain
│  └── View All
├── Featured Products (grid 2x2)
│  └── Highest rated/newest
├── Promotions (carousel)
└── Recent Orders (for logged-in users)

Data Loading:
1. GET /api/products/?limit=10&ordering=-rating
2. GET /api/products/?category=VEGETABLE&limit=6
3. Cache results for 5 minutes

Gestures:
- Swipe category carousel
- Tap product → ProductDetailScreen
- Tap category → ProductListScreen filtered
```

#### **Screen 6: Product List Screen (with Filters)**
```
File: OPAS_Flutter/lib/features/marketplace/screens/product_list_screen.dart

Purpose: Browse all marketplace products with filtering

Layout:
├── Search + Filter bar
│  ├── Search input
│  └── Filter icon (opens bottom sheet)
├── View mode toggle (grid/list)
└── Product grid/list
   ├── Grid: 2 columns
   └── List: Full width cards

Filter Options (BottomSheet):
├── Category (checkboxes)
├── Price range (slider: 0-500)
├── Seller rating (≥ 3★, ≥ 4★, ≥ 5★)
├── Availability (In stock / All)
├── Sort order (Newest, Price: Low→High, Top rated)
└── Apply/Clear buttons

API Integration:
1. Initial load: GET /api/products/?page=1
2. Search: GET /api/products/?search=tomato
3. Filter: GET /api/products/?category=VEGETABLE&min_price=40&max_price=80
4. Infinite scroll pagination

Optimization:
├── Lazy load images (cached_network_image)
├── Pagination (20 items per page)
├── Debounced search (500ms delay)
└── Shimmer loading skeleton

State Management:
├── products: List<Product>
├── filteredProducts: After client-side filtering
├── isLoading: Loading state
├── hasMoreData: Pagination control
├── filters: Current filter values
└── searchQuery: Current search term
```

#### **Screen 7: Product Detail Screen**
```
File: OPAS_Flutter/lib/features/products/screens/product_detail_screen.dart

Purpose: View detailed product information

Layout:
├── Image Gallery (swipeable)
│  ├── Full-screen images
│  ├── Thumbnail strip
│  └── Image counter
├── Product Info
│  ├── Name + category badge
│  ├── Price comparison (seller vs OPAS)
│  ├── Stock indicator
│  ├── Unit size
│  └── Quality grade
├── Seller Profile
│  ├── Seller name
│  ├── Rating + reviews count
│  ├── Location
│  ├── Response time
│  └── "Visit Shop" button
├── Description
│  ├── Full product description
│  └── Expand/collapse for long text
├── Reviews Section
│  ├── Average rating
│  ├── Review breakdown (5★, 4★, 3★, 2★, 1★)
│  ├── Recent reviews (3-5 shown)
│  └── "View all reviews" link
├── Price History Chart
│  └── Line graph of price trends (if available)
└── Action Bar
   ├── Add to Cart button
   ├── Buy Now button
   └── Share button

Data Loading:
1. GET /api/products/{id}/
2. Parse all product details
3. Render gallery, seller info, reviews
4. Display price history if available

Error Handling:
├── Product not found (404)
├── Network timeout
└── Seller offline (show cached data)

Related Products:
- Display 4-5 related products
- Same category but different seller
- Tap to view details
```

#### **Screen 8: Seller Shop/Profile Screen (Buyer View)**
```
File: OPAS_Flutter/lib/features/profile/screens/seller_shop_screen.dart

Purpose: Buyer views seller's full catalog

Display:
├── Seller Header
│  ├── Shop name
│  ├── Average rating + review count
│  ├── Response time
│  ├── Location
│  └── Verification badges
├── Shop Stats
│  ├── Total products
│  ├── Successful orders
│  └── Member since
├── Products Grid
│  ├── All seller's products
│  ├── Sort/filter options
│  └── Infinite scroll
└── Reviews Tab
   └── All seller reviews

API Calls:
- GET /api/products/?seller_id={id}
- GET /api/seller/{id}/profile/
- GET /api/seller/{id}/reviews/
```

---

## 🔄 PART 4: DATA FLOW & WORKFLOWS

### 4.1 Seller Product Posting Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                 SELLER PRODUCT POSTING WORKFLOW                 │
└─────────────────────────────────────────────────────────────────┘

1. SELLER NAVIGATES TO ADD PRODUCT
   └─ Clicks "Add Product" button
   └─ Route: /seller/products/add
   └─ Screen: AddProductScreen

2. FORM INITIALIZATION
   └─ Initialize empty form
   └─ Load category options from enum
   └─ Set default unit to "kg"

3. SELLER FILLS FORM
   ├─ Product Name (required)
   ├─ Category (dropdown)
   ├─ Description (optional)
   ├─ Price (with real-time validation)
   │  └─ checkCeilingPrice() on each change
   │  └─ Display warning if exceeds ceiling
   ├─ Stock Level
   ├─ Unit Type
   ├─ Quality Grade
   └─ Upload Images (max 5)
      └─ pickImages() from device gallery

4. REAL-TIME VALIDATION
   └─ checkCeilingPrice API call
      ├─ POST /api/seller/products/check_ceiling_price/
      ├─ Send: { product_type: "VEGETABLE" }
      ├─ Receive: { ceiling_price: "75.00" }
      └─ Compare current_price vs ceiling_price

5. SELLER SUBMITS FORM
   └─ Validate all fields locally
   └─ Show loading indicator

6. BACKEND PROCESSING
   ├─ POST /api/users/seller/products/
   ├─ Backend validation
   │  ├─ Price ≤ ceiling_price
   │  ├─ Stock > 0
   │  ├─ Images format validation
   │  └─ Seller approval verification
   ├─ Image processing
   │  ├─ Resize to standard size
   │  ├─ Save to media directory
   │  └─ Set primary image
   └─ Create SellerProduct record
      └─ Status: ACTIVE

7. RESPONSE HANDLING
   ├─ 201 Created Success
   │  ├─ Parse response
   │  ├─ Show success message
   │  └─ Navigate back to product list
   └─ Error Handling
      ├─ 400 Validation Error
      │  └─ Display field-specific errors
      ├─ 401 Unauthorized
      │  └─ Redirect to login
      ├─ 403 Forbidden
      │  └─ Show "Not approved seller" message
      └─ 500 Server Error
         └─ Show generic error + retry button

8. PRODUCT LIVE IN MARKETPLACE
   ├─ Product immediately visible in seller's list
   ├─ Cache invalidated
   └─ Appears in marketplace browse
      └─ GET /api/products/ includes new product
```

### 4.2 Buyer Product Discovery & Display Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│              BUYER PRODUCT DISCOVERY & DISPLAY WORKFLOW          │
└─────────────────────────────────────────────────────────────────┘

1. BUYER OPENS MARKETPLACE
   ├─ Screen: BuyerHomeScreen
   └─ Load featured products
      ├─ GET /api/products/?limit=10&ordering=-rating
      └─ Display featured items

2. BUYER NAVIGATES TO PRODUCT LIST
   ├─ Clicks "Browse Products" or category
   └─ Screen: ProductListScreen

3. INITIAL DATA LOAD
   ├─ GET /api/products/?page=1
   ├─ Backend filters:
   │  ├─ Only ACTIVE products
   │  ├─ From APPROVED sellers
   │  └─ With stock > 0
   ├─ Response pagination: 20 items/page
   └─ Display as grid

4. BUYER APPLIES FILTERS
   ├─ Opens filter BottomSheet
   ├─ Adjusts:
   │  ├─ Category
   │  ├─ Price range
   │  ├─ Seller rating
   │  └─ Sort order
   ├─ Clicks "Apply"
   └─ New API call:
      GET /api/products/?category=VEGETABLE&min_price=40&max_price=80

5. BUYER SEARCHES
   ├─ Types in search box
   ├─ Debounce 500ms
   └─ GET /api/products/?search=tomato

6. BUYER VIEWS PRODUCT DETAIL
   ├─ Clicks product card
   ├─ Route: /product/{id}
   ├─ GET /api/products/{id}/
   └─ Display:
      ├─ Image gallery
      ├─ Price details
      ├─ Seller information
      ├─ Reviews
      └─ Related products

7. BUYER VIEWS SELLER PROFILE
   ├─ Clicks seller name
   ├─ Route: /seller/{id}
   ├─ GET /api/products/?seller_id={id}
   ├─ GET /api/seller/{id}/profile/
   └─ Display seller shop

8. BUYER ADDS TO CART / PURCHASES
   ├─ Clicks "Add to Cart"
   ├─ POST /api/cart/add/
   │  └─ Send: { product_id: 123, quantity: 5 }
   └─ Continue shopping or checkout
      └─ POST /api/orders/create/
```

### 4.3 Product Update & Expiration Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│           PRODUCT UPDATE & EXPIRATION WORKFLOW                   │
└─────────────────────────────────────────────────────────────────┘

SELLER UPDATES PRODUCT:
1. Seller clicks Edit on product card
2. GET /api/users/seller/products/{id}/
3. Form pre-populated with current data
4. Seller modifies fields
5. PUT /api/users/seller/products/{id}/
6. Backend validation (same as create)
7. Update SellerProduct record
8. Return updated product
9. Show success + return to list

PRODUCT EXPIRATION:
1. Seller can manually mark a product as Expired from the product actions menu
   └─ new 'Mark as Expired' option added between Edit and Delete on the product modal
2. Set status = EXPIRED
3. Remove from marketplace queries
4. Seller can see in "Expired" tab
5. Seller can:
   ├─ Reactivate (restore existing product to its previous status — preserves sales, ratings, and history). If no previous status exists, fall back to PENDING (admin review required).
   ├─ Extend expiration
   └─ Archive permanently

PRODUCT DELETION:
1. Seller clicks Delete
2. Confirmation dialog
3. DELETE /api/users/seller/products/{id}/
4. Backend soft-deletes (status = ARCHIVED)
5. Removed from all marketplace queries
6. Historical data retained for:
   ├─ Order history
   ├─ Analytics
   └─ Audit trails
```

---

## 💾 PART 5: BACKEND API LAYER (DJANGO)

### 5.1 Serializers

```
Location: OPAS_Django/apps/users/seller_serializers.py

Serializer Classes:
├── SellerProductListSerializer (read-only)
│  └─ For GET /api/seller/products/ (optimized for lists)
│
├── SellerProductCreateUpdateSerializer (write)
│  └─ For POST/PUT with image handling
│
└── ProductImageSerializer
   └─ For nested image objects
```

### 5.2 ViewSets

```
Location: OPAS_Django/apps/users/seller_views.py

ProductManagementViewSet:
├── list(request)          → GET /api/users/seller/products/
├── create(request)        → POST /api/users/seller/products/
├── retrieve(request, pk)  → GET /api/users/seller/products/{id}/
├── update(request, pk)    → PUT /api/users/seller/products/{id}/
├── destroy(request, pk)   → DELETE /api/users/seller/products/{id}/
├── @action active()       → GET /api/users/seller/products/active/
├── @action expired()      → GET /api/users/seller/products/expired/
└── @action check_ceiling_price() → POST /api/users/seller/products/check_ceiling_price/

Permissions:
- IsAuthenticated: User must be logged in
- IsOPASSeller: User must be approved SELLER
```

### 5.3 URL Routing

```
Location: OPAS_Django/apps/users/urls.py

Router Configuration:
seller_router.register(
    r'seller/products',
    ProductManagementViewSet,
    basename='seller-products'
)

Generated URLs:
GET    /api/users/seller/products/
POST   /api/users/seller/products/
GET    /api/users/seller/products/{id}/
PUT    /api/users/seller/products/{id}/
DELETE /api/users/seller/products/{id}/
GET    /api/users/seller/products/active/
GET    /api/users/seller/products/expired/
POST   /api/users/seller/products/check_ceiling_price/
```

### 5.4 Buyer-Facing Endpoints

```
Location: OPAS_Django/apps/core/ or separate apps/products/

GET  /api/products/                 - Browse all products
GET  /api/products/{id}/            - Product details
GET  /api/seller/{id}/              - Seller profile
GET  /api/seller/{id}/reviews/      - Seller reviews
```

---

## 🔐 PART 6: SECURITY & PERMISSIONS

### 6.1 Authorization Flow

```
SELLER OPERATIONS:
1. User requests: POST /api/users/seller/products/
2. DRF checks IsAuthenticated
   └─ Verify user has valid JWT token
3. DRF checks IsOPASSeller
   └─ Verify user.role == 'SELLER'
   └─ Verify user.seller_status == 'APPROVED'
4. Both pass → Endpoint executes
5. Both fail → Return 403 Forbidden

BUYER OPERATIONS:
1. User requests: GET /api/products/
2. DRF checks IsAuthenticated (optional for public)
   └─ Allow anonymous or verified users
3. ViewSet filters results:
   └─ Only products from APPROVED sellers
   └─ Only ACTIVE products
   └─ Only products with stock > 0
```

### 6.2 Data Protection

```
Image Storage:
├── Location: /media/products/
├── Naming: UUID-based (e.g., abc123def456.jpg)
├── Permissions: Only owner can delete
└── URL: /media/products/{uuid}.jpg

Sensitive Data:
├── Seller financial info (hidden from buyers)
├── Seller personal info (limited visibility)
└── Price history (seller only, admin audit)
```

---

## 📊 PART 7: PERFORMANCE OPTIMIZATION

### 7.1 Database Optimization

```
Indexes:
- SellerProduct (seller_id, status) - Fast seller product filtering
- SellerProduct (created_at DESC) - Timeline sorting
- SellerProduct (product_type) - Category filtering
- ProductImage (product_id, is_primary) - Image retrieval

Query Optimization:
├── select_related('seller') - Avoid N+1 in seller field
├── prefetch_related('product_images') - Batch image queries
└── Only() fields - Return only needed columns
```

### 7.2 Caching Strategy

```
Cache Layers:

Level 1: Redis (5 minute TTL)
├── /api/products/?category=VEGETABLE (populated queries)
├── /api/products/{id}/ (popular products)
└── /api/seller/{id}/profile/ (seller info)

Level 2: Client-side (Flutter)
├── Product list (1 hour)
├── Product images (24 hours)
└── Seller profiles (24 hours)

Invalidation Triggers:
├── New product created
├── Product updated
├── Stock level changed
└── Price violation alert
```

### 7.3 API Pagination

```
Standard Pagination (20 items/page):
├── GET /api/products/?page=1
├── Response includes:
│  ├── count (total items)
│  ├── next (next page URL)
│  ├── previous (previous page URL)
│  └── results (items array)
└── Client implements infinite scroll
   └─ Load next page when user scrolls 80% down
```

---

## 🧪 PART 8: TESTING STRATEGY

### 8.1 Backend Tests

```
File: OPAS_Django/tests/api/test_seller_api.py

Test Cases:

1. Create Product Tests
   ├── Valid product creation
   ├── Price ceiling validation
   ├── Multiple image upload
   ├── Validation errors
   └── Unauthorized access

2. List Products Tests
   ├── Seller sees own products
   ├── Pagination works
   ├── Filtering by status
   ├── Search functionality
   └── No products returns empty list

3. Update Product Tests
   ├── Edit product details
   ├── Update images
   ├── Cannot edit category
   ├── Stock updates
   └── Price validation

4. Delete Product Tests
   ├── Soft delete works
   ├── Product no longer in marketplace
   ├── Order history preserved
   └── Permissions enforced

5. Buyer Browse Tests
   ├── Sees only ACTIVE products
   ├── Filter by category/price
   ├── Search works
   ├── Pagination
   └── No unauthorized data leak
```

### 8.2 Frontend Tests

```
File: OPAS_Flutter/test/features/seller_panel/

Test Cases:

1. AddProductScreen
   ├── Form validation
   ├── Image picker
   ├── Real-time price validation
   ├── API call success/failure
   └── Navigation after success

2. ProductListScreen
   ├── Display all products
   ├── Filter functionality
   ├── Search debouncing
   ├── Infinite scroll
   └── Refresh functionality

3. ProductDetailScreen
   ├── Image gallery swipe
   ├── Display product info
   ├── Seller info rendering
   ├── Reviews display
   └── Add to cart integration
```

---

## 📋 PART 9: IMPLEMENTATION CHECKLIST

### Phase 1: Backend Setup ✓
- [x] Create SellerProduct model
- [x] Create ProductImage model
- [x] Create ProductManagementViewSet
- [x] Implement all 8 endpoints
- [x] Add image upload handling
- [x] Price ceiling validation
- [x] Write backend tests
- [x] API documentation

### Phase 2: Frontend Seller Panel ✓
- [x] Create AddProductScreen
- [x] Create ProductListScreen
- [x] Create EditProductScreen
- [x] Implement image picker
- [x] Real-time price validation
- [x] Add SellerService methods
- [x] Image caching strategy
- [x] Form validation

### Phase 3: Frontend Buyer Marketplace ✓
- [x] Create ProductListScreen with filters
- [x] Create ProductDetailScreen
- [x] Create BuyerApiService methods
- [x] Image gallery implementation
- [x] Filter bottom sheet
- [x] Search with debounce
- [x] Infinite scroll pagination
- [x] Seller profile view

### Phase 4: Advanced Features
- [ ] Price history charts
- [ ] Related products recommendation
- [ ] Product reviews system
- [ ] Seller ratings aggregation
- [ ] Product analytics dashboard
- [ ] Inventory forecasting
- [ ] Auto-expiration system
- [ ] Batch product operations

### Phase 5: Performance & Scale
- [ ] Redis caching layer
- [ ] Image CDN integration
- [ ] Query optimization
- [ ] Load testing
- [ ] Database indexing audit
- [ ] API response time optimization

### Phase 6: Admin Features
- [ ] Price violation monitoring
- [ ] Marketplace analytics
- [ ] Seller performance metrics
- [ ] Product quality flags
- [ ] Compliance auditing

---

## 🔗 PART 10: KEY FILE REFERENCES

### Backend Files
```
OPAS_Django/
├── apps/users/
│  ├── seller_models.py          # SellerProduct, ProductImage models
│  ├── seller_serializers.py     # Serializers for products
│  ├── seller_views.py           # ProductManagementViewSet
│  ├── urls.py                   # Route configuration
│  └── seller_services.py        # Price validation, etc.
├── tests/api/
│  └── test_seller_api.py        # Backend tests
└── core/
   └── settings.py               # Media configuration
```

### Frontend Files
```
OPAS_Flutter/
├── lib/features/
│  ├── seller_panel/
│  │  ├── screens/
│  │  │  ├── add_product_screen.dart
│  │  │  ├── product_listing_screen.dart
│  │  │  ├── edit_product_screen.dart
│  │  │  └── inventory_listing_screen.dart
│  │  ├── services/
│  │  │  └── seller_service.dart
│  │  └── widgets/
│  │     ├── product_card.dart
│  │     └── image_picker_widget.dart
│  ├── marketplace/
│  │  ├── screens/
│  │  │  └── product_list_screen.dart
│  │  └── widgets/
│  │     └── filter_bottom_sheet.dart
│  ├── products/
│  │  ├── models/
│  │  │  ├── product_model.dart
│  │  │  └── review_model.dart
│  │  ├── screens/
│  │  │  └── product_detail_screen.dart
│  │  ├── services/
│  │  │  └── buyer_api_service.dart
│  │  └── widgets/
│  │     ├── product_card.dart
│  │     ├── image_gallery.dart
│  │     └── seller_info_card.dart
│  └── home/
│     └── screens/
│        └── buyer_home_screen.dart
├── core/
│  ├── models/
│  │  └── price_trend_model.dart
│  ├── services/
│  │  └── api_service.dart
│  └── routing/
│     └── seller_router.dart
└── test/
   └── features/
      ├── seller_panel/
      └── marketplace/
```

---

## 📞 PART 11: COMMON API RESPONSE PATTERNS

### Success Response (200/201)
```json
{
  "id": 123,
  "name": "Tomato",
  "category": "VEGETABLE",
  "price": "50.00",
  "stock": 100,
  "status": "ACTIVE",
  "images": [ { "id": 1, "image": "/media/products/abc.jpg", "is_primary": true } ],
  "created_at": "2025-11-26T10:30:00Z"
}
```

### List Response (200)
```json
{
  "count": 50,
  "next": "?page=2",
  "previous": null,
  "results": [ /* array of items */ ]
}
```

### Error Response (400/403/500)
```json
{
  "error": "Error message",
  "details": {
    "field_name": ["Field-specific error message"]
  }
}
```

---

## 🎯 PART 12: NEXT STEPS & ENHANCEMENTS

### Short-term (1-2 weeks)
1. [ ] Implement bulk product operations
2. [ ] Add product templates for sellers
3. [ ] Create seller product recommendations
4. [ ] Add product quality scoring

### Medium-term (1-2 months)
1. [ ] AI-powered product categorization
2. [ ] Automated price optimization
3. [ ] Product analytics dashboard
4. [ ] Review sentiment analysis
5. [ ] Demand forecasting visualization

### Long-term (3+ months)
1. [ ] Machine learning-based recommendations
2. [ ] Dynamic pricing automation
3. [ ] Supply chain optimization
4. [ ] Market analysis reports
5. [ ] Multi-language product support

---

## 📞 Support & Contact

For questions or updates to this implementation map:
- **Backend Lead:** Django team
- **Frontend Lead:** Flutter team
- **Product Manager:** Project lead
- **Documentation:** Keep this file updated with changes

---

**Last Updated:** November 26, 2025
**Version:** 1.0
**Status:** Complete & Production Ready ✅
