#!/usr/bin/env python
"""Create test product images for OPAS submission product."""

import os
import sys
import django
from pathlib import Path

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, str(Path(__file__).parent))
django.setup()

from apps.users.seller_models import ProductImage, SellerProduct
from django.core.files.base import ContentFile
from PIL import Image as PILImage
import io

# Get the product
product = SellerProduct.objects.get(id=60)

# Create a test image
img = PILImage.new('RGB', (200, 200), color='red')
img_io = io.BytesIO()
img.save(img_io, format='JPEG')
img_io.seek(0)

# Create product images
for i in range(3):
    image_name = f'test_image_{i+1}.jpg'
    img_io.seek(0)
    product_image = ProductImage.objects.create(
        product=product,
        image=ContentFile(img_io.getvalue(), name=image_name),
        is_primary=(i == 0),
        order=i,
        alt_text=f'Test product image {i+1}'
    )
    print(f'Created image {product_image.id}: {product_image.image.url}')

print(f'\nTotal images for {product.name}: {ProductImage.objects.filter(product=product).count()}')
