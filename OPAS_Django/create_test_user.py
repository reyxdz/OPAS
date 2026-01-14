#!/usr/bin/env python
"""Create a test user with the specified phone number"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

phone = '9327538189'
password = 'password123'

# Check if user already exists
try:
    user = User.objects.get(phone_number=phone)
    print(f"✓ User already exists with phone {phone}")
    print(f"  Name: {user.first_name} {user.last_name}")
    print(f"  Role: {user.role}")
except User.DoesNotExist:
    # Create new user
    user = User.objects.create_user(
        username=phone,
        phone_number=phone,
        email=phone,
        first_name='Test',
        last_name='User',
        password=password,
        role='BUYER',
        address='Test Address',
    )
    print(f"✓ Created new user with phone {phone}")
    print(f"  Username: {user.username}")
    print(f"  Password: {password}")
    print(f"  Role: {user.role}")
