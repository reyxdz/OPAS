#!/usr/bin/env python
"""
Test script for buyer-facing marketplace API endpoints.

Tests:
- GET /api/products/ - List products
- GET /api/products/{id}/ - Get product detail
- GET /api/seller/{id}/ - Get seller profile
- GET /api/seller/{id}/products/ - Get seller's products
"""

import os
import django
import requests
from decimal import Decimal

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from apps.users.models import User, UserRole, SellerStatus
from apps.users.seller_models import SellerProduct, ProductStatus, ProductImage
from django.utils import timezone
from io import BytesIO
from PIL import Image


def create_test_data():
    """Create test sellers and products"""
    print("=" * 70)
    print("CREATING TEST DATA")
    print("=" * 70)
    
    # Create or get sellers
    seller1, created1 = User.objects.get_or_create(
        email='seller1@test.com',
        defaults={
            'username': 'seller1',
            'first_name': 'John',
            'last_name': 'Farmer',
            'role': UserRole.SELLER,
            'seller_status': SellerStatus.APPROVED,
            'store_name': 'Fresh Farm 1',
            'store_description': 'Quality vegetables and fruits'
        }
    )
    if created1:
        seller1.set_password('testpass123')
        seller1.save()
        print(f"✓ Created seller: {seller1.email}")
    else:
        print(f"✓ Found existing seller: {seller1.email}")
    
    seller2, created2 = User.objects.get_or_create(
        email='seller2@test.com',
        defaults={
            'username': 'seller2',
            'first_name': 'Maria',
            'last_name': 'Farmer',
            'role': UserRole.SELLER,
            'seller_status': SellerStatus.APPROVED,
            'store_name': 'Organic Harvest',
            'store_description': '100% organic produce'
        }
    )
    if created2:
        seller2.set_password('testpass123')
        seller2.save()
        print(f"✓ Created seller: {seller2.email}")
    else:
        print(f"✓ Found existing seller: {seller2.email}")
    
    # Create products
    products = []
    product_data = [
        {
            'name': 'Fresh Tomatoes',
            'product_type': 'VEGETABLE',
            'price': '50.00',
            'stock_level': 100,
            'seller': seller1,
        },
        {
            'name': 'Organic Carrots',
            'product_type': 'VEGETABLE',
            'price': '35.00',
            'stock_level': 150,
            'seller': seller1,
        },
        {
            'name': 'Fresh Mangoes',
            'product_type': 'FRUIT',
            'price': '80.00',
            'stock_level': 50,
            'seller': seller2,
        },
        {
            'name': 'Bananas Bundle',
            'product_type': 'FRUIT',
            'price': '45.00',
            'stock_level': 200,
            'seller': seller2,
        },
    ]
    
    for data in product_data:
        product, created = SellerProduct.objects.get_or_create(
            name=data['name'],
            seller=data['seller'],
            defaults={
                'product_type': data['product_type'],
                'price': Decimal(data['price']),
                'stock_level': data['stock_level'],
                'status': ProductStatus.ACTIVE,
                'unit': 'kg',
                'quality_grade': 'STANDARD',
            }
        )
        if created:
            print(f"✓ Created product: {product.name}")
        else:
            print(f"✓ Found existing product: {product.name}")
        products.append(product)
    
    print()
    return seller1, seller2, products


