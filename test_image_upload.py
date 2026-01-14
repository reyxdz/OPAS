import requests
import json
from io import BytesIO
from PIL import Image

# Login first
login_resp = requests.post('http://localhost:8000/api/auth/login/', json={
    'phone_number': '9000000000', 
    'password': 'rey1172003'
})
token = login_resp.json()['access']
headers = {'Authorization': f'Bearer {token}'}

# Create a test image
img = Image.new('RGB', (100, 100), color='red')
img_bytes = BytesIO()
img.save(img_bytes, format='JPEG')
img_bytes.seek(0)

# Upload with image
files = {
    'product_name': (None, 'Test Product with Image'),
    'description': (None, 'Test description'),
    'price': (None, '99.99'),
    'stock_level': (None, '50'),
    'category': (None, 'Test Category'),
    'image': ('test.jpg', img_bytes, 'image/jpeg'),
}

upload_resp = requests.post(
    'http://localhost:8000/api/admin/opas-products/',
    headers=headers,
    files=files
)

print(f"Upload status: {upload_resp.status_code}")
print(f"Response: {json.dumps(json.loads(upload_resp.text), indent=2)}")
