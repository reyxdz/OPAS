#!/usr/bin/env python
"""
Test buyer orders API endpoint
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

def test_buyer_orders():
    """Test the buyer orders endpoint"""
    
    # Get buyer user with ID 43
    buyer = User.objects.get(id=43)
    if not buyer:
        print("❌ Buyer user not found")
        return
    
    # Create token
    refresh = RefreshToken.for_user(buyer)
    access_token = str(refresh.access_token)
    
    print("=" * 80)
    print("Testing Buyer Orders API Endpoint")
    print("=" * 80)
    print(f"\nBuyer: {buyer.phone_number} (ID: {buyer.id}, Role: {buyer.role})")
    print(f"Token: {access_token[:50]}...\n")
    
    client = Client()
    headers = {
        'HTTP_AUTHORIZATION': f'Bearer {access_token}',
        'CONTENT_TYPE': 'application/json'
    }
    
    # Test GET /api/orders/
    print("-" * 80)
    print("Testing: GET /api/orders/")
    print("-" * 80)
    response = client.get(
        '/api/orders/',
        **headers
    )
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        try:
            data = json.loads(response.content)
            print("✅ SUCCESS!")
            
            # Handle paginated response
            if isinstance(data, dict) and 'results' in data:
                orders = data['results']
                print(f"Found {len(orders)} orders (paginated)")
            else:
                orders = data if isinstance(data, list) else [data]
                print(f"Found {len(orders)} order(s)")
            
            if orders:
                print("\nFirst Order:")
                first_order = orders[0]
                print(f"  Order #: {first_order.get('order_number')}")
                print(f"  Status: {first_order.get('status')}")
                print(f"  Total: ₱{first_order.get('total_amount')}")
                print(f"  Items: {len(first_order.get('items', []))}")
                
                if first_order.get('items'):
                    print(f"  First Item: {first_order['items'][0].get('product_name')}")
            else:
                print("No orders found (user may not have any orders)")
        except Exception as e:
            print(f"Error parsing response: {e}")
            print(f"Response: {response.content.decode()}")
    else:
        print(f"❌ FAILED: {response.content.decode()}")

if __name__ == '__main__':
    test_buyer_orders()
