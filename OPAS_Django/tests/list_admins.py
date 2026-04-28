#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

print("All superuser accounts:")
superusers = User.objects.filter(is_superuser=True)
for user in superusers:
    print(f"  - Username: {user.username}, Email: {user.email}")

if not superusers.exists():
    print("  No superuser accounts found")
