"""
Seller serializers for OPAS Platform.

Handles serialization/deserialization of data for seller panel operations.
Includes 10 serializers across different seller operation categories:
- Profile management (1)
- Product management (2)
- Order management (1)
- Sell to OPAS (1)
- Payout tracking (1)
- Forecasting (1)
- Notifications (1)
- Analytics (1)
- Dashboard (1)
"""

from rest_framework import serializers
from django.utils import timezone
from django.core.exceptions import ValidationError
from .models import User, UserRole, SellerStatus
from .seller_models import (
    SellerProduct, SellerOrder, SellToOPAS, 
    SellerPayout, SellerForecast, ProductStatus, OrderStatus, ProductImage,
    Notification, Announcement, SellerAnnouncementRead
)
from .admin_models import (
    SellerRegistrationRequest, SellerDocumentVerification,
    SellerApprovalHistory, DocumentVerificationStatus, SellerRegistrationStatus
)


# ==================== SELLER PROFILE SERIALIZERS (1) ====================

class SellerProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for seller profile information.
    Used in: 
    - GET /api/seller/profile/
    - PUT /api/seller/profile/
    - POST /api/seller/profile/submit_documents/
    
    Includes:
    - Personal information
    - Store/farm details
    - Seller status and verification
    - Account management
    """
    full_name = serializers.SerializerMethodField(read_only=True)
    seller_status_display = serializers.CharField(
        source='get_seller_status_display',
        read_only=True
    )
    is_approved = serializers.SerializerMethodField(read_only=True)
    is_pending = serializers.SerializerMethodField(read_only=True)
    is_suspended = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = User
        fields = [
            'id',
            'first_name',
            'last_name',
            'full_name',
            'email',
            'phone_number',
            'address',
            'municipality',
            'barangay',
            'store_name',
            'store_description',
            'farm_municipality',
            'farm_barangay',
            'role',
            'seller_status',
            'seller_status_display',
            'seller_approval_date',
            'seller_documents_verified',
            'is_approved',
            'is_pending',
            'is_suspended',
            'suspension_reason',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'role',
            'seller_status',
            'seller_status_display',
            'seller_approval_date',
            'seller_documents_verified',
            'is_approved',
            'is_pending',
            'is_suspended',
            'suspension_reason',
            'created_at',
            'updated_at',
        ]

    def get_full_name(self, obj):
        """Get seller's full name"""
        return obj.full_name

    def get_is_approved(self, obj):
        """Check if seller is approved"""
        return obj.is_seller_approved

    def get_is_pending(self, obj):
        """Check if seller is pending approval"""
        return obj.is_seller_pending

    def get_is_suspended(self, obj):
        """Check if seller is suspended"""
        return obj.is_suspended

    def update(self, instance, validated_data):
        """Update seller profile (allow only non-critical fields)"""
        instance.first_name = validated_data.get('first_name', instance.first_name)
        instance.last_name = validated_data.get('last_name', instance.last_name)
        instance.phone_number = validated_data.get('phone_number', instance.phone_number)
        instance.address = validated_data.get('address', instance.address)
        instance.store_name = validated_data.get('store_name', instance.store_name)
        instance.store_description = validated_data.get('store_description', instance.store_description)
        instance.save()
        return instance


# ==================== PRODUCT SERIALIZERS (2) ====================

class SellerProductListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing seller products.
    Used in: GET /api/seller/products/
    
    Includes:
    - Product basics (name, price, stock)
    - Status information
    - Quick reference fields
    - Minimal data to avoid N+1 queries
    
    NOTE: Images are NOT included in list view to avoid performance issues.
    Use SellerProductDetailSerializer for full product data including images.
    """
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_active = serializers.SerializerMethodField(read_only=True)
    is_low_stock = serializers.SerializerMethodField(read_only=True)
    price_exceeds_ceiling = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = SellerProduct
        fields = [
            'id',
            'name',
            'product_type',
            'price',
            'ceiling_price',
            'unit',
            'stock_level',
            'minimum_stock',
            'quality_grade',
            'status',
            'status_display',
            'is_active',
            'is_low_stock',
            'price_exceeds_ceiling',
            'listed_date',
            'expiry_date',
            'seller_name',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'listed_date',
            'created_at',
            'updated_at',
            'status_display',
            'seller_name',
        ]

    def get_is_active(self, obj):
        """Check if product is active"""
        return obj.is_active

    def get_is_low_stock(self, obj):
        """Check if stock is low"""
        return obj.is_low_stock

    def get_price_exceeds_ceiling(self, obj):
        """Check if price exceeds ceiling"""
        return obj.price_exceeds_ceiling


class SellerProductCreateUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating and updating seller products.
    Used in:
    - POST /api/seller/products/
    - PUT /api/seller/products/{id}/
    
    Includes:
    - All product fields for CRUD operations
    - Validation for pricing and inventory
    """
    seller = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = SellerProduct
        fields = [
            'id',
            'name',
            'description',
            'product_type',
            'price',
            'ceiling_price',
            'unit',
            'stock_level',
            'minimum_stock',
            'quality_grade',
            'image_url',
            'images',
            'status',
            'expiry_date',
            'seller',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'seller',
            'created_at',
            'updated_at',
        ]

    def validate_price(self, value):
        """Validate that price is positive"""
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than 0")
        return value

    def validate_stock_level(self, value):
        """Validate that stock level is non-negative"""
        if value < 0:
            raise serializers.ValidationError("Stock level cannot be negative")
        return value

    def validate(self, data):
        """Validate product data"""
        # Check ceiling price if provided
        if data.get('ceiling_price') and data.get('price'):
            if data['price'] > data['ceiling_price']:
                raise serializers.ValidationError({
                    'price': 'Price cannot exceed ceiling price'
                })
        return data

    def create(self, validated_data):
        """Create product with current seller"""
        request = self.context.get('request')
        validated_data['seller'] = request.user
        return super().create(validated_data)


# ==================== ORDER SERIALIZERS (1) ====================

class SellerOrderSerializer(serializers.ModelSerializer):
    """
    Serializer for seller order management.
    Used in:
    - GET /api/seller/orders/
    - POST /api/seller/orders/{id}/accept/
    - POST /api/seller/orders/{id}/reject/
    - POST /api/seller/orders/{id}/mark_fulfilled/
    - POST /api/seller/orders/{id}/mark_delivered/
    
    Includes:
    - Order details
    - Buyer information
    - Status tracking
    - Timeline information
    """
    buyer_name = serializers.CharField(source='buyer.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    can_be_accepted = serializers.SerializerMethodField(read_only=True)
    can_be_rejected = serializers.SerializerMethodField(read_only=True)
    can_be_fulfilled = serializers.SerializerMethodField(read_only=True)
    can_be_delivered = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = SellerOrder
        fields = [
            'id',
            'order_number',
            'seller',
            'buyer',
            'buyer_name',
            'product',
            'product_name',
            'quantity',
            'price_per_unit',
            'total_amount',
            'status',
            'status_display',
            'rejection_reason',
            'delivery_location',
            'delivery_date',
            'can_be_accepted',
            'can_be_rejected',
            'can_be_fulfilled',
            'can_be_delivered',
            'created_at',
            'accepted_at',
            'fulfilled_at',
            'delivered_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'order_number',
            'seller',
            'buyer',
            'buyer_name',
            'product_name',
            'price_per_unit',
            'total_amount',
            'status_display',
            'can_be_accepted',
            'can_be_rejected',
            'can_be_fulfilled',
            'can_be_delivered',
            'created_at',
            'accepted_at',
            'fulfilled_at',
            'delivered_at',
            'updated_at',
        ]

    def get_can_be_accepted(self, obj):
        """Check if order can be accepted"""
        return obj.can_be_accepted

    def get_can_be_rejected(self, obj):
        """Check if order can be rejected"""
        return obj.can_be_rejected

    def get_can_be_fulfilled(self, obj):
        """Check if order can be fulfilled"""
        return obj.can_be_fulfilled

    def get_can_be_delivered(self, obj):
        """Check if order can be delivered"""
        return obj.can_be_delivered


# ==================== SELL TO OPAS SERIALIZERS (1) ====================

class SellToOPASSerializer(serializers.ModelSerializer):
    """
    Serializer for Sell to OPAS submissions.
    Used in:
    - POST /api/seller/sell-to-opas/submit/
    - GET /api/seller/sell-to-opas/pending/
    - GET /api/seller/sell-to-opas/history/
    - GET /api/seller/sell-to-opas/{id}/status/
    
    Includes:
    - Submission details
    - Pricing and quantity
    - Status tracking
    """
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = SellToOPAS
        fields = [
            'id',
            'submission_number',
            'seller',
            'seller_name',
            'product',
            'product_name',
            'quantity_offered',
            'unit',
            'offered_price',
            'approved_price',
            'quality_grade',
            'status',
            'status_display',
            'rejection_reason',
            'delivery_date',
            'pickup_location',
            'created_at',
            'accepted_at',
            'completed_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'submission_number',
            'seller',
            'seller_name',
            'product_name',
            'approved_price',
            'status_display',
            'created_at',
            'accepted_at',
            'completed_at',
            'updated_at',
        ]

    def validate_quantity_offered(self, value):
        """Validate quantity is positive"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        return value

    def create(self, validated_data):
        """Create submission with current seller"""
        request = self.context.get('request')
        validated_data['seller'] = request.user
        return super().create(validated_data)


# ==================== PAYOUT SERIALIZERS (1) ====================

class SellerPayoutSerializer(serializers.ModelSerializer):
    """
    Serializer for seller payout tracking.
    Used in:
    - GET /api/seller/payouts/
    - GET /api/seller/payouts/pending/
    - GET /api/seller/payouts/completed/
    - GET /api/seller/payouts/earnings/
    
    Includes:
    - Payout periods
    - Financial calculations
    - Status tracking
    """
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    deduction_breakdown = serializers.SerializerMethodField(read_only=True)
    days_in_period = serializers.SerializerMethodField(read_only=True)
    avg_daily_earnings = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = SellerPayout
        fields = [
            'id',
            'seller',
            'seller_name',
            'period_start',
            'period_end',
            'days_in_period',
            'total_earnings',
            'transaction_fees',
            'service_fee_percent',
            'service_fee_amount',
            'other_deductions',
            'deduction_breakdown',
            'net_earnings',
            'avg_daily_earnings',
            'status',
            'status_display',
            'payment_method',
            'bank_account',
            'transaction_id',
            'created_at',
            'processed_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'seller',
            'seller_name',
            'net_earnings',
            'status_display',
            'deduction_breakdown',
            'days_in_period',
            'avg_daily_earnings',
            'created_at',
            'processed_at',
            'updated_at',
        ]

    def get_deduction_breakdown(self, obj):
        """Get breakdown of all deductions"""
        return {
            'service_fee': float(obj.service_fee_amount),
            'transaction_fees': float(obj.transaction_fees),
            'other_deductions': float(obj.other_deductions),
            'total_deductions': float(
                obj.service_fee_amount + 
                obj.transaction_fees + 
                obj.other_deductions
            ),
        }

    def get_days_in_period(self, obj):
        """Calculate days in payout period"""
        return (obj.period_end - obj.period_start).days + 1

    def get_avg_daily_earnings(self, obj):
        """Calculate average daily earnings"""
        days = (obj.period_end - obj.period_start).days + 1
        return float(obj.net_earnings) / days if days > 0 else 0


# ==================== FORECAST SERIALIZERS (1) ====================

class SellerForecastSerializer(serializers.ModelSerializer):
    """
    Serializer for demand forecasting data.
    Used in:
    - GET /api/seller/forecast/next_month/
    - GET /api/seller/forecast/product/{product}/
    - GET /api/seller/forecast/historical/
    - GET /api/seller/forecast/insights/
    
    Includes:
    - Forecast data
    - Risk assessment
    - Accuracy metrics
    - Trend analysis
    - Recommendations
    """
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    demand_variance = serializers.SerializerMethodField(read_only=True)
    is_surplus_risk = serializers.SerializerMethodField(read_only=True)
    is_stockout_risk = serializers.SerializerMethodField(read_only=True)
    risk_level = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = SellerForecast
        fields = [
            'id',
            'seller',
            'seller_name',
            'product',
            'product_name',
            'forecast_date',
            'forecast_start',
            'forecast_end',
            'forecasted_demand',
            'actual_demand',
            'demand_variance',
            'confidence_score',
            'accuracy',
            'surplus_probability',
            'stockout_probability',
            'is_surplus_risk',
            'is_stockout_risk',
            'risk_level',
            'recommended_stock',
            'trend',
            'volatility',
            'growth_rate',
            'trend_multiplier',
            'seasonality_detected',
            'historical_sales_count',
            'average_daily_sales',
            'recommendations',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'seller',
            'seller_name',
            'product_name',
            'demand_variance',
            'is_surplus_risk',
            'is_stockout_risk',
            'risk_level',
            'trend',
            'volatility',
            'growth_rate',
            'trend_multiplier',
            'seasonality_detected',
            'historical_sales_count',
            'average_daily_sales',
            'recommendations',
            'created_at',
            'updated_at',
        ]

    def get_demand_variance(self, obj):
        """Get demand variance between forecast and actual"""
        return obj.demand_variance

    def get_is_surplus_risk(self, obj):
        """Check if surplus risk is high"""
        return obj.is_surplus_risk

    def get_is_stockout_risk(self, obj):
        """Check if stockout risk is high"""
        return obj.is_stockout_risk
    
    def get_risk_level(self, obj):
        """Calculate overall risk level"""
        max_prob = max(obj.surplus_probability, obj.stockout_probability)
        if max_prob >= 70:
            return 'HIGH'
        elif max_prob >= 40:
            return 'MEDIUM'
        else:
            return 'LOW'


# ==================== NOTIFICATION SERIALIZERS (1) ====================

class NotificationSerializer(serializers.Serializer):
    """
    Serializer for seller notifications.
    Used in:
    - GET /api/seller/notifications/
    - POST /api/seller/notifications/{id}/mark_read/
    
    Includes:
    - Notification type and content
    - Status tracking
    - Related objects
    """
    id = serializers.IntegerField()
    type = serializers.CharField()
    title = serializers.CharField()
    message = serializers.CharField()
    is_read = serializers.BooleanField()
    related_object_id = serializers.IntegerField(required=False, allow_null=True)
    related_object_type = serializers.CharField(required=False, allow_null=True)
    created_at = serializers.DateTimeField()
    updated_at = serializers.DateTimeField()

    def to_representation(self, instance):
        """Format notification data"""
        return {
            'id': instance.get('id'),
            'type': instance.get('type'),
            'title': instance.get('title'),
            'message': instance.get('message'),
            'is_read': instance.get('is_read', False),
            'related_object': {
                'id': instance.get('related_object_id'),
                'type': instance.get('related_object_type'),
            },
            'created_at': instance.get('created_at'),
            'updated_at': instance.get('updated_at'),
        }


# ==================== ANALYTICS SERIALIZERS (1) ====================

class AnalyticsSerializer(serializers.Serializer):
    """
    Serializer for seller analytics data.
    Used in:
    - GET /api/seller/analytics/dashboard/
    - GET /api/seller/analytics/daily/
    - GET /api/seller/analytics/weekly/
    - GET /api/seller/analytics/monthly/
    - GET /api/seller/analytics/top_products/
    - GET /api/seller/analytics/forecast_vs_actual/
    
    Includes:
    - Sales metrics
    - Performance data
    - Comparisons and trends
    """
    period = serializers.CharField()
    total_sales = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_orders = serializers.IntegerField()
    total_products = serializers.IntegerField()
    average_order_value = serializers.DecimalField(max_digits=10, decimal_places=2)
    growth_rate = serializers.DecimalField(max_digits=5, decimal_places=2)
    top_products = serializers.ListField(child=serializers.DictField())
    conversion_rate = serializers.DecimalField(max_digits=5, decimal_places=2)
    customer_satisfaction = serializers.DecimalField(max_digits=5, decimal_places=2)

    def to_representation(self, instance):
        """Format analytics data"""
        return {
            'period': instance.get('period'),
            'metrics': {
                'total_sales': instance.get('total_sales'),
                'total_orders': instance.get('total_orders'),
                'total_products': instance.get('total_products'),
                'average_order_value': instance.get('average_order_value'),
            },
            'performance': {
                'growth_rate': instance.get('growth_rate'),
                'conversion_rate': instance.get('conversion_rate'),
                'customer_satisfaction': instance.get('customer_satisfaction'),
            },
            'top_products': instance.get('top_products'),
        }


# ==================== DASHBOARD SERIALIZERS (1) ====================

class SellerDashboardSerializer(serializers.Serializer):
    """
    Serializer for seller dashboard data.
    Used in: GET /api/seller/dashboard/
    
    Includes:
    - Summary statistics
    - Recent activity
    - Quick actions
    - Performance overview
    """
    seller_info = serializers.DictField()
    dashboard_stats = serializers.DictField()
    recent_orders = serializers.ListField(child=serializers.DictField())
    recent_products = serializers.ListField(child=serializers.DictField())
    pending_payouts = serializers.DictField()
    notifications_count = serializers.IntegerField()
    low_stock_products = serializers.ListField(child=serializers.DictField())
    forecast_summary = serializers.DictField()

    def to_representation(self, instance):
        """Format dashboard data for frontend"""
        return {
            'seller': instance.get('seller_info'),
            'stats': {
                'total_sales': instance.get('dashboard_stats', {}).get('total_sales'),
                'total_orders': instance.get('dashboard_stats', {}).get('total_orders'),
                'active_products': instance.get('dashboard_stats', {}).get('active_products'),
                'pending_payouts': instance.get('pending_payouts', {}),
            },
            'recent_activity': {
                'orders': instance.get('recent_orders', []),
                'products': instance.get('recent_products', []),
                'notifications': instance.get('notifications_count', 0),
            },
            'alerts': {
                'low_stock_products': instance.get('low_stock_products', []),
                'forecast_summary': instance.get('forecast_summary', {}),
            },
        }


# ==================== PRODUCT IMAGE SERIALIZERS ====================

class ProductImageSerializer(serializers.ModelSerializer):
    """
    Serializer for product images.
    Used in:
    - GET /api/seller/products/{id}/images/
    - POST /api/seller/products/{id}/images/
    - DELETE /api/seller/products/{id}/images/{image_id}/
    
    Includes:
    - Image file and metadata
    - Primary image designation
    - Upload timestamps
    """
    image_url = serializers.SerializerMethodField(read_only=True)
    
    class Meta:
        model = ProductImage
        fields = [
            'id',
            'product',
            'image',
            'image_url',
            'is_primary',
            'order',
            'alt_text',
            'uploaded_at',
        ]
        read_only_fields = [
            'id',
            'product',
            'uploaded_at',
        ]
    
    def get_image_url(self, obj):
        """Get full image URL"""
        if obj.image:
            request = self.context.get('request')
            if request:
                # Build absolute URL
                return request.build_absolute_uri(obj.image.url)
            else:
                # Fallback: construct URL with default domain
                from django.conf import settings
                if obj.image.url.startswith('http'):
                    return obj.image.url
                # Return full URL with domain
                return f"http://10.113.93.34:8000{obj.image.url}"
        return None
    
    def create(self, validated_data):
        """Create product image"""
        product_id = self.context.get('product_id')
        validated_data['product_id'] = product_id
        return ProductImage.objects.create(**validated_data)


class SellerProductDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed product information including images.
    Used in: GET /api/seller/products/{id}/
    
    Includes:
    - All product fields
    - Related images
    - Extended metadata
    """
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    product_images = ProductImageSerializer(many=True, read_only=True)
    is_active = serializers.SerializerMethodField(read_only=True)
    is_low_stock = serializers.SerializerMethodField(read_only=True)
    price_exceeds_ceiling = serializers.SerializerMethodField(read_only=True)
    primary_image = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = SellerProduct
        fields = [
            'id',
            'seller_name',
            'name',
            'description',
            'product_type',
            'price',
            'ceiling_price',
            'unit',
            'stock_level',
            'minimum_stock',
            'quality_grade',
            'image_url',
            'product_images',
            'primary_image',
            'images',
            'status',
            'status_display',
            'is_active',
            'is_low_stock',
            'price_exceeds_ceiling',
            'listed_date',
            'expiry_date',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'seller_name',
            'listed_date',
            'created_at',
            'updated_at',
            'status_display',
            'product_images',
            'primary_image',
        ]

    def get_is_active(self, obj):
        """Check if product is active"""
        return obj.is_active

    def get_is_low_stock(self, obj):
        """Check if stock is low"""
        return obj.is_low_stock

    def get_price_exceeds_ceiling(self, obj):
        """Check if price exceeds ceiling"""
        return obj.price_exceeds_ceiling
    
    def get_primary_image(self, obj):
        """Get primary image"""
        primary = obj.product_images.filter(is_primary=True).first()
        if primary:
            return ProductImageSerializer(primary, context=self.context).data
        return None


# ==================== NOTIFICATION & ANNOUNCEMENT SERIALIZERS ====================

class NotificationSerializer(serializers.ModelSerializer):
    """
    Serializer for seller notifications.
    
    Provides notification details including type, content, read status,
    and timestamp information.
    """
    created_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)
    
    class Meta:
        model = Notification
        fields = [
            'id', 'seller', 'type', 'title', 'message',
            'is_read', 'created_at', 'read_at'
        ]
        read_only_fields = [
            'id', 'seller', 'type', 'title', 'message',
            'created_at', 'read_at'
        ]
        
    def to_representation(self, instance):
        """
        Convert notification to dictionary representation.
        """
        data = super().to_representation(instance)
        # Format timestamps in relative format for frontend
        data['created_at_display'] = self._format_time(instance.created_at)
        return data
    
    def _format_time(self, dt):
        """Format datetime to relative time string"""
        from django.utils.timesince import timesince
        return f"{timesince(dt)} ago"


class NotificationListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for notification lists.
    
    Used in list views to provide essential notification data
    without full details.
    """
    created_at_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id', 'type', 'title', 'message',
            'is_read', 'created_at', 'created_at_display'
        ]
        read_only_fields = fields
    
    def get_created_at_display(self, obj):
        """Get relative time display"""
        from django.utils.timesince import timesince
        return f"{timesince(obj.created_at)} ago"


class AnnouncementSerializer(serializers.ModelSerializer):
    """
    Serializer for admin announcements to sellers.
    
    Includes announcement content, type, priority level, read status,
    and metadata for frontend display.
    """
    created_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)
    read_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'content', 'type', 'priority',
            'created_by', 'created_at', 'updated_at', 'expires_at', 'read_status'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_read_status(self, obj):
        """Check if current seller has read this announcement"""
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            seller_user = request.user
            # Check if seller has a read entry for this announcement
            return obj.seller_reads.filter(seller=seller_user).exists()
        return False


class AnnouncementListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for announcement lists.
    
    Used in list views with condensed announcement information.
    """
    read_status = serializers.SerializerMethodField()
    created_at_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'type', 'priority',
            'created_at', 'created_at_display', 'read_status'
        ]
        read_only_fields = fields
    
    def get_read_status(self, obj):
        """Check if current seller has read this announcement"""
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            seller_user = request.user
            # Check if seller has a read entry for this announcement
            return obj.seller_reads.filter(seller=seller_user).exists()
        return False
    
    def get_created_at_display(self, obj):
        """Get relative time display"""
        from django.utils.timesince import timesince
        return f"{timesince(obj.created_at)} ago"


# ==================== SELLER REGISTRATION SERIALIZERS ====================

class SellerDocumentVerificationSerializer(serializers.ModelSerializer):
    """
    Serializer for seller registration documents.
    
    Handles document verification status and metadata.
    Applied CORE PRINCIPLES:
    - Input Validation: Document file size/type validation on backend
    - Security: Secure storage of document URLs
    - Idempotency: Document type + registration must be unique
    
    Usage:
    - GET /api/sellers/registrations/{id}/ (included in registration detail)
    - Used for document tracking and verification status
    """
    verified_by_name = serializers.CharField(
        source='verified_by.user.full_name',
        read_only=True,
        allow_null=True
    )
    status_display = serializers.CharField(
        source='get_status_display',
        read_only=True
    )
    
    class Meta:
        model = SellerDocumentVerification
        fields = [
            'id',
            'document_type',
            'document_url',
            'status',
            'status_display',
            'verification_notes',
            'verified_by_name',
            'uploaded_at',
            'verified_at',
            'expires_at',
        ]
        read_only_fields = [
            'id',
            'status',
            'status_display',
            'verification_notes',
            'verified_by_name',
            'uploaded_at',
            'verified_at',
            'expires_at',
        ]


class SellerRegistrationRequestSerializer(serializers.ModelSerializer):
    """
    Serializer for seller registration requests (buyer-to-seller conversion).
    
    Comprehensive serializer for managing seller registration workflow including:
    - Farm/store information collection
    - Document submission and tracking
    - Registration status tracking
    - Admin approval/rejection workflow
    
    Applied CORE PRINCIPLES:
    1. Resource Management: Efficient JSON structure, lazy-loading documents
    2. Input Validation: Server-side validation of all fields
    3. Security & Authorization: Always validate authenticated user owns registration
    4. API Idempotency: Prevent duplicate submissions via unique constraint on seller_id
    5. Rate Limiting: Document upload validation (file size, format)
    
    Usage:
    - POST /api/sellers/register-application/ (create registration)
    - GET /api/sellers/registrations/{id}/ (retrieve details)
    - GET /api/sellers/my-registration/ (buyer's own registration)
    
    Example POST payload:
    {
        "farm_name": "Green Valley Farm",
        "farm_location": "Davao, Philippines",
        "products_grown": "Bananas, Coconut, Cacao",
        "store_name": "Green Valley Marketplace",
        "store_description": "Premium organic farm products"
    }
    """
    seller_email = serializers.CharField(
        source='seller.email',
        read_only=True
    )
    seller_full_name = serializers.CharField(
        source='seller.full_name',
        read_only=True
    )
    status_display = serializers.CharField(
        source='get_status_display',
        read_only=True
    )
    documents = SellerDocumentVerificationSerializer(
        source='document_verifications',
        many=True,
        read_only=True
    )
    days_pending = serializers.SerializerMethodField()
    is_approved = serializers.SerializerMethodField()
    is_rejected = serializers.SerializerMethodField()
    is_pending = serializers.SerializerMethodField()
    rejection_reason = serializers.CharField(
        allow_blank=True,
        required=False
    )
    
    class Meta:
        model = SellerRegistrationRequest
        fields = [
            'id',
            'seller_email',
            'seller_full_name',
            'farm_name',
            'farm_location',
            'products_grown',
            'store_name',
            'store_description',
            'status',
            'status_display',
            'documents',
            'rejection_reason',
            'submitted_at',
            'reviewed_at',
            'approved_at',
            'rejected_at',
            'days_pending',
            'is_approved',
            'is_rejected',
            'is_pending',
        ]
        read_only_fields = [
            'id',
            'seller_email',
            'seller_full_name',
            'status',
            'status_display',
            'documents',
            'rejection_reason',
            'submitted_at',
            'reviewed_at',
            'approved_at',
            'rejected_at',
            'days_pending',
            'is_approved',
            'is_rejected',
            'is_pending',
        ]
    
    def get_days_pending(self, obj):
        """Calculate days since submission."""
        return obj.days_since_submission()
    
    def get_is_approved(self, obj):
        """Check if application is approved."""
        return obj.is_approved()
    
    def get_is_rejected(self, obj):
        """Check if application is rejected."""
        return obj.is_rejected()
    
    def get_is_pending(self, obj):
        """Check if application is pending."""
        return obj.is_pending()


