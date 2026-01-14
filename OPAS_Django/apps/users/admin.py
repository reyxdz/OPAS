from django.contrib import admin
from django.utils.html import format_html
from .models import User, SellerApplication
from .seller_models import (
    SellerProduct, SellerOrder, SellToOPAS, SellerPayout, SellerForecast, 
    ProductImage, ProductCategory, CategoryPriceCeiling, Notification, 
    Announcement, SellerAnnouncementRead
)
from .opas_models import OPASProduct, OPASProductSale
from .admin_models import AdminUser, SellerRegistrationRequest

# Configure admin site
admin.site.site_header = "OPAS Administration"
admin.site.site_title = "OPAS Admin Portal"


@admin.register(User)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('id', 'phone_number', 'first_name', 'last_name', 'role', 'municipality', 'barangay', 'farm_municipality', 'farm_barangay', 'is_active', 'created_at')
    search_fields = ('phone_number', 'first_name', 'last_name', 'municipality', 'barangay', 'farm_municipality', 'farm_barangay', 'email')
    list_filter = ('role', 'is_active', 'municipality', 'farm_municipality', 'created_at', 'seller_status')
    ordering = ('-created_at',)
    list_per_page = 50
    
    fieldsets = (
        (None, {'fields': ('phone_number', 'password')}),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'address', 'email')}),
        ('Residence Location', {'fields': ('municipality', 'barangay')}),
        ('Farm Location', {'fields': ('farm_municipality', 'farm_barangay')}),
        ('Seller Info', {'fields': ('store_name', 'store_description', 'seller_status', 'seller_approval_date', 'products_grown')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('User Role', {'fields': ('role', 'admin_role', 'is_opas_admin')}),
        ('Important Dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'password1', 'password2'),
        }),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'address')}),
        ('Residence Location', {'fields': ('municipality', 'barangay')}),
        ('Farm Location', {'fields': ('farm_municipality', 'farm_barangay')}),
        ('User Role', {'fields': ('role',)}),
    )


