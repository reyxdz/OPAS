"""
Serializers for Forecasting API endpoints.

Provides serialization for:
- ProductForecast - Main forecast results
- ForecastMetadata - Model information and statistics
- ForecastAlert - Alerts and anomalies
- Statistics and coverage reports

Author: OPAS System
Created: December 2025
"""

from rest_framework import serializers
from decimal import Decimal
from django.utils import timezone

from apps.forecasting.models import (
    ProductForecast,
    ForecastMetadata,
    ForecastAlert,
)
from apps.users.models import SellerProduct


class ForecastSerializer(serializers.ModelSerializer):
    """Basic forecast serializer for list and detail views"""
    product_name = serializers.SerializerMethodField()
    product_category = serializers.SerializerMethodField()
    
    # Explicitly define numeric fields as FloatField to convert Decimal to float
    demand_forecast_kg = serializers.FloatField()
    demand_lower_bound = serializers.FloatField()
    demand_upper_bound = serializers.FloatField()
    price_forecast = serializers.FloatField()
    price_lower_bound = serializers.FloatField()
    price_upper_bound = serializers.FloatField()
    
    class Meta:
        model = ProductForecast
        fields = [
            'id', 'product_id', 'product_name', 'product_category',
            'forecast_date', 'forecast_period',
            'demand_forecast_kg', 'demand_lower_bound', 'demand_upper_bound',
            'price_forecast', 'price_lower_bound', 'price_upper_bound',
            'confidence_level', 'model_type', 'is_current'
        ]
        read_only_fields = ['id', 'forecast_date']
    
    def get_product_name(self, obj):
        """Get product name from either product.name or product_name field"""
        if obj.product:
            return obj.product.name
        return obj.product_name or 'Unknown'
    
    def get_product_category(self, obj):
        """Get category name from seller product or return Market Data for CSV products"""
        if obj.product and obj.product.category:
            return obj.product.category.name
        return 'Market Data' if obj.product_name else 'Unknown'


class ForecastAlertSerializer(serializers.ModelSerializer):
    """Serializer for ForecastAlert model"""
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_id = serializers.IntegerField(source='product.id', read_only=True)
    
    class Meta:
        model = ForecastAlert
        fields = [
            'id',
            'product_id',
            'product_name',
            'alert_type',
            'severity',
            'message',
            'is_acknowledged',
            'created_at',
            'acknowledged_at',
        ]
        read_only_fields = ['id', 'created_at', 'acknowledged_at']


class ForecastMetadataSerializer(serializers.ModelSerializer):
    """Serializer for ForecastMetadata model - model info & statistics"""
    
    class Meta:
        model = ForecastMetadata
        fields = [
            'product_id', 'data_points_count', 'model_type',
            'last_training_date', 'is_reliable', 'notes'
        ]
        read_only_fields = [
            'product_id',
            'data_points_count',
            'last_training_date',
        ]


class ProductForecastSerializer(serializers.ModelSerializer):
    """
    Serializer for ProductForecast model.
    
    Used for list and detail views. Includes confidence interval bounds
    and model metadata inline for quick access.
    """
    product_name = serializers.SerializerMethodField()
    product_id = serializers.SerializerMethodField()
    category_name = serializers.SerializerMethodField()
    seller_name = serializers.SerializerMethodField()
    
    # Explicitly define numeric fields as FloatField to convert Decimal to float
    demand_forecast_kg = serializers.FloatField()
    demand_lower_bound = serializers.FloatField()
    demand_upper_bound = serializers.FloatField()
    price_forecast = serializers.FloatField()
    price_lower_bound = serializers.FloatField()
    price_upper_bound = serializers.FloatField()
    rmse_demand = serializers.FloatField()
    rmse_price = serializers.FloatField()
    mape_demand = serializers.FloatField()
    mape_price = serializers.FloatField()
    
    # Metadata inline
    model_reliability = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductForecast
        fields = [
            'id',
            'product_id',
            'product_name',
            'category_name',
            'seller_name',
            'forecast_date',
            'forecast_period',
            'demand_forecast_kg',
            'demand_lower_bound',
            'demand_upper_bound',
            'price_forecast',
            'price_lower_bound',
            'price_upper_bound',
            'confidence_level',
            'model_type',
            'rmse_demand',
            'rmse_price',
            'mape_demand',
            'mape_price',
            'is_current',
            'model_reliability',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'forecast_date',
            'created_at',
            'updated_at',
        ]

    def get_product_name(self, obj):
        """Get product name from either product.name or product_name field"""
        if obj.product:
            return obj.product.name
        return obj.product_name or 'Unknown'
    
    def get_product_id(self, obj):
        """Get product ID (None for CSV products)"""
        return obj.product.id if obj.product else None
    
    def get_seller_name(self, obj):
        """Get seller name or None for CSV products"""
        if obj.product and obj.product.seller:
            return obj.product.seller.first_name
        return None

    def get_category_name(self, obj):
        """Get product category name"""
        if obj.product and obj.product.category:
            return obj.product.category.name
        return 'Market Data' if obj.product_name else 'Unknown'

    def get_model_reliability(self, obj):
        """
        Calculate model reliability score based on:
        - Confidence level
        - Model type
        - Error metrics
        
        Returns: 0-100 reliability score
        """
        base_score = 60  # Base score
        
        # Confidence level bonus
        confidence_bonus = {
            'HIGH': 30,
            'MEDIUM': 15,
            'LOW': 0,
        }
        base_score += confidence_bonus.get(obj.confidence_level, 0)
        
        # Model type adjustment
        if obj.model_type == 'INSUFFICIENT_DATA':
            return 0
        elif obj.model_type == 'SARIMA':
            base_score += 10
        elif obj.model_type == 'ARIMA':
            base_score += 5
        
        # RMSE penalty (if available)
        if obj.rmse_demand and obj.rmse_demand > Decimal('100'):
            base_score -= 10
        
        return min(100, max(0, base_score))


class ProductForecastListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views (minimal fields)"""
    product_name = serializers.SerializerMethodField()
    product_id = serializers.SerializerMethodField()
    category_name = serializers.SerializerMethodField()
    
    # Explicitly define numeric fields as FloatField to convert Decimal to float
    demand_forecast_kg = serializers.FloatField()
    demand_lower_bound = serializers.FloatField()
    demand_upper_bound = serializers.FloatField()
    price_forecast = serializers.FloatField()
    price_lower_bound = serializers.FloatField()
    price_upper_bound = serializers.FloatField()
    
    class Meta:
        model = ProductForecast
        fields = [
            'id',
            'product_id',
            'product_name',
            'category_name',
            'forecast_period',
            'demand_forecast_kg',
            'demand_lower_bound',
            'demand_upper_bound',
            'price_forecast',
            'price_lower_bound',
            'price_upper_bound',
            'confidence_level',
            'model_type',
            'is_current',
            'forecast_date',
        ]
        read_only_fields = [
            'id',
            'forecast_date',
        ]

    def get_product_name(self, obj):
        """Get product name from either product.name or product_name field"""
        if obj.product:
            return obj.product.name
        return obj.product_name or 'Unknown'
    
    def get_product_id(self, obj):
        """Get product ID (None for CSV products)"""
        return obj.product.id if obj.product else None

    def get_category_name(self, obj):
        """Get product category name"""
        if obj.product and obj.product.category:
            return obj.product.category.name
        return 'Market Data' if obj.product_name else 'Unknown'


class ForecastCoverageStatisticsSerializer(serializers.Serializer):
    """Statistics about forecasting coverage across all products"""
    total_products = serializers.IntegerField()
    products_with_forecasts = serializers.IntegerField()
    coverage_percentage = serializers.FloatField()
    products_by_model_type = serializers.DictField()
    products_by_confidence = serializers.DictField()
    last_batch_generation = serializers.DateTimeField(allow_null=True)
    avg_forecast_age_days = serializers.FloatField()
    stale_forecasts_count = serializers.IntegerField()
    insufficient_data_count = serializers.IntegerField()
    
    class Meta:
        fields = [
            'total_products',
            'products_with_forecasts',
            'coverage_percentage',
            'products_by_model_type',
            'products_by_confidence',
            'last_batch_generation',
            'avg_forecast_age_days',
            'stale_forecasts_count',
            'insufficient_data_count',
        ]


class ForecastDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for single forecast view.
    Includes all forecast data plus related metadata.
    """
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_id = serializers.IntegerField(source='product.id', read_only=True)
    category_name = serializers.SerializerMethodField()
    seller_name = serializers.CharField(
        source='product.seller.first_name',
        read_only=True,
        allow_null=True
    )
    seller_location = serializers.SerializerMethodField()
    
    # Explicitly define numeric fields as FloatField to convert Decimal to float
    demand_forecast_kg = serializers.FloatField()
    demand_lower_bound = serializers.FloatField()
    demand_upper_bound = serializers.FloatField()
    price_forecast = serializers.FloatField()
    price_lower_bound = serializers.FloatField()
    price_upper_bound = serializers.FloatField()
    rmse_demand = serializers.FloatField()
    rmse_price = serializers.FloatField()
    mape_demand = serializers.FloatField()
    mape_price = serializers.FloatField()
    
    # Metadata from related ForecastMetadata
    metadata = serializers.SerializerMethodField()
    
    # Related alerts
    active_alerts = serializers.SerializerMethodField()
    
    # Staleness info
    days_old = serializers.SerializerMethodField()
    is_stale = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductForecast
        fields = [
            'id',
            'product_id',
            'product_name',
            'category_name',
            'seller_name',
            'seller_location',
            'forecast_date',
            'forecast_period',
            'demand_forecast_kg',
            'demand_lower_bound',
            'demand_upper_bound',
            'price_forecast',
            'price_lower_bound',
            'price_upper_bound',
            'confidence_level',
            'model_type',
            'rmse_demand',
            'rmse_price',
            'mape_demand',
            'mape_price',
            'is_current',
            'metadata',
            'active_alerts',
            'days_old',
            'is_stale',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'forecast_date',
            'created_at',
            'updated_at',
        ]

    def get_category_name(self, obj):
        """Get product category name"""
        if obj.product and obj.product.category:
            return obj.product.category.name
        return 'Market Data' if obj.product_name else 'Unknown'

    def get_seller_location(self, obj):
        """Get seller location"""
        if not obj.product:
            return 'Market Data'
        seller = obj.product.seller
        if seller:
            municipality = getattr(seller, 'municipality', None)
            barangay = getattr(seller, 'barangay', None)
            if municipality and barangay:
                return f"{barangay}, {municipality}"
            return str(municipality) if municipality else 'Unknown'
        return 'Unknown'

    def get_metadata(self, obj):
        """Get related ForecastMetadata"""
        if not obj.product:
            return None
        try:
            metadata = ForecastMetadata.objects.get(product=obj.product)
            return ForecastMetadataSerializer(metadata).data
        except ForecastMetadata.DoesNotExist:
            return None

    def get_active_alerts(self, obj):
        """Get active (unacknowledged) alerts for this product"""
        if not obj.product:
            return []
        alerts = ForecastAlert.objects.filter(
            product=obj.product,
            is_acknowledged=False
        ).order_by('-created_at')
        return ForecastAlertSerializer(alerts, many=True).data

    def get_days_old(self, obj):
        """Calculate how many days old the forecast is"""
        age = timezone.now() - obj.forecast_date
        return age.days

    def get_is_stale(self, obj):
        """Check if forecast is stale (>7 days old)"""
        age = timezone.now() - obj.forecast_date
        return age.days >= 7


