#!/usr/bin/env python
import requests
import json

# Test 1: Without authentication
print("TEST 1: API call WITHOUT authentication")
print("=" * 50)
response = requests.get('http://localhost:8000/api/admin/sellers/pending-approvals/')
print(f"Status: {response.status_code}")
print(f"Body: {response.text}\n")

# Test 2: With invalid token
print("TEST 2: API call WITH invalid token")
print("=" * 50)
headers = {
    'Authorization': 'Bearer invalid_token_12345',
    'Content-Type': 'application/json',
}
response = requests.get(
    'http://localhost:8000/api/admin/sellers/pending-approvals/',
    headers=headers
)
print(f"Status: {response.status_code}")
print(f"Body: {response.text}\n")

# Test 3: With valid admin login
print("TEST 3: Login as admin and get token")
print("=" * 50)
login_data = {
    'phone_number': '091234567891',
    'password': 'SellerMgr@123'
}
response = requests.post(
    'http://localhost:8000/api/auth/login/',
    json=login_data,
    headers={'Content-Type': 'application/json'}
)
print(f"Login Status: {response.status_code}")
if response.status_code == 200:
    login_response = response.json()
    token = login_response.get('access')
    print(f"Got token: {token[:20]}..." if token else "No token in response")
    
    # Now test the pending approvals endpoint with this token
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }
    response = requests.get(
        'http://localhost:8000/api/admin/sellers/pending-approvals/',
        headers=headers
    )
    print(f"\nPending Approvals Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Pending Approvals Response:")
        print(json.dumps(data, indent=2))
    else:
        print(f"Error: {response.text}")
else:
    print(f"Login failed: {response.text}")
