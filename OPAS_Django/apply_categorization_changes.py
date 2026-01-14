import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.opas_models import OPASProduct

print("=" * 90)
print("APPLYING PRODUCT CATEGORIZATION CHANGES")
print("=" * 90)

# Track changes
updates = []
merges = []

# [2] Baguio beans - Fix Type and Subtype
p2 = OPASProduct.objects.get(name='Baguio beans')
p2.product_type = 'Beans'
p2.product_subtype = 'Baguio Beans'
p2.save()
updates.append(f"[2] Baguio beans: Type=Beans, Subtype=Baguio Beans")

# [7] Chinese Pechay - Fix Type and Subtype
p7 = OPASProduct.objects.get(name='Chinese Pechay')
p7.product_type = 'Pechay'
p7.product_subtype = 'Chinese Pechay'
p7.save()
updates.append(f"[7] Chinese Pechay: Type=Pechay, Subtype=Chinese Pechay")

# [8] Dragon Fruit - Fix Category and Type
p8 = OPASProduct.objects.get(name='Dragon Fruit')
p8.category_forecast = 'FRUIT'
p8.product_type = 'Dragon Fruit'
p8.product_subtype = None
p8.save()
updates.append(f"[8] Dragon Fruit: Category=FRUIT, Type=Dragon Fruit")

# [9] Durian - Fix Category
p9 = OPASProduct.objects.get(name='Durian')
p9.category_forecast = 'FRUIT'
p9.save()
updates.append(f"[9] Durian: Category=FRUIT")

# [10] Hot pepper - Fix Type and Subtype
p10 = OPASProduct.objects.get(name='Hot pepper')
p10.product_type = 'Pepper'
p10.product_subtype = 'Hot Pepper'
p10.save()
updates.append(f"[10] Hot pepper: Type=Pepper, Subtype=Hot Pepper")

# [11] Hot pepper A - MERGE with [10]
p11 = OPASProduct.objects.get(name='Hot pepper A')
p11.delete()
merges.append(f"[11] Hot pepper A: DELETED (merged with [10] Hot pepper)")

# [18] & [19] Mais malagkit and Malagkit mais - MERGE
# Keep [18], Delete [19]
p18 = OPASProduct.objects.get(name='Mais malagkit')
p18.product_type = 'Corn'
p18.product_subtype = 'Malagkit'
p18.save()
updates.append(f"[18] Mais malagkit: Type=Corn, Subtype=Malagkit")

p19 = OPASProduct.objects.get(name='Malagkit mais')
p19.delete()
merges.append(f"[19] Malagkit mais: DELETED (merged with [18] Mais malagkit)")

# [23] Pakwan - Fix Category and Type
p23 = OPASProduct.objects.get(name='Pakwan')
p23.category_forecast = 'FRUIT'
p23.product_type = 'Watermelon'
p23.product_subtype = None
p23.save()
updates.append(f"[23] Pakwan: Category=FRUIT, Type=Watermelon")

# [27] Pepper - MERGE with [10]
p27 = OPASProduct.objects.get(name='Pepper')
p27.delete()
merges.append(f"[27] Pepper: DELETED (merged with [10] Hot pepper)")

# [32] Red pakwan - MERGE with [23]
p32 = OPASProduct.objects.get(name='Red pakwan')
p32.delete()
merges.append(f"[32] Red pakwan: DELETED (merged with [23] Pakwan/Watermelon)")

# [36] Sili - MERGE with [10]
p36 = OPASProduct.objects.get(name='Sili')
p36.delete()
merges.append(f"[36] Sili: DELETED (merged with [10] Hot pepper)")

# [37] Spring Onion - Fix Type and Subtype
p37 = OPASProduct.objects.get(name='Spring Onion')
p37.product_type = 'Onion'
p37.product_subtype = 'Spring Onion'
p37.save()
updates.append(f"[37] Spring Onion: Type=Onion, Subtype=Spring Onion")

# [38] String Beans - Fix Type and Subtype
p38 = OPASProduct.objects.get(name='String Beans')
p38.product_type = 'Beans'
p38.product_subtype = 'String Beans'
p38.save()
updates.append(f"[38] String Beans: Type=Beans, Subtype=String Beans")

# [39] String beans - MERGE with [38]
p39 = OPASProduct.objects.get(name='String beans')
p39.delete()
merges.append(f"[39] String beans: DELETED (merged with [38] String Beans)")

# [41] Sweet pepper - Fix Type and Subtype
p41 = OPASProduct.objects.get(name='Sweet pepper')
p41.product_type = 'Pepper'
p41.product_subtype = 'Sweet Pepper'
p41.save()
updates.append(f"[41] Sweet pepper: Type=Pepper, Subtype=Sweet Pepper")

print("\n✓ CATEGORY UPDATES:")
for update in updates:
    print(f"  {update}")

print("\n✓ PRODUCT MERGES (Deletions):")
for merge in merges:
    print(f"  {merge}")

# Display final count
final_count = OPASProduct.objects.count()
print(f"\n" + "=" * 90)
print(f"CHANGES COMPLETE")
print(f"Original count: 45 products")
print(f"Final count: {final_count} products")
print(f"Merged/Deleted: {45 - final_count} products")
print("=" * 90)
