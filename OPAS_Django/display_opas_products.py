import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.opas_models import OPASProduct

prods = OPASProduct.objects.all().order_by('id')
print(f'Total OPAS Products: {prods.count()}\n')
print(f"{'#':<4} {'Product Name':<30} {'Category':<15} {'Type':<20} {'Subtype':<20}")
print("=" * 90)

for idx, p in enumerate(prods, 1):
    cat = p.category_forecast or "None"
    typ = p.product_type or "None"
    sub = p.product_subtype or "None"
    print(f"[{idx:2d}] {p.name:<28} {cat:<15} {typ:<20} {sub:<20}")
