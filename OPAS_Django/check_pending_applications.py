import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import SellerApplication

# Check pending applications
pending = SellerApplication.objects.filter(status='PENDING')
print(f"Total PENDING applications: {pending.count()}")

for app in pending:
    print(f"\nID: {app.id}")
    print(f"User: {app.user.email}")
    print(f"Farm Name: {app.farm_name}")
    print(f"Status: {app.status}")
    print(f"Created: {app.created_at}")
    print(f"User Role: {app.user.role}")
    print(f"Seller Status: {app.user.seller_status}")

# Also check all applications
all_apps = SellerApplication.objects.all()
print(f"\n\nTotal applications (all statuses): {all_apps.count()}")
for app in all_apps:
    print(f"  - {app.user.email}: {app.status}")
