#!/usr/bin/env python3
"""
Test script for OPAS product upload functionality
Tests the complete backend integration
"""

import requests
import json
import sys

BASE_URL = "http://10.174.45.34:8000/api"

def test_login():
    """Test login and get JWT tokens"""
    print("\n1. Testing Admin Login...")
    response = requests.post(
        f"{BASE_URL}/auth/login/",
        json={
            "phone_number": "9000000000",
            "password": "password123"
        }
    )
    
    if response.status_code != 200:
        print(f"❌ Login failed: {response.status_code}")
        print(response.text)
        return None
    
    data = response.json()
    access_token = data.get('access')
    print(f"✅ Login successful. Token: {access_token[:20]}...")
    return access_token

def test_opas_products_endpoint(token):
    """Test accessing the OPAS products endpoint"""
    print("\n2. Testing OPAS Products Endpoint (GET)...")
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/admin/opas-products/",
        headers=headers
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text[:200]}")
    
    if response.status_code == 200:
        print("✅ GET endpoint working!")
        return True
    else:
        print(f"❌ GET endpoint failed: {response.status_code}")
        return False

def test_product_upload(token):
    """Test uploading a product with image"""
    print("\n3. Testing Product Upload (POST with multipart)...")
    
    # Create a simple test image
    import io
    from PIL import Image
    
    img = Image.new('RGB', (100, 100), color='red')
    img_io = io.BytesIO()
    img.save(img_io, 'JPEG')
    img_io.seek(0)
    
    headers = {"Authorization": f"Bearer {token}"}
    files = {
        'image': ('test_image.jpg', img_io, 'image/jpeg'),
    }
    data = {
        'product_name': 'Test Tomato',
        'description': 'Fresh red tomatoes from OPAS marketplace',
        'price': '50.00',
        'stock_level': '100',
        'category': 'Vegetable',
    }
    
    response = requests.post(
        f"{BASE_URL}/admin/opas-products/",
        headers=headers,
        files=files,
        data=data
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code in [200, 201]:
        result = response.json()
        print(f"✅ Product uploaded! ID: {result.get('id')}")
        return True
    else:
        print(f"❌ Upload failed: {response.status_code}")
        return False

def main():
    print("=" * 60)
    print("OPAS Product Upload API Test")
    print("=" * 60)
    
    # Step 1: Login
    token = test_login()
    if not token:
        sys.exit(1)
    
    # Step 2: Test endpoint
    if not test_opas_products_endpoint(token):
        print("⚠️ Endpoint may have permission issues")
    
    # Step 3: Test upload
    test_product_upload(token)
    
    print("\n" + "=" * 60)
    print("Test Complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
