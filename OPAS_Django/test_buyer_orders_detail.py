#!/usr/bin/env python
"""
Detailed test of buyer orders API - check full response format
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

def test_buyer_orders_detail():
    """Test the buyer orders endpoint - detailed response"""
    
    buyer = User.objects.get(id=43)
    refresh = RefreshToken.for_user(buyer)
    access_token = str(refresh.access_token)
    
    print("=" * 80)
    print("Detailed Buyer Orders API Response Test")
    print("=" * 80)
    
    client = Client()
    headers = {
        'HTTP_AUTHORIZATION': f'Bearer {access_token}',
        'CONTENT_TYPE': 'application/json'
    }
    
    response = client.get('/api/orders/', **headers)
    
    if response.status_code == 200:
        data = json.loads(response.content)
        orders = data if isinstance(data, list) else data.get('results', [])
        
        print(f"\n✅ API Response - Status 200")
        print(f"Total Orders: {len(orders)}\n")
        
        if orders:
            first_order = orders[0]
            print("First Order Structure:")
            print(json.dumps(first_order, indent=2, default=str))
    else:
        print(f"❌ Failed: {response.status_code}")
        print(response.content.decode())

if __name__ == '__main__':
    test_buyer_orders_detail()
