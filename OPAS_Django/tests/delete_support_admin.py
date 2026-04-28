import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

# Delete support admin user
try:
    user = User.objects.get(email='support.admin@opas.com')
    user.delete()
    print("✓ Support Admin user deleted successfully")
except User.DoesNotExist:
    print("Support Admin user not found")

# Verify remaining admins
admins = User.objects.filter(role='ADMIN')
print("\nRemaining admin users:")
for admin in admins:
    print(f"  - {admin.email} ({admin.admin_role})")
