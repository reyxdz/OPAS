#!/usr/bin/env python
"""Quick test to verify server is responding"""

import requests
import sys
import json

BASE_URL = 'http://127.0.0.1:8000/api'

print("Testing if server is responding...")

try:
    # Try a simple endpoint first
    response = requests.get(f'{BASE_URL}/seller/products/', timeout=5)
    print(f"✅ Server is responding! Status: {response.status_code}")
    
except Exception as e:
    print(f"❌ Server not responding: {e}")
    sys.exit(1)

print("\n✅ Django server is running and ready for requests")
