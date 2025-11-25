#!/usr/bin/env python
import os
import sys
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(__file__))

import django
django.setup()

from apps.users.models import User, UserRole

# Check for admin users
admin_users = User.objects.filter(role='ADMIN')
print(f"Total admin users: {admin_users.count()}\n")

for user in admin_users:
    print(f"Admin User:")
    print(f"  ID: {user.id}")
    print(f"  Phone: {user.phone_number}")
    print(f"  Full Name: {user.full_name}")
    print(f"  Role: {user.role}")
    print()

# Check if there are any users who are not admins
all_users = User.objects.all()
print(f"\nTotal users: {all_users.count()}")
print("User roles:")
for role in set(all_users.values_list('role', flat=True)):
    count = User.objects.filter(role=role).count()
    print(f"  {role}: {count}")
