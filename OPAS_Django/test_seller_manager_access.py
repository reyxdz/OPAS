import requests
import json

BASE_URL = 'http://localhost:8000/api'

# Seller Manager credentials
phone = '091234567891'
password = 'SellerMgr@123'

# Step 1: Login
print("Step 1: Logging in as Seller Manager...")
response = requests.post(
    f'{BASE_URL}/login/',
    json={'phone_number': phone, 'password': password},
)

print(f"Login Status: {response.status_code}")
if response.status_code != 200:
    print(f"Response: {response.text}")
    exit(1)

login_data = response.json()
access_token = login_data.get('access')
print(f"✓ Logged in successfully")
print(f"Admin Role from response: {login_data.get('admin_role')}")

# Step 2: Get pending approvals
print("\nStep 2: Fetching pending approvals...")
headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json',
}

response = requests.get(
    f'{BASE_URL}/admin/sellers/pending-approvals/',
    headers=headers,
)

print(f"Status Code: {response.status_code}")
print(f"Response:")
print(json.dumps(response.json(), indent=2))
