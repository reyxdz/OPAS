"""
Forecasting models for OPAS platform.

Models:
- ProductForecast: Stores demand and price forecast results
- ForecastMetadata: Model information and statistics
- HistoricalTransactions: Aggregated transaction data for training
- ForecastAlert: Anomalies and alerts for admins
"""

from django.db import models
from django.utils import timezone
from decimal import Decimal


class ConfidenceLevel(models.TextChoices):
    """Confidence level choices for forecasts"""
    HIGH = 'HIGH', 'High'
    MEDIUM = 'MEDIUM', 'Medium'
    LOW = 'LOW', 'Low'


class ModelType(models.TextChoices):
    """Forecasting model type choices"""
    SARIMA = 'SARIMA', 'SARIMA (Seasonal ARIMA)'
    ARIMA = 'ARIMA', 'ARIMA (Non-Seasonal)'
    SIMPLE = 'SIMPLE', 'Simple (Exponential Smoothing)'
    INSUFFICIENT_DATA = 'INSUFFICIENT_DATA', 'Insufficient Data'


class AlertType(models.TextChoices):
    """Forecast alert type choices"""
    DECLINING_DEMAND = 'DECLINING_DEMAND', 'Declining Demand'
    PRICE_SPIKE = 'PRICE_SPIKE', 'Price Spike'
    LOW_CONFIDENCE = 'LOW_CONFIDENCE', 'Low Confidence Forecast'
    ANOMALY = 'ANOMALY', 'Data Anomaly'
    MODEL_FAILURE = 'MODEL_FAILURE', 'Model Training Failure'


class AlertSeverity(models.TextChoices):
    """Alert severity levels"""
    INFO = 'INFO', 'Info'
    WARNING = 'WARNING', 'Warning'
    CRITICAL = 'CRITICAL', 'Critical'


class ProductForecast(models.Model):
    """
    Stores demand and price forecast results for products.

    Each forecast contains predictions for a specific period (week/month)
    with confidence intervals and model metadata.
    
    Can be used for:
    1. SellerProduct (farmer products) - linked via product FK
    2. MarketHistoricalData (CSV products) - stored as product_name string
    """

    # ==================== RELATIONSHIPS ====================
    product = models.ForeignKey(
        'users.SellerProduct',
        on_delete=models.CASCADE,
        related_name='admin_forecasts',
        null=True,
        blank=True,
        help_text='The product being forecasted (farmer product)'
    )
    
    # ==================== PRODUCT REFERENCE ====================
    product_name = models.CharField(
        max_length=255,
        blank=True,
        default='',
        help_text='Product name (for CSV/market data forecasts)'
    )
    
    # ==================== FORECAST METADATA ====================
    forecast_date = models.DateTimeField(
        default=timezone.now,
        help_text='When this forecast was generated'
    )
    forecast_period = models.CharField(
        max_length=20,
        help_text='Period being forecasted (e.g., "2025-01", "Week 1 2025")'
    )
    is_current = models.BooleanField(
        default=True,
        help_text='Is this the latest forecast for this product?',
        db_index=True
    )
    
    # ==================== DEMAND FORECAST ====================
    demand_forecast_kg = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='Predicted demand in kilograms'
    )
    demand_lower_bound = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='Lower bound of 95% confidence interval for demand'
    )
    demand_upper_bound = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='Upper bound of 95% confidence interval for demand'
    )
    
    # ==================== PRICE FORECAST ====================
    price_forecast = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Predicted price per kilogram'
    )
    price_lower_bound = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Lower bound of 95% confidence interval for price'
    )
    price_upper_bound = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Upper bound of 95% confidence interval for price'
    )
    
    # ==================== MODEL INFORMATION ====================
    model_type = models.CharField(
        max_length=20,
        choices=ModelType.choices,
        default=ModelType.INSUFFICIENT_DATA,
        help_text='Type of forecasting model used'
    )
    confidence_level = models.CharField(
        max_length=10,
        choices=ConfidenceLevel.choices,
        default=ConfidenceLevel.LOW,
        help_text='Confidence level of forecast based on data quality'
    )
    
    # ==================== MODEL PERFORMANCE METRICS ====================
    rmse_demand = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True,
        help_text='Root Mean Square Error for demand model'
    )
    rmse_price = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True,
        help_text='Root Mean Square Error for price model'
    )
    mape_demand = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        help_text='Mean Absolute Percentage Error for demand (percentage)'
    )
    mape_price = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        help_text='Mean Absolute Percentage Error for price (percentage)'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'forecasting_product_forecast'
        verbose_name = 'Product Forecast'
        verbose_name_plural = 'Product Forecasts'
        ordering = ['-forecast_date']
        indexes = [
            models.Index(fields=['product', '-forecast_date']),
            models.Index(fields=['product', 'is_current']),
            models.Index(fields=['model_type']),
            models.Index(fields=['confidence_level']),
        ]
        constraints = [
            # Only one current forecast per product
            models.UniqueConstraint(
                fields=['product', 'forecast_period'],
                condition=models.Q(is_current=True),
                name='unique_current_forecast_per_product_period'
            ),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.forecast_period} ({self.model_type})"
    
    def __repr__(self):
        return f"<ProductForecast: {self.product.id} | {self.forecast_period} | {self.model_type}>"


