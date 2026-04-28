#!/usr/bin/env python
"""Check phone number formats in the database"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

print("=" * 60)
print("Phone Numbers in Database:")
print("=" * 60)

users = User.objects.all()
for user in users:
    print(f"User: {user.first_name} {user.last_name}")
    print(f"  Phone: '{user.phone_number}' (length: {len(user.phone_number)})")
    print(f"  Cleaned (no spaces): '{user.phone_number.replace(' ', '')}'")
    print()

# Check if phone number '9327538189' exists
print("\n" + "=" * 60)
print("Searching for phone '9327538189'...")
print("=" * 60)

variants = [
    '9327538189',
    '9327 538 189',
    '+639327538189',
    '+63 9327 538 189',
]

for variant in variants:
    try:
        user = User.objects.get(phone_number=variant)
        print(f"✓ Found with '{variant}': {user.first_name} {user.last_name}")
    except User.DoesNotExist:
        print(f"✗ Not found with '{variant}'")
