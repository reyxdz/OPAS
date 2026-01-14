#!/usr/bin/env python
"""
Create OPASPurchaseOrder objects for existing approved SellToOPAS submissions
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellToOPAS
from apps.users.admin_models import OPASPurchaseOrder
from django.utils import timezone

# Get all ACCEPTED SellToOPAS submissions that don't have a purchase order
approved_submissions = SellToOPAS.objects.filter(status='ACCEPTED').exclude(purchase_order__isnull=False)

count = 0
for submission in approved_submissions:
    try:
        purchase_order, created = OPASPurchaseOrder.objects.get_or_create(
            sell_to_opas=submission,
            defaults={
                'seller': submission.seller,
                'product': submission.product,
                'offered_quantity': submission.quantity_offered,
                'offered_price': submission.offered_price,
                'approved_quantity': submission.quantity_offered,
                'final_price': submission.approved_price or submission.offered_price,
                'status': 'APPROVED',
                'approved_at': submission.accepted_at or timezone.now(),
                'delivery_terms': str(submission.delivery_date) if submission.delivery_date else '',
            }
        )
        if created:
            count += 1
            print(f"Created OPASPurchaseOrder for submission {submission.id}")
    except Exception as e:
        print(f"Error for submission {submission.id}: {e}")

print(f"\nTotal OPASPurchaseOrder created: {count}")
print(f"Total OPASPurchaseOrder now: {OPASPurchaseOrder.objects.count()}")
