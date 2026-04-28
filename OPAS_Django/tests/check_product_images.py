import requests
import json

# Login first
login_resp = requests.post('http://localhost:8000/api/auth/login/', json={
    'phone_number': '9000000000', 
    'password': 'rey1172003'
})
token = login_resp.json()['access']

# Check what's returned when listing products
headers = {'Authorization': f'Bearer {token}'}
list_resp = requests.get('http://localhost:8000/api/admin/opas-products/', headers=headers)
print('Products currently in DB:')
for p in list_resp.json():
    print(f"  - {p['product_name']}: image={p.get('image')}")
