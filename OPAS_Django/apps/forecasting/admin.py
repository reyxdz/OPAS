from django.contrib import admin
from .models import (
    ProductForecast,
    ForecastMetadata,
    HistoricalTransactions,
    ForecastAlert,
    MarketHistoricalData,
)


@admin.register(ProductForecast)
class ProductForecastAdmin(admin.ModelAdmin):
    """Admin interface for ProductForecast model"""
    
    list_display = [
        'id', 'product', 'forecast_period', 'model_type', 'confidence_level',
        'demand_forecast_kg', 'demand_lower_bound', 'demand_upper_bound',
        'price_forecast', 'price_lower_bound', 'price_upper_bound',
        'is_current', 'created_at', 'updated_at'
    ]
    list_filter = [
        'model_type', 'confidence_level', 'is_current', 'created_at', 'updated_at'
    ]
    search_fields = ['product__name', 'product__seller__email']
    readonly_fields = ['forecast_date', 'created_at', 'updated_at']
    list_per_page = 50
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Product & Period', {
            'fields': ('product', 'forecast_period', 'forecast_date', 'is_current')
        }),
        ('Demand Forecast', {
            'fields': (
                'demand_forecast_kg', 'demand_lower_bound', 'demand_upper_bound'
            )
        }),
        ('Price Forecast', {
            'fields': (
                'price_forecast', 'price_lower_bound', 'price_upper_bound'
            )
        }),
        ('Model Information', {
            'fields': ('model_type', 'confidence_level')
        }),
        ('Performance Metrics', {
            'fields': ('rmse_demand', 'rmse_price', 'mape_demand', 'mape_price'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def has_add_permission(self, request):
        # Forecasts are generated programmatically, not manually added
        return False


@admin.register(ForecastMetadata)
class ForecastMetadataAdmin(admin.ModelAdmin):
    """Admin interface for ForecastMetadata model"""
    
    list_display = [
        'id', 'product', 'model_type', 'data_points_count',
        'data_coverage_percentage', 'is_reliable', 'last_training_date',
        'last_successful_forecast_date', 'updated_at'
    ]
    list_filter = ['model_type', 'is_reliable', 'last_training_date', 'updated_at']
    search_fields = ['product__name', 'product__seller__email']
    readonly_fields = ['updated_at', 'last_training_date']
    list_per_page = 50
    ordering = ('-updated_at',)
    
    fieldsets = (
        ('Product', {
            'fields': ('product',)
        }),
        ('Model Selection', {
            'fields': ('model_type', 'is_reliable', 'model_parameters')
        }),
        ('Data Statistics', {
            'fields': (
                'data_points_count', 'data_coverage_percentage'
            )
        }),
        ('Training Information', {
            'fields': (
                'last_training_date', 'last_successful_forecast_date'
            )
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
        ('Timestamps', {
            'fields': ('updated_at',),
            'classes': ('collapse',)
        }),
    )
    
    def has_add_permission(self, request):
        # Metadata is generated programmatically
        return False


@admin.register(HistoricalTransactions)
class HistoricalTransactionsAdmin(admin.ModelAdmin):
    """Admin interface for HistoricalTransactions model"""
    
    list_display = [
        'id', 'product', 'transaction_date', 'quantity_sold_kg',
        'average_price_per_kg', 'total_revenue', 'transaction_count',
        'data_quality_score', 'is_complete', 'created_at', 'updated_at'
    ]
    list_filter = ['transaction_date', 'data_quality_score', 'is_complete', 'created_at']
    search_fields = ['product__name', 'product__seller__email']
    readonly_fields = ['total_revenue', 'created_at', 'updated_at']
    date_hierarchy = 'transaction_date'
    list_per_page = 50
    ordering = ('-transaction_date',)
    
    fieldsets = (
        ('Product & Date', {
            'fields': ('product', 'transaction_date')
        }),
        ('Transaction Data', {
            'fields': (
                'quantity_sold_kg', 'average_price_per_kg', 'total_revenue',
                'transaction_count'
            )
        }),
        ('Data Quality', {
            'fields': ('data_quality_score', 'is_complete')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(MarketHistoricalData)
class MarketHistoricalDataAdmin(admin.ModelAdmin):
    """Admin interface for MarketHistoricalData model"""
    
    list_display = [
        'id', 'product_name', 'category_name', 'market_date', 'quantity_kg', 'price_per_kg', 'source', 'created_at'
    ]
    list_filter = ['market_date', 'source', 'created_at']
    search_fields = ['product_name', 'category_name']
    readonly_fields = ['created_at', 'updated_at']
    list_per_page = 50
    ordering = ('-market_date',)
    
    fieldsets = (
        ('Product Information', {
            'fields': ('product_name', 'category_name')
        }),
        ('Market Data', {
            'fields': ('market_date', 'quantity_kg', 'price_per_kg', 'total_value')
        }),
        ('Source & Quality', {
            'fields': ('source', 'data_quality_score', 'notes')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(ForecastAlert)
class ForecastAlertAdmin(admin.ModelAdmin):
    """Admin interface for ForecastAlert model"""
    
    list_display = [
        'id', 'product', 'alert_type', 'severity', 'message',
        'is_acknowledged', 'acknowledged_by', 'created_at',
        'acknowledged_at', 'resolved_at'
    ]
    list_filter = [
        'alert_type', 'severity', 'is_acknowledged', 'created_at', 'acknowledged_at'
    ]
    search_fields = ['product__name', 'product__seller__email', 'message']
    readonly_fields = ['created_at', 'acknowledged_at']
    list_per_page = 50
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Alert Information', {
            'fields': ('product', 'alert_type', 'severity', 'message')
        }),
        ('Related Forecast', {
            'fields': ('related_forecast',)
        }),
        ('Metadata', {
            'fields': ('metadata',),
            'classes': ('collapse',)
        }),
        ('Acknowledgment', {
            'fields': ('is_acknowledged', 'acknowledged_by', 'acknowledged_at', 'resolved_at')
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['mark_acknowledged', 'mark_unacknowledged']
    
    def mark_acknowledged(self, request, queryset):
        """Mark selected alerts as acknowledged"""
        updated = queryset.update(is_acknowledged=True, acknowledged_by=request.user)
        self.message_user(request, f'{updated} alert(s) marked as acknowledged.')
    
    mark_acknowledged.short_description = 'Mark selected alerts as acknowledged'
    
    def mark_unacknowledged(self, request, queryset):
        """Mark selected alerts as unacknowledged"""
        updated = queryset.update(is_acknowledged=False, acknowledged_by=None)
        self.message_user(request, f'{updated} alert(s) marked as unacknowledged.')
    
    mark_unacknowledged.short_description = 'Mark selected alerts as unacknowledged'
