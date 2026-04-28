#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

print("All users in database:")
for u in User.objects.all():
    pwd_check = u.check_password('AdminTest123!')
    print(f"\nID: {u.id}")
    print(f"  Username: {u.username}")
    print(f"  Email: {u.email}")
    print(f"  Phone: {u.phone_number}")
    print(f"  Role: {u.role}")
    print(f"  Password 'AdminTest123!' valid: {pwd_check}")
    print(f"  Is staff: {u.is_staff}")
    print(f"  Is superuser: {u.is_superuser}")
