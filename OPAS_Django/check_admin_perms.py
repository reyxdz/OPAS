#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User, UserRole
from rest_framework.authtoken.models import Token

print("=" * 70)
print("ADMIN USER PERMISSIONS CHECK")
print("=" * 70)

admin = User.objects.filter(username='opas_admin').first()
if admin:
    print(f"\nAdmin User: {admin.username}")
    print(f"  Email: {admin.email}")
    print(f"  Role: {admin.role}")
    print(f"  Is Staff: {admin.is_staff}")
    print(f"  Is Superuser: {admin.is_superuser}")
    
    # Check token
    token, created = Token.objects.get_or_create(user=admin)
    print(f"\n  Token: {token.key}")
    print(f"  Token Created: {created}")
else:
    print("Admin user 'opas_admin' not found!")

# Check if admin should have ADMIN role
print("\n" + "=" * 70)
print("Expected Role: ADMIN")
print("Actual Role: " + (admin.role if admin else "N/A"))
print("=" * 70)