class ForecastMetadata(models.Model):
    """
    Stores model information and training statistics for each product.
    
    Used to determine model reliability and display data coverage info
    to admins in the dashboard.
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.OneToOneField(
        'users.SellerProduct',
        on_delete=models.CASCADE,
        related_name='forecast_metadata',
        help_text='The product this metadata belongs to'
    )
    
    # ==================== MODEL INFORMATION ====================
    model_type = models.CharField(
        max_length=20,
        choices=ModelType.choices,
        default=ModelType.INSUFFICIENT_DATA,
        help_text='Type of forecasting model selected for this product'
    )
    data_points_count = models.IntegerField(
        default=0,
        help_text='Number of historical data points available'
    )
    data_coverage_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text='Percentage of expected time periods with data (0-100)'
    )
    is_reliable = models.BooleanField(
        default=False,
        help_text='Whether forecast is reliable (enough data quality)',
        db_index=True
    )
    
    # ==================== MODEL PARAMETERS ====================
    model_parameters = models.JSONField(
        default=dict,
        blank=True,
        help_text='Stores SARIMA/ARIMA parameters: {order: (p,d,q), seasonal_order: (P,D,Q,m)}'
    )
    
    # ==================== TRAINING TIMESTAMPS ====================
    last_training_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the model was last trained'
    )
    last_successful_forecast_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When forecast was last successfully generated'
    )
    
    # ==================== VALIDATION METRICS (NEW) ====================
    # These metrics are calculated during model validation on test set
    validation_mape_demand = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        null=True,
        blank=True,
        help_text='MAPE (%) for demand model validation - how accurate is the model'
    )
    validation_mape_price = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        null=True,
        blank=True,
        help_text='MAPE (%) for price model validation'
    )
    validation_rmse_demand = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True,
        help_text='RMSE for demand model validation'
    )
    validation_rmse_price = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True,
        help_text='RMSE for price model validation'
    )
    validation_mae_demand = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True,
        help_text='MAE for demand model validation'
    )
    validation_mae_price = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True,
        help_text='MAE for price model validation'
    )
    validation_sample_size = models.IntegerField(
        null=True,
        blank=True,
        help_text='Number of test samples used for validation'
    )
    validation_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When validation metrics were last calculated'
    )
    
    # ==================== MODEL COMPARISON (NEW) ====================
    # Store results of comparing all 3 models during validation
    model_comparison_results = models.JSONField(
        default=dict,
        blank=True,
        help_text='Results from comparing SARIMA vs ARIMA vs SIMPLE models'
    )
    
    # ==================== NOTES & WARNINGS ====================
    notes = models.TextField(
        blank=True,
        help_text='Additional notes about model limitations or issues'
    )
    
    # ==================== TIMESTAMPS ====================
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'forecasting_forecast_metadata'
        verbose_name = 'Forecast Metadata'
        verbose_name_plural = 'Forecast Metadata'
        indexes = [
            models.Index(fields=['model_type', 'is_reliable']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.model_type} ({self.data_points_count} points)"
    
    def __repr__(self):
        return f"<ForecastMetadata: {self.product.id} | {self.model_type}>"


class MarketHistoricalData(models.Model):
    """
    External market reference data for benchmarking and trend analysis.
    
    This model stores historical market data imported from CSV or other
    external sources (e.g., agricultural bureau, market reports). It is
    NOT tied to actual SellerProduct sales, but rather serves as market
    context for trend analysis and product opportunity identification.
    
    Example: If market data shows Papaya trending but no farmer sells it,
    admins can see this as an opportunity to suggest to farmers.
    """
    
    # ==================== PRODUCT REFERENCE ====================
    product_name = models.CharField(
        max_length=255,
        help_text='Name of the product (not necessarily in SellerProduct table)'
    )
    category_name = models.CharField(
        max_length=255,
        blank=True,
        help_text='Product category from external source'
    )
    
    # ==================== MARKET DATA ====================
    market_date = models.DateField(
        help_text='Date of the market data'
    )
    quantity_kg = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text='Quantity traded in the market for this period'
    )
    price_per_kg = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text='Average market price per kilogram'
    )
    total_value = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        help_text='Total market value (quantity × price)'
    )
    
    # ==================== SOURCE INFORMATION ====================
    source = models.CharField(
        max_length=255,
        default='CSV Import',
        help_text='Source of this data (e.g., "CSV Import", "Market Bureau", "Agricultural Bureau")'
    )
    
    # ==================== DATA QUALITY ====================
    data_quality_score = models.IntegerField(
        default=100,
        help_text='Quality score 0-100 (100 = complete/verified data)'
    )
    notes = models.TextField(
        blank=True,
        help_text='Additional notes about this market data entry'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'forecasting_market_historical_data'
        verbose_name = 'Market Historical Data'
        verbose_name_plural = 'Market Historical Data'
        ordering = ['product_name', 'market_date']
        indexes = [
            models.Index(fields=['product_name', 'market_date']),
            models.Index(fields=['market_date']),
            models.Index(fields=['source']),
        ]
        constraints = [
            # Prevent duplicate entries for same product, date, and source
            models.UniqueConstraint(
                fields=['product_name', 'market_date', 'source'],
                name='unique_market_product_date_source'
            ),
        ]
    
    def calculate_total_value(self):
        """Calculate and update total value"""
        self.total_value = self.quantity_kg * self.price_per_kg
        return self.total_value
    
    def save(self, *args, **kwargs):
        """Auto-calculate total value before saving"""
        self.calculate_total_value()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.product_name} - {self.market_date} ({self.quantity_kg}kg @ P{self.price_per_kg}/kg)"
    
    def __repr__(self):
        return f"<MarketHistoricalData: {self.product_name} | {self.market_date}>"


class HistoricalTransactions(models.Model):
    """
    Aggregated transaction data used for training forecasting models.
    
    This model stores weekly/monthly aggregates of orders to SellerProduct,
    including quantity sold and average prices. Used as the source of truth
    for building historical time series data for actual products being sold.
    
    IMPORTANT: This is for DYNAMIC data only (real SellerProduct sales).
    External market reference data goes in MarketHistoricalData instead.
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.ForeignKey(
        'users.SellerProduct',
        on_delete=models.CASCADE,
        related_name='historical_transactions',
        help_text='The product these transactions relate to'
    )
    
    # ==================== TRANSACTION DATA ====================
    transaction_date = models.DateField(
        help_text='Date of the transaction/aggregation period'
    )
    quantity_sold_kg = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text='Total quantity sold in this period'
    )
    average_price_per_kg = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text='Average selling price per kilogram in this period'
    )
    total_revenue = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        help_text='Total revenue (quantity × average price)'
    )
    transaction_count = models.IntegerField(
        default=0,
        help_text='Number of individual transactions in this period'
    )
    
    # ==================== DATA QUALITY ====================
    data_quality_score = models.IntegerField(
        default=100,
        help_text='Quality score 0-100 (100 = complete data, 0 = missing/suspect data)'
    )
    is_complete = models.BooleanField(
        default=True,
        help_text='Whether this period has complete data'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'forecasting_historical_transactions'
        verbose_name = 'Historical Transaction'
        verbose_name_plural = 'Historical Transactions'
        ordering = ['product', 'transaction_date']
        indexes = [
            models.Index(fields=['product', 'transaction_date']),
            models.Index(fields=['product', '-transaction_date']),
            models.Index(fields=['transaction_date']),
        ]
        constraints = [
            # Prevent duplicate entries for same product and date
            models.UniqueConstraint(
                fields=['product', 'transaction_date'],
                name='unique_product_transaction_date'
            ),
        ]
    
    def calculate_revenue(self):
        """Calculate and update total revenue"""
        self.total_revenue = self.quantity_sold_kg * self.average_price_per_kg
        return self.total_revenue
    
    def save(self, *args, **kwargs):
        """Auto-calculate revenue before saving"""
        self.calculate_revenue()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.product.name} - {self.transaction_date} ({self.quantity_sold_kg}kg)"
    
    def __repr__(self):
        return f"<HistoricalTransactions: {self.product.id} | {self.transaction_date}>"


