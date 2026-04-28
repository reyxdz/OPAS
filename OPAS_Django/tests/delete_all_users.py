#!/usr/bin/env python
"""Delete all users from the database"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# Get count before deletion
count_before = User.objects.count()
print(f"Users before deletion: {count_before}")

if count_before == 0:
    print("No users to delete.")
    exit(0)

# Confirm deletion
confirm = input(f"\n⚠️  This will delete ALL {count_before} users! Type 'yes' to confirm: ").strip().lower()

if confirm != 'yes':
    print("❌ Deletion cancelled.")
    exit(0)

# Delete all users
try:
    User.objects.all().delete()
    count_after = User.objects.count()
    print(f"\n✅ All users deleted successfully!")
    print(f"Users after deletion: {count_after}")
except Exception as e:
    print(f"❌ Error deleting users: {e}")
    exit(1)
