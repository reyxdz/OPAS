#!/usr/bin/env python
"""Test the order creation endpoint"""
import os
import sys
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, '/c/BSCS-4B/Thesis/OPAS_Application/OPAS_Django')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from apps.users.seller_models import SellerProduct
from decimal import Decimal

User = get_user_model()

def test_order_creation():
    """Test creating an order"""
    client = Client()
    
    print("=" * 80)
    print("TESTING ORDER CREATION ENDPOINT")
    print("=" * 80)
    
    # Get existing test users or use any available users
    buyers = User.objects.filter(role='BUYER')[:1]
    sellers = User.objects.filter(role='SELLER')[:1]
    products = SellerProduct.objects.filter(stock_level__gt=0)[:1]
    
    if not buyers or not sellers or not products:
        print("✗ Missing test data (buyer, seller, or product)")
        print(f"  Buyers: {buyers.count()}")
        print(f"  Sellers: {sellers.count()}")  
        print(f"  Products: {products.count()}")
        return
    
    buyer = buyers[0]
    seller = sellers[0]
    product = products[0]
    
    print(f"\n✓ Using buyer: {buyer.email}")
    print(f"✓ Using seller: {seller.email}")
    print(f"✓ Using product: {product.name} (ID: {product.id}, Stock: {product.stock_level})")
    
    # Test unauthenticated request
    print("\n1. Testing unauthenticated request:")
    response = client.post(
        '/api/orders/create/',
        data=json.dumps({
            'cart_items': [product.id],
            'payment_method': 'delivery',
            'delivery_address': 'Test Address'
        }),
        content_type='application/json'
    )
    print(f"   Status: {response.status_code}")
    if response.status_code != 200:
        print(f"   (Expected: 401 Unauthorized)")
    
    # Test authenticated request
    print("\n2. Testing authenticated request:")
    # Force login with token (simulating API token auth)
    client.force_login(buyer)
    response = client.post(
        '/api/orders/create/',
        data=json.dumps({
            'cart_items': [product.id],
            'payment_method': 'delivery',
            'delivery_address': 'Test Address, City'
        }),
        content_type='application/json'
    )
    print(f"   Status: {response.status_code}")
    try:
        print(f"   Response: {response.json()}")
    except:
        print(f"   Response text: {response.content.decode()}")
    
    if response.status_code == 201:
        print("\n✓ Order creation successful!")
    else:
        print(f"\n✗ Order creation returned status {response.status_code}")
    
    print("\n" + "=" * 80)

if __name__ == '__main__':
    test_order_creation()

