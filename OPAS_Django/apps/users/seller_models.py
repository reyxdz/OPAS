"""
Seller-specific models for OPAS platform.

Models:
- SellerProduct: Product listings by sellers
- SellerOrder: Orders from buyers to sellers
- SellToOPAS: Bulk submissions to OPAS platform
- SellerPayout: Payment tracking for sellers
- SellerForecast: Demand forecasting data
"""

from django.db import models
from django.utils import timezone
from .models import User


class ProductStatus(models.TextChoices):
    """Product listing status choices"""
    ACTIVE = 'ACTIVE', 'Active'
    INACTIVE = 'INACTIVE', 'Inactive'
    EXPIRED = 'EXPIRED', 'Expired'
    PENDING = 'PENDING', 'Pending Approval'
    REJECTED = 'REJECTED', 'Rejected'


class ProductCategory(models.Model):
    """Hierarchical category/type/subtype node for seller products.

    This supports a flexible taxonomy (category -> type -> subtype) using a
    self-referential parent link. Admins manage category nodes; sellers will
    assign products to one node.
    """
    slug = models.SlugField(max_length=120, unique=True, help_text='Canonical slug (e.g., TOMATO)')
    name = models.CharField(max_length=255, help_text='Human-friendly name')
    parent = models.ForeignKey(
        'self', null=True, blank=True, on_delete=models.SET_NULL, related_name='children'
    )
    description = models.TextField(blank=True, null=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'product_categories'
        verbose_name = 'Product Category'
        verbose_name_plural = 'Product Categories'
        indexes = [models.Index(fields=['slug'])]

    def __str__(self):
        return self.name


class CategoryPriceCeiling(models.Model):
    """Admin-managed category-level price ceiling attached to a ProductCategory node.

    This model is separate from the per-product PriceCeiling (admin_models.PriceCeiling)
    which is one-to-one with a SellerProduct. CategoryPriceCeiling applies ceilings at
    the taxonomy level (category / type / subtype) and will be used for category-wide
    enforcement or lookups.
    """
    category = models.ForeignKey(ProductCategory, on_delete=models.CASCADE, related_name='category_price_ceilings')
    ceiling_price = models.DecimalField(max_digits=10, decimal_places=2)
    active = models.BooleanField(default=True)
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL, related_name='ceilings_created')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'category_price_ceilings'
        verbose_name = 'Category Price Ceiling'
        verbose_name_plural = 'Category Price Ceilings'
        indexes = [models.Index(fields=['category', 'active'])]

    def __str__(self):
        return f"{self.category.slug} — {self.ceiling_price}"


class SellerProductQuerySet(models.QuerySet):
    """Custom QuerySet for SellerProduct model"""
    
    def active(self):
        """Get only non-deleted, active products"""
        return self.filter(is_deleted=False, status=ProductStatus.ACTIVE)
    
    def deleted(self):
        """Get deleted products"""
        return self.filter(is_deleted=True)
    
    def not_deleted(self):
        """Get non-deleted products"""
        return self.filter(is_deleted=False)
    
    def by_seller(self, seller):
        """Filter products by seller"""
        return self.filter(seller=seller)
    
    def compliant(self):
        """Get products within price ceiling"""
        from django.db.models import Q
        return self.filter(Q(ceiling_price__isnull=True) | Q(price__lte=models.F('ceiling_price')))
    
    def non_compliant(self):
        """Get products exceeding price ceiling"""
        return self.filter(price__gt=models.F('ceiling_price'), ceiling_price__isnull=False)


class SellerProductManager(models.Manager):
    """Manager for SellerProduct model"""
    
    def get_queryset(self):
        return SellerProductQuerySet(self.model, using=self._db)
    
    def active(self):
        """Get active products"""
        return self.get_queryset().active()
    
    def deleted(self):
        """Get deleted products"""
        return self.get_queryset().deleted()
    
    def not_deleted(self):
        """Get non-deleted products"""
        return self.get_queryset().not_deleted()
    
    def compliant(self):
        """Get compliant products"""
        return self.get_queryset().compliant()
    
    def non_compliant(self):
        """Get non-compliant products"""
        return self.get_queryset().non_compliant()


