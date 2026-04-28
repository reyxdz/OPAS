import os
import sys
import django

# Setup Django
sys.path.insert(0, '/BSCS-4B/Thesis/OPAS_Application/OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from apps.users.seller_models import SellerProduct, ProductImage
from django.core.files.base import ContentFile
from PIL import Image
from io import BytesIO

def create_sample_image(color_hex):
    """Create a simple PIL image with given color"""
    img = Image.new('RGB', (400, 300), color=color_hex)
    img_io = BytesIO()
    img.save(img_io, format='JPEG')
    img_io.seek(0)
    return img_io

colors = {
    1: 'FF6B6B',  # Red
    2: '4ECDC4',  # Teal
    3: 'FFE66D',  # Yellow
}

products = SellerProduct.objects.filter(id__in=[1, 2, 3])
for product in products:
    if product.product_images.exists():
        print(f'Product {product.id} already has images')
        continue
    
    color = colors.get(product.id, 'CCCCCC')
    img_io = create_sample_image(color)
    
    product_image = ProductImage(product=product, is_primary=True)
    product_image.image.save(f'sample_{product.id}.jpg', ContentFile(img_io.read()), save=True)
    print(f'Added image to product {product.id}')

print('\nVerifying:')
for p in SellerProduct.objects.all():
    print(f'Product {p.id}: {p.name} - Images: {p.product_images.count()}')
