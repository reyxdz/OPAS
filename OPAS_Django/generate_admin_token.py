#!/usr/bin/env python
"""Generate fresh admin tokens for testing"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.authtoken.models import Token

User = get_user_model()

# Check if admin user exists
admins = User.objects.filter(role='ADMIN')
print(f"Admin users found: {admins.count()}")

for admin in admins:
    print(f"\nAdmin: {admin.full_name} ({admin.email})")
    print(f"  ID: {admin.id}")
    
    # Generate JWT token
    refresh = RefreshToken.for_user(admin)
    access_token = str(refresh.access_token)
    print(f"  JWT Access Token: {access_token}")
    
    # Try to get or create a DRF Token
    token, created = Token.objects.get_or_create(user=admin)
    print(f"  Token Auth: {token.key}")
    print(f"  Token created: {created}")
