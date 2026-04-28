"""Create test products with images"""
from apps.users.seller_models import SellerProduct, ProductStatus, ProductImage
from apps.users.models import User
from django.core.files.base import ContentFile
from PIL import Image
from io import BytesIO
from datetime import datetime, timedelta

def create_sample_image(color_hex):
    """Create a simple PIL image with given color"""
    # Convert hex to RGB tuple
    color = tuple(int(color_hex[i:i+2], 16) for i in (0, 2, 4))
    img = Image.new('RGB', (400, 300), color=color)
    img_io = BytesIO()
    img.save(img_io, format='JPEG')
    img_io.seek(0)
    return img_io

# Get the first seller (user)
seller = User.objects.filter(role='SELLER').first()
if not seller:
    print("No seller found!")
    exit(1)

print(f"Creating products for seller: {seller.full_name}")

# Product data
products_data = [
    {
        'name': 'Fresh Tomatoes',
        'description': 'Red, ripe tomatoes fresh from the farm',
        'product_type': 'VEGETABLE',
        'price': 50.00,
        'ceiling_price': 75.00,
        'stock_level': 100,
        'unit': 'kg',
        'quality_grade': 'PREMIUM',
        'color': 'FF6B6B',
    },
    {
        'name': 'Organic Lettuce',
        'description': 'Fresh organic lettuce, pesticide-free',
        'product_type': 'VEGETABLE',
        'price': 40.00,
        'ceiling_price': 60.00,
        'stock_level': 50,
        'unit': 'piece',
        'quality_grade': 'STANDARD',
        'color': '4ECDC4',
    },
    {
        'name': 'Ripe Bananas',
        'description': 'Golden ripe bananas, perfect for eating',
        'product_type': 'FRUIT',
        'price': 35.00,
        'ceiling_price': 50.00,
        'stock_level': 80,
        'unit': 'kg',
        'quality_grade': 'STANDARD',
        'color': 'FFE66D',
    },
]

for pdata in products_data:
    color = pdata.pop('color')
    
    # Create product
    product = SellerProduct.objects.create(
        seller=seller,
        status=ProductStatus.ACTIVE,
        listed_date=datetime.now(),
        **pdata
    )
    
    # Create image
    img_io = create_sample_image(color)
    product_image = ProductImage(product=product, is_primary=True)
    product_image.image.save(f'sample_{product.id}.jpg', ContentFile(img_io.read()), save=True)
    
    print(f'✓ Created {product.name} (ID: {product.id}) with image')

print('\nAll test products created!')
