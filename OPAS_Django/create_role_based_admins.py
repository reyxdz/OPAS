#!/usr/bin/env python
"""Create admin users with specific roles"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.authtoken.models import Token

User = get_user_model()

# Define admins with their roles
admins_to_create = [
    {
        'email': 'super.admin@opas.com',
        'phone': '091234567890',
        'name': 'Super Admin',
        'password': 'SuperAdmin@123',
        'admin_role': 'SUPER_ADMIN',
        'description': 'Full access to all features'
    },
    {
        'email': 'seller.manager@opas.com',
        'phone': '091234567891',
        'name': 'Seller Manager',
        'password': 'SellerMgr@123',
        'admin_role': 'SELLER_MANAGER',
        'description': 'Can approve/reject sellers, manage seller accounts'
    },
    {
        'email': 'price.manager@opas.com',
        'phone': '091234567892',
        'name': 'Price Manager',
        'password': 'PriceMgr@123',
        'admin_role': 'PRICE_MANAGER',
        'description': 'Can manage price ceilings, advisories, compliance'
    },
    {
        'email': 'analytics.admin@opas.com',
        'phone': '091234567893',
        'name': 'Analytics Admin',
        'password': 'Analytics@123',
        'admin_role': 'ANALYTICS_ADMIN',
        'description': 'Read-only access to reports and analytics'
    },
    {
        'email': 'support.admin@opas.com',
        'phone': '091234567894',
        'name': 'Support Admin',
        'password': 'Support@123',
        'admin_role': 'SUPPORT_ADMIN',
        'description': 'Handle suspensions, refunds, customer issues'
    },
]

created_count = 0
failed_count = 0

print("=" * 80)
print("Creating Admin Users with Specific Roles")
print("=" * 80)

for admin_data in admins_to_create:
    try:
        email = admin_data['email']
        phone = admin_data['phone']
        
        # Check if already exists
        if User.objects.filter(email=email).exists():
            print(f"\n⚠️  {email} already exists, skipping...")
            continue
        
        if User.objects.filter(phone_number=phone).exists():
            print(f"\n⚠️  Phone {phone} already exists, skipping...")
            continue
        
        # Split name
        name_parts = admin_data['name'].split(' ', 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ''
        
        # Create user
        user = User.objects.create_user(
            username=email,
            email=email,
            phone_number=phone,
            first_name=first_name,
            last_name=last_name,
            password=admin_data['password'],
            role='ADMIN',
            admin_role=admin_data['admin_role'],
            is_staff=True,
            is_superuser=(admin_data['admin_role'] == 'SUPER_ADMIN'),
        )
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        access_token = str(refresh.access_token)
        token, _ = Token.objects.get_or_create(user=user)
        
        print(f"\n✅ Created: {admin_data['name']}")
        print(f"   Role: {admin_data['admin_role']}")
        print(f"   {admin_data['description']}")
        print(f"   Email: {email}")
        print(f"   Phone: {phone}")
        print(f"   Password: {admin_data['password']}")
        
        created_count += 1
        
    except Exception as e:
        print(f"\n❌ Error creating {admin_data['email']}: {e}")
        failed_count += 1

print("\n" + "=" * 80)
print(f"Summary: {created_count} admins created, {failed_count} failed")
print("=" * 80)
