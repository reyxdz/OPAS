#!/usr/bin/env python
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()
admin = User.objects.filter(is_superuser=True).first()
if admin:
    refresh = RefreshToken.for_user(admin)
    token = str(refresh.access_token)
    with open('token.txt', 'w') as f:
        f.write(token)
    print('✅ Token saved to token.txt')
    print(f'Token: {token[:50]}...')
else:
    print('❌ No admin found')
