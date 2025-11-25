"""
Dashboard Metrics ViewSet Implementation Guide

This file provides ready-to-use code snippets for implementing the dashboard
metrics endpoint based on the completed Phase 3.1 enhancements.

Usage:
1. Copy the serializers section to admin_serializers.py
2. Copy the ViewSet section to admin_viewsets.py or create admin_dashboard.py
3. Register in admin_urls.py
4. Test with: GET /api/admin/dashboard/stats/
"""

from rest_framework import serializers, viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Count, Q, Sum, F, DecimalField
from datetime import timedelta
from decimal import Decimal

from .models import (
    User, UserRole, SellerStatus, ProductStatus, OrderStatus,
    SellerProduct, SellerOrder, SellToOPAS
)
from .admin_models import (
    OPASInventory, MarketplaceAlert, PriceNonCompliance,
    PriceHistory
)


# ==================== SERIALIZERS ====================

class SellerMetricsSerializer(serializers.Serializer):
    """Serializer for seller marketplace metrics"""
    total_sellers = serializers.IntegerField(read_only=True)
    pending_approvals = serializers.IntegerField(read_only=True)
    active_sellers = serializers.IntegerField(read_only=True)
    suspended_sellers = serializers.IntegerField(read_only=True)
    new_this_month = serializers.IntegerField(read_only=True)
    approval_rate = serializers.FloatField(read_only=True)


class MarketMetricsSerializer(serializers.Serializer):
    """Serializer for market metrics"""
    active_listings = serializers.IntegerField(read_only=True)
    total_sales_today = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        read_only=True
    )
    total_sales_month = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        read_only=True
    )
    avg_price_change = serializers.FloatField(read_only=True)
    avg_transaction = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        read_only=True
    )


class OPASMetricsSerializer(serializers.Serializer):
    """Serializer for OPAS metrics"""
    pending_submissions = serializers.IntegerField(read_only=True)
    approved_this_month = serializers.IntegerField(read_only=True)
    total_inventory = serializers.IntegerField(read_only=True)
    low_stock_count = serializers.IntegerField(read_only=True)
    expiring_count = serializers.IntegerField(read_only=True)
    total_inventory_value = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        read_only=True
    )


class PriceComplianceSerializer(serializers.Serializer):
    """Serializer for price compliance metrics"""
    compliant_listings = serializers.IntegerField(read_only=True)
    non_compliant = serializers.IntegerField(read_only=True)
    compliance_rate = serializers.FloatField(read_only=True)


class AlertsSerializer(serializers.Serializer):
    """Serializer for alerts and health metrics"""
    price_violations = serializers.IntegerField(read_only=True)
    seller_issues = serializers.IntegerField(read_only=True)
    inventory_alerts = serializers.IntegerField(read_only=True)
    total_open_alerts = serializers.IntegerField(read_only=True)


class AdminDashboardStatsSerializer(serializers.Serializer):
    """Comprehensive serializer for admin dashboard statistics"""
    timestamp = serializers.DateTimeField(read_only=True)
    seller_metrics = SellerMetricsSerializer(read_only=True)
    market_metrics = MarketMetricsSerializer(read_only=True)
    opas_metrics = OPASMetricsSerializer(read_only=True)
    price_compliance = PriceComplianceSerializer(read_only=True)
    alerts = AlertsSerializer(read_only=True)
    marketplace_health_score = serializers.IntegerField(read_only=True)


# ==================== VIEWSET ====================

