#!/usr/bin/env python
"""
Check users by role
"""

import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from rest_framework_simplejwt.tokens import AccessToken

# Get all users
print("=" * 80)
print("All Users:")
print("=" * 80)

users = User.objects.all()
for user in users:
    print(f"ID: {user.id:3} | Email: {user.email:30} | Role: {user.role:10} | Phone: {user.phone_number}")

# Get first user (usually ID 1)
print("\n" + "=" * 80)
print("Creating Token for First User")
print("=" * 80)

first_user = User.objects.first()
if first_user:
    token = AccessToken.for_user(first_user)
    print(f"✅ Token for {first_user.email} (ID: {first_user.id}):")
    print(f"   {str(token)}")
else:
    print("❌ No users found")
