#!/usr/bin/env python3
"""Check if product images exist in the database"""
import os
import sys
import django
from django.conf import settings

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import ProductImage, SellerProduct
from apps.users.models import User

print("Checking ProductImage records...")
total_images = ProductImage.objects.count()
print(f"Total ProductImage records: {total_images}")

if total_images > 0:
    for img in ProductImage.objects.all():
        print(f"\nImage ID: {img.id}")
        print(f"  Product: {img.product.name} (ID: {img.product.id})")
        print(f"  Seller: {img.product.seller.email} (ID: {img.product.seller.id})")
        print(f"  Image File: {img.image.name if img.image else 'None'}")
        print(f"  Image URL: {img.image.url if img.image else 'None'}")
        print(f"  Is Primary: {img.is_primary}")
else:
    print("No ProductImage records found!")

print("\n\nCurrent sellers:")
for user in User.objects.filter(role='SELLER'):
    products = SellerProduct.objects.filter(seller=user)
    images = ProductImage.objects.filter(product__seller=user)
    print(f"  - {user.email} (ID: {user.id})")
    print(f"    Products: {products.count()}")
    print(f"    Images: {images.count()}")
