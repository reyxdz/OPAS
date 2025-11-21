"""
Admin API URL configuration for OPAS platform.

URL routing for all admin panel endpoints using Django REST Framework SimpleRouter.
"""

from django.urls import path, include
from rest_framework.routers import SimpleRouter

from apps.users.admin_viewsets import (
    SellerManagementViewSet,
    PriceManagementViewSet,
    OPASPurchasingViewSet,
    MarketplaceOversightViewSet,
    AnalyticsReportingViewSet,
    AdminNotificationsViewSet,
)

# Initialize SimpleRouter for automatic route generation
router = SimpleRouter()

# Register ViewSets with their base routes
router.register(r'sellers', SellerManagementViewSet, basename='admin-sellers')
router.register(r'prices', PriceManagementViewSet, basename='admin-prices')
router.register(r'opas', OPASPurchasingViewSet, basename='admin-opas')
router.register(r'marketplace', MarketplaceOversightViewSet, basename='admin-marketplace')
router.register(r'analytics', AnalyticsReportingViewSet, basename='admin-analytics')
router.register(r'notifications', AdminNotificationsViewSet, basename='admin-notifications')

# URL patterns
urlpatterns = [
    path('', include(router.urls)),
]

__all__ = ['urlpatterns', 'router']
