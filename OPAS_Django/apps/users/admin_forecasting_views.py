"""
Admin Forecasting API Endpoints

Endpoints for OPAS Admin to manage forecasting with product grouping.
Includes:
- Product classification endpoints
- Group forecast endpoints
- Product breakdown by group
- Forecast comparison views
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import timedelta
import logging

from apps.users.forecasting_grouping import ProductGroupingService, ProductClassificationHelper
from apps.users.hybrid_forecasting import create_hybrid_forecaster
from apps.users.forecasting_algorithm import ForecastingAlgorithm
from apps.users.seller_models import SellerProduct

logger = logging.getLogger(__name__)


class AdminForecastingViewSet(viewsets.ViewSet):
    """
    Forecasting API for OPAS Admin
    
    Manages product forecasting with smart grouping by category/type/subtype
    """
    permission_classes = [IsAuthenticated]
    
    def _is_opas_admin(self, user):
        """Check if user is OPAS Admin"""
        return hasattr(user, 'is_opas_admin') and user.is_opas_admin
    
    @action(detail=False, methods=['get'])
    def product_classifications(self, request):
        """
        GET /api/admin/forecasting/product-classifications/
        
        Returns the full product hierarchy for classification
        Used by frontend to populate cascading dropdowns
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        hierarchy = ProductClassificationHelper.get_hierarchy()
        
        return Response({
            'categories': ProductClassificationHelper.get_categories(),
            'hierarchy': hierarchy,
        })
    
    @action(detail=False, methods=['get'])
    def types_for_category(self, request):
        """
        GET /api/admin/forecasting/types-for-category/?category=LIVESTOCK
        
        Get product types for a given category
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        category = request.query_params.get('category')
        if not category:
            return Response({'error': 'category parameter required'}, status=400)
        
        types = ProductClassificationHelper.get_types_for_category(category)
        
        # Always return data, even if empty list
        return Response({
            'category': category,
            'types': types,
        })
    
    @action(detail=False, methods=['get'])
    def subtypes_for_type(self, request):
        """
        GET /api/admin/forecasting/subtypes-for-type/?category=LIVESTOCK&type=Fish
        
        Get product subtypes for a given category and type
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        category = request.query_params.get('category')
        product_type = request.query_params.get('type')
        
        if not all([category, product_type]):
            return Response(
                {'error': 'category and type parameters required'},
                status=400
            )
        
        subtypes = ProductClassificationHelper.get_subtypes_for_type(category, product_type)
        
        # Always return data, even if empty list
        return Response({
            'category': category,
            'type': product_type,
            'subtypes': subtypes,
        })
    
    @action(detail=False, methods=['get'])
    def products_by_group(self, request):
        """
        GET /api/admin/forecasting/products-by-group/
        
        Returns all OPAS Admin products organized by forecast group (category:type:subtype)
        Shows data points and forecasting readiness per group
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            # Get all OPAS Admin products
            products = SellerProduct.objects.filter(
                seller=request.user,
                is_deleted=False,
                status='ACTIVE'
            ).order_by('-created_at')
            
            if not products.exists():
                return Response({
                    'message': 'No active products found',
                    'groups': []
                })
            
            # Group products by classification
            groups_dict = {}
            
            for product in products:
                group_key = product.get_forecast_group_key()
                
                if not group_key:
                    continue  # Skip products without classification
                
                if group_key not in groups_dict:
                    groups_dict[group_key] = {
                        'group_key': group_key,
                        'category': product.category_forecast,
                        'type': product.product_type,
                        'subtype': product.product_subtype,
                        'products': [],
                        'combined_data_points': 0,
                    }
                
                # Get sales data count for this product
                from apps.users.seller_models import SellerOrder
                cutoff_date = timezone.now().date() - timedelta(days=180)
                
                sales_count = SellerOrder.objects.filter(
                    product=product,
                    status__in=['FULFILLED', 'DELIVERED'],
                    created_at__date__gte=cutoff_date
                ).values('created_at__date').distinct().count()
                
                groups_dict[group_key]['products'].append({
                    'id': product.id,
                    'name': product.name,
                    'price': float(product.price),
                    'data_points': sales_count,
                })
                
                groups_dict[group_key]['combined_data_points'] += sales_count
            
            # Determine forecasting status
            groups_list = []
            for group_key, group_info in groups_dict.items():
                combined_data = group_info['combined_data_points']
                
                if combined_data < 20:
                    status_val = 'NO_FORECAST'
                    status_text = 'Insufficient Data'
                elif combined_data < 60:
                    status_val = 'BASIC_FORECAST'
                    status_text = 'Basic Forecasting Available'
                else:
                    status_val = 'ADVANCED_FORECAST'
                    status_text = 'Advanced AI Forecasting'
                
                group_info['status'] = status_val
                group_info['status_text'] = status_text
                group_info['days_until_next'] = (
                    20 - combined_data if combined_data < 20
                    else 60 - combined_data if combined_data < 60
                    else 0
                )
                
                groups_list.append(group_info)
            
            # Sort by data points descending
            groups_list.sort(key=lambda x: x['combined_data_points'], reverse=True)
            
            return Response({
                'total_groups': len(groups_list),
                'groups': groups_list,
            })
        
        except Exception as e:
            logger.error(f"Error fetching products by group: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def group_forecast(self, request):
        """
        GET /api/admin/forecasting/group-forecast/?category=LIVESTOCK&type=Fish&subtype=Bangus
        
        Get combined forecast for entire product group with individual product breakdown
        Shows how similar products are grouped and forecasted together
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            category = request.query_params.get('category')
            product_type = request.query_params.get('type')
            subtype = request.query_params.get('subtype')
            
            if not all([category, product_type, subtype]):
                return Response(
                    {'error': 'category, type, and subtype parameters required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get sample product from group
            sample_product = SellerProduct.objects.filter(
                seller=request.user,
                category_forecast=category,
                product_type=product_type,
                product_subtype=subtype,
                is_deleted=False,
                status='ACTIVE'
            ).first()
            
            if not sample_product:
                return Response(
                    {'error': 'No products found in this group'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Initialize forecasters
            hybrid_forecaster = create_hybrid_forecaster()
            stat_forecaster = ForecastingAlgorithm()
            
            # Get group summary
            group_summary = ProductGroupingService.get_group_data_summary(sample_product)
            
            if group_summary['status'] == 'NO_DATA':
                return Response(group_summary)
            
            # Get full breakdown
            breakdown = ProductGroupingService.get_group_forecast_breakdown(
                sample_product,
                stat_forecaster,
                hybrid_forecaster
            )
            
            return Response(breakdown)
        
        except Exception as e:
            logger.error(f"Error getting group forecast: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def product_forecast_detail(self, request):
        """
        GET /api/admin/forecasting/product-forecast-detail/?product_id=123
        
        Get detailed forecast for a specific product including group info
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            product_id = request.query_params.get('product_id')
            
            if not product_id:
                return Response(
                    {'error': 'product_id parameter required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get product
            product = SellerProduct.objects.get(
                id=product_id,
                seller=request.user,
                is_deleted=False
            )
            
            # Initialize forecasters
            hybrid_forecaster = create_hybrid_forecaster()
            stat_forecaster = ForecastingAlgorithm()
            
            # Get forecast with grouping
            forecast = ProductGroupingService.forecast_with_grouping(
                product,
                stat_forecaster,
                hybrid_forecaster
            )
            
            return Response({
                'product': {
                    'id': product.id,
                    'name': product.name,
                    'price': float(product.price),
                },
                'forecast': forecast,
            })
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error getting product forecast detail: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def forecast_readiness_dashboard(self, request):
        """
        GET /api/admin/forecasting/forecast-readiness-dashboard/
        
        High-level view of all product groups and their forecast readiness
        Shows which groups are ready for advanced ML, which need more data
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            products = SellerProduct.objects.filter(
                seller=request.user,
                is_deleted=False,
                status='ACTIVE'
            )
            
            groups_by_status = {
                'NO_FORECAST': [],
                'BASIC_FORECAST': [],
                'ADVANCED_FORECAST': [],
            }
            
            seen_groups = set()
            
            for product in products:
                group_key = product.get_forecast_group_key()
                
                if not group_key or group_key in seen_groups:
                    continue
                
                seen_groups.add(group_key)
                
                summary = ProductGroupingService.get_group_data_summary(product)
                group_status = summary['status']
                
                groups_by_status[group_status].append(summary)
            
            return Response({
                'no_forecast': {
                    'count': len(groups_by_status['NO_FORECAST']),
                    'message': 'Need 20+ days of data',
                    'groups': groups_by_status['NO_FORECAST'],
                },
                'basic_forecast': {
                    'count': len(groups_by_status['BASIC_FORECAST']),
                    'message': '20-60 days: Statistical + basic ML',
                    'groups': groups_by_status['BASIC_FORECAST'],
                },
                'advanced_forecast': {
                    'count': len(groups_by_status['ADVANCED_FORECAST']),
                    'message': '60+ days: Advanced AI forecasting',
                    'groups': groups_by_status['ADVANCED_FORECAST'],
                },
                'total_groups': len(seen_groups),
            })
        
        except Exception as e:
            logger.error(f"Error getting forecast readiness dashboard: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def add_type(self, request):
        """
        POST /api/admin/forecasting/add-type/
        
        Add a new product type to a category in the product hierarchy
        
        Request body:
        {
            "category": "VEGETABLE",
            "type": "NewType"
        }
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            category = request.data.get('category')
            product_type = request.data.get('type')
            
            if not all([category, product_type]):
                return Response(
                    {'error': 'category and type are required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get current hierarchy
            hierarchy = ProductClassificationHelper.get_hierarchy()
            
            # Check if category exists
            if category not in hierarchy:
                return Response(
                    {'error': f'Category {category} does not exist'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if type already exists
            if product_type in hierarchy[category]:
                return Response(
                    {'error': f'Type {product_type} already exists in {category}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Add the new type with empty subtypes list
            ProductClassificationHelper.add_type(category, product_type)
            
            return Response({
                'success': True,
                'message': f'Type {product_type} added to {category}',
                'category': category,
                'type': product_type,
            }, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f"Error adding product type: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def add_subtype(self, request):
        """
        POST /api/admin/forecasting/add-subtype/
        
        Add a new product subtype to a type in the product hierarchy
        
        Request body:
        {
            "category": "VEGETABLE",
            "type": "Leafy",
            "subtype": "NewSubtype"
        }
        """
        if not self._is_opas_admin(request.user):
            return Response(
                {'error': 'Only OPAS Admin can access this'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            category = request.data.get('category')
            product_type = request.data.get('type')
            subtype = request.data.get('subtype')
            
            if not all([category, product_type, subtype]):
                return Response(
                    {'error': 'category, type, and subtype are required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get current hierarchy
            hierarchy = ProductClassificationHelper.get_hierarchy()
            
            # Check if category exists
            if category not in hierarchy:
                return Response(
                    {'error': f'Category {category} does not exist'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if type exists
            if product_type not in hierarchy[category]:
                return Response(
                    {'error': f'Type {product_type} does not exist in {category}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if subtype already exists
            if subtype in hierarchy[category][product_type]:
                return Response(
                    {'error': f'Subtype {subtype} already exists'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Add the new subtype
            ProductClassificationHelper.add_subtype(category, product_type, subtype)
            
            return Response({
                'success': True,
                'message': f'Subtype {subtype} added to {category} > {product_type}',
                'category': category,
                'type': product_type,
                'subtype': subtype,
            }, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f"Error adding product subtype: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )