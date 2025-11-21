#!/usr/bin/env python3
"""
Test script to debug seller API endpoints
"""
import os
import sys
import django
import json
from django.conf import settings

# Add Django project to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import UserRole, SellerStatus

User = get_user_model()

def test_seller_endpoints():
    """Test seller product endpoints"""
    
    # Get first APPROVED seller user
    sellers = User.objects.filter(
        role='SELLER',
        seller_status='APPROVED'
    )
    
    if not sellers.exists():
        print("No approved sellers found!")
        print("Available sellers:")
        all_sellers = User.objects.filter(role='SELLER')
        for s in all_sellers:
            print(f"  - {s.email}: status={s.seller_status}, is_seller_approved={s.is_seller_approved}")
        return
    
    seller_user = sellers.first()
    print(f"Using seller: {seller_user.email}")
    print(f"Seller role: {seller_user.role}")
    print(f"Seller status: {seller_user.seller_status}")
    print(f"Is seller approved: {seller_user.is_seller_approved}")
    print(f"Username: {seller_user.username}")
    
    # Generate tokens
    refresh = RefreshToken.for_user(seller_user)
    access_token = str(refresh.access_token)
    
    print(f"\nAccess Token: {access_token[:50]}...")
    
    # Create API client
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
    
    # Test GET all products (should now include images)
    print("\n1. Testing GET /api/users/seller/products/")
    response = client.get('/api/users/seller/products/')
    print(f"Status: {response.status_code}")
    data = response.json()
    
    # Look for the first product with images
    found_with_images = False
    for product in data:
        if product.get('images') and len(product['images']) > 0:
            print(f"\nProduct {product['id']} with images:")
            print(json.dumps(product, indent=2))
            found_with_images = True
            break
    
    if not found_with_images:
        print(f"\nNo products with images found. Total products: {len(data)}")
        if data:
            print(f"First product sample:")
            print(json.dumps(data[0], indent=2))
    
    # Test POST product endpoint
    print("\n2. Testing POST /api/users/seller/products/")
    product_data = {
        'name': 'Test Product',
        'description': 'Test product description',
        'product_type': 'VEGETABLE',
        'price': 100.00,
        'stock_level': 50,
        'unit': 'kg',
        'category': 'Test'
    }
    response = client.post('/api/users/seller/products/', product_data, format='json')
    print(f"Status: {response.status_code}")
    try:
        print(f"Response: {response.json()}")
    except:
        print(f"Response (text): {response.text}")
    
    # Test uploading image
    print("\n3. Testing image upload")
    if response.status_code == 201:
        product_id = response.json()['id']
        print(f"Product ID: {product_id}")
        
        # Create a simple test image file
        from io import BytesIO
        from PIL import Image as PILImage
        
        # Create a simple image
        img = PILImage.new('RGB', (100, 100), color='red')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        
        # Upload image
        with open('test_image.jpg', 'wb') as f:
            f.write(img_bytes.getvalue())
        
        files = {'image': open('test_image.jpg', 'rb')}
        data = {'is_primary': 'true', 'alt_text': 'Test image'}
        response = client.post(
            f'/api/users/seller/products/{product_id}/upload_image/',
            data=data,
            files=files
        )
        print(f"Upload status: {response.status_code}")
        print(f"Upload response: {json.dumps(response.json(), indent=2)}")

if __name__ == '__main__':
    test_seller_endpoints()
