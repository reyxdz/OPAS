import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User

user = User.objects.filter(phone_number='9000000000').first()
if user:
    print(f"User found: {user.email}")
    print(f"Name: {user.first_name} {user.last_name}")
    print(f"Is active: {user.is_active}")
    print(f"Role: {user.role}")
    print(f"Password check for 'rey1172003': {user.check_password('rey1172003')}")
    print(f"Password check for 'password123': {user.check_password('password123')}")
else:
    print("No user found with that phone number")
