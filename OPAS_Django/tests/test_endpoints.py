#!/usr/bin/env python
"""Test script for classification endpoints"""
import os
import sys
import django

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.test import APIRequestFactory
from apps.users.admin_viewsets import OPASForecastingViewSet

factory = APIRequestFactory()

# Test types_for_category
request = factory.get('/api/admin/forecasts/types-for-category/?category=FRUIT')
viewset = OPASForecastingViewSet()
viewset.request = request
response = viewset.types_for_category(request)

print("Test 1: types_for_category")
print("Status Code:", response.status_code)
print("Response Data:", response.data)
print()

# Test subtypes_for_type
request = factory.get('/api/admin/forecasts/subtypes-for-type/?category=FRUIT&type=Citrus')
viewset = OPASForecastingViewSet()
viewset.request = request
response = viewset.subtypes_for_type(request)

print("Test 2: subtypes_for_type")
print("Status Code:", response.status_code)
print("Response Data:", response.data)
