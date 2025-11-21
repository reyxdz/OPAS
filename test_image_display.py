#!/usr/bin/env python3
"""
Test script to check product image display
"""
import os
import sys
import django
import json
from django.conf import settings

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.seller_models import SellerProduct, ProductImage

User = get_user_model()

# Check all sellers and their images
print("All sellers and their images:")
for seller in User.objects.filter(role='SELLER'):
    products_with_images = SellerProduct.objects.filter(
        seller=seller,
        product_images__isnull=False
    ).distinct()
    
    if products_with_images.exists():
        print(f"\n{seller.email}:")
        for product in products_with_images:
            print(f"  Product {product.id}: {product.name}")
            for img in product.product_images.all():
                print(f"    - Image {img.id}: Primary={img.is_primary}, File={img.image.name}")

# Use the seller that actually has images
seller_with_images = None
for seller in User.objects.filter(role='SELLER'):
    if SellerProduct.objects.filter(seller=seller, product_images__isnull=False).exists():
        seller_with_images = seller
        break

if not seller_with_images:
    print("\nNo sellers with images found!")
    sys.exit(1)

seller_user = seller_with_images
print(f"\n\nUsing seller with images: {seller_user.email}")

# Generate tokens
refresh = RefreshToken.for_user(seller_user)
access_token = str(refresh.access_token)

# Create API client
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

# Test the check ceiling price endpoint
print("\n" + "="*60)
print("Testing check_ceiling_price endpoint")
print("="*60)

response = client.post(
    '/api/users/seller/products/check_ceiling_price/',
    {'product_type': 'VEGETABLE'},
    format='json'
)
print(f"\nPOST /api/users/seller/products/check_ceiling_price/ Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")

# Now test the main API
print("\n" + "="*60)
print("Testing product listing with images")
print("="*60)

# Get products
response = client.get('/api/users/seller/products/')
print(f"\nGET /api/users/seller/products/ Status: {response.status_code}")
data = response.json()

# Find first product with images
for product in data:
    if product.get('images') and len(product['images']) > 0:
        print(f"\nProduct {product['id']} - Full Response:")
        print(json.dumps(product, indent=2))
        break
else:
    print("\nNo products with images in API response!")
    if data:
        print(f"\nFirst product:")
        print(json.dumps(data[0], indent=2))