class OrderStatus(models.TextChoices):
    """Order status choices"""
    PENDING = 'PENDING', 'Pending'
    ACCEPTED = 'ACCEPTED', 'Accepted'
    REJECTED = 'REJECTED', 'Rejected'
    FULFILLED = 'FULFILLED', 'Fulfilled'
    DELIVERED = 'DELIVERED', 'Delivered'
    CANCELLED = 'CANCELLED', 'Cancelled'


class SellerProduct(models.Model):
    """
    Product model for seller listings.
    
    Tracks:
    - Product information (name, price, quality)
    - Seller relationship and ownership
    - Inventory levels and stock tracking
    - Pricing with ceiling enforcement
    - Product status and approval workflow
    - Timestamps for audit trail
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='products',
        help_text='The seller who listed this product'
    )
    
    # ==================== PRODUCT INFORMATION ====================
    name = models.CharField(
        max_length=255,
        help_text='Product name'
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text='Product description'
    )
    product_type = models.CharField(
        max_length=100,
        help_text='Category or type of product (e.g., vegetables, fruits)'
    )

    # New: link each SellerProduct to a canonical ProductCategory node
    category = models.ForeignKey(
        'ProductCategory',
        on_delete=models.SET_NULL,
        related_name='products',
        blank=True,
        null=True,
        help_text='Canonical category/type/subtype node for the product (admin-managed)'
    )
    
    # ==================== PRICING ====================
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Selling price per unit'
    )
    ceiling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Maximum allowed price set by OPAS'
    )
    unit = models.CharField(
        max_length=50,
        default='kg',
        help_text='Unit of measurement (kg, lbs, piece, etc.)'
    )
    
    # ==================== INVENTORY ====================
    stock_level = models.IntegerField(
        default=0,
        help_text='Current stock quantity'
    )
    minimum_stock = models.IntegerField(
        default=0,
        help_text='Minimum stock level before alert'
    )
    
    # ==================== QUALITY & GRADING ====================
    quality_grade = models.CharField(
        max_length=20,
        choices=[
            ('PREMIUM', 'Premium'),
            ('STANDARD', 'Standard'),
            ('BASIC', 'Basic'),
        ],
        default='STANDARD',
        help_text='Quality grade of the product'
    )
    
    # ==================== MEDIA ====================
    image_url = models.URLField(
        blank=True,
        null=True,
        help_text='Primary product image URL'
    )
    images = models.JSONField(
        default=list,
        blank=True,
        help_text='List of product image URLs'
    )
    
    # ==================== STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=ProductStatus.choices,
        default=ProductStatus.PENDING,
        help_text='Current product listing status'
    )
    is_deleted = models.BooleanField(
        default=False,
        help_text='Soft delete flag for product listing'
    )
    deleted_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the product was deleted'
    )
    deletion_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for deletion'
    )
    
    # ==================== EXPIRY ====================
    listed_date = models.DateTimeField(
        auto_now_add=True,
        help_text='When the product was listed'
    )
    expiry_date = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the product listing expires'
    )
    # Store the previous status before the product was expired so reactivation
    # can restore the prior state (e.g., ACTIVE/PENDING) rather than guessing.
    previous_status = models.CharField(
        max_length=20,
        choices=ProductStatus.choices,
        blank=True,
        null=True,
        help_text='Previous status of the product before it was set to EXPIRED',
    )

    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Product creation timestamp'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    
    class Meta:
        db_table = 'seller_products'
        verbose_name = 'Seller Product'
        verbose_name_plural = 'Seller Products'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller', 'status']),
            models.Index(fields=['product_type']),
            models.Index(fields=['expiry_date']),
            models.Index(fields=['is_deleted']),
            models.Index(fields=['seller', 'is_deleted']),
        ]
    
    objects = SellerProductManager()
    
    @property
    def is_active(self):
        """Check if product is active and not deleted"""
        return self.status == ProductStatus.ACTIVE and not self.is_deleted
    
    @property
    def is_expired(self):
        """Check if product listing has expired"""
        return self.expiry_date and self.expiry_date < timezone.now()
    
    @property
    def price_exceeds_ceiling(self):
        """Check if price exceeds ceiling price"""
        if self.ceiling_price:
            return self.price > self.ceiling_price
        return False
    
    @property
    def is_low_stock(self):
        """Check if stock is below minimum"""
        return self.stock_level < self.minimum_stock
    
    def soft_delete(self, reason=''):
        """Soft delete the product"""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.deletion_reason = reason
        self.save()
    
    def restore(self):
        """Restore a soft-deleted product"""
        self.is_deleted = False
        self.deleted_at = None
        self.deletion_reason = ''
        self.save()
    
    def __str__(self):
        return f"{self.name} ({self.seller.email})"
    
    def __repr__(self):
        return f"<SellerProduct: {self.name} | Seller: {self.seller.email}>"


class SellerOrder(models.Model):
    """
    Order model for tracking orders from buyers to sellers.
    
    Tracks:
    - Buyer and seller relationship
    - Order items and quantities
    - Order status and workflow
    - Delivery information
    - Payment and fulfillment
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='seller_orders',
        help_text='The seller fulfilling this order'
    )
    buyer = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='buyer_orders',
        help_text='The buyer who placed this order'
    )
    product = models.ForeignKey(
        SellerProduct,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='orders',
        help_text='The product being ordered'
    )
    
    # ==================== ORDER DETAILS ====================
    order_number = models.CharField(
        max_length=50,
        unique=True,
        help_text='Unique order number'
    )
    quantity = models.IntegerField(
        help_text='Quantity ordered'
    )
    price_per_unit = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Price per unit at time of order'
    )
    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Total order amount'
    )
    
    # ==================== STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=OrderStatus.choices,
        default=OrderStatus.PENDING,
        help_text='Current order status'
    )
    rejection_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for order rejection (if rejected)'
    )
    
    # ==================== DELIVERY ====================
    delivery_location = models.TextField(
        blank=True,
        null=True,
        help_text='Delivery address'
    )
    delivery_date = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Expected delivery date'
    )
    
    # ==================== FULFILLMENT TRACKING ====================
    on_time = models.BooleanField(
        default=True,
        help_text='Whether order was fulfilled on time'
    )
    fulfillment_days = models.IntegerField(
        blank=True,
        null=True,
        help_text='Number of days from creation to delivery'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Order creation timestamp'
    )
    accepted_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When order was accepted by seller'
    )
    fulfilled_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When order was fulfilled/shipped'
    )
    delivered_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When order was delivered'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    
    class Meta:
        db_table = 'seller_orders'
        verbose_name = 'Seller Order'
        verbose_name_plural = 'Seller Orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller', 'status']),
            models.Index(fields=['buyer', 'status']),
            models.Index(fields=['order_number']),
        ]
    
    @property
    def is_pending(self):
        """Check if order is pending"""
        return self.status == OrderStatus.PENDING
    
    @property
    def is_accepted(self):
        """Check if order is accepted"""
        return self.status == OrderStatus.ACCEPTED
    
    @property
    def is_fulfilled(self):
        """Check if order is fulfilled"""
        return self.status == OrderStatus.FULFILLED
    
    @property
    def is_delivered(self):
        """Check if order is delivered"""
        return self.status == OrderStatus.DELIVERED
    
    @property
    def can_be_accepted(self):
        """Check if order can be accepted"""
        return self.status == OrderStatus.PENDING
    
    @property
    def can_be_rejected(self):
        """Check if order can be rejected"""
        return self.status == OrderStatus.PENDING
    
    @property
    def can_be_fulfilled(self):
        """Check if order can be marked fulfilled"""
        return self.status == OrderStatus.ACCEPTED
    
    @property
    def can_be_delivered(self):
        """Check if order can be marked delivered"""
        return self.status == OrderStatus.FULFILLED
    
    def mark_delivered(self):
        """Mark order as delivered and calculate fulfillment metrics"""
        self.status = OrderStatus.DELIVERED
        self.delivered_at = timezone.now()
        
        # Calculate fulfillment days
        if self.created_at:
            self.fulfillment_days = (self.delivered_at - self.created_at).days
        
        # Check if delivered on time
        if self.delivery_date and self.delivered_at:
            self.on_time = self.delivered_at <= self.delivery_date
        
        self.save()
    
    def get_fulfillment_status(self):
        """Get detailed fulfillment status"""
        return {
            'on_time': self.on_time,
            'fulfillment_days': self.fulfillment_days,
            'was_late': not self.on_time if self.on_time is not None else None,
        }
    
    def __str__(self):
        return f"Order {self.order_number} - {self.seller.email}"
    
    def __repr__(self):
        return f"<SellerOrder: {self.order_number} | Status: {self.status}>"


