from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, SellerApplication
from .seller_models import SellerProduct, SellerOrder, SellToOPAS, SellerPayout, SellerForecast

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('phone_number', 'username', 'first_name', 'last_name', 'municipality', 'barangay', 'farm_municipality', 'farm_barangay', 'role', 'created_at')
    search_fields = ('phone_number', 'username', 'first_name', 'last_name', 'municipality', 'barangay', 'farm_municipality', 'farm_barangay')
    list_filter = ('role', 'municipality', 'farm_municipality', 'created_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        (None, {'fields': ('username', 'phone_number', 'password')}),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'address')}),
        ('Residence Location', {'fields': ('municipality', 'barangay')}),
        ('Farm Location', {'fields': ('farm_municipality', 'farm_barangay')}),
        ('Seller Info', {'fields': ('store_name', 'store_description', 'seller_status', 'seller_approval_date')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('User Role', {'fields': ('role', 'admin_role')}),
        ('Important Dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'phone_number', 'password1', 'password2'),
        }),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'address')}),
        ('Residence Location', {'fields': ('municipality', 'barangay')}),
        ('Farm Location', {'fields': ('farm_municipality', 'farm_barangay')}),
        ('User Role', {'fields': ('role',)}),
    )


@admin.register(SellerApplication)
class SellerApplicationAdmin(admin.ModelAdmin):
    list_display = ('user', 'farm_name', 'store_name', 'status', 'created_at', 'reviewed_at')
    search_fields = ('user__email', 'farm_name', 'store_name')
    list_filter = ('status', 'created_at', 'reviewed_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'reviewed_at', 'reviewed_by')
    
    fieldsets = (
        ('Applicant Information', {
            'fields': ('user',)
        }),
        ('Farm Information', {
            'fields': ('farm_name', 'farm_location')
        }),
        ('Store Information', {
            'fields': ('store_name', 'store_description')
        }),
        ('Application Status', {
            'fields': ('status', 'rejection_reason')
        }),
        ('Review Information', {
            'fields': ('created_at', 'updated_at', 'reviewed_at', 'reviewed_by')
        }),
    )


@admin.register(SellerProduct)
class SellerProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'seller', 'status', 'price', 'ceiling_price', 'stock_level', 'created_at')
    search_fields = ('name', 'seller__email', 'product_type')
    list_filter = ('status', 'product_type', 'quality_grade', 'created_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'listed_date')
    
    fieldsets = (
        ('Product Information', {
            'fields': ('seller', 'name', 'description', 'product_type')
        }),
        ('Pricing', {
            'fields': ('price', 'ceiling_price', 'unit')
        }),
        ('Inventory', {
            'fields': ('stock_level', 'minimum_stock')
        }),
        ('Quality & Media', {
            'fields': ('quality_grade', 'image_url', 'images')
        }),
        ('Status', {
            'fields': ('status', 'listed_date', 'expiry_date')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SellerOrder)
class SellerOrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'seller', 'buyer', 'status', 'total_amount', 'created_at')
    search_fields = ('order_number', 'seller__email', 'buyer__email')
    list_filter = ('status', 'created_at', 'accepted_at', 'delivered_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'accepted_at', 'fulfilled_at', 'delivered_at')
    
    fieldsets = (
        ('Order Information', {
            'fields': ('order_number', 'seller', 'buyer', 'product')
        }),
        ('Order Details', {
            'fields': ('quantity', 'price_per_unit', 'total_amount')
        }),
        ('Status', {
            'fields': ('status', 'rejection_reason')
        }),
        ('Delivery', {
            'fields': ('delivery_location', 'delivery_date')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'accepted_at', 'fulfilled_at', 'delivered_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SellToOPAS)
class SellToOPASAdmin(admin.ModelAdmin):
    list_display = ('submission_number', 'seller', 'quantity_offered', 'status', 'offered_price', 'created_at')
    search_fields = ('submission_number', 'seller__email')
    list_filter = ('status', 'quality_grade', 'created_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'accepted_at', 'completed_at')
    
    fieldsets = (
        ('Submission Information', {
            'fields': ('submission_number', 'seller', 'product')
        }),
        ('Submission Details', {
            'fields': ('quantity_offered', 'unit', 'quality_grade')
        }),
        ('Pricing', {
            'fields': ('offered_price', 'approved_price')
        }),
        ('Status', {
            'fields': ('status', 'rejection_reason')
        }),
        ('Delivery', {
            'fields': ('delivery_date', 'pickup_location')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'accepted_at', 'completed_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SellerPayout)
class SellerPayoutAdmin(admin.ModelAdmin):
    list_display = ('seller', 'period_start', 'period_end', 'status', 'net_earnings', 'created_at')
    search_fields = ('seller__email', 'transaction_id')
    list_filter = ('status', 'payment_method', 'period_end')
    ordering = ('-period_end',)
    readonly_fields = ('created_at', 'updated_at', 'processed_at')
    
    fieldsets = (
        ('Payout Information', {
            'fields': ('seller', 'period_start', 'period_end')
        }),
        ('Financial Details', {
            'fields': (
                'total_earnings',
                'transaction_fees',
                'service_fee_percent',
                'service_fee_amount',
                'other_deductions',
                'net_earnings'
            )
        }),
        ('Status & Payment', {
            'fields': ('status', 'payment_method', 'bank_account', 'transaction_id')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'processed_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SellerForecast)
class SellerForecastAdmin(admin.ModelAdmin):
    list_display = ('seller', 'forecast_start', 'forecast_end', 'forecasted_demand', 'actual_demand', 'confidence_score')
    search_fields = ('seller__email',)
    list_filter = ('forecast_date', 'forecast_start', 'forecast_end')
    ordering = ('-forecast_date',)
    readonly_fields = ('created_at', 'updated_at')
    
    fieldsets = (
        ('Forecast Information', {
            'fields': ('seller', 'product', 'forecast_date')
        }),
        ('Forecast Period', {
            'fields': ('forecast_start', 'forecast_end')
        }),
        ('Forecast Data', {
            'fields': ('forecasted_demand', 'actual_demand', 'confidence_score', 'accuracy')
        }),
        ('Risk Assessment', {
            'fields': (
                'surplus_probability',
                'stockout_probability',
                'recommended_stock'
            )
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
