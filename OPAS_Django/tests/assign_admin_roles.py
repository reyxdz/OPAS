#!/usr/bin/env python
"""Assign admin roles to existing admins"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.users.models import AdminRole

User = get_user_model()

# Get all admins
admins = User.objects.filter(role='ADMIN')

print(f"\n Found {admins.count()} admin users:\n")

for i, admin in enumerate(admins, 1):
    print(f"{i}. {admin.full_name} ({admin.email})")
    print(f"   Current role: {admin.admin_role or 'Not set'}")

print(f"\nAvailable admin roles:")
for role_key, role_display in AdminRole.choices:
    print(f"  {role_key}: {role_display}")

print("\n" + "="*60)

# Assign roles
while True:
    email = input("\nEnter admin email to assign role (or 'done' to exit): ").strip()
    
    if email.lower() == 'done':
        break
    
    try:
        admin = User.objects.get(email=email, role='ADMIN')
    except User.DoesNotExist:
        print(f"❌ Admin with email {email} not found")
        continue
    
    print(f"\nCurrent role: {admin.admin_role or 'SUPER_ADMIN (default)'}")
    print("\nAvailable roles:")
    for role_key, role_display in AdminRole.choices:
        print(f"  {role_key}")
    
    role = input("\nEnter admin role to assign: ").strip().upper()
    
    if role not in dict(AdminRole.choices):
        print(f"❌ Invalid role: {role}")
        continue
    
    admin.admin_role = role
    admin.save()
    
    print(f"✅ Admin {admin.full_name} assigned role: {role}")

print("\n" + "="*60)
print("\n✅ Admin role assignment complete!")
print("\nFinal Admin Roles:")
for admin in User.objects.filter(role='ADMIN'):
    print(f"  {admin.full_name}: {admin.get_admin_role_display()}")
