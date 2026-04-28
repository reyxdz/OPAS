#!/usr/bin/env python
"""
Simple test to check what the database has and if we can create a valid order
"""

import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from apps.users.seller_models import SellerProduct

# Check existing users
print("=" * 80)
print("Checking Existing Users")
print("=" * 80)

users = User.objects.all()[:5]
for user in users:
    print(f"- {user.email} (ID: {user.id}) - Phone: {user.phone_number}")

print("\n" + "=" * 80)
print("Checking Products")
print("=" * 80)

products = SellerProduct.objects.all()[:5]
for product in products:
    print(f"- {product.name} (ID: {product.id}) - Stock: {product.stock_level} - Price: {product.price}")

print("\n" + "=" * 80)
print("Creating Fresh Token")
print("=" * 80)

# Get the first buyer user (ID 2 based on previous logs)
try:
    buyer = User.objects.get(id=2)
    from rest_framework_simplejwt.tokens import AccessToken
    
    token = AccessToken.for_user(buyer)
    print(f"✅ Fresh token for {buyer.email}:")
    print(f"   {str(token)}")
    
    # Save for use in tests
    with open('fresh_buyer_token.txt', 'w') as f:
        f.write(str(token))
    print("\n✅ Token saved to fresh_buyer_token.txt")
    
except User.DoesNotExist:
    print("❌ Buyer user not found")
