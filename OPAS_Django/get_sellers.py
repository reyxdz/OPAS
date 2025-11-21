"""
Get test sellers from database
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.users.models import UserRole

User = get_user_model()

# Get all sellers
sellers = User.objects.filter(role=UserRole.SELLER)
print(f"Total sellers: {sellers.count()}")
for seller in sellers[:5]:
    product_count = seller.products.count()
    print(f"  - {seller.email} (ID: {seller.id}, Products: {product_count})")
