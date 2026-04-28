import os
import sys
import django

sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import ProductCategory

# Get only top-level categories (parent_id is NULL)
top_cats = ProductCategory.objects.filter(parent_id__isnull=True).order_by('id').values('id', 'name')
print("TOP-LEVEL CATEGORIES:")
for cat in top_cats:
    print(f"  {cat['id']}: {cat['name']}")