class DashboardViewSet(viewsets.ViewSet):
    """Dashboard statistics for admin panel"""
    permission_classes = [IsAuthenticated]
    
    def _get_seller_metrics(self):
        """Calculate seller metrics"""
        seller_stats = User.objects.filter(role=UserRole.SELLER).aggregate(
            total=Count('id'),
            pending=Count('id', filter=Q(seller_status=SellerStatus.PENDING)),
            approved=Count('id', filter=Q(seller_status=SellerStatus.APPROVED)),
            suspended=Count('id', filter=Q(seller_status=SellerStatus.SUSPENDED)),
            rejected=Count('id', filter=Q(seller_status=SellerStatus.REJECTED)),
            new_this_month=Count('id', filter=Q(
                created_at__month=timezone.now().month,
                created_at__year=timezone.now().year
            ))
        )
        
        # Calculate approval rate
        total_decisions = seller_stats['approved'] + seller_stats['rejected']
        approval_rate = (
            (seller_stats['approved'] / total_decisions * 100)
            if total_decisions > 0 else 0
        )
        
        return {
            'total_sellers': seller_stats['total'],
            'pending_approvals': seller_stats['pending'],
            'active_sellers': seller_stats['approved'],
            'suspended_sellers': seller_stats['suspended'],
            'new_this_month': seller_stats['new_this_month'],
            'approval_rate': round(approval_rate, 2)
        }
    
    def _get_market_metrics(self):
        """Calculate market metrics"""
        today = timezone.now()
        current_month_start = today.replace(day=1)
        today_date = today.date()
        
        # Active listings
        active_listings = SellerProduct.objects.filter(
            is_deleted=False,
            status=ProductStatus.ACTIVE
        ).count()
        
        # Sales metrics
        sales_stats = SellerOrder.objects.filter(
            status=OrderStatus.DELIVERED
        ).aggregate(
            sales_today=Sum('total_amount', filter=Q(created_at__date=today_date)),
            sales_month=Sum(
                'total_amount',
                filter=Q(created_at__date__gte=current_month_start.date())
            ),
            orders_month=Count('id', filter=Q(
                created_at__date__gte=current_month_start.date()
            ))
        )
        
        sales_today = sales_stats['sales_today'] or Decimal('0')
        sales_month = sales_stats['sales_month'] or Decimal('0')
        orders_month = sales_stats['orders_month'] or 1
        
        avg_transaction = sales_month / orders_month if orders_month > 0 else Decimal('0')
        
        # Price change (simplified - from PriceHistory)
        avg_price_change = 0.0
        try:
            price_changes = PriceHistory.objects.filter(
                change_date__date=today_date
            ).count()
            if price_changes > 0:
                avg_price_change = 0.5  # Placeholder - calculate actual average
        except:
            avg_price_change = 0.0
        
        return {
            'active_listings': active_listings,
            'total_sales_today': float(sales_today),
            'total_sales_month': float(sales_month),
            'avg_price_change': avg_price_change,
            'avg_transaction': float(avg_transaction)
        }
    
    def _get_opas_metrics(self):
        """Calculate OPAS metrics"""
        current_month_start = timezone.now().replace(day=1).date()
        
        opas_stats = SellToOPAS.objects.aggregate(
            pending=Count('id', filter=Q(status='PENDING')),
            approved_month=Count('id', filter=Q(
                status='ACCEPTED',
                created_at__date__gte=current_month_start
            ))
        )
        
        # Inventory metrics
        total_inventory = OPASInventory.objects.total_quantity()
        low_stock_count = OPASInventory.objects.low_stock().count()
        expiring_count = OPASInventory.objects.expiring_soon(days=7).count()
        total_inventory_value = OPASInventory.objects.total_value() or Decimal('0')
        
        return {
            'pending_submissions': opas_stats['pending'],
            'approved_this_month': opas_stats['approved_month'],
            'total_inventory': total_inventory or 0,
            'low_stock_count': low_stock_count,
            'expiring_count': expiring_count,
            'total_inventory_value': float(total_inventory_value)
        }
    
    def _get_price_compliance(self):
        """Calculate price compliance metrics"""
        compliant = SellerProduct.objects.filter(
            is_deleted=False
        ).compliant().count()
        
        non_compliant = SellerProduct.objects.filter(
            is_deleted=False
        ).non_compliant().count()
        
        total = compliant + non_compliant
        compliance_rate = (compliant / total * 100) if total > 0 else 0
        
        return {
            'compliant_listings': compliant,
            'non_compliant': non_compliant,
            'compliance_rate': round(compliance_rate, 2)
        }
    
    def _get_alerts(self):
        """Calculate alerts and health metrics"""
        alert_stats = MarketplaceAlert.objects.filter(
            status='OPEN'
        ).aggregate(
            price_violations=Count('id', filter=Q(alert_type='PRICE_VIOLATION')),
            seller_issues=Count('id', filter=Q(alert_type='SELLER_ISSUE')),
            inventory_alerts=Count('id', filter=Q(alert_type='INVENTORY_ALERT')),
            total_open=Count('id')
        )
        
        return {
            'price_violations': alert_stats['price_violations'],
            'seller_issues': alert_stats['seller_issues'],
            'inventory_alerts': alert_stats['inventory_alerts'],
            'total_open_alerts': alert_stats['total_open']
        }
    
    def _calculate_health_score(self, compliance_data):
        """Calculate marketplace health score"""
        compliance_rate = compliance_data['compliance_rate']
        
        # Calculate order fulfillment rate
        today = timezone.now()
        current_month_start = today.replace(day=1).date()
        
        fulfillment_stats = SellerOrder.objects.filter(
            status=OrderStatus.DELIVERED,
            created_at__date__gte=current_month_start
        ).aggregate(
            on_time=Count('id', filter=Q(on_time=True)),
            total=Count('id')
        )
        
        order_fulfillment_rate = (
            (fulfillment_stats['on_time'] / fulfillment_stats['total'] * 100)
            if fulfillment_stats['total'] > 0 else 0
        )
        
        # Calculate health score (fallback without seller ratings)
        health_score = (
            (compliance_rate * 0.5) +
            (order_fulfillment_rate * 0.5)
        )
        
        return int(health_score)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Get comprehensive admin dashboard statistics
        
        Returns:
            JSON object with all dashboard metrics organized by category
        
        Example Response:
        {
            "timestamp": "2025-11-22T14:35:42.123456Z",
            "seller_metrics": {...},
            "market_metrics": {...},
            "opas_metrics": {...},
            "price_compliance": {...},
            "alerts": {...},
            "marketplace_health_score": 92
        }
        """
        try:
            # Calculate all metrics
            seller_metrics = self._get_seller_metrics()
            market_metrics = self._get_market_metrics()
            opas_metrics = self._get_opas_metrics()
            price_compliance = self._get_price_compliance()
            alerts = self._get_alerts()
            health_score = self._calculate_health_score(price_compliance)
            
            # Prepare response
            data = {
                'timestamp': timezone.now(),
                'seller_metrics': seller_metrics,
                'market_metrics': market_metrics,
                'opas_metrics': opas_metrics,
                'price_compliance': price_compliance,
                'alerts': alerts,
                'marketplace_health_score': health_score
            }
            
            serializer = AdminDashboardStatsSerializer(data)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== REGISTRATION ====================
# Add to admin_urls.py:
"""
from rest_framework.routers import DefaultRouter
from .admin_dashboard import DashboardViewSet