class SellerRegistrationSubmitSerializer(serializers.Serializer):
    """
    Serializer for buyer-to-seller registration submission.
    
    Handles the initial registration form submission from buyers.
    Validates all required fields and creates SellerRegistrationRequest.
    
    Applied CORE PRINCIPLES:
    1. Input Validation & Sanitization: Comprehensive field validation
    2. Rate Limiting: Prevent spam via one registration per user
    3. Security: Only current authenticated user can submit for themselves
    4. Idempotency: Prevent duplicate registrations via unique constraint
    
    Usage:
    POST /api/sellers/register-application/
    
    Example payload:
    {
        "farm_name": "Green Valley Farm",
        "farm_location": "Davao, Philippines",
        "products_grown": "Bananas, Coconut, Cacao",
        "store_name": "Green Valley Marketplace",
        "store_description": "Premium organic farm products offering fresh produce"
    }
    
    Response:
    {
        "id": 1,
        "status": "PENDING",
        "seller_email": "farmer@example.com",
        "seller_full_name": "John Doe",
        "farm_name": "Green Valley Farm",
        "submitted_at": "2025-11-23T10:30:00Z",
        ...
    }
    """
    farm_name = serializers.CharField(
        max_length=255,
        required=True,
        trim_whitespace=True,
        help_text="Name of the farm"
    )
    farm_location = serializers.CharField(
        max_length=255,
        required=True,
        trim_whitespace=True,
        help_text="Location/address of the farm"
    )
    products_grown = serializers.CharField(
        max_length=1000,
        required=False,
        allow_blank=True,
        trim_whitespace=True,
        help_text="Comma-separated list of products grown"
    )
    store_name = serializers.CharField(
        max_length=255,
        required=True,
        trim_whitespace=True,
        help_text="Name of the store/business"
    )
    store_description = serializers.CharField(
        max_length=1000,
        required=True,
        trim_whitespace=True,
        help_text="Description of the store"
    )
    
    def validate_farm_name(self, value):
        """Validate farm name is not empty after stripping."""
        if not value or not value.strip():
            raise serializers.ValidationError(
                "Farm name cannot be empty."
            )
        if len(value) < 3:
            raise serializers.ValidationError(
                "Farm name must be at least 3 characters long."
            )
        return value
    
    def validate_farm_location(self, value):
        """Validate farm location is not empty."""
        if not value or not value.strip():
            raise serializers.ValidationError(
                "Farm location cannot be empty."
            )
        return value
    
    def validate_store_name(self, value):
        """Validate store name."""
        if not value or not value.strip():
            raise serializers.ValidationError(
                "Store name cannot be empty."
            )
        if len(value) < 3:
            raise serializers.ValidationError(
                "Store name must be at least 3 characters long."
            )
        return value
    
    def validate_store_description(self, value):
        """Validate store description."""
        if not value or not value.strip():
            raise serializers.ValidationError(
                "Store description cannot be empty."
            )
        if len(value) < 10:
            raise serializers.ValidationError(
                "Store description must be at least 10 characters long."
            )
        return value
    
    def validate(self, data):
        """
        Perform cross-field validation.
        
        Checks:
        - User is authenticated buyer
        - User doesn't already have a pending/approved registration
        """
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError(
                "Authentication required to submit seller registration."
            )
        
        user = request.user
        
        # Check user is a BUYER
        if user.role != UserRole.BUYER:
            raise serializers.ValidationError(
                "Only buyers can submit seller registration applications."
            )
        
        # Check if user already has a pending or approved registration
        existing_registration = SellerRegistrationRequest.objects.filter(
            seller=user
        ).exclude(
            status=SellerRegistrationStatus.REJECTED
        ).first()
        
        if existing_registration:
            raise serializers.ValidationError(
                f"You already have a {existing_registration.status.lower()} "
                f"seller registration. Please contact support to modify it."
            )
        
        return data
    
    def create(self, validated_data):
        """
        Create seller registration request.
        
        Creates a new SellerRegistrationRequest and updates seller user record
        with store information.
        """
        user = self.context['request'].user
        
        # Create registration request
        registration = SellerRegistrationRequest.objects.create(
            seller=user,
            status=SellerRegistrationStatus.PENDING,
            **validated_data
        )
        
        # Update user store information (for redundancy/optimization)
        user.store_name = validated_data['store_name']
        user.store_description = validated_data['store_description']
        user.save(update_fields=['store_name', 'store_description'])
        
        # Send notification to all OPAS Admin users
        try:
            from apps.core.notifications import NotificationService
            NotificationService.send_registration_submitted_notification(
                registration,
                request=self.context.get('request')
            )
        except Exception as e:
            # Log error but don't fail the registration creation
            import logging
            logger_obj = logging.getLogger(__name__)
            logger_obj.error(f"Failed to send registration notification: {str(e)}")
        
        return registration


class SellerRegistrationStatusSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for buyer's registration status.
    
    Provides essential status information for the buyer's dashboard.
    Does not include detailed documents or admin notes.
    
    Applied CORE PRINCIPLES:
    - Resource Management: Minimal payload, only essential fields
    - User Experience: Clear status indication with human-readable display
    
    Usage:
    GET /api/sellers/my-registration/
    
    Response example:
    {
        "id": 1,
        "status": "PENDING",
        "status_display": "Pending Approval",
        "farm_name": "Green Valley Farm",
        "store_name": "Green Valley Marketplace",
        "submitted_at": "2025-11-23T10:30:00Z",
        "reviewed_at": null,
        "rejection_reason": null,
        "days_pending": 2,
        "is_pending": true,
        "is_approved": false,
        "is_rejected": false,
        "message": null
    }
    """
    status_display = serializers.CharField(
        source='get_status_display',
        read_only=True
    )
    days_pending = serializers.SerializerMethodField()
    is_approved = serializers.SerializerMethodField()
    is_rejected = serializers.SerializerMethodField()
    is_pending = serializers.SerializerMethodField()
    message = serializers.SerializerMethodField()
    
    class Meta:
        model = SellerRegistrationRequest
        fields = [
            'id',
            'status',
            'status_display',
            'farm_name',
            'store_name',
            'submitted_at',
            'reviewed_at',
            'rejection_reason',
            'days_pending',
            'is_pending',
            'is_approved',
            'is_rejected',
            'message',
        ]
        read_only_fields = fields
    
    def get_days_pending(self, obj):
        """Calculate days since submission."""
        return obj.days_since_submission()
    
    def get_is_approved(self, obj):
        """Check if application is approved."""
        return obj.is_approved()
    
    def get_is_rejected(self, obj):
        """Check if application is rejected."""
        return obj.is_rejected()
    
    def get_is_pending(self, obj):
        """Check if application is pending."""
        return obj.is_pending()
    
    def get_message(self, obj):
        """Get user-friendly status message."""
        if obj.is_pending():
            return f"Your application is being reviewed. Submitted {obj.days_since_submission()} days ago."
        elif obj.is_approved():
            return "Congratulations! Your seller account has been approved. You can now list products."
        elif obj.is_rejected():
            return f"Your application was not approved. Reason: {obj.rejection_reason}"
        return None
