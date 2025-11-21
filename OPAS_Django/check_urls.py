import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.routers import DefaultRouter
from apps.users.admin_views import SellerManagementViewSet

router = DefaultRouter()
router.register(r'admin/sellers', SellerManagementViewSet, basename='seller-management')

print("Generated URLs for SellerManagementViewSet:")
for url_pattern in router.urls:
    print(f"  {url_pattern.pattern}")
