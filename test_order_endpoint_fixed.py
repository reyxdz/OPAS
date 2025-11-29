#!/usr/bin/env python
"""Test the fixed order creation endpoint with proper response format"""

import requests
import json
from datetime import datetime

BASE_URL = 'http://127.0.0.1:8000/api'

def test_order_endpoint():
    """Test order creation endpoint with corrected response format"""
    print("=" * 80)
    print("Testing Order Endpoint with Fixed Response Format")
    print("=" * 80)
    
    # Use existing buyer and seller from previous tests
    buyer_token = "6dc6b52a4a7d7e2d9e8c3f8b5a1d7e2c9f0a3b5c"  # Existing buyer token
    
    # Cart items - using product IDs from previous tests
    cart_items = [1]  # Product ID 1 (Baboy Lechonon)
    
    payload = {
        'cart_items': cart_items,
        'payment_method': 'delivery',  # Using 'delivery' as fulfillment method
        'delivery_address': '123 Main Street, Luzon'
    }
    
    headers = {
        'Authorization': f'Bearer {buyer_token}',
        'Content-Type': 'application/json'
    }
    
    print(f"\nRequest URL: POST {BASE_URL}/orders/create/")
    print(f"Headers: {json.dumps(headers, indent=2)}")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f'{BASE_URL}/orders/create/',
            json=payload,
            headers=headers,
            timeout=10
        )
        
        print(f"\n{'Status Code:':<20} {response.status_code}")
        print(f"{'Response Headers:':<20} {dict(response.headers)}")
        
        try:
            response_data = response.json()
            print(f"\n{'Response Data:':<20}")
            print(json.dumps(response_data, indent=2))
            
            # Verify response structure matches Flutter Order model
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
                        print(f"✅ Items array present with {len(response_data['items'])} items")
                        for i, item in enumerate(response_data['items']):
                            print(f"\n   Item {i+1}:")
                            print(f"   - Product: {item.get('product_name')}")
                            print(f"   - Quantity: {item.get('quantity')}")
                            print(f"   - Price: {item.get('price_per_kilo')}")
                            print(f"   - Subtotal: {item.get('subtotal')}")
                    
                    print(f"\n📋 Order Summary:")
                    print(f"   - Order Number: {response_data.get('order_number')}")
                    print(f"   - Status: {response_data.get('status')}")
                    print(f"   - Total Amount: {response_data.get('total_amount')}")
                    print(f"   - Fulfillment: {response_data.get('payment_method')}")
                    print(f"   - Address: {response_data.get('delivery_address')}")
                    print(f"   - Buyer: {response_data.get('buyer_name')}")
                
        except ValueError as e:
            print(f"❌ Failed to parse JSON response: {e}")
            print(f"Response text: {response.text}")
    
    except requests.exceptions.Timeout:
        print("❌ Request timeout - server not responding")
    except Exception as e:
        print(f"❌ Request failed: {e}")
    
    print("\n" + "=" * 80)

if __name__ == '__main__':
    test_order_endpoint()
