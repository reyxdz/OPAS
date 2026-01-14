"""
Views for Forecasting API endpoints.

Provides REST API endpoints for:
- Listing all forecasts with filtering
- Detailed forecast view for single product
- Search and filter forecasts by various criteria
- System-wide forecasting statistics and coverage
- Manual forecast refresh (admin only)
- Forecast alerts listing and management

All endpoints require admin authentication.

Author: OPAS System
Created: December 2025
"""

import logging
from decimal import Decimal
from datetime import datetime, timedelta

from django.utils import timezone
from django.db.models import Q, Count, Avg, Max, Min
from django.core.paginator import Paginator

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.parsers import JSONParser

from apps.forecasting.models import (
    ProductForecast,
    ForecastMetadata,
    ForecastAlert,
    AlertType,
    AlertSeverity,
)
from apps.forecasting.serializers import (
    ProductForecastSerializer,
    ProductForecastListSerializer,
    ForecastMetadataSerializer,
    ForecastAlertSerializer,
    ForecastDetailSerializer,
    ForecastCoverageStatisticsSerializer,
    ForecastRefreshRequestSerializer,
    ForecastRefreshResponseSerializer,
)
from apps.forecasting.serializers_enhanced import (
    ForecastDetailedSerializer,
    ForecastMetadataDetailedSerializer,
)
from apps.forecasting.services import ForecastingService
from apps.users.models import SellerProduct
from apps.users.opas_models import OPASProduct
from apps.users.seller_models import ProductStatus

logger = logging.getLogger(__name__)


class IsAdminUser(BasePermission):
    """
    Permission class to allow only admin users.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_admin)


class IsSuperAdminUser(BasePermission):
    """
    Permission class to allow only super admin users.
    """
    def has_permission(self, request, view):
        return (
            bool(request.user and request.user.is_authenticated) and
            request.user.is_admin and
            request.user.admin_role in ['SUPER_ADMIN', 'SYSTEM_ADMIN']
        )


class IsAdminForForecasting(BasePermission):
    """
    Allow Super Admin, Analytics Admin, or superuser to view forecasts.
    
    This permission class is specifically for the forecasting feature,
    allowing super admins, analytics admins, and Django superusers to access
    forecast data and analytics.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Allow Django superusers
        if request.user.is_superuser:
            return True
        
        # Allow admin users with correct role
        if hasattr(request.user, 'is_admin') and request.user.is_admin:
            if hasattr(request.user, 'admin_role'):
                return request.user.admin_role in ['SUPER_ADMIN', 'ANALYTICS_ADMIN']
        
        return False


class ProductForecastViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for ProductForecast model.
    
    Provides endpoints for:
    - GET /api/admin/forecasts/ - List all forecasts with pagination
    - GET /api/admin/forecasts/{id}/ - Detailed forecast view
    - GET /api/admin/forecasts/search/ - Filter forecasts
    - GET /api/admin/forecasts/metadata/ - System statistics
    - POST /api/admin/forecasts/refresh/ - Manual refresh (admin only)
    - GET /api/admin/forecasts/alerts/ - Active alerts
    """
    
    permission_classes = [IsAuthenticated, IsAdminForForecasting]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['product__name', 'product__category__name']
    ordering_fields = ['forecast_date', 'confidence_level', 'model_type']
    ordering = ['-forecast_date']
    pagination_class = None  # Will implement manual pagination
    
    def get_queryset(self):
        """
        Returns current (is_current=True) forecasts for products.
        Filters based on query parameters.
        """
        queryset = ProductForecast.objects.filter(
            is_current=True
        ).select_related('product', 'product__category', 'product__seller')
        
        # Filter by confidence level
        confidence = self.request.query_params.get('confidence', None)
        if confidence:
            queryset = queryset.filter(confidence_level=confidence)
        
        # Filter by model type
        model_type = self.request.query_params.get('model_type', None)
        if model_type:
            queryset = queryset.filter(model_type=model_type)
        
        # Filter by category
        category = self.request.query_params.get('category', None)
        if category:
            queryset = queryset.filter(product__category__name=category)
        
        # Filter only reliable forecasts
        reliable = self.request.query_params.get('reliable', None)
        if reliable in ['true', '1', 'yes']:
            queryset = queryset.exclude(model_type='INSUFFICIENT_DATA')
        
        # Filter by forecast period
        period = self.request.query_params.get('period', None)
        if period:
            queryset = queryset.filter(forecast_period=period)
        
        # Stale forecasts filter
        stale = self.request.query_params.get('stale', None)
        if stale in ['true', '1', 'yes']:
            cutoff = timezone.now() - timedelta(days=7)
            queryset = queryset.filter(forecast_date__lt=cutoff)
        
        return queryset.order_by('-forecast_date')

    def get_serializer_class(self):
        """Use lightweight serializer for list, enhanced for detail with validation metrics"""
        if self.action == 'retrieve':
            return ForecastDetailedSerializer  # Shows validation metrics
        return ProductForecastListSerializer

    def list(self, request, *args, **kwargs):
        """
        List all current forecasts with pagination.
        
        Query Parameters:
        - confidence: Filter by HIGH/MEDIUM/LOW
        - model_type: Filter by SARIMA/ARIMA/SIMPLE/INSUFFICIENT_DATA
        - category: Filter by product category name
        - reliable: 'true' to exclude INSUFFICIENT_DATA
        - period: Filter by forecast period
        - stale: 'true' to show only stale forecasts (>7 days old)
        - search: Search by product name or category
        - ordering: Order by field (forecast_date, confidence_level, model_type)
        - page_size: Results per page (default 20)
        """
        queryset = self.get_queryset()
        
        # Apply search filter
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(product__name__icontains=search) |
                Q(product__category__name__icontains=search)
            )
        
        # Apply ordering
        ordering = self.request.query_params.get('ordering', '-forecast_date')
        queryset = queryset.order_by(ordering)
        
        # Pagination
        page_size = int(self.request.query_params.get('page_size', 20))
        page = int(self.request.query_params.get('page', 1))
        
        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)
        
        serializer = self.get_serializer(page_obj, many=True)
        
        return Response({
            'count': paginator.count,
            'total_pages': paginator.num_pages,
            'current_page': page,
            'page_size': page_size,
            'results': serializer.data
        })

    def retrieve(self, request, *args, **kwargs):
        """
        Get detailed forecast for a specific product.
        
        Returns: Full forecast data with metadata, alerts, and staleness info
        """
        product_id = kwargs.get('pk')
        
        try:
            forecast = ProductForecast.objects.get(
                product_id=product_id,
                is_current=True
            )
        except ProductForecast.DoesNotExist:
            return Response(
                {'detail': 'No current forecast found for this product'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = self.get_serializer(forecast)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='history')
    def history(self, request):
        """
        Get all historical forecasts (including old ones) for a product.
        
        Query Parameters:
        - product_name: Required. Filter by product name
        
        Returns: All forecasts for this product ordered by forecast date (newest first)
        """
        product_name = request.query_params.get('product_name', None)
        
        if not product_name:
            return Response(
                {'detail': 'product_name query parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get ALL forecasts for this product (not just current)
        queryset = ProductForecast.objects.filter(
            product_name=product_name
        ).order_by('-forecast_date')
        
        if not queryset.exists():
            return Response(
                {'detail': f'No forecasts found for product: {product_name}'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = ProductForecastListSerializer(queryset, many=True)
        
        return Response({
            'product_name': product_name,
            'total_forecasts': queryset.count(),
            'results': serializer.data
        })

    @action(detail=False, methods=['get'], url_path='search')
    def search(self, request):
        """
        Advanced search and filter for forecasts.
        
        Supports complex filtering by multiple criteria:
        - Product name or category (search query)
        - Confidence level (HIGH/MEDIUM/LOW)
        - Model type (SARIMA/ARIMA/SIMPLE)
        - Category name
        - Reliable forecasts only (exclude INSUFFICIENT_DATA)
        - Stale forecasts (>7 days old)
        - Forecast period
        
        Returns paginated results with count and total pages.
        """
        queryset = self.get_queryset()
        
        # Apply all filters
        search = request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(product__name__icontains=search) |
                Q(product__category__name__icontains=search)
            )
        
        ordering = request.query_params.get('ordering', '-forecast_date')
        queryset = queryset.order_by(ordering)
        
        page_size = int(request.query_params.get('page_size', 20))
        page = int(request.query_params.get('page', 1))
        
        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)
        
        serializer = ProductForecastListSerializer(page_obj, many=True)
        
        return Response({
            'count': paginator.count,
            'total_pages': paginator.num_pages,
            'current_page': page,
            'page_size': page_size,
            'results': serializer.data
        })

    @action(detail=False, methods=['get'])
    def metadata(self, request):
        """
        Get system-wide forecasting statistics and coverage information.
        
        Returns:
        - Total products in system
        - Products with forecasts
        - Coverage percentage
        - Breakdown by model type
        - Breakdown by confidence level
        - Stale forecasts count
        - Insufficient data count
        - Average forecast age
        """
        all_products = SellerProduct.objects.filter(
            status=ProductStatus.ACTIVE,
            is_deleted=False
        ).count()
        
        forecasts = ProductForecast.objects.filter(is_current=True)
        products_with_forecasts = forecasts.values('product_id').distinct().count()
        
        coverage_pct = (
            (products_with_forecasts / all_products * 100)
            if all_products > 0 else 0
        )
        
        # Group by model type
        model_breakdown = dict(
            forecasts.values('model_type').annotate(count=Count('id')).values_list('model_type', 'count')
        )
        
        # Group by confidence level
        confidence_breakdown = dict(
            forecasts.values('confidence_level').annotate(count=Count('id')).values_list('confidence_level', 'count')
        )
        
        # Stale forecasts (>7 days old)
        cutoff = timezone.now() - timedelta(days=7)
        stale_count = forecasts.filter(forecast_date__lt=cutoff).count()
        
        # Insufficient data count
        insufficient = forecasts.filter(model_type='INSUFFICIENT_DATA').count()
        
        # Average forecast age
        age_stats = forecasts.aggregate(
            avg_age=Avg(timezone.now() - timezone.now())  # Will use Python calculation
        )
        
        # Calculate average age in days
        if forecasts.exists():
            ages = [(timezone.now() - f.forecast_date).days for f in forecasts]
            avg_age = sum(ages) / len(ages) if ages else 0
        else:
            avg_age = 0
        
        # Last batch generation (most recent forecast date)
        last_batch = forecasts.aggregate(Max('forecast_date'))['forecast_date__max']
        
        data = {
            'total_products': all_products,
            'products_with_forecasts': products_with_forecasts,
            'coverage_percentage': round(coverage_pct, 2),
            'products_by_model_type': model_breakdown,
            'products_by_confidence': confidence_breakdown,
            'last_batch_generation': last_batch,
            'avg_forecast_age_days': round(avg_age, 2),
            'stale_forecasts_count': stale_count,
            'insufficient_data_count': insufficient,
        }
        
        serializer = ForecastCoverageStatisticsSerializer(data)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def alerts(self, request):
        """
        List all active forecast alerts.
        
        Query Parameters:
        - severity: Filter by INFO/WARNING/CRITICAL
        - alert_type: Filter by alert type
        - product_id: Filter by product ID
        - unacknowledged_only: 'true' to show only unacknowledged
        - page_size: Results per page (default 20)
        """
        queryset = ForecastAlert.objects.select_related('product')
        
        # Filter unacknowledged by default
        unacknowledged_only = request.query_params.get('unacknowledged_only', 'true')
        if unacknowledged_only in ['true', '1', 'yes']:
            queryset = queryset.filter(is_acknowledged=False)
        
        # Filter by severity
        severity = request.query_params.get('severity', None)
        if severity:
            queryset = queryset.filter(severity=severity)
        
        # Filter by alert type
        alert_type = request.query_params.get('alert_type', None)
        if alert_type:
            queryset = queryset.filter(alert_type=alert_type)
        
        # Filter by product
        product_id = request.query_params.get('product_id', None)
        if product_id:
            queryset = queryset.filter(product_id=product_id)
        
        # Order by creation date
        queryset = queryset.order_by('-created_at')
        
        # Pagination
        page_size = int(request.query_params.get('page_size', 20))
        page = int(request.query_params.get('page', 1))
        
        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)
        
        serializer = ForecastAlertSerializer(page_obj, many=True)
        
        return Response({
            'count': paginator.count,
            'total_pages': paginator.num_pages,
            'current_page': page,
            'page_size': page_size,
            'results': serializer.data
        })

    @action(detail=False, methods=['get'], url_path='types-for-category')
    def types_for_category(self, request):
        """Get types for a category from actual OPASProduct data"""
        try:
            category = request.query_params.get('category')
            if not category:
                return Response(
                    {'error': 'Category parameter is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get unique types for this category from OPASProduct
            types = OPASProduct.objects.filter(
                category_forecast=category,
                is_active=True
            ).values_list('product_type', flat=True).distinct().order_by('product_type')
            
            types_list = [t for t in types if t]  # Filter out None/empty values
            
            return Response({
                'category': category,
                'types': types_list
            }, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f'Error fetching types: {str(e)}')
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['get'], url_path='subtypes-for-type')
    def subtypes_for_type(self, request):
        """Get subtypes for a type from actual OPASProduct data"""
        try:
            category = request.query_params.get('category')
            type_value = request.query_params.get('type')
            
            if not category or not type_value:
                return Response(
                    {'error': 'Category and type parameters are required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get unique subtypes for this category:type combination from OPASProduct
            subtypes = OPASProduct.objects.filter(
                category_forecast=category,
                product_type=type_value,
                is_active=True
            ).values_list('product_subtype', flat=True).distinct().order_by('product_subtype')
            
            subtypes_list = [s for s in subtypes if s]  # Filter out None/empty values
            
            return Response({
                'category': category,
                'type': type_value,
                'subtypes': subtypes_list
            }, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f'Error fetching subtypes: {str(e)}')
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated, IsSuperAdminUser])
    def refresh(self, request):
        """
        Manually trigger forecast refresh for selected products or all products.
        
        Request Body:
        {
            "product_ids": [1, 2, 3],  # Optional, if empty refreshes all
            "force_regenerate": false   # If true, regenerates even if recent
        }
        
        Returns:
        {
            "status": "success|processing",
            "total_processed": 45,
            "successful": 43,
            "failed": 2,
            "task_id": "celery_task_id",  # If async
            "message": "Refresh initiated for 45 products"
        }
        """
        serializer = ForecastRefreshRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        product_ids = serializer.validated_data.get('product_ids', None)
        force_regenerate = serializer.validated_data.get('force_regenerate', False)
        
        try:
            forecasting_service = ForecastingService()
            
            if product_ids:
                # Refresh specific products
                total = len(product_ids)
                successful = 0
                failed = 0
                
                for product_id in product_ids:
                    try:
                        product = SellerProduct.objects.get(id=product_id)
                        result = forecasting_service.generate_forecast(product)
                        if result and result.forecast_id:
                            successful += 1
                        else:
                            failed += 1
                    except Exception as e:
                        logger.error(f"Error refreshing product {product_id}: {str(e)}")
                        failed += 1
                
                message = f"Refresh completed for {total} products ({successful} successful, {failed} failed)"
            else:
                # Refresh all products with sufficient data
                result = forecasting_service.batch_generate_all_products()
                successful = result.get('successful_count', 0)
                failed = result.get('failed_count', 0)
                total = successful + failed
                stale_detected = result.get('stale_forecasts_detected', 0)
                alerts_created = result.get('alerts_created', 0)
                
                message = (
                    f"Batch refresh completed: {successful} successful, {failed} failed. "
                    f"Detected {stale_detected} stale forecasts, created {alerts_created} alerts."
                )
            
            response_data = {
                'status': 'success',
                'total_processed': total,
                'successful': successful,
                'failed': failed,
                'stale_forecasts_detected': stale_detected if not product_ids else None,
                'alerts_created': alerts_created if not product_ids else None,
                'task_id': None,
                'message': message,
                'timestamp': timezone.now(),
            }
            
            logger.info(f"Manual forecast refresh initiated by {request.user.username}: {message}")
            
            serializer = ForecastRefreshResponseSerializer(response_data)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f"Error during forecast refresh: {str(e)}", exc_info=True)
            return Response(
                {
                    'status': 'error',
                    'message': f"Error during forecast refresh: {str(e)}",
                    'timestamp': timezone.now(),
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
