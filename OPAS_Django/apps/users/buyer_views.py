"""
Buyer-related views and API endpoints for OPAS marketplace.

Handles:
- Order creation and management from buyer perspective
- Cart operations
- Product browsing and search
- Seller browsing and ratings
"""

from rest_framework import status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.utils import timezone
from datetime import datetime, timedelta
from decimal import Decimal

from apps.users.models import User
from apps.users.seller_models import SellerOrder, SellerProduct, OrderStatus
from apps.users.seller_serializers import SellerOrderSerializer


class BuyerOrderViewSet(viewsets.ModelViewSet):
    """
    ViewSet for buyer order management.
    
    Endpoints:
    - POST /api/orders/create/ - Create new order from cart items
    - GET /api/orders/ - Get buyer's orders
    - GET /api/orders/{id}/ - Get specific order details
    """
    
    serializer_class = SellerOrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get orders for the current buyer only"""
        return SellerOrder.objects.filter(buyer=self.request.user).order_by('-created_at')
    
    def create(self, request, *args, **kwargs):
        """
        Override default create to handle order creation from cart items.
        
        Expected payload:
        {
            "cart_items": [1, 2, 3],  # Product IDs
            "payment_method": "delivery",  # or "pickup"
            "delivery_address": "123 Main St"
        }
        """
        try:
            cart_item_ids = request.data.get('cart_items', [])
            fulfillment_method = request.data.get('payment_method', 'delivery')  # Using payment_method for fulfillment
            delivery_address = request.data.get('delivery_address', '')
            
            # Validate inputs
            if not cart_item_ids:
                return Response(
                    {'error': 'cart_items is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if not fulfillment_method:
                return Response(
                    {'error': 'payment_method (fulfillment method) is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if fulfillment_method == 'delivery' and not delivery_address:
                return Response(
                    {'error': 'delivery_address is required for delivery orders'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Convert to integers and fetch products
            try:
                product_ids = [int(id) for id in cart_item_ids]
            except (ValueError, TypeError):
                return Response(
                    {'error': 'Invalid cart_items format'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            products = SellerProduct.objects.filter(id__in=product_ids).select_related('seller')
            
            if not products.exists():
                return Response(
                    {'error': 'No products found for the given cart items'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Create orders in a transaction
            with transaction.atomic():
                orders = []
                total_orders_amount = Decimal('0.00')
                
                for product in products:
                    # Check stock
                    if product.stock_level <= 0:
                        return Response(
                            {'error': f'Product "{product.name}" is out of stock'},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                    
                    # Generate unique order number
                    order_number = self._generate_order_number()
                    
                    # Create order
                    order = SellerOrder.objects.create(
                        seller=product.seller,
                        buyer=request.user,
                        product=product,
                        order_number=order_number,
                        quantity=1,  # Default to 1 per product for now
                        price_per_unit=product.price,
                        total_amount=product.price,
                        status=OrderStatus.PENDING,
                        delivery_location=delivery_address if fulfillment_method == 'delivery' else None,
                        delivery_date=None,  # Will be set by seller
                        on_time=True,
                    )
                    
                    # Reduce stock
                    product.stock_level -= 1
                    product.save()
                    
                    orders.append(order)
                    total_orders_amount += order.total_amount
                
                # Return the first order as the main response (Flutter app expects single order)
                if orders:
                    first_order = orders[0]
                    
                    # Format response to match Flutter Order model expectations
                    order_response = {
                        'id': first_order.id,
                        'order_number': first_order.order_number,
                        'items': [
                            {
                                'id': order.id,
                                'product_id': order.product.id,
                                'product_name': order.product.name,
                                'price_per_kilo': float(order.price_per_unit),
                                'quantity': order.quantity,
                                'unit': 'kg',  # Default unit
                                'subtotal': float(order.total_amount),
                                'image_url': order.product.image_url if hasattr(order.product, 'image_url') else '',
                            } for order in orders
                        ],
                        'total_amount': float(total_orders_amount),
                        'status': first_order.status.lower(),
                        'payment_method': fulfillment_method,
                        'created_at': first_order.created_at.isoformat(),
                        'completed_at': None,
                        'delivery_address': delivery_address if fulfillment_method == 'delivery' else '',
                        'buyer_name': request.user.full_name or request.user.username,
                        'buyer_phone': request.user.phone_number or '',
                    }
                    return Response(order_response, status=status.HTTP_201_CREATED)
                else:
                    return Response(
                        {'error': 'Failed to create order'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
                
        except Exception as e:
            return Response(
                {'error': f'Failed to create order: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _generate_order_number(self):
        """Generate a unique order number"""
        timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
        last_order = SellerOrder.objects.order_by('-id').first()
        sequence = (last_order.id + 1) if last_order else 1
        return f"ORD-{timestamp}-{sequence:06d}"