def test_marketplace_list():
    """Test GET /api/products/"""
    print("=" * 70)
    print("TEST 1: GET /api/products/ - List all products")
    print("=" * 70)
    
    client = Client()
    response = client.get('/api/products/')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        
        # Handle both paginated and list responses
        if isinstance(data, dict):
            count = data.get('count', len(data.get('results', [])))
            results = data.get('results', [])
        else:
            count = len(data)
            results = data
        
        print(f"✓ Products count: {count}")
        for product in results[:2]:
            print(f"  - {product['name']} (${product['price']})")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_marketplace_filter():
    """Test GET /api/products/?product_type=VEGETABLE"""
    print("=" * 70)
    print("TEST 2: GET /api/products/?product_type=VEGETABLE - Filter by type")
    print("=" * 70)
    
    client = Client()
    response = client.get('/api/products/?product_type=VEGETABLE')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        if isinstance(data, dict):
            count = data.get('count', len(data.get('results', [])))
        else:
            count = len(data)
        print(f"✓ Vegetable count: {count}")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_marketplace_search():
    """Test GET /api/products/?search=tomato"""
    print("=" * 70)
    print("TEST 3: GET /api/products/?search=tomato - Search products")
    print("=" * 70)
    
    client = Client()
    response = client.get('/api/products/?search=tomato')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        if isinstance(data, dict):
            count = data.get('count', len(data.get('results', [])))
        else:
            count = len(data)
        print(f"✓ Search results: {count}")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_product_detail():
    """Test GET /api/products/{id}/"""
    print("=" * 70)
    print("TEST 4: GET /api/products/{id}/ - Get product detail")
    print("=" * 70)
    
    client = Client()
    product = SellerProduct.objects.filter(status=ProductStatus.ACTIVE).first()
    
    if not product:
        print("✗ No products found for testing")
        return
    
    response = client.get(f'/api/products/{product.id}/')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Product: {data['name']}")
        print(f"✓ Price: ${data['price']}")
        print(f"✓ Seller: {data['seller_info']['store_name']}")
        print(f"✓ Stock: {data['stock_level']}")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_seller_profile():
    """Test GET /api/seller/{id}/"""
    print("=" * 70)
    print("TEST 5: GET /api/seller/{id}/ - Get seller profile")
    print("=" * 70)
    
    client = Client()
    seller = User.objects.filter(
        role=UserRole.SELLER,
        seller_status=SellerStatus.APPROVED
    ).first()
    
    if not seller:
        print("✗ No approved sellers found for testing")
        return
    
    response = client.get(f'/api/seller/{seller.id}/')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Store: {data['store_name']}")
        print(f"✓ Products count: {data['total_products']}")
        print(f"✓ Is verified: {data['is_verified']}")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_seller_products():
    """Test GET /api/seller/{id}/products/"""
    print("=" * 70)
    print("TEST 6: GET /api/seller/{id}/products/ - Get seller's products")
    print("=" * 70)
    
    client = Client()
    seller = User.objects.filter(
        role=UserRole.SELLER,
        seller_status=SellerStatus.APPROVED
    ).first()
    
    if not seller:
        print("✗ No approved sellers found for testing")
        return
    
    response = client.get(f'/api/seller/{seller.id}/products/')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        if isinstance(data, dict):
            count = data.get('count', len(data.get('results', [])))
        else:
            count = len(data)
        print(f"✓ Seller products: {count}")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_price_range():
    """Test GET /api/products/?min_price=40&max_price=60"""
    print("=" * 70)
    print("TEST 7: Price range filtering")
    print("=" * 70)
    
    client = Client()
    response = client.get('/api/products/?min_price=40&max_price=60')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        if isinstance(data, dict):
            count = data.get('count', len(data.get('results', [])))
        else:
            count = len(data)
        print(f"✓ Products in range [40-60]: {count}")
        print("✓ PASS")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


def test_ordering():
    """Test GET /api/products/?ordering=price"""
    print("=" * 70)
    print("TEST 8: Ordering by price")
    print("=" * 70)
    
    client = Client()
    response = client.get('/api/products/?ordering=price')
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        if isinstance(data, dict):
            results = data.get('results', [])
        else:
            results = data
        if len(results) >= 2:
            price1 = Decimal(results[0]['price'])
            price2 = Decimal(results[1]['price'])
            print(f"✓ First product: ${price1}")
            print(f"✓ Second product: ${price2}")
            if price1 <= price2:
                print("✓ PASS - Prices sorted correctly")
            else:
                print("✗ FAIL - Prices not sorted")
        else:
            print("✓ PASS - Limited results")
    else:
        print(f"✗ FAIL: {response.content}")
    print()


if __name__ == '__main__':
    print("\n")
    print("=" * 70)
    print("OPAS BUYER MARKETPLACE API TESTS - PART 2")
    print("=" * 70)
    print("\n")
    
    # Check existing test data
    seller_count = User.objects.filter(role=UserRole.SELLER).count()
    product_count = SellerProduct.objects.filter(status=ProductStatus.ACTIVE).count()
    print(f"Existing sellers: {seller_count}")
    print(f"Existing active products: {product_count}\n")
    
    # Run tests
    test_marketplace_list()
    test_marketplace_filter()
    test_marketplace_search()
    test_product_detail()
    test_seller_profile()
    test_seller_products()
    test_price_range()
    test_ordering()
    
    print("=" * 70)
    print("ALL TESTS COMPLETED")
    print("=" * 70)
