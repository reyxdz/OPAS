import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
import json

# Get the admin user
admin = User.objects.filter(role='ADMIN').first()
print(f"Admin user: {admin.email if admin else 'Not found'}")

if admin:
    # Get access token (for testing, we'll generate one)
    from rest_framework_simplejwt.tokens import RefreshToken
    
    refresh = RefreshToken.for_user(admin)
    access_token = str(refresh.access_token)
    
    print(f"\nAccess Token: {access_token[:50]}...")
    print(f"\nTest the endpoint with:")
    print(f'curl -H "Authorization: Bearer {access_token}" http://10.113.93.34:8000/api/users/admin/sellers/pending_applications/')
