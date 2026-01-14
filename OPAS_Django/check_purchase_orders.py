#!/usr/bin/env python
"""Check all ACCEPTED submissions for purchase orders"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellToOPAS

approved = SellToOPAS.objects.filter(status='ACCEPTED')
print(f'Total ACCEPTED: {approved.count()}')
for s in approved:
    has_po = hasattr(s, 'purchase_order') and s.purchase_order is not None
    print(f'ID {s.id}: has purchase_order = {has_po}')
