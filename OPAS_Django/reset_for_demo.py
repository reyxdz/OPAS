#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.admin_models import SellerRegistrationRequest, SellerRegistrationStatus
from apps.users.models import User, UserRole, SellerStatus

# Reset the approved registrations back to PENDING for demo
approved_list = SellerRegistrationRequest.objects.filter(status=SellerRegistrationStatus.APPROVED)
for approved in approved_list:
    # Reset registration status
    approved.status = SellerRegistrationStatus.PENDING
    approved.approved_at = None
    approved.reviewed_at = None
    approved.save()
    
    # Reset user role and status
    approved.seller.role = UserRole.BUYER
    approved.seller.seller_status = SellerStatus.PENDING
    approved.seller.seller_approval_date = None
    approved.seller.save()
    
    print(f"Reset {approved.farm_name} back to PENDING for demo")
    
# Verify we have 2 pending again
pending_count = SellerRegistrationRequest.objects.filter(status=SellerRegistrationStatus.PENDING).count()
print(f"\nTotal pending registrations: {pending_count}")
for req in SellerRegistrationRequest.objects.filter(status=SellerRegistrationStatus.PENDING).order_by('id'):
    print(f"  - {req.farm_name} ({req.seller.email}) - Role: {req.seller.role}")
