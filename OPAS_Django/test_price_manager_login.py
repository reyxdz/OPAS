import requests
import json

BASE_URL = 'http://localhost:8000/api'

# Price Manager credentials
phone = '091234567892'
password = 'PriceMgr@123'

response = requests.post(
    f'{BASE_URL}/login/',
    json={'phone_number': phone, 'password': password},
)

print('Status Code:', response.status_code)
print('Response:')
print(json.dumps(response.json(), indent=2))
