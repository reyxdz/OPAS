"""
Admin API URL configuration for OPAS platform.

URL routing for all admin panel endpoints using Django REST Framework SimpleRouter.

Admin endpoints available at /api/admin/:
- dashboard/ - Dashboard statistics
- sellers/ - Seller management
- prices/ - Price regulation
- opas/ - OPAS purchasing
- marketplace/ - Marketplace oversight
- analytics/ - Analytics reporting
- notifications/ - Admin notifications
- audit-logs/ - Audit logs
- marketplace-control/ - Part 3: Admin Marketplace Control (new)
- price-monitoring/ - Part 3: Price Violation Monitoring (new)
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
    AdminAuditViewSet,
    DashboardViewSet,
    AdminMarketplaceViewSet,
    AdminPriceMonitoringViewSet,
    ProductApprovalViewSet,
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
router.register(r'audit-logs', AdminAuditViewSet, basename='admin-audit-logs')
router.register(r'dashboard', DashboardViewSet, basename='admin-dashboard')

# Part 3: Admin Marketplace Control
router.register(r'marketplace-control', AdminMarketplaceViewSet, basename='admin-marketplace-control')

# Part 3: Admin Price Monitoring
router.register(r'price-monitoring', AdminPriceMonitoringViewSet, basename='admin-price-monitoring')

# Product Approval Management
router.register(r'products', ProductApprovalViewSet, basename='admin-products')

# URL patterns
urlpatterns = [
    path('', include(router.urls)),
]

__all__ = ['urlpatterns', 'router']
