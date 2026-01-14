#!/usr/bin/env python
"""Find user with username 9327538189"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

try:
    user = User.objects.get(username='9327538189')
    print(f"Found user with username '9327538189':")
    print(f"  Name: {user.first_name} {user.last_name}")
    print(f"  Phone: '{user.phone_number}'")
    print(f"  Email: {user.email}")
    print(f"  Role: {user.role}")
    print(f"\nTo fix: Update the phone_number field to '9327538189'")
    
    # Auto-fix it
    user.phone_number = '9327538189'
    user.save()
    print(f"✓ Fixed! Phone number updated to '9327538189'")
except User.DoesNotExist:
    print("User not found")
