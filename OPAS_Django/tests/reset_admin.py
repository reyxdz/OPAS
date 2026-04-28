#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

# Try to find and update existing admin
try:
    admin = User.objects.filter(is_superuser=True).first()
    if admin:
        print(f"Found admin user: {admin.email}")
        admin.set_password('admin123')
        admin.save()
        print(f"Password reset to: admin123")
        print(f"Email: {admin.email}")
    else:
        # Create new admin if none exists
        admin = User.objects.create_superuser(
            username='admin',
            email='admin@opas.local',
            password='admin123'
        )
        print(f"Created new admin user")
        print(f"Username: admin")
        print(f"Email: admin@opas.local")
        print(f"Password: admin123")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