@admin.register(AdminUser)
class AdminUserAdmin(admin.ModelAdmin):
    list_display = ('user', 'admin_role', 'department', 'is_active', 'created_at')
    search_fields = ('user__phone_number', 'user__first_name', 'user__last_name', 'user__email')
    list_filter = ('admin_role', 'is_active', 'created_at')
    ordering = ('-created_at',)
    list_per_page = 50
    
    fieldsets = (
        ('User Assignment', {'fields': ('user',)}),
        ('Role & Permissions', {'fields': ('admin_role', 'department', 'custom_permissions')}),
        ('Status', {'fields': ('is_active',)}),
        ('Activity', {'fields': ('last_login', 'last_activity')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at'), 'classes': ('collapse',)}),
    )


@admin.register(SellerRegistrationRequest)
class SellerRegistrationRequestAdmin(admin.ModelAdmin):
    list_display = ('seller', 'status', 'farm_name', 'store_name', 'submitted_at', 'reviewed_at')
    search_fields = ('seller__phone_number', 'seller__first_name', 'seller__email', 'farm_name', 'store_name')
    list_filter = ('status', 'submitted_at', 'reviewed_at')
    ordering = ('-submitted_at',)
    list_per_page = 50
    readonly_fields = ('submitted_at', 'reviewed_at', 'approved_at', 'rejected_at')
    
    fieldsets = (
        ('Seller Information', {'fields': ('seller',)}),
        ('Farm & Store', {'fields': ('farm_name', 'farm_location', 'store_name', 'store_description', 'products_grown')}),
        ('Status', {'fields': ('status', 'rejection_reason')}),
        ('Timestamps', {'fields': ('submitted_at', 'reviewed_at', 'approved_at', 'rejected_at')}),
    )


@admin.register(SellerApplication)
class SellerApplicationAdmin(admin.ModelAdmin):
    list_display = ('user', 'farm_name', 'store_name', 'status', 'created_at', 'reviewed_at', 'reviewed_by')
    search_fields = ('user__email', 'user__phone_number', 'farm_name', 'store_name')
    list_filter = ('status', 'created_at', 'reviewed_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'reviewed_at', 'reviewed_by')
    list_per_page = 50
    
    fieldsets = (
        ('Applicant Information', {'fields': ('user',)}),
        ('Farm Information', {'fields': ('farm_name', 'farm_location')}),
        ('Store Information', {'fields': ('store_name', 'store_description')}),
        ('Application Status', {'fields': ('status', 'rejection_reason')}),
        ('Review Information', {'fields': ('created_at', 'updated_at', 'reviewed_at', 'reviewed_by')}),
    )


@admin.register(ProductCategory)
class ProductCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name', 'description')
    list_per_page = 50


@admin.register(CategoryPriceCeiling)
class CategoryPriceCeilingAdmin(admin.ModelAdmin):
    list_display = ('category', 'updated_at')
    search_fields = ('category__name',)
    list_filter = ('category',)
    ordering = ('-updated_at',)
    list_per_page = 50
    readonly_fields = ('updated_at',)


@admin.register(SellerProduct)
class SellerProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'seller', 'category', 'product_type', 'product_subtype', 'price', 'stock_level', 'status', 'created_at')
    search_fields = ('name', 'seller__email', 'seller__phone_number', 'category', 'product_type')
    list_filter = ('status', 'category', 'product_type', 'quality_grade', 'created_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'listed_date')
    list_per_page = 50
    
    fieldsets = (
        ('Product Information', {
            'fields': ('seller', 'name', 'description', 'category', 'product_type', 'product_subtype')
        }),
        ('Pricing & Unit', {
            'fields': ('price', 'unit')
        }),
        ('Inventory', {
            'fields': ('stock_level', 'minimum_stock')
        }),
        ('Quality & Media', {
            'fields': ('quality_grade', 'image_url', 'images')
        }),
        ('Fulfillment', {
            'fields': ('fulfillment_methods',)
        }),
        ('Status', {
            'fields': ('status', 'listed_date', 'expiry_date')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'product', 'is_primary', 'order', 'alt_text', 'uploaded_at')
    search_fields = ('product__name', 'alt_text')
    list_filter = ('is_primary', 'uploaded_at')
    ordering = ('-uploaded_at',)
    readonly_fields = ('uploaded_at',)
    list_per_page = 50


@admin.register(SellerOrder)
class SellerOrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'seller', 'buyer', 'product', 'quantity', 'total_amount', 'status', 'created_at')
    search_fields = ('order_number', 'seller__email', 'seller__phone_number', 'buyer__email', 'buyer__phone_number')
    list_filter = ('status', 'created_at', 'accepted_at', 'delivered_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'accepted_at', 'fulfilled_at', 'delivered_at')
    list_per_page = 50
    
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
    list_display = ('submission_number', 'seller', 'product', 'quantity_offered', 'offered_price', 'approved_price', 'status', 'created_at')
    search_fields = ('submission_number', 'seller__email', 'seller__phone_number', 'product__name')
    list_filter = ('status', 'quality_grade', 'created_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'accepted_at', 'completed_at')
    list_per_page = 50
    
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
    list_display = ('seller', 'period_start', 'period_end', 'status', 'net_earnings', 'payment_method', 'created_at')
    search_fields = ('seller__email', 'seller__phone_number', 'transaction_id')
    list_filter = ('status', 'payment_method', 'period_end')
    ordering = ('-period_end',)
    readonly_fields = ('created_at', 'updated_at', 'processed_at')
    list_per_page = 50
    
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
    list_display = ('seller', 'product', 'forecast_start', 'forecast_end', 'forecasted_demand', 'actual_demand', 'confidence_score', 'forecast_date')
    search_fields = ('seller__email', 'seller__phone_number', 'product__name')
    list_filter = ('forecast_date', 'forecast_start', 'forecast_end')
    ordering = ('-forecast_date',)
    readonly_fields = ('created_at', 'updated_at')
    list_per_page = 50
    
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


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'is_read', 'created_at', 'read_at')
    search_fields = ('user__email', 'user__phone_number', 'title', 'message')
    list_filter = ('is_read', 'created_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'read_at')
    list_per_page = 50
    
    fieldsets = (
        ('Notification Content', {'fields': ('user', 'title', 'message')}),
        ('Metadata', {'fields': ('data',)}),
        ('Status', {'fields': ('is_read',)}),
        ('Timestamps', {'fields': ('created_at', 'read_at'), 'classes': ('collapse',)}),
    )


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'created_by', 'created_at', 'updated_at')
    search_fields = ('title', 'content', 'created_by__email')
    list_filter = ('created_at',)
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')
    list_per_page = 50
    
    fieldsets = (
        ('Announcement Content', {'fields': ('title', 'content')}),
        ('Creator', {'fields': ('created_by',)}),
        ('Timestamps', {'fields': ('created_at', 'updated_at'), 'classes': ('collapse',)}),
    )


@admin.register(SellerAnnouncementRead)
class SellerAnnouncementReadAdmin(admin.ModelAdmin):
    list_display = ('id', 'announcement', 'read_at')
    search_fields = ('seller__email', 'seller__phone_number', 'announcement__title')
    ordering = ('-read_at',)
    list_per_page = 50


@admin.register(OPASProduct)
class OPASProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'category_forecast', 'product_type', 'product_subtype', 'created_at')
    search_fields = ('name', 'description', 'category_forecast', 'product_type', 'product_subtype')
    list_filter = ('category_forecast', 'product_type', 'created_at')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')
    list_per_page = 50
    
    fieldsets = (
        ('Product Information', {
            'fields': ('name', 'description', 'category_forecast', 'product_type', 'product_subtype')
        }),
        ('Pricing & Unit', {
            'fields': ('price', 'unit')
        }),
        ('Stock', {
            'fields': ('stock_level',)
        }),
        ('Fulfillment', {
            'fields': ('fulfillment_methods',)
        }),
        ('Image', {
            'fields': ('image',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(OPASProductSale)
class OPASProductSaleAdmin(admin.ModelAdmin):
    list_display = ('id', 'opas_product', 'seller_product', 'quantity_sold', 'price_per_unit', 'total_amount', 'sale_date')
    search_fields = ('opas_product__name', 'seller_product__name')
    list_filter = ('sale_date',)
    ordering = ('-sale_date',)
    readonly_fields = ('recorded_at', 'total_amount')
    list_per_page = 50
    
    fieldsets = (
        ('Products', {'fields': ('opas_product', 'seller_product')}),
        ('Sale Details', {'fields': ('quantity_sold', 'price_per_unit', 'total_amount')}),
        ('Date', {'fields': ('sale_date', 'recorded_at')}),
    )
