import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

user = User.objects.filter(phone_number='9000000000').first()
if user:
    user.set_password('rey1172003')
    user.save()
    print(f"✅ Password updated for user {user.phone_number}")
    print(f"   New password: rey1172003")
    print(f"   Verification: {user.check_password('rey1172003')}")
else:
    print("❌ User not found")
