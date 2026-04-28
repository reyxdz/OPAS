#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'opas_django.settings')
django.setup()

from apps.users.models import User

# Check if user exists
user = User.objects.filter(phone_number='9000000000').first()
if user:
    print(f"User found: {user.email}")
    print(f"Is active: {user.is_active}")
    print(f"Password check for 'password123': {user.check_password('password123')}")
else:
    print("User not found!")