class SellToOPAS(models.Model):
    """
    Model for bulk submissions to OPAS platform.
    
    Tracks:
    - Seller bulk product submissions
    - Submission status and approval
    - Quality assessment and grading
    - Price negotiation
    - Quantity and delivery details
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='opas_submissions',
        help_text='The seller making the submission'
    )
    product = models.ForeignKey(
        SellerProduct,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='opas_submissions',
        help_text='The product being submitted'
    )
    
    # ==================== SUBMISSION DETAILS ====================
    submission_number = models.CharField(
        max_length=50,
        unique=True,
        help_text='Unique submission number'
    )
    quantity_offered = models.IntegerField(
        help_text='Total quantity offered to OPAS'
    )
    unit = models.CharField(
        max_length=50,
        default='kg',
        help_text='Unit of measurement'
    )
    
    # ==================== PRICING ====================
    offered_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Price per unit offered by seller'
    )
    approved_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Price approved by OPAS'
    )
    
    # ==================== QUALITY ====================
    quality_grade = models.CharField(
        max_length=20,
        choices=[
            ('PREMIUM', 'Premium'),
            ('STANDARD', 'Standard'),
            ('BASIC', 'Basic'),
        ],
        default='STANDARD',
        help_text='Quality grade of the product'
    )
    
    # ==================== STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=[
            ('PENDING', 'Pending Review'),
            ('ACCEPTED', 'Accepted'),
            ('REJECTED', 'Rejected'),
            ('COMPLETED', 'Completed'),
        ],
        default='PENDING',
        help_text='Submission status'
    )
    rejection_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for rejection (if rejected)'
    )
    
    # ==================== DELIVERY ====================
    delivery_date = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Expected delivery date'
    )
    pickup_location = models.TextField(
        blank=True,
        null=True,
        help_text='Location for OPAS to pick up product'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Submission creation timestamp'
    )
    accepted_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When submission was accepted'
    )
    completed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When submission was completed'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    
    class Meta:
        db_table = 'seller_sell_to_opas'
        verbose_name = 'Sell to OPAS Submission'
        verbose_name_plural = 'Sell to OPAS Submissions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller', 'status']),
            models.Index(fields=['submission_number']),
        ]
    
    def __str__(self):
        return f"OPAS Submission {self.submission_number} - {self.seller.email}"
    
    def __repr__(self):
        return f"<SellToOPAS: {self.submission_number} | Status: {self.status}>"


class SellerPayout(models.Model):
    """
    Model for tracking seller payouts and earnings.
    
    Tracks:
    - Payment periods and amounts
    - Earnings and deductions
    - Payout status and method
    - Transaction details
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='payouts',
        help_text='The seller receiving payout'
    )
    
    # ==================== PERIOD ====================
    period_start = models.DateField(
        help_text='Start date of payout period'
    )
    period_end = models.DateField(
        help_text='End date of payout period'
    )
    
    # ==================== FINANCIAL DETAILS ====================
    total_earnings = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='Total earnings in this period'
    )
    transaction_fees = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text='Platform transaction fees'
    )
    service_fee_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=5.00,
        help_text='Service fee percentage'
    )
    service_fee_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text='Calculated service fee'
    )
    other_deductions = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text='Other deductions'
    )
    net_earnings = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='Net earnings after deductions'
    )
    
    # ==================== PAYOUT STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=[
            ('PENDING', 'Pending'),
            ('PROCESSING', 'Processing'),
            ('COMPLETED', 'Completed'),
            ('FAILED', 'Failed'),
        ],
        default='PENDING',
        help_text='Payout status'
    )
    
    # ==================== PAYMENT METHOD ====================
    payment_method = models.CharField(
        max_length=50,
        choices=[
            ('BANK_TRANSFER', 'Bank Transfer'),
            ('WALLET', 'Wallet'),
            ('CHECK', 'Check'),
        ],
        default='BANK_TRANSFER',
        help_text='Payment method used'
    )
    bank_account = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text='Bank account number (masked)'
    )
    
    # ==================== TRANSACTION ====================
    transaction_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Transaction ID from payment processor'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Payout record creation timestamp'
    )
    processed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When payout was processed'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    
    class Meta:
        db_table = 'seller_payouts'
        verbose_name = 'Seller Payout'
        verbose_name_plural = 'Seller Payouts'
        ordering = ['-period_end']
        indexes = [
            models.Index(fields=['seller', 'status']),
            models.Index(fields=['period_end']),
        ]
        unique_together = ('seller', 'period_start', 'period_end')
    
    def calculate_net_earnings(self):
        """Calculate net earnings after deductions"""
        service_fee = (self.total_earnings * self.service_fee_percent) / 100
        self.service_fee_amount = service_fee
        self.net_earnings = (
            self.total_earnings - 
            service_fee - 
            self.transaction_fees - 
            self.other_deductions
        )
        return self.net_earnings
    
    def __str__(self):
        return f"Payout {self.period_start} to {self.period_end} - {self.seller.email}"
    
    def __repr__(self):
        return f"<SellerPayout: {self.seller.email} | Status: {self.status}>"


