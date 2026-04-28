#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Direct test of order endpoint using Django test client
No need to run the server separately
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from django.contrib.auth.models import AnonymousUser
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken
from apps.users.models import User
import json

def test_order_endpoint():
    """Test order creation without running server"""
    print("=" * 80)
    print("Testing Order Endpoint (Direct Django Test)")
    print("=" * 80)
    
    try:
        # Get buyer user
        buyer = User.objects.get(id=43)
        token = str(AccessToken.for_user(buyer))
        
        print(f"\n[OK] Using buyer: {buyer.email} (ID: {buyer.id})")
        print(f"[OK] Generated token: {token[:50]}...")
        
        # Use APIClient to test
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        payload = {
            'cart_items': [41],
            'payment_method': 'delivery',
            'delivery_address': '123 Main Street, Luzon'
        }
        
        print(f"\n[SEND] Sending POST to /api/orders/create/")
        print(f"   Payload: {json.dumps(payload, indent=2)}")
        
        response = client.post('/api/orders/create/', payload, format='json')
        
        print(f"\n[RECV] Response Status: {response.status_code}")
        
        if response.status_code in [200, 201]:
            print("[OK] SUCCESS!")
            data = response.json()
            print(f"\n[INFO] Order Details:")
            print(f"   ID: {data.get('id')}")
            print(f"   Order #: {data.get('order_number')}")
            print(f"   Status: {data.get('status')}")
            print(f"   Total: {data.get('total_amount')}")
            print(f"   Method: {data.get('payment_method')}")
            print(f"   Address: {data.get('delivery_address')}")
            print(f"   Buyer: {data.get('buyer_name')}")
            print(f"   Items: {len(data.get('items', []))} item(s)")
            
            if 'items' in data and data['items']:
                print(f"\n   Item 1:")
                item = data['items'][0]
                print(f"   - Product: {item.get('product_name')}")
                print(f"   - Quantity: {item.get('quantity')}")
                print(f"   - Price: {item.get('price_per_kilo')}")
            
            return True
        else:
            print(f"[ERROR] Error: {response.status_code}")
            print(f"Response: {response.json()}")
            return False
            
    except Exception as e:
        print(f"[ERROR] Exception: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    success = test_order_endpoint()
    sys.exit(0 if success else 1)
