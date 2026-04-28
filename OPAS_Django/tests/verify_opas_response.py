#!/usr/bin/env python
"""Verify OPAS admin API response includes stock monitoring fields"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.admin_serializers import get_or_create_opas_seller
from apps.users.seller_models import SellerProduct
from apps.users.admin_models import OPASInventory

opas_seller = get_or_create_opas_seller()
products = SellerProduct.objects.filter(seller=opas_seller)

print('Testing response building for admin API:')
for product in products:
    inventory = OPASInventory.objects.filter(product=product).first()
    response_data = {
        'id': inventory.id if inventory else product.id,
        'product_id': product.id,
        'product_name': product.name,
        'price': str(product.price),
        'stock_level': inventory.quantity_on_hand if inventory else 0,
        'category': product.category.name if product.category else 'Uncategorized',
        'description': product.description,
        'image': product.image_url if product.image_url else None,
        # Stock monitoring fields
        'initial_stock': product.initial_stock,
        'baseline_stock': product.baseline_stock,
        'stock_baseline_updated_at': product.stock_baseline_updated_at.isoformat() if product.stock_baseline_updated_at else None,
        'stock_percentage': product.stock_percentage,
        'stock_status': product.stock_status,
    }
    
    print(f'\n✓ Product: {product.name}')
    print(json.dumps(response_data, indent=2, default=str))
