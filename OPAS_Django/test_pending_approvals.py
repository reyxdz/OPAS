#!/usr/bin/env python
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'OPAS_Django.settings')
sys.path.insert(0, os.path.dirname(__file__))

django.setup()

from apps.users.models import SellerApplication
from apps.users.admin_serializers import SellerApplicationSerializer
import json

pending = SellerApplication.objects.filter(status='PENDING')
print(f'Total pending applications: {pending.count()}')
print()

for app in pending:
    serializer = SellerApplicationSerializer(app)
    print('Serialized Application:')
    print(json.dumps(serializer.data, indent=2, default=str))
    print()
