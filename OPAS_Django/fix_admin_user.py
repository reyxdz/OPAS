#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User, AdminUser
from django.contrib.auth.models import Group

print("=" * 70)
print("ADMIN USER DETAILS CHECK")
print("=" * 70)

admin_user = User.objects.filter(username='opas_admin').first()

if admin_user:
    print(f"\nUser: {admin_user.username}")
    print(f"  Has AdminUser record: ", end="")
    
    try:
        admin_record = AdminUser.objects.get(user=admin_user)
        print(f"YES")
        print(f"    ID: {admin_record.id}")
        print(f"    Is Active: {admin_record.is_active}")
        print(f"    Department: {admin_record.department if hasattr(admin_record, 'department') else 'N/A'}")
    except AdminUser.DoesNotExist:
        print(f"NO - This is the problem!")
        print(f"\n  Creating AdminUser record...")
        admin_record = AdminUser.objects.create(
            user=admin_user,
            is_active=True
        )
        print(f"  Created! ID: {admin_record.id}")

print("\n" + "=" * 70)
