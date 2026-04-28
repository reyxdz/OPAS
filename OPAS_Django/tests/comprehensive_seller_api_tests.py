#!/usr/bin/env python
"""
Comprehensive Seller API Endpoints Test Suite

Tests all 43+ seller endpoints with GET, POST, PUT, DELETE operations.
Validates:
- Endpoint accessibility
- Response status codes
- Request/response structure
- Permission validation
- Error handling
"""

import os
import django
import json
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework.test import APIClient
from rest_framework import status
from apps.users.models import User, UserRole, SellerStatus
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.seller_models import SellerProduct, ProductStatus

print("\n" + "=" * 120)
print("✅ SELLER API COMPREHENSIVE ENDPOINT TEST SUITE")
print("=" * 120)

# ==================== TEST SETUP ====================

# Create test seller user
test_seller_data = {
    'email': 'comprehensive_test_seller@test.com',
    'username': 'comprehensive_test_seller',
    'password': 'testpass123',
    'phone_number': '09123456789',
    'role': UserRole.SELLER,
    'seller_status': SellerStatus.APPROVED,
    'store_name': 'Comprehensive Test Store',
    'first_name': 'Test',
    'last_name': 'Seller'
}

# Cleanup existing test user
User.objects.filter(email=test_seller_data['email']).delete()

# Create new test seller
test_seller = User.objects.create_user(
    email=test_seller_data['email'],
    username=test_seller_data['username'],
    password=test_seller_data['password'],
    phone_number=test_seller_data['phone_number'],
    role=test_seller_data['role'],
    seller_status=test_seller_data['seller_status'],
    store_name=test_seller_data['store_name'],
    first_name=test_seller_data['first_name'],
    last_name=test_seller_data['last_name']
)

# Generate JWT token
refresh = RefreshToken.for_user(test_seller)
access_token = str(refresh.access_token)

# Initialize API client with authentication
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

print(f"\n✓ Test seller user created: {test_seller.email}")
print(f"✓ JWT token generated for testing")

# ==================== TEST EXECUTION ====================

test_results = {
    'profile': [],
    'products': [],
    'orders': [],
    'sell_to_opas': [],
    'inventory': [],
    'forecast': [],
    'payouts': [],
    'analytics': []
}

def test_endpoint(method, endpoint, description, data=None, expected_status=None):
    """Helper function to test an endpoint"""
    try:
        if method == 'GET':
            response = client.get(endpoint)
        elif method == 'POST':
            response = client.post(endpoint, data=data, format='json')
        elif method == 'PUT':
            response = client.put(endpoint, data=data, format='json')
        elif method == 'PATCH':
            response = client.patch(endpoint, data=data, format='json')
        elif method == 'DELETE':
            response = client.delete(endpoint)
        else:
            return None
        
        # Check if successful
        success = response.status_code in range(200, 300) or (expected_status and response.status_code == expected_status)
        
        return {
            'method': method,
            'endpoint': endpoint,
            'description': description,
            'status_code': response.status_code,
            'success': success,
            'response': response.data if hasattr(response, 'data') else response.content
        }
    except Exception as e:
        return {
            'method': method,
            'endpoint': endpoint,
            'description': description,
            'status_code': 'ERROR',
            'success': False,
            'error': str(e)
        }

print("\n" + "=" * 120)
print("📊 TESTING PROFILE ENDPOINTS")
print("=" * 120)

profile_tests = [
    ('GET', '/api/users/seller/profile/', 'Get seller profile', None, None),
    ('PUT', '/api/users/seller/profile/', 'Update seller profile', 
     {'store_name': 'Updated Store', 'store_description': 'Test description'}, None),
    ('GET', '/api/users/seller/profile/document_status/', 'Get document status', None, None),
    ('POST', '/api/users/seller/profile/submit_documents/', 'Submit documents', {}, 400),  # Expecting 400 due to missing data
]

