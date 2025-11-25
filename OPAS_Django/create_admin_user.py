#!/usr/bin/env python
"""Create a new admin user"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.authtoken.models import Token

User = get_user_model()

# Admin credentials
email = input("Enter admin email: ").strip()
phone = input("Enter admin phone number: ").strip()
full_name = input("Enter admin full name: ").strip()
password = input("Enter admin password: ").strip()

# Check if admin already exists
if User.objects.filter(email=email).exists():
    print(f"❌ Admin with email {email} already exists!")
    exit(1)

if User.objects.filter(phone_number=phone).exists():
    print(f"❌ Admin with phone {phone} already exists!")
    exit(1)

# Split full name into first and last
name_parts = full_name.split(' ', 1)
first_name = name_parts[0]
last_name = name_parts[1] if len(name_parts) > 1 else ''

# Create the admin user
try:
    admin = User.objects.create_user(
        username=email,  # Use email as username
        email=email,
        phone_number=phone,
        first_name=first_name,
        last_name=last_name,
        password=password,
        role='ADMIN',
        is_staff=True,
        is_superuser=True,
    )
    
    # Generate JWT token
    refresh = RefreshToken.for_user(admin)
    access_token = str(refresh.access_token)
    
    # Generate DRF Token
    token, created = Token.objects.get_or_create(user=admin)
    drf_token = token.key
    
    print("\n✅ Admin user created successfully!")
    print(f"\nAdmin Details:")
    print(f"  Email: {email}")
    print(f"  Phone: {phone}")
    print(f"  Name: {full_name}")
    print(f"  ID: {admin.id}")
    print(f"\nTokens:")
    print(f"  JWT Access Token: {access_token}")
    print(f"  DRF Token (for Token auth): {drf_token}")
    print(f"\nLogin Credentials:")
    print(f"  Phone: {phone}")
    print(f"  Password: {password}")
    
except Exception as e:
    print(f"❌ Error creating admin: {e}")
    exit(1)