class ForecastAlert(models.Model):
    """
    Tracks anomalies and alerts related to forecasts.
    
    Created when:
    - Demand shows declining trend
    - Price spikes are detected
    - Forecast confidence drops below threshold
    - Model training fails
    
    Admins can acknowledge alerts and take action.
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.ForeignKey(
        'users.SellerProduct',
        on_delete=models.CASCADE,
        related_name='forecast_alerts',
        help_text='The product this alert relates to'
    )
    
    # ==================== ALERT INFORMATION ====================
    alert_type = models.CharField(
        max_length=30,
        choices=AlertType.choices,
        help_text='Type of alert'
    )
    severity = models.CharField(
        max_length=10,
        choices=AlertSeverity.choices,
        default=AlertSeverity.WARNING,
        help_text='Alert severity level'
    )
    message = models.TextField(
        help_text='Detailed description of the alert'
    )
    
    # ==================== ADDITIONAL DATA ====================
    related_forecast = models.ForeignKey(
        ProductForecast,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='alerts',
        help_text='Related forecast that triggered this alert'
    )
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text='Additional structured data about the alert'
    )
    
    # ==================== ACKNOWLEDGMENT ====================
    is_acknowledged = models.BooleanField(
        default=False,
        db_index=True,
        help_text='Whether admin has acknowledged this alert'
    )
    acknowledged_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='acknowledged_forecast_alerts',
        help_text='Admin who acknowledged this alert'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(auto_now_add=True)
    acknowledged_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the alert was acknowledged'
    )
    resolved_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the alert was resolved'
    )
    
    class Meta:
        db_table = 'forecasting_forecast_alert'
        verbose_name = 'Forecast Alert'
        verbose_name_plural = 'Forecast Alerts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', '-created_at']),
            models.Index(fields=['alert_type', 'is_acknowledged']),
            models.Index(fields=['severity', '-created_at']),
        ]
    
    def acknowledge(self, user=None):
        """Mark alert as acknowledged by admin"""
        self.is_acknowledged = True
        self.acknowledged_by = user
        self.acknowledged_at = timezone.now()
        self.save()
    
    def resolve(self):
        """Mark alert as resolved"""
        self.resolved_at = timezone.now()
        self.save()
    
    def __str__(self):
        return f"{self.product.name} - {self.alert_type} ({self.severity})"
    
    def __repr__(self):
        return f"<ForecastAlert: {self.product.id} | {self.alert_type}>"