class SellerForecast(models.Model):
    """
    Model for demand forecasting data.
    
    Tracks:
    - Forecasted vs actual demand
    - Historical data for comparison
    - Confidence scores and accuracy
    - Risk assessment (surplus/stockout)
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='forecasts',
        help_text='The seller for whom forecast is made'
    )
    product = models.ForeignKey(
        SellerProduct,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='forecasts',
        help_text='The product being forecasted'
    )
    
    # ==================== FORECAST PERIOD ====================
    forecast_date = models.DateField(
        help_text='Date forecast was generated'
    )
    forecast_start = models.DateField(
        help_text='Start date of forecast period'
    )
    forecast_end = models.DateField(
        help_text='End date of forecast period'
    )
    
    # ==================== FORECAST DATA ====================
    forecasted_demand = models.IntegerField(
        help_text='Forecasted demand quantity'
    )
    actual_demand = models.IntegerField(
        blank=True,
        null=True,
        help_text='Actual demand (if period has passed)'
    )
    
    # ==================== ACCURACY ====================
    confidence_score = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text='Forecast confidence (0-100%)'
    )
    accuracy = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Forecast accuracy (0-100%)'
    )
    
    # ==================== RISK ASSESSMENT ====================
    surplus_probability = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text='Probability of surplus (0-100%)'
    )
    stockout_probability = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text='Probability of stockout (0-100%)'
    )
    recommended_stock = models.IntegerField(
        blank=True,
        null=True,
        help_text='Recommended stock level'
    )
    
    # ==================== TREND & SEASONALITY ====================
    trend = models.CharField(
        max_length=20,
        choices=[
            ('UPTREND', 'Uptrend'),
            ('DOWNTREND', 'Downtrend'),
            ('STABLE', 'Stable'),
        ],
        default='STABLE',
        help_text='Demand trend (uptrend, downtrend, stable)'
    )
    volatility = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text='Sales volatility percentage (0-100%)'
    )
    growth_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text='Growth rate percentage (-100% to +100%)'
    )
    trend_multiplier = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=1.0,
        help_text='Trend adjustment multiplier'
    )
    seasonality_detected = models.BooleanField(
        default=False,
        help_text='Whether seasonality pattern was detected'
    )
    
    # ==================== ALGORITHM DATA ====================
    historical_sales_count = models.IntegerField(
        default=0,
        help_text='Number of historical data points used'
    )
    average_daily_sales = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text='Average daily sales from historical data'
    )
    
    # ==================== RECOMMENDATIONS (JSON) ====================
    recommendations = models.JSONField(
        default=list,
        blank=True,
        help_text='List of actionable recommendations'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Forecast creation timestamp'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    
    class Meta:
        db_table = 'seller_forecasts'
        verbose_name = 'Seller Forecast'
        verbose_name_plural = 'Seller Forecasts'
        ordering = ['-forecast_date']
        indexes = [
            models.Index(fields=['seller', 'forecast_date']),
            models.Index(fields=['product', 'forecast_date']),
        ]
    
    @property
    def demand_variance(self):
        """Calculate variance between forecast and actual"""
        if self.actual_demand is not None:
            return abs(self.forecasted_demand - self.actual_demand)
        return None
    
    @property
    def is_surplus_risk(self):
        """Check if surplus risk is high"""
        return self.surplus_probability > 50
    
    @property
    def is_stockout_risk(self):
        """Check if stockout risk is high"""
        return self.stockout_probability > 50
    
    def __str__(self):
        return f"Forecast {self.forecast_start} - {self.seller.email}"
    
    def __repr__(self):
        return f"<SellerForecast: {self.seller.email} | Period: {self.forecast_start}>"


class ProductImage(models.Model):
    """
    Model for storing product images with metadata.
    
    Tracks:
    - Image file and URL
    - Primary image designation
    - Upload details and timestamps
    - Image ordering for display
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.ForeignKey(
        SellerProduct,
        on_delete=models.CASCADE,
        related_name='product_images',
        help_text='The product this image belongs to'
    )
    
    # ==================== FILE ====================
    image = models.ImageField(
        upload_to='product_images/%Y/%m/',
        help_text='Product image file'
    )
    
    # ==================== METADATA ====================
    is_primary = models.BooleanField(
        default=False,
        help_text='Whether this is the primary product image'
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text='Display order for images'
    )
    
    alt_text = models.CharField(
        max_length=255,
        blank=True,
        help_text='Alt text for image accessibility'
    )
    
    # ==================== TIMESTAMPS ====================
    uploaded_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Image upload timestamp'
    )
    
    class Meta:
        db_table = 'seller_product_images'
        verbose_name = 'Product Image'
        verbose_name_plural = 'Product Images'
        ordering = ['order', '-uploaded_at']
        indexes = [
            models.Index(fields=['product', 'is_primary']),
            models.Index(fields=['product', 'order']),
        ]
    
    def __str__(self):
        return f"Image for {self.product.name} - {self.uploaded_at.strftime('%Y-%m-%d')}"
    
    def __repr__(self):
        return f"<ProductImage: {self.product.name} | Primary: {self.is_primary}>"
    
    def save(self, *args, **kwargs):
        """Override save to ensure only one primary image per product"""
        if self.is_primary:
            # Unset other primary images for this product
            ProductImage.objects.filter(
                product=self.product,
                is_primary=True
            ).exclude(pk=self.pk).update(is_primary=False)
        super().save(*args, **kwargs)


