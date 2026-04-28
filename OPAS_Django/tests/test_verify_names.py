#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.admin_models import SellerRegistrationRequest, SellerRegistrationStatus
from apps.users.seller_serializers import SellerRegistrationRequestSerializer
import json

# Get pending registrations
pending = SellerRegistrationRequest.objects.filter(status=SellerRegistrationStatus.PENDING).order_by('id')

print('Sample pending applications:')
for req in pending:
    serializer = SellerRegistrationRequestSerializer(req)
    data = serializer.data
    print(f'\nFarm: {data["farm_name"]}')
    print(f'  Seller Email: {data["seller_email"]}')
    print(f'  Seller Full Name: {data["seller_full_name"]}')
    print(f'  Store: {data["store_name"]}')
    print(f'  Products: {data["products_grown"]}')
    print(f'  Submitted: {data["submitted_at"]}')
