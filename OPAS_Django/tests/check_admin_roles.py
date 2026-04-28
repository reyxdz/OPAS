import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

# Check all admin users
admins = User.objects.filter(role='ADMIN')
for admin in admins:
    print(f"Email: {admin.email}, Phone: {admin.phone_number}, Admin Role: {admin.admin_role}")
