#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

try:
    user = User.objects.get(email='admin@opas.com')
    user.phone_number = '1234567890'
    user.save()
    print(f'✓ Admin updated:')
    print(f'  Email: {user.email}')
    print(f'  Phone: {user.phone_number}')
    print(f'  Role: {user.role}')
except User.DoesNotExist:
    print('Admin user not found')
