"""
Mark CSV products as OPAS-managed.

Products imported from CSV should be marked with is_opas_managed=True so they
can be properly classified and managed separately from regular seller products.
"""

import os
import sys
import django

# Setup Django
sys.path.insert(0, r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellerProduct

print(f"{'='*70}")
print(f"MARKING CSV PRODUCTS AS OPAS-MANAGED")
print(f"{'='*70}\n")

# Find all non-deleted products not yet marked as OPAS-managed
# These are the CSV products that need to be marked
products_to_mark = SellerProduct.objects.filter(
    is_deleted=False,
    is_opas_managed=False
)

print(f"Products to mark as OPAS-managed: {products_to_mark.count()}")

for product in products_to_mark:
    seller_name = product.seller.store_name or f"{product.seller.first_name} {product.seller.last_name}"
    
    # Mark as OPAS-managed
    product.is_opas_managed = True
    product.save()
    
    print(f"  ✓ {product.name}")
    print(f"    Seller: {seller_name} (ID: {product.seller_id})")
    print(f"    Marked as: OPAS-managed (is_opas_managed=True)")

print(f"\n{'='*70}")
print(f"MARKING COMPLETE")
print(f"{'='*70}")
print(f"Total products marked: {products_to_mark.count()}")

# Verify
all_opas_products = SellerProduct.objects.filter(is_deleted=False, is_opas_managed=True)
print(f"Total OPAS-managed products now: {all_opas_products.count()}")
print(f"{'='*70}\n")
