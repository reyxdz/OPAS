import os
import sys
import django

sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import ProductCategory

# Define the 8 standard top-level categories
standard_categories = [
    {'name': 'Vegetable', 'slug': 'VEGETABLE'},
    {'name': 'Fruit', 'slug': 'FRUIT'},
    {'name': 'Livestock', 'slug': 'LIVESTOCK'},
    {'name': 'Poultry', 'slug': 'POULTRY'},
    {'name': 'Seeds', 'slug': 'SEEDS'},
    {'name': 'Fertilizers', 'slug': 'FERTILIZERS'},
    {'name': 'Feeds', 'slug': 'FEEDS'},
    {'name': 'Medicines', 'slug': 'MEDICINES'},
]

print("=" * 80)
print("CREATING STANDARD TOP-LEVEL CATEGORIES")
print("=" * 80)

created_count = 0
for cat_data in standard_categories:
    cat, created = ProductCategory.objects.get_or_create(
        slug=cat_data['slug'],
        defaults={
            'name': cat_data['name'],
            'parent': None,
            'active': True,
        }
    )
    
    if created:
        print(f"✅ CREATED: ID {cat.id:3d} - {cat.name:20s} (slug: {cat.slug})")
        created_count += 1
    else:
        print(f"⏭️  EXISTS:  ID {cat.id:3d} - {cat.name:20s} (slug: {cat.slug})")

print("\n" + "=" * 80)
print(f"Summary: {created_count} new categories created")
print("=" * 80)

# List all top-level categories
print("\nALL TOP-LEVEL CATEGORIES NOW:")
top_cats = ProductCategory.objects.filter(parent_id__isnull=True).order_by('id')
for cat in top_cats:
    print(f"  ID: {cat.id:3d} | Name: {cat.name:20s} | Slug: {cat.slug}")