class Notification(models.Model):
    """
    Model for seller notifications.
    
    Tracks:
    - Order updates
    - Payment notifications
    - System alerts
    - Read/unread status
    """
    
    # ==================== TYPES ====================
    TYPE_CHOICES = [
        ('Orders', 'Order Notification'),
        ('Payments', 'Payment Notification'),
        ('System', 'System Alert'),
    ]
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        help_text='The seller receiving the notification'
    )
    
    # ==================== CONTENT ====================
    type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        default='System',
        help_text='Notification type'
    )
    title = models.CharField(
        max_length=255,
        help_text='Notification title'
    )
    message = models.TextField(
        help_text='Notification message'
    )
    
    # ==================== STATUS ====================
    is_read = models.BooleanField(
        default=False,
        help_text='Whether notification has been read'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Notification creation timestamp'
    )
    read_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When notification was read'
    )
    
    class Meta:
        db_table = 'seller_notifications'
        verbose_name = 'Seller Notification'
        verbose_name_plural = 'Seller Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller', 'is_read']),
            models.Index(fields=['seller', '-created_at']),
        ]
    
    def __str__(self):
        return f"Notification: {self.title} - {self.seller.email}"
    
    def __repr__(self):
        return f"<Notification: {self.title} | Read: {self.is_read}>"


