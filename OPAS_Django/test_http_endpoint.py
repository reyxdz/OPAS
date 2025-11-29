#!/usr/bin/env python
"""
Test the order endpoint via HTTP with detailed debugging
"""
import requests
import json
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, r'c:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.seller_models import SellerProduct

User = get_user_model()

# Get buyer
buyer = User.objects.filter(role='buyer').first()
if not buyer:
    print("❌ No buyer found")
    sys.exit(1)

# Create token
refresh = RefreshToken.for_user(buyer)
access_token = str(refresh.access_token)

# Get product
product = SellerProduct.objects.first()
if not product:
    print("❌ No product found")
    sys.exit(1)

# Just use product IDs for cart items
cart_item_ids = [product.id]

headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json'
}

print("=" * 80)
print("Testing /api/orders/create/ via HTTP")
print("=" * 80)
print(f"\nBuyer: {buyer.phone_number}")
print(f"Token: {access_token[:50]}...")
print(f"Payload: {json.dumps(payload, indent=2)}")
print(f"\nHeaders:")
for k, v in headers.items():
    if k == 'Authorization':
        print(f"  {k}: {v[:50]}...")
    else:
        print(f"  {k}: {v}")

print("\n" + "-" * 80)
print("POST http://localhost:8000/api/orders/create/")
print("-" * 80)

try:
    response = requests.post(
        'http://localhost:8000/api/orders/create/',
        json=payload,
        headers=headers,
        timeout=10
    )
    
    print(f"Status: {response.status_code}")
    print(f"Headers: {dict(response.headers)}")
    print(f"Body:")
    try:
        print(json.dumps(response.json(), indent=2))
    except:
        print(response.text)
        
except requests.exceptions.ConnectionError as e:
    print(f"❌ Connection Error: {e}")
    print("\n   Is Django server running? Try:")
    print("   python manage.py runserver 0.0.0.0:8000")
except Exception as e:
    print(f"❌ Error: {e}")

finally:
    # Clean up - no cart items to delete
    pass
