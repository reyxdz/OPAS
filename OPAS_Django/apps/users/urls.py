"""
URL Configuration for Users App - OPAS Platform (Seller Routes)

Routes include:
- User authentication and profile management
- Seller upgrade functionality
- Seller registration workflow (buyer-to-seller conversion)
- Seller panel endpoints (profile, products, orders, forecasting, payouts, analytics)

Seller Router endpoints (46 total):
- Profile: GET/PUT /api/users/seller/profile/, POST /api/users/seller/profile/submit_documents/, GET /api/users/seller/profile/document_status/
- Products: GET/POST /api/users/seller/products/, GET/PUT/DELETE /api/users/seller/products/{id}/, GET /api/users/seller/products/active/, GET /api/users/seller/products/expired/, POST /api/users/seller/products/check_ceiling_price/
- SellToOPAS: POST /api/users/seller/sell-to-opas/, GET /api/users/seller/sell-to-opas/pending/, GET /api/users/seller/sell-to-opas/history/, GET /api/users/seller/sell-to-opas/{id}/status/
- Orders: GET /api/users/seller/orders/incoming/, POST /api/users/seller/orders/{id}/accept/, POST /api/users/seller/orders/{id}/reject/, POST /api/users/seller/orders/{id}/mark_fulfilled/, POST /api/users/seller/orders/{id}/mark_delivered/, GET /api/users/seller/orders/completed/, GET /api/users/seller/orders/pending/, GET /api/users/seller/orders/cancelled/
- Inventory: GET /api/users/seller/inventory/overview/, GET /api/users/seller/inventory/by_product/, GET /api/users/seller/inventory/low_stock/, GET /api/users/seller/inventory/movement/
- Forecast: GET /api/users/seller/forecast/next_month/, GET /api/users/seller/forecast/product/{id}/, GET /api/users/seller/forecast/historical/, GET /api/users/seller/forecast/insights/
- Payouts: GET /api/users/seller/payouts/, GET /api/users/seller/payouts/pending/, GET /api/users/seller/payouts/completed/, GET /api/users/seller/payouts/earnings/
- Analytics: GET /api/users/seller/analytics/dashboard/, GET /api/users/seller/analytics/daily/, GET /api/users/seller/analytics/weekly/, GET /api/users/seller/analytics/monthly/, GET /api/users/seller/analytics/top_products/, GET /api/users/seller/analytics/forecast_vs_actual/
- Registration: POST /api/users/sellers/register-application/, GET /api/users/sellers/registrations/{id}/, GET /api/users/sellers/my-registration/
- Notifications: GET/POST /api/users/seller/notifications/
- Announcements: GET/POST /api/users/seller/announcements/

Note: Admin routes are now consolidated in apps.users.admin_urls at /api/admin/
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UpgradeToSellerView, SellerApplicationView, UserStatusView, FCMTokenView
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
    SellerRegistrationViewSet,
    MarketplaceViewSet,
    SellerPublicViewSet,
)


# ==================== ROUTER CONFIGURATION ====================

# Seller Router
seller_router = DefaultRouter()

# Buyer/Marketplace Router
buyer_router = DefaultRouter()

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

# Seller Registration Router
seller_router.register(
    r'sellers',
    SellerRegistrationViewSet,
    basename='seller-registration'
)

# ==================== BUYER MARKETPLACE ROUTERS ====================

# Marketplace Products Router
buyer_router.register(
    r'products',
    MarketplaceViewSet,
    basename='marketplace-products'
)

# Seller Public Profile Router
buyer_router.register(
    r'seller',
    SellerPublicViewSet,
    basename='seller-public'
)


# ==================== URL PATTERNS ====================

urlpatterns = [
    # User profile and seller upgrade
    path('upgrade-to-seller/', UpgradeToSellerView.as_view(), name='upgrade-to-seller'),
    
    # Get current user status and role
    path('me/', UserStatusView.as_view(), name='user-status'),
    
    # Seller application submission
    path('seller-application/', SellerApplicationView.as_view(), name='seller-application'),
    
    # FCM token for push notifications
    path('fcm-token/', FCMTokenView.as_view(), name='fcm-token'),
    
    # Include seller router URLs
    path('users/', include(seller_router.urls)),
    
    # Include buyer/marketplace router URLs
    path('', include(buyer_router.urls)),
]