router = DefaultRouter()
router.register(r'dashboard', DashboardViewSet, basename='admin-dashboard')

urlpatterns = [
    ...
    path('', include(router.urls)),
    ...
]

# URL: GET /api/admin/dashboard/stats/
"""


# ==================== PERMISSION CLASSES ====================
# Add to admin_permissions.py:
"""
from rest_framework.permissions import BasePermission

class IsOPASAdmin(BasePermission):
    '''
    Allow access only to OPAS admins
    '''
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_opas_admin)

# Then use in ViewSet:
class DashboardViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated, IsOPASAdmin]
    ...
"""


# ==================== TESTING EXAMPLE ====================
# Test endpoint:
"""
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model

User = get_user_model()

class DashboardStatsTestCase(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            email='admin@test.com',
            password='pass123',
            username='admin',
            role='ADMIN'
        )
        self.client.force_authenticate(user=self.admin)
    
    def test_dashboard_stats_endpoint(self):
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertIn('timestamp', data)
        self.assertIn('seller_metrics', data)
        self.assertIn('marketplace_health_score', data)
    
    def test_unauthorized_access(self):
        self.client.force_authenticate(user=None)
        response = self.client.get('/api/admin/dashboard/stats/')
        self.assertEqual(response.status_code, 401)
"""
