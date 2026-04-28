#!/usr/bin/env python
"""
Test script to verify the buyer order API endpoints are working correctly.
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, '/c/BSCS-4B/Thesis/OPAS_Application/OPAS_Django')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from apps.users.seller_models import SellerProduct, OrderStatus
from decimal import Decimal
import json

User = get_user_model()

def test_order_endpoints():
    """Test that order endpoints are accessible"""
    client = Client()
    
    print("=" * 60)
    print("Testing Buyer Order API Endpoints")
    print("=" * 60)
    
    # Check if buyers can access the create order endpoint
    print("\n1. Testing POST /api/orders/create/ endpoint...")
    
    # Create test users
    try:
        buyer = User.objects.create_user(
            email='buyer@test.com',
            password='testpass123',
            first_name='Test',
            last_name='Buyer',
            role='BUYER'
        )
        print(f"   ✓ Created test buyer: {buyer.email}")
    except Exception as e:
        print(f"   ✗ Error creating buyer: {e}")
        buyer = User.objects.filter(email='buyer@test.com').first()
        if not buyer:
            return
    
    try:
        seller = User.objects.create_user(
            email='seller@test.com',
            password='testpass123',
            first_name='Test',
            last_name='Seller',
            role='SELLER'
        )
        print(f"   ✓ Created test seller: {seller.email}")
    except Exception as e:
        print(f"   ✗ Error creating seller: {e}")
        seller = User.objects.filter(email='seller@test.com').first()
        if not seller:
            return
    
    # Create test product
    try:
        product = SellerProduct.objects.create(
            seller=seller,
            name='Test Product',
            description='Test product description',
            price=Decimal('100.00'),
            unit='kg',
            stock_level=10,
            status='ACTIVE'
        )
        print(f"   ✓ Created test product: {product.name} (ID: {product.id})")
    except Exception as e:
        print(f"   ✗ Error creating product: {e}")
        return
    
    # Login buyer
    print("\n2. Testing authentication...")
    login_success = client.login(username='buyer@test.com', password='testpass123')
    if login_success:
        print(f"   ✓ Buyer logged in successfully")
    else:
        print(f"   ✗ Failed to login buyer")
        return
    
    # Test creating order
    print("\n3. Testing order creation...")
    order_data = {
        'cart_items': [product.id],
        'payment_method': 'delivery',
        'delivery_address': 'Test Address, Test City'
    }
    
    response = client.post(
        '/api/orders/create/',
        data=json.dumps(order_data),
        content_type='application/json'
    )
    
    print(f"   Response status: {response.status_code}")
    print(f"   Response data: {response.json()}")
    
    if response.status_code in [200, 201]:
        print("   ✓ Order creation successful!")
    else:
        print(f"   ✗ Order creation failed with status {response.status_code}")
    
    print("\n" + "=" * 60)
    print("Test completed!")
    print("=" * 60)

if __name__ == '__main__':
    test_order_endpoints()
