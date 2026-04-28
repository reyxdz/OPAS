#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

try:
    u = User.objects.get(phone_number='1234567890')
    pwd_check = u.check_password('AdminTest123!')
    print("✅ User found!")
    print(f"   Email: {u.email}")
    print(f"   Phone: {u.phone_number}")
    print(f"   Role: {u.role}")
    print(f"   Password valid: {pwd_check}")
    print(f"   Is staff: {u.is_staff}")
    print(f"   Is superuser: {u.is_superuser}")
except User.DoesNotExist:
    print("❌ User not found with phone_number='1234567890'")
except Exception as e:
    print(f"❌ Error: {e}")
