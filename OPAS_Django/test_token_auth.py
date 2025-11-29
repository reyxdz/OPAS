#!/usr/bin/env python
"""
Test with different token approaches
"""

import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from rest_framework_simplejwt.tokens import AccessToken
from apps.users.models import User
import json

def test_with_fresh_token():
    """Test order endpoint with a fresh token"""
    print("=" * 80)
    print("Testing Order Endpoint with Fresh Token")
    print("=" * 80)
    
    try:
        # Get buyer user
        buyer = User.objects.filter(role='BUYER').first()
        if not buyer:
            buyer = User.objects.get(id=43)
        
        # Generate fresh token
        token = AccessToken.for_user(buyer)
        print(f"\n✅ Buyer: {buyer.email} (ID: {buyer.id})")
        print(f"✅ Fresh Token: {str(token)[:80]}...")
        
        # Use APIClient
        client = Client()
        
        # First, let's check if we can access the endpoint without a token
        print("\n" + "=" * 80)
        print("Test 1: Without Token (should be 401)")
        print("=" * 80)
        
        response = client.post('/api/orders/create/', 
            json.dumps({'cart_items': [41], 'payment_method': 'pickup', 'delivery_address': 'Test'}),
            content_type='application/json'
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.content[:200]}")
        
        # Now with token
        print("\n" + "=" * 80)
        print("Test 2: With Fresh Token (should be 201)")
        print("=" * 80)
        
        response = client.post('/api/orders/create/',
            json.dumps({'cart_items': [41], 'payment_method': 'pickup', 'delivery_address': 'Test'}),
            content_type='application/json',
            HTTP_AUTHORIZATION=f'Bearer {str(token)}'
        )
        print(f"Status: {response.status_code}")
        if response.status_code == 201:
            print("✅ SUCCESS!")
            data = json.loads(response.content)
            print(f"Order #: {data.get('order_number')}")
        else:
            print(f"❌ Error: {response.content}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_with_fresh_token()
