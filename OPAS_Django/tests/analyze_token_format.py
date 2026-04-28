#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.authtoken.models import Token
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import User

print("=" * 70)
print("TOKEN FORMAT ANALYSIS")
print("=" * 70)

# Check what token type we're using
admin = User.objects.filter(username='opas_admin').first()

print("\n1. Token Authentication (DRF):")
token, _ = Token.objects.get_or_create(user=admin)
print(f"   Format: Token {token.key}")
print(f"   Example: Authorization: Token {token.key[:20]}...")

print("\n2. JWT Tokens (SimpleJWT):")
refresh = RefreshToken.for_user(admin)
print(f"   Access Token: {str(refresh.access_token)[:50]}...")
print(f"   Refresh Token: {str(refresh)[:50]}...")

print("\n3. What the API currently uses:")
print("   - Authentication backend: TokenAuthentication (DRF)")
print("   - Expected header: Authorization: Token <token_key>")

print("\n4. What Flutter app sends:")
print("   - From login: JWT access token")
print("   - Header format: Authorization: Token <jwt_access_token>")

print("\n⚠️  ISSUE:")
print("   The Flutter app is sending JWT tokens with 'Token' prefix")
print("   but the API is configured for DRF Token Authentication!")
print("=" * 70)
