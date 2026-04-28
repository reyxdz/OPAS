#!/usr/bin/env python
import os
import sys
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Add current directory to path
sys.path.insert(0, os.path.dirname(__file__))

import django
django.setup()

from django.test import RequestFactory
from apps.users.admin_viewsets import SellerManagementViewSet
from rest_framework.request import Request as DRFRequest
from rest_framework_simplejwt.tokens import RefreshToken
from apps.users.models import User
import json

# Create a test admin user
try:
    admin_user = User.objects.get(phone_number='09123456789')
except User.DoesNotExist:
    print("Admin user not found, creating mock request...")
    admin_user = None

# Create the viewset and test the endpoint
factory = RequestFactory()
request = factory.get('/api/admin/sellers/pending-approvals/')
drf_request = DRFRequest(request)

viewset = SellerManagementViewSet()
viewset.request = drf_request
viewset.format_kwarg = None

try:
    response = viewset.pending_approvals(drf_request)
    print('API Response:')
    print(json.dumps(response.data, indent=2, default=str))
except Exception as e:
    print(f'Error calling endpoint: {e}')
    import traceback
    traceback.print_exc()
