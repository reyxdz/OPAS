#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

# Delete the old/duplicate admin user
old_user = User.objects.get(id=4)
print(f"Deleting old user: {old_user.username} ({old_user.email})")
old_user.delete()

# Verify only one admin user remains with phone 1234567890
admins = User.objects.filter(phone_number='1234567890')
print(f"\nRemaining users with phone='1234567890': {admins.count()}")
for u in admins:
    print(f"  ✅ {u.username} ({u.email}) - Role: {u.role}")
