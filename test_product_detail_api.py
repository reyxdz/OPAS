#!/usr/bin/env python
import requests
import json

# Test the product detail endpoint
url = "http://10.207.234.34:8000/api/products/39/"
print(f"Testing endpoint: {url}\n")

response = requests.get(url)
print(f"Status Code: {response.status_code}")
print(f"Response:\n{json.dumps(response.json(), indent=2)}\n")
