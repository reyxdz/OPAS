import os
import django
import requests
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

# Get the seller user
seller = User.objects.get(phone_number='09544498779')
print(f"Seller: {seller.email} ({seller.phone_number})")

# Generate JWT token for the seller
refresh = RefreshToken.for_user(seller)
access_token = str(refresh.access_token)
print(f"\nAccess Token: {access_token[:50]}...")

# Test the API
import requests
url = 'http://127.0.0.1:8000/api/users/seller/orders/pending/'
headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json',
}

print(f"\nTesting endpoint: {url}")
response = requests.get(url, headers=headers)
print(f"Status Code: {response.status_code}")
print(f"Response:")
data = response.json()
print(json.dumps(data, indent=2)[:2000])
print(f"\nTotal orders returned: {len(data) if isinstance(data, list) else 'Not a list'}")
