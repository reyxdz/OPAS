#!/usr/bin/env python
"""
Check if there's an auth issue - test the endpoint with different auth headers
"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from apps.users.models import User, UserRole
from rest_framework.authtoken.models import Token

print("=" * 80)
print("TESTING AUTH METHOD - TOKEN vs BEARER")
print("=" * 80)

admin = User.objects.filter(role=UserRole.ADMIN).first()
if not admin:
    print("❌ No admin user")
    exit(1)

token_obj, _ = Token.objects.get_or_create(user=admin)
token_key = token_obj.key

print(f"Admin: {admin.email}")
print(f"Token: {token_key[:20]}...")

client = Client()

# Test 1: Using "Token" auth (current method)
print("\n[TEST 1] Using 'Token {key}' Auth")
print("-" * 80)
headers1 = {'HTTP_AUTHORIZATION': f'Token {token_key}'}
response1 = client.get('/api/admin/sellers/pending-approvals/', **headers1)
print(f"Status: {response1.status_code}")
if response1.status_code == 200:
    data = json.loads(response1.content)
    print(f"✅ Success - Returns {data.get('count', 0)} applications")
else:
    print(f"❌ Failed")

# Test 2: Using "Bearer" auth (what Flutter is using)
print("\n[TEST 2] Using 'Bearer {key}' Auth (Flutter method)")
print("-" * 80)
headers2 = {'HTTP_AUTHORIZATION': f'Bearer {token_key}'}
response2 = client.get('/api/admin/sellers/pending-approvals/', **headers2)
print(f"Status: {response2.status_code}")
if response2.status_code == 200:
    data = json.loads(response2.content)
    print(f"✅ Success - Returns {data.get('count', 0)} applications")
else:
    print(f"❌ Failed - Bearer auth not working!")
    print(f"Response: {response2.content[:200]}")

# Test 3: Check what auth backends are configured
print("\n[TEST 3] Checking Django Auth Configuration")
print("-" * 80)
from django.conf import settings

auth_backends = getattr(settings, 'REST_FRAMEWORK', {}).get('DEFAULT_AUTHENTICATION_CLASSES', [])
print(f"Configured authentication backends:")
for backend in auth_backends:
    print(f"  • {backend}")

if 'rest_framework.authentication.TokenAuthentication' in auth_backends:
    print("\n✅ TokenAuthentication is configured")
    print("   This uses 'Token {key}' format")
else:
    print("\n❌ TokenAuthentication NOT found!")

if 'rest_framework_simplejwt.authentication.JWTAuthentication' in auth_backends:
    print("✅ JWTAuthentication is configured")
    print("   This uses 'Bearer {key}' format")
else:
    print("❌ JWTAuthentication NOT found")

print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
if response1.status_code == 200 and response2.status_code != 200:
    print("⚠️  TOKEN AUTH MISMATCH!")
    print("Backend expects: 'Token {key}'")
    print("Flutter is using: 'Bearer {key}'")
    print("\nFLUTTER NEEDS TO BE UPDATED!")
elif response2.status_code == 200:
    print("✅ Bearer auth works - no change needed")
else:
    print("⚠️  Both methods failed - check auth configuration")
