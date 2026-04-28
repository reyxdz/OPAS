#!/usr/bin/env python
"""
Test URL routing for order endpoints
"""
import os
import sys
import django
import json
from django.test import Client
from django.contrib.auth import get_user_model

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, r'c:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
django.setup()

from rest_framework_simplejwt.tokens import RefreshToken
from apps.cart.models import CartItem
from apps.products.models import Product

User = get_user_model()

def test_order_endpoints():
    """Test both possible order endpoints"""
    
    # Get or create a test buyer
    buyer, _ = User.objects.get_or_create(
        phone_number='test_buyer_routing@test.com',
        defaults={
            'role': 'buyer',
            'is_active': True,
        }
    )
    
    # Create a refresh token for the buyer
    refresh = RefreshToken.for_user(buyer)
    access_token = str(refresh.access_token)
    
    print("=" * 80)
    print("Testing Order Endpoints")
    print("=" * 80)
    print(f"\nUsing buyer: {buyer.phone_number} (ID: {buyer.id})")
    print(f"Token: {access_token[:50]}...")
    
    # Get a product for cart
    product = Product.objects.first()
    if not product:
        print("❌ No products found in database")
        return
    
    # Create a cart item
    cart_item = CartItem.objects.create(
        buyer=buyer,
        product=product,
        quantity=1
    )
    print(f"✓ Created cart item: {product.name}")
    
    # Prepare request payload
    payload = {
        "cart_items": [cart_item.id],
        "payment_method": "delivery",
        "delivery_address": "Test Address, Test City"
    }
    
    client = Client()
    
    # Test endpoint 1: /api/orders/create/
    print("\n" + "-" * 80)
    print("Test 1: POST /api/orders/create/")
    print("-" * 80)
    try:
        response = client.post(
            '/api/orders/create/',
            data=json.dumps(payload),
            content_type='application/json',
            HTTP_AUTHORIZATION=f'Bearer {access_token}'
        )
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✓ SUCCESS: {response.content.decode()[:200]}")
        else:
            print(f"✗ FAILED: {response.content.decode()}")
    except Exception as e:
        print(f"✗ ERROR: {e}")
    
    # Test endpoint 2: /api/users/orders/create/
    print("\n" + "-" * 80)
    print("Test 2: POST /api/users/orders/create/")
    print("-" * 80)
    try:
        response = client.post(
            '/api/users/orders/create/',
            data=json.dumps(payload),
            content_type='application/json',
            HTTP_AUTHORIZATION=f'Bearer {access_token}'
        )
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✓ SUCCESS: {response.content.decode()[:200]}")
        else:
            print(f"✗ FAILED: {response.content.decode()}")
    except Exception as e:
        print(f"✗ ERROR: {e}")
    
    # Clean up
    cart_item.delete()

if __name__ == '__main__':
    test_order_endpoints()
