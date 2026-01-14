"""
URL Configuration for Forecasting API endpoints.

Routes:
- GET  /api/admin/forecasts/              - List all forecasts
- GET  /api/admin/forecasts/{id}/         - Detailed forecast view
- GET  /api/admin/forecasts/search/       - Search and filter forecasts
- GET  /api/admin/forecasts/metadata/     - System statistics
- GET  /api/admin/forecasts/alerts/       - List alerts
- POST /api/admin/forecasts/refresh/      - Manual refresh (admin only)

Author: OPAS System
Created: December 2025
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.forecasting.views import ProductForecastViewSet

# Create router and register viewsets
router = DefaultRouter()
router.register(r'forecasts', ProductForecastViewSet, basename='forecast')

app_name = 'forecasting'

urlpatterns = [
    path('', include(router.urls)),
]