class ForecastRefreshRequestSerializer(serializers.Serializer):
    """Serializer for manual forecast refresh request"""
    product_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        help_text='List of product IDs to refresh. If empty, refreshes all products.'
    )
    force_regenerate = serializers.BooleanField(
        default=False,
        help_text='If True, regenerates even if forecast is recent'
    )
    
    def validate(self, data):
        """Validate and reject unknown fields"""
        # Check for unknown fields in the input data
        allowed_fields = {'product_ids', 'force_regenerate'}
        provided_fields = set(self.initial_data.keys())
        unknown_fields = provided_fields - allowed_fields
        
        if unknown_fields:
            raise serializers.ValidationError(
                f"Unknown field(s): {', '.join(unknown_fields)}"
            )
        
        return data
    
    class Meta:
        fields = ['product_ids', 'force_regenerate']


class ForecastRefreshResponseSerializer(serializers.Serializer):
    """Response serializer for forecast refresh operation"""
    status = serializers.CharField()
    total_processed = serializers.IntegerField()
    successful = serializers.IntegerField()
    failed = serializers.IntegerField()
    stale_forecasts_detected = serializers.IntegerField(allow_null=True)
    alerts_created = serializers.IntegerField(allow_null=True)
    task_id = serializers.CharField(allow_null=True)
    message = serializers.CharField()
    timestamp = serializers.DateTimeField()
    
    class Meta:
        fields = [
            'status',
            'total_processed',
            'successful',
            'failed',
            'stale_forecasts_detected',
            'alerts_created',
            'task_id',
            'message',
            'timestamp',
        ]
