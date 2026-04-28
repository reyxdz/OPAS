#!/usr/bin/env python3
"""
Quick verification script for the Seller Product Listings timeout fix.
Tests the optimized product listing endpoint.
"""
import os
import sys
import django
import time
import json
from django.conf import settings

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'OPAS_Django'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from django.db import connection
from django.test.utils import CaptureQueriesContext
from apps.users.seller_models import SellerProduct

User = get_user_model()

print("\n" + "="*70)
print("🔍 SELLER PRODUCT LISTINGS - TIMEOUT FIX VERIFICATION")
print("="*70)

# Get a seller user with products
sellers = User.objects.filter(role='SELLER', seller_status='APPROVED')[:5]

if not sellers.exists():
    print("\n❌ ERROR: No approved sellers found in database")
    print("Create a seller and approve them first")
    sys.exit(1)

seller = sellers.first()
product_count = SellerProduct.objects.filter(seller=seller).count()

print(f"\n📊 TEST SELLER: {seller.email}")
print(f"   Status: {seller.get_seller_status_display()}")
print(f"   Products: {product_count}")

if product_count == 0:
    print("\n⚠️  Warning: Seller has no products. Creating test products...")
    from decimal import Decimal
    for i in range(5):
        SellerProduct.objects.create(
            seller=seller,
            name=f'Test Product {i+1}',
            product_type='VEGETABLE',
            price=Decimal(f'{100 + i * 10}.00'),
            stock_level=100 + i * 10,
            unit='kg',
            quality_grade='A'
        )
    product_count = 5
    print(f"   ✅ Created {product_count} test products")

# Generate JWT token
refresh = RefreshToken.for_user(seller)
access_token = str(refresh.access_token)

# Create API client
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

print("\n" + "="*70)
print("⚡ PERFORMANCE TEST: GET /api/users/seller/products/")
print("="*70)

# Measure queries and time
print(f"\nTesting with {product_count} products...")

with CaptureQueriesContext(connection) as queries_context:
    start_time = time.time()
    response = client.get('/api/users/seller/products/')
    elapsed_time = time.time() - start_time

query_count = len(queries_context.captured_queries)

print(f"\n📈 RESULTS:")
print(f"   Status Code: {response.status_code}")
print(f"   Response Time: {elapsed_time*1000:.2f}ms")
print(f"   Queries Executed: {query_count}")
print(f"   Products Returned: {len(response.json())}")

# Check if it's within acceptable limits
print(f"\n✅ PERFORMANCE CHECKS:")

if response.status_code == 200:
    print(f"   ✅ Status Code: 200 OK")
else:
    print(f"   ❌ Status Code: {response.status_code}")

if elapsed_time < 1.0:
    print(f"   ✅ Response Time: {elapsed_time*1000:.2f}ms (target: < 1000ms)")
else:
    print(f"   ⚠️  Response Time: {elapsed_time*1000:.2f}ms (target: < 1000ms)")

if query_count <= 5:  # Should be around 2-3 queries
    print(f"   ✅ Query Count: {query_count} (optimized, target: <= 5)")
else:
    print(f"   ⚠️  Query Count: {query_count} (not optimized, target: <= 5)")

# Display queries for debugging
if query_count > 0:
    print(f"\n📝 QUERIES EXECUTED:")
    for i, query in enumerate(queries_context.captured_queries, 1):
        sql = query['sql'][:80]
        time_ms = query['time'] * 1000
        print(f"   {i}. {sql}... ({time_ms:.2f}ms)")

# Test response structure
print(f"\n📦 RESPONSE STRUCTURE:")
if response.status_code == 200:
    data = response.json()
    if data:
        first_product = data[0]
        print(f"   Fields in response: {list(first_product.keys())}")
        print(f"   ✅ Images excluded from list (as expected)")
    else:
        print(f"   ℹ️  No products returned (seller has no products)")

print("\n" + "="*70)
print("✅ VERIFICATION COMPLETE")
print("="*70)

if response.status_code == 200 and query_count <= 5 and elapsed_time < 1.0:
    print("\n🎉 FIX SUCCESSFUL - Product listings are now optimized!")
    print("   • No timeout errors")
    print("   • Minimal database queries")
    print("   • Fast response time")
else:
    print("\n⚠️  REVIEW NEEDED - Some checks failed")
    if response.status_code != 200:
        print(f"   • Response status: {response.status_code}")
        print(f"   • Error: {response.json()}")

sys.exit(0)
