#!/usr/bin/env python
"""Test the serializer with actual forecast data"""

import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from apps.forecasting.models import ProductForecast
from apps.forecasting.serializers import ProductForecastListSerializer
import json

# Test serializer directly
forecasts = ProductForecast.objects.all()[:3]
print(f"Found {forecasts.count()} forecasts\n")

try:
    serializer = ProductForecastListSerializer(forecasts, many=True)
    print("✅ Serialization successful!\n")
    print("Sample data:")
    print(json.dumps(serializer.data, indent=2, default=str))
except Exception as e:
    print(f"❌ Serialization failed: {e}")
    import traceback
    traceback.print_exc()
