#!/usr/bin/env python
"""
Detailed test of order endpoint with URL debugging
"""
import os
import sys
import django
import json

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, r'c:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

def test_endpoints():
    """Test the order endpoints"""
    
    # Get or create a test buyer
    buyer = User.objects.filter(phone_number='reyxdz').first()
    if not buyer:
        print("❌ Buyer 'reyxdz' not found")
        return
    
    # Create token
    refresh = RefreshToken.for_user(buyer)
    access_token = str(refresh.access_token)
    
    print("=" * 80)
    print("Testing Order Endpoints with Django Test Client")
    print("=" * 80)
    print(f"\nBuyer: {buyer.phone_number} (ID: {buyer.id})")
    print(f"Token: {access_token[:50]}...\n")
    
    # Get first product for cart
    from apps.products.models import Product
    from apps.cart.models import CartItem
    
    product = Product.objects.first()
    if not product:
        print("❌ No products in database")
        return
    
    # Create cart item
    cart_item = CartItem.objects.create(
        buyer=buyer,
        product=product,
        quantity=1
    )
    
    payload = {
        "cart_items": [cart_item.id],
        "payment_method": "delivery",
        "delivery_address": "Test Address"
    }
    
    client = Client()
    headers = {
        'HTTP_AUTHORIZATION': f'Bearer {access_token}',
        'CONTENT_TYPE': 'application/json'
    }
    
    # Test /api/orders/create/
    print("-" * 80)
    print("Testing: POST /api/orders/create/")
    print("-" * 80)
    response = client.post(
        '/api/orders/create/',
        data=json.dumps(payload),
        **headers
    )
    print(f"Status: {response.status_code}")
    if response.status_code in [200, 201]:
        print("✅ SUCCESS!")
        data = json.loads(response.content)
        print(f"Order ID: {data.get('id')}")
        print(f"Order #: {data.get('order_number')}")
    else:
        print(f"❌ FAILED: {response.content.decode()}")
    
    # Clean up
    cart_item.delete()

if __name__ == '__main__':
    test_endpoints()
