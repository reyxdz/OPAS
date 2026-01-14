from django.db import models
from django.utils import timezone


class OPASProduct(models.Model):
    """
    Products imported from CSV for OPAS demand forecasting.
    
    These products are owned and managed exclusively by OPAS Admin for:
    - Demand forecasting using historical CSV data
    - ML model training with reliable historical patterns
    - Autonomous product grouping by category/type/subtype
    
    Different from SellerProduct:
    - SellerProduct: Posted by individual sellers to marketplace
    - OPASProduct: System-level products for forecasting only (not for sale)
    """
    
    # ==================== IDENTITY ====================
    name = models.CharField(
        max_length=255,
        unique=True,
        help_text='Unique product name from CSV'
    )
    
    # ==================== FORECASTING CLASSIFICATION ====================
    # Hierarchical classification for demand forecasting
    category_forecast = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Category (VEGETABLE, FRUIT, LIVESTOCK, POULTRY, SEEDS, FERTILIZERS, FEEDS, MEDICINES)'
    )
    product_type = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Type in English (e.g., Banana, Tomato, Chicken)'
    )
    product_subtype = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Subtype in original language (e.g., Lakatan, Fresh, Lechonon)'
    )
    
    # ==================== FORECASTING DATA ====================
    forecast_group_key = models.CharField(
        max_length=300,
        blank=True,
        help_text='Composite key: category:type:subtype for grouping with similar products'
    )
    
    # ==================== FORECASTING RESULTS ====================
    forecasted_demand_next_month = models.IntegerField(
        blank=True,
        null=True,
        help_text='Predicted demand quantity for next 30 days'
    )
    forecasted_price_next_month = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Predicted average price for next 30 days'
    )
    last_aggregated_date = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When sales data was last aggregated for forecasting'
    )
    
    # ==================== STATUS ====================
    is_active = models.BooleanField(
        default=True,
        help_text='Active for forecasting'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    imported_from_csv = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When product was imported from CSV'
    )
    
    class Meta:
        db_table = 'opas_products'
        verbose_name = 'OPAS Product'
        verbose_name_plural = 'OPAS Products'
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['category_forecast', 'product_type', 'product_subtype']),
            models.Index(fields=['forecast_group_key']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.product_type}/{self.product_subtype})"
    
    def get_forecast_group_key(self):
        """Return composite key for product grouping"""
        if self.category_forecast and self.product_type and self.product_subtype:
            return f"{self.category_forecast}:{self.product_type}:{self.product_subtype}"
        return ""
    
    def save(self, *args, **kwargs):
        """Auto-generate forecast group key on save"""
        self.forecast_group_key = self.get_forecast_group_key()
        super().save(*args, **kwargs)


class OPASProductSale(models.Model):
    """
    Records each sale of an OPAS product for demand forecasting.
    
    Links:
    - OPASProduct: The product being sold (for forecasting)
    - SellerProduct: The actual marketplace product (if buyer purchased from OPAS posting)
    - Buyer purchase data through SellerOrder
    
    Data collected:
    - Quantity sold
    - Price per unit
    - Sale date/time
    
    Used for:
    - 31-day aggregation
    - Demand and price forecasting
    - Trend analysis
    """
    
    # ==================== RELATIONSHIPS ====================
    opas_product = models.ForeignKey(
        'OPASProduct',
        on_delete=models.CASCADE,
        related_name='sales',
        help_text='The OPAS product being sold'
    )
    seller_product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='opas_sales',
        help_text='The marketplace product (if purchased from OPAS posting)'
    )
    
    # ==================== SALES DATA ====================
    quantity_sold = models.IntegerField(
        help_text='Quantity sold in this transaction'
    )
    price_per_unit = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Price per unit at time of sale'
    )
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        blank=True,
        help_text='Total sale amount (auto-calculated)'
    )
    
    # ==================== TIMESTAMPS ====================
    sale_date = models.DateTimeField(
        help_text='When the sale occurred'
    )
    recorded_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When this sale record was created'
    )
    
    class Meta:
        db_table = 'opas_product_sales'
        verbose_name = 'OPAS Product Sale'
        verbose_name_plural = 'OPAS Product Sales'
        indexes = [
            models.Index(fields=['opas_product', 'sale_date']),
            models.Index(fields=['sale_date']),
        ]
    
    def save(self, *args, **kwargs):
        """Auto-calculate total amount"""
        if not self.total_amount:
            self.total_amount = self.quantity_sold * self.price_per_unit
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.opas_product.name}: {self.quantity_sold} units @ {self.price_per_unit} on {self.sale_date.date()}"