class Announcement(models.Model):
    """
    Model for admin announcements to sellers.
    
    Tracks:
    - Feature updates
    - Maintenance notices
    - Policy changes
    - Action required items
    """
    
    # ==================== TYPES ====================
    TYPE_CHOICES = [
        ('Features', 'New Features'),
        ('Maintenance', 'Maintenance Notice'),
        ('Policy', 'Policy Update'),
        ('Action Required', 'Action Required'),
    ]
    
    # ==================== PRIORITY ====================
    PRIORITY_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
    ]
    
    # ==================== CONTENT ====================
    title = models.CharField(
        max_length=255,
        help_text='Announcement title'
    )
    content = models.TextField(
        help_text='Announcement content'
    )
    type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        default='Features',
        help_text='Announcement type'
    )
    priority = models.CharField(
        max_length=10,
        choices=PRIORITY_CHOICES,
        default='MEDIUM',
        help_text='Announcement priority'
    )
    
    # ==================== METADATA ====================
    created_by = models.CharField(
        max_length=255,
        default='Admin',
        help_text='Who created this announcement'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Announcement creation timestamp'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When announcement expires'
    )
    
    class Meta:
        db_table = 'seller_announcements'
        verbose_name = 'Seller Announcement'
        verbose_name_plural = 'Seller Announcements'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Announcement: {self.title}"
    
    def __repr__(self):
        return f"<Announcement: {self.title} | Priority: {self.priority}>"


class SellerAnnouncementRead(models.Model):
    """
    Track which sellers have read which announcements.
    
    Tracks:
    - Seller-announcement read status
    - Timestamps
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='announcement_reads',
        help_text='The seller who read the announcement'
    )
    announcement = models.ForeignKey(
        Announcement,
        on_delete=models.CASCADE,
        related_name='seller_reads',
        help_text='The announcement that was read'
    )
    
    # ==================== TIMESTAMPS ====================
    read_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When announcement was read'
    )
    
    class Meta:
        db_table = 'seller_announcement_reads'
        verbose_name = 'Seller Announcement Read'
        verbose_name_plural = 'Seller Announcement Reads'
        unique_together = ('seller', 'announcement')
        indexes = [
            models.Index(fields=['seller', 'announcement']),
        ]
    
    def __str__(self):
        return f"{self.seller.email} read {self.announcement.title}"
    
    def __repr__(self):
        return f"<SellerAnnouncementRead: {self.seller.email} | {self.announcement.title}>"
