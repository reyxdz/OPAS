import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework_simplejwt.tokens import RefreshToken, TokenError
from rest_framework_simplejwt.backends import TokenBackend
from apps.users.models import User

# Get opas_admin user
user = User.objects.get(username='opas_admin')
print(f"User: {user.username}, ID: {user.id}")

# Generate token
refresh = RefreshToken.for_user(user)
access_token = str(refresh.access_token)
print(f"\nAccess Token Generated: {access_token[:50]}...")

# Decode to verify claims
backend = TokenBackend(algorithm='HS256')
decoded = backend.decode(access_token, verify=True)
print(f"\nToken Claims:")
print(f"  user_id: {decoded.get('user_id')}")
print(f"  username: {decoded.get('username')}")

# Check admin status
from apps.users.admin_models import AdminUser
try:
    admin_user = AdminUser.objects.get(user=user)
    print(f"\nAdminUser:")
    print(f"  admin_role: {admin_user.admin_role}")
    print(f"  is_active: {admin_user.is_active}")
except AdminUser.DoesNotExist:
    print("\nAdminUser does NOT exist!")
