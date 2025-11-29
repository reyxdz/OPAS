#!/usr/bin/env python
"""Test the fixed order creation endpoint with proper response format"""

import requests
import json
import sys
import os

# Setup Django
sys.path.insert(0, os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

import django
django.setup()

from apps.users.models import User
from rest_framework_simplejwt.tokens import AccessToken

BASE_URL = 'http://127.0.0.1:8000/api'

def test_order_endpoint():
    """Test order creation endpoint"""
    print("=" * 80)
    print("Testing Order Endpoint with Fixed Response Format")
    print("=" * 80)
    
    # Create fresh token for buyer
    buyer = User.objects.get(id=43)
    buyer_token = str(AccessToken.for_user(buyer))
    print(f"\n✅ Created fresh token for {buyer.email} (ID: {buyer.id})")
    
    # Cart items
    cart_items = [41]  # Baboy Lechonon product
    
    payload = {
        'cart_items': cart_items,
        'payment_method': 'delivery',
        'delivery_address': '123 Main Street, Luzon'
    }
    
    headers = {
        'Authorization': f'Bearer {buyer_token}',
        'Content-Type': 'application/json'
    }
    
    print(f"\nRequest URL: POST {BASE_URL}/orders/create/")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f'{BASE_URL}/orders/create/',
            json=payload,
            headers=headers,
            timeout=10
        )
        
        print(f"\nStatus Code: {response.status_code}")
        
        try:
            response_data = response.json()
            print(f"\nResponse Data:")
            print(json.dumps(response_data, indent=2))
            
            # Verify response structure
            if response.status_code == 201:
                print("\n✅ Order Created Successfully!")
                
                # Check required fields
                required_fields = [
                    'id', 'order_number', 'items', 'total_amount', 'status',
                    'payment_method', 'created_at', 'delivery_address',
                    'buyer_name', 'buyer_phone'
                ]
                
                missing_fields = [f for f in required_fields if f not in response_data]
                if missing_fields:
                    print(f"❌ Missing fields: {missing_fields}")
                else:
                    print("✅ All required fields present!")
                    
                    # Verify items structure
                    if 'items' in response_data and isinstance(response_data['items'], list):
                        print(f"✅ Items array has {len(response_data['items'])} items")
                        for i, item in enumerate(response_data['items']):
                            print(f"\n   Item {i+1}:")
                            print(f"   - Product: {item.get('product_name')}")
                            print(f"   - Quantity: {item.get('quantity')}")
                            print(f"   - Price: {item.get('price_per_kilo')}")
                            print(f"   - Subtotal: {item.get('subtotal')}")
                    
                    print(f"\n📋 Order Summary:")
                    print(f"   - Order ID: {response_data.get('id')}")
                    print(f"   - Order Number: {response_data.get('order_number')}")
                    print(f"   - Status: {response_data.get('status')}")
                    print(f"   - Total: {response_data.get('total_amount')}")
                    print(f"   - Method: {response_data.get('payment_method')}")
            else:
                print(f"\n❌ Unexpected status code: {response.status_code}")
                
        except ValueError as e:
            print(f"❌ Failed to parse JSON: {e}")
            print(f"Response text: {response.text}")
    
    except Exception as e:
        print(f"❌ Request failed: {e}")
    
    print("\n" + "=" * 80)

if __name__ == '__main__':
    test_order_endpoint()