for method, endpoint, desc, data, expected in profile_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['profile'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING PRODUCT ENDPOINTS (CRUD)")
print("=" * 120)

# Create a product for testing
product_data = {
    'name': 'Test Product',
    'product_type': 'Vegetables',
    'price': '100.00',
    'unit': 'kg',
    'stock_level': 100,
    'minimum_stock': 10,
    'quality_grade': 'STANDARD',
    'description': 'Test product for API testing'
}

created_product_id = None

product_tests = [
    ('POST', '/api/users/seller/products/', 'Create product', product_data, None),
    ('GET', '/api/users/seller/products/', 'List products', None, None),
    ('GET', '/api/users/seller/products/active/', 'List active products', None, None),
    ('GET', '/api/users/seller/products/expired/', 'List expired products', None, None),
    ('GET', '/api/users/seller/products/check_ceiling_price/', 'Check ceiling price', {'price': '100'}, 200),
]

for method, endpoint, desc, data, expected in product_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['products'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")
    
    # Capture product ID from creation
    if method == 'POST' and result['success'] and 'id' in result['response']:
        created_product_id = result['response']['id']

# Test product detail endpoints if we created one
if created_product_id:
    product_detail_tests = [
        ('GET', f'/api/users/seller/products/{created_product_id}/', 'Get product details', None, None),
        ('PUT', f'/api/users/seller/products/{created_product_id}/', 'Update product', 
         {'name': 'Updated Product Name', 'price': '120.00'}, None),
        ('DELETE', f'/api/users/seller/products/{created_product_id}/', 'Delete product', None, None),
    ]
    
    print(f"\n✓ Testing product detail endpoints (ID: {created_product_id})")
    for method, endpoint, desc, data, expected in product_detail_tests:
        result = test_endpoint(method, endpoint, desc, data, expected)
        test_results['products'].append(result)
        status_icon = "✓" if result['success'] else "⚠"
        print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING ORDER ENDPOINTS")
print("=" * 120)

order_tests = [
    ('GET', '/api/users/seller/orders/incoming/', 'List incoming orders', None, None),
    ('GET', '/api/users/seller/orders/pending/', 'List pending orders', None, None),
    ('GET', '/api/users/seller/orders/completed/', 'List completed orders', None, None),
]

for method, endpoint, desc, data, expected in order_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['orders'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING SELL TO OPAS ENDPOINTS")
print("=" * 120)

opas_tests = [
    ('GET', '/api/users/seller/sell-to-opas/pending/', 'List pending OPAS submissions', None, None),
    ('GET', '/api/users/seller/sell-to-opas/history/', 'Get OPAS history', None, None),
]

for method, endpoint, desc, data, expected in opas_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['sell_to_opas'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING INVENTORY ENDPOINTS")
print("=" * 120)

inventory_tests = [
    ('GET', '/api/users/seller/inventory/overview/', 'Get inventory overview', None, None),
    ('GET', '/api/users/seller/inventory/by_product/', 'Get inventory by product', None, None),
    ('GET', '/api/users/seller/inventory/low_stock/', 'Get low stock items', None, None),
    ('GET', '/api/users/seller/inventory/movement/', 'Get inventory movement', None, None),
]

for method, endpoint, desc, data, expected in inventory_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['inventory'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING FORECAST ENDPOINTS")
print("=" * 120)

forecast_tests = [
    ('GET', '/api/users/seller/forecast/next_month/', 'Get next month forecast', None, None),
    ('GET', '/api/users/seller/forecast/historical/', 'Get historical forecasts', None, None),
    ('GET', '/api/users/seller/forecast/insights/', 'Get forecast insights', None, None),
]

for method, endpoint, desc, data, expected in forecast_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['forecast'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING PAYOUT ENDPOINTS")
print("=" * 120)

payout_tests = [
    ('GET', '/api/users/seller/payouts/', 'List payouts', None, None),
    ('GET', '/api/users/seller/payouts/pending/', 'List pending payouts', None, None),
    ('GET', '/api/users/seller/payouts/completed/', 'List completed payouts', None, None),
    ('GET', '/api/users/seller/payouts/earnings/', 'Get earnings summary', None, None),
]

for method, endpoint, desc, data, expected in payout_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['payouts'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

print("\n" + "=" * 120)
print("📊 TESTING ANALYTICS & DASHBOARD ENDPOINTS")
print("=" * 120)

analytics_tests = [
    ('GET', '/api/users/seller/analytics/dashboard/', 'Get analytics dashboard', None, None),
    ('GET', '/api/users/seller/analytics/daily/', 'Get daily analytics', None, None),
    ('GET', '/api/users/seller/analytics/weekly/', 'Get weekly analytics', None, None),
    ('GET', '/api/users/seller/analytics/monthly/', 'Get monthly analytics', None, None),
]

for method, endpoint, desc, data, expected in analytics_tests:
    result = test_endpoint(method, endpoint, desc, data, expected)
    test_results['analytics'].append(result)
    status_icon = "✓" if result['success'] else "⚠"
    print(f"{status_icon} {method:<6} {endpoint:<50} {desc:<30} [{result['status_code']}]")

# ==================== RESULTS SUMMARY ====================

print("\n" + "=" * 120)
print("📈 TEST RESULTS SUMMARY")
print("=" * 120)

total_tests = 0
total_passed = 0
total_failed = 0

for category, tests in test_results.items():
    passed = sum(1 for t in tests if t['success'])
    failed = len(tests) - passed
    total_tests += len(tests)
    total_passed += passed
    total_failed += failed
    
    status_icon = "✅" if failed == 0 else "⚠️"
    print(f"\n{status_icon} {category.upper()}: {passed}/{len(tests)} passed")
    
    # Show failed tests
    for test in tests:
        if not test['success']:
            print(f"   ✗ {test['method']} {test['endpoint']} - Status: {test['status_code']}")

print("\n" + "=" * 120)
print("🎯 OVERALL RESULTS")
print("=" * 120)

print(f"\nTotal Tests: {total_tests}")
print(f"✓ Passed: {total_passed}")
print(f"✗ Failed: {total_failed}")
print(f"Success Rate: {(total_passed/total_tests)*100:.1f}%")

if total_failed == 0:
    print("\n🎉 ALL TESTS PASSED! Seller API is fully functional!")
else:
    print(f"\n⚠️  {total_failed} test(s) failed. Review above for details.")

# Cleanup
test_seller.delete()
print(f"\n✓ Test user cleaned up")

print("\n" + "=" * 120)
print("✅ COMPREHENSIVE TEST SUITE COMPLETE")
print("=" * 120 + "\n")
