#!/usr/bin/env python
"""
Test script to check what image URLs are returned by the API
"""
import os
import sys
import django

# Add the Django project to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Setup Django
django.setup()

from django.test import RequestFactory
from apps.users.seller_models import SellerProduct, ProductStatus
from apps.users.seller_serializers import SellerProductListSerializer

# Create a mock request
factory = RequestFactory()
request = factory.get('/api/admin/products/pending/')

# Get pending products
pending_products = SellerProduct.objects.filter(
    status=ProductStatus.PENDING
).select_related('seller').order_by('-created_at')[:5]

print(f"Found {pending_products.count()} pending products")

# Serialize them
serializer = SellerProductListSerializer(
    pending_products,
    many=True,
    context={'request': request}
)

# Print the serialized data
import json
data = serializer.data
print("\n=== API Response ===")
print(json.dumps(data, indent=2))

# Print image URLs specifically
print("\n=== Image URLs ===")
for product in data:
    print(f"Product: {product.get('name')}")
    print(f"  image_url: {product.get('image_url')}")
    print(f"  images: {product.get('images')}")
    print()
