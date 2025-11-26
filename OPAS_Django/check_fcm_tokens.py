#!/usr/bin/env python
"""Check if users have FCM tokens"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import UserProfile, User

# Get all users
users = User.objects.all()
print(f"Total users: {users.count()}")

# Check their FCM tokens
for user in users:
    profile = UserProfile.objects.filter(user=user).first()
    if profile:
        token_status = "✓ Has FCM token" if profile.fcm_token else "✗ NO FCM token"
        print(f"  {user.email}: {token_status}")
    else:
        print(f"  {user.email}: ✗ NO UserProfile")

print("\nNote: For push notifications to work, the mobile app must:")
print("1. Request notification permission")
print("2. Get FCM token from Firebase")
print("3. Send token to backend via API")
