import os
import django
import json
import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from rest_framework_simplejwt.tokens import RefreshToken

# Get a buyer with no pending registration
buyers = User.objects.filter(role='BUYER')
print(f"Available buyers: {[b.username for b in buyers]}")

# Try with first buyer
for buyer in buyers:
    # Check if they have pending registration
    from apps.users.admin_models import SellerRegistrationRequest
    existing = SellerRegistrationRequest.objects.filter(seller=buyer).first()
    if not existing:
        token = str(RefreshToken.for_user(buyer).access_token)
        print(f"\nUsing buyer: {buyer.username}")
        
        # Test registration with comma-separated products
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        
        payload = {
            "farm_name": f"Test Farm {buyer.username}",
            "farm_location": "Test Location",
            "products_grown": "Rice, Corn, Wheat",
            "store_name": "Test Store",
            "store_description": "Test Description"
        }
        
        response = requests.post(
            'http://localhost:8000/api/users/sellers/register-application/',
            headers=headers,
            json=payload
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        break
else:
    print("\nAll buyers have pending registrations. Creating new test buyer...")
    from django.contrib.auth import get_user_model
    test_buyer = User.objects.create_user(
        username='test_buyer_001',
        email='test@example.com',
        password='test123',
        role='BUYER'
    )
    
    token = str(RefreshToken.for_user(test_buyer).access_token)
    print(f"Created test buyer: {test_buyer.username}")
    
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        "farm_name": "Test Farm New",
        "farm_location": "Test Location",
        "products_grown": "Rice, Corn, Wheat",
        "store_name": "Test Store",
        "store_description": "Test Description"
    }
    
    response = requests.post(
        'http://localhost:8000/api/users/sellers/register-application/',
        headers=headers,
        json=payload
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
