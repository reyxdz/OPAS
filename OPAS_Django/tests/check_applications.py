import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import SellerApplication

apps = SellerApplication.objects.filter(status='PENDING').select_related('user')
print(f'Found {apps.count()} pending applications')
for app in apps:
    print(f'ID: {app.id}, User: {app.user.email}, Farm: {app.farm_name}, Status: {app.status}')
