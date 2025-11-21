"""
URL Configuration for Users App - OPAS Platform

Routes include:
- User authentication and profile management
- Seller upgrade functionality
- Admin panel endpoints (dashboard, sellers, users, pricing, inventory, announcements)
- Seller panel endpoints (profile, products, orders, forecasting, payouts, analytics)

Admin Router endpoints (43 total):
- GET/POST /api/users/admin/dashboard/stats/ - Dashboard statistics
- GET/POST /api/users/admin/sellers/ - List sellers
- GET /api/users/admin/sellers/pending_approvals/ - Pending approvals
- GET /api/users/admin/sellers/list_sellers/ - All sellers
- POST /api/users/admin/sellers/{id}/approve/ - Approve seller
- POST /api/users/admin/sellers/{id}/suspend/ - Suspend seller
- POST /api/users/admin/sellers/{id}/verify_documents/ - Verify documents
- GET/POST /api/users/admin/users/ - List users
- GET /api/users/admin/users/list_users/ - User list with filters
- GET /api/users/admin/users/statistics/ - User statistics
- GET/POST /api/users/admin/pricing/ - Price regulation
- POST /api/users/admin/pricing/set_ceiling_price/ - Set ceiling price
- POST /api/users/admin/pricing/post_advisory/ - Post price advisory
- GET /api/users/admin/pricing/violations/ - Price violations
- GET/POST /api/users/admin/inventory/ - Inventory management
- GET /api/users/admin/inventory/current_stock/ - Current stock
- GET /api/users/admin/inventory/low_stock/ - Low stock items
- POST /api/users/admin/inventory/accept_sell_to_opas/ - Accept submissions
- GET/POST /api/users/admin/announcements/ - Announcements
- POST /api/users/admin/announcements/create_announcement/ - Create announcement
- GET /api/users/admin/announcements/list_announcements/ - List announcements

Seller Router endpoints (43 total):
- Profile: GET/PUT /api/seller/profile/, POST /api/seller/profile/submit_documents/, GET /api/seller/profile/document_status/
- Products: GET/POST /api/seller/products/, GET/PUT/DELETE /api/seller/products/{id}/, GET /api/seller/products/active/, GET /api/seller/products/expired/, POST /api/seller/products/check_ceiling_price/
- SellToOPAS: POST /api/seller/sell-to-opas/, GET /api/seller/sell-to-opas/pending/, GET /api/seller/sell-to-opas/history/, GET /api/seller/sell-to-opas/{id}/status/
- Orders: GET /api/seller/orders/incoming/, POST /api/seller/orders/{id}/accept/, POST /api/seller/orders/{id}/reject/, POST /api/seller/orders/{id}/mark_fulfilled/, POST /api/seller/orders/{id}/mark_delivered/, GET /api/seller/orders/completed/, GET /api/seller/orders/pending/, GET /api/seller/orders/cancelled/
- Inventory: GET /api/seller/inventory/overview/, GET /api/seller/inventory/by_product/, GET /api/seller/inventory/low_stock/, GET /api/seller/inventory/movement/
- Forecast: GET /api/seller/forecast/next_month/, GET /api/seller/forecast/product/{id}/, GET /api/seller/forecast/historical/, GET /api/seller/forecast/insights/
- Payouts: GET /api/seller/payouts/, GET /api/seller/payouts/pending/, GET /api/seller/payouts/completed/, GET /api/seller/payouts/earnings/
- Analytics: GET /api/seller/analytics/dashboard/, GET /api/seller/analytics/daily/, GET /api/seller/analytics/weekly/, GET /api/seller/analytics/monthly/, GET /api/seller/analytics/top_products/, GET /api/seller/analytics/forecast_vs_actual/
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .views import UpgradeToSellerView, SellerApplicationView
from .admin_views import (
    AdminDashboardView,
    SellerManagementViewSet,
    UserManagementViewSet,
    PriceRegulationViewSet,
    InventoryManagementViewSet,
    AnnouncementViewSet,
)
from .seller_views import (
    SellerProfileViewSet,
    ProductManagementViewSet,
    SellToOPASViewSet,
    OrderManagementViewSet,
    InventoryTrackingViewSet,
    ForecastingViewSet,
    PayoutTrackingViewSet,
    AnalyticsViewSet,
    NotificationViewSet,
    AnnouncementViewSet as SellerAnnouncementViewSet,
)


# ==================== WRAPPER VIEWS ====================

class ApproveSellerApplicationView(APIView):
    """Wrapper view for approving seller applications"""
    def post(self, request, pk=None):
        viewset = SellerManagementViewSet()
        viewset.request = request
        viewset.format_kwarg = None
        return viewset.approve_application(request, pk=pk)


class RejectSellerApplicationView(APIView):
    """Wrapper view for rejecting seller applications"""
    def post(self, request, pk=None):
        viewset = SellerManagementViewSet()
        viewset.request = request
        viewset.format_kwarg = None
        return viewset.reject_application(request, pk=pk)


# ==================== ROUTER CONFIGURATION ====================

# Admin Router
admin_router = DefaultRouter()

# Admin Dashboard Router
admin_router.register(
    r'admin/dashboard',
    AdminDashboardView,
    basename='admin-dashboard'
)

# Seller Management Router
admin_router.register(
    r'admin/sellers',
    SellerManagementViewSet,
    basename='seller-management'
)

# User Management Router
admin_router.register(
    r'admin/users',
    UserManagementViewSet,
    basename='user-management'
)

# Price Regulation Router
admin_router.register(
    r'admin/pricing',
    PriceRegulationViewSet,
    basename='price-regulation'
)

# Inventory Management Router
admin_router.register(
    r'admin/inventory',
    InventoryManagementViewSet,
    basename='inventory-management'
)

# Announcements Router
admin_router.register(
    r'admin/announcements',
    AnnouncementViewSet,
    basename='announcements'
)


# Seller Router
seller_router = DefaultRouter()

# Seller Profile Router
seller_router.register(
    r'seller/profile',
    SellerProfileViewSet,
    basename='seller-profile'
)

# Product Management Router
seller_router.register(
    r'seller/products',
    ProductManagementViewSet,
    basename='seller-products'
)

# Sell to OPAS Router
seller_router.register(
    r'seller/sell-to-opas',
    SellToOPASViewSet,
    basename='seller-sell-to-opas'
)

# Order Management Router
seller_router.register(
    r'seller/orders',
    OrderManagementViewSet,
    basename='seller-orders'
)

# Inventory Tracking Router
seller_router.register(
    r'seller/inventory',
    InventoryTrackingViewSet,
    basename='seller-inventory'
)

# Forecasting Router
seller_router.register(
    r'seller/forecast',
    ForecastingViewSet,
    basename='seller-forecast'
)

# Payout Tracking Router
seller_router.register(
    r'seller/payouts',
    PayoutTrackingViewSet,
    basename='seller-payouts'
)

# Analytics Router
seller_router.register(
    r'seller/analytics',
    AnalyticsViewSet,
    basename='seller-analytics'
)

# Notifications Router
seller_router.register(
    r'seller/notifications',
    NotificationViewSet,
    basename='seller-notifications'
)

# Seller Announcements Router
seller_router.register(
    r'seller/announcements',
    SellerAnnouncementViewSet,
    basename='seller-announcements'
)


# ==================== URL PATTERNS ====================

urlpatterns = [
    # User profile and seller upgrade
    path('upgrade-to-seller/', UpgradeToSellerView.as_view(), name='upgrade-to-seller'),
    
    # Seller application submission
    path('seller-application/', SellerApplicationView.as_view(), name='seller-application'),
    
    # Seller Management - Explicit routes for application actions
    path('admin/sellers/<int:pk>/approve-application/', ApproveSellerApplicationView.as_view(), name='seller-management-approve-application'),
    path('admin/sellers/<int:pk>/reject-application/', RejectSellerApplicationView.as_view(), name='seller-management-reject-application'),
    
    # Include admin router URLs
    path('', include(admin_router.urls)),
    
    # Include seller router URLs with 'api/' prefix
    path('', include(seller_router.urls)),
]

