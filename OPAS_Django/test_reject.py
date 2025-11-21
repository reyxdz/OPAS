#!/usr/bin/env python
"""
Test script to debug reject functionality
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from apps.users.models import User, SellerApplication, SellerStatus, UserRole
from django.utils import timezone

# Find a pending application
app = SellerApplication.objects.filter(status='PENDING').first()
if not app:
    print("No pending applications found")
    sys.exit(1)

print(f"Testing reject on application: {app.id}")
print(f"User: {app.user.email}")
print(f"Status before: {app.status}")

# Find an admin user
admin = User.objects.filter(role=UserRole.OPAS_ADMIN).first()
if not admin:
    print("No admin user found")
    sys.exit(1)

print(f"Admin user: {admin.email}")

try:
    # Call reject
    app.reject(admin_user=admin, reason='Test rejection')
    print(f"Status after: {app.status}")
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
