# Generated migration for seller models

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_sellerapplication_and_more'),
    ]

    operations = [
        # ==================== SellerProduct ====================
        migrations.CreateModel(
            name='SellerProduct',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(help_text='Product name', max_length=255)),
                ('description', models.TextField(blank=True, help_text='Product description', null=True)),
                ('product_type', models.CharField(help_text='Category or type of product (e.g., vegetables, fruits)', max_length=100)),
                ('price', models.DecimalField(decimal_places=2, help_text='Selling price per unit', max_digits=10)),
                ('ceiling_price', models.DecimalField(blank=True, decimal_places=2, help_text='Maximum allowed price set by OPAS', max_digits=10, null=True)),
                ('unit', models.CharField(default='kg', help_text='Unit of measurement (kg, lbs, piece, etc.)', max_length=50)),
                ('stock_level', models.IntegerField(default=0, help_text='Current stock quantity')),
                ('minimum_stock', models.IntegerField(default=0, help_text='Minimum stock level before alert')),
                ('quality_grade', models.CharField(choices=[('PREMIUM', 'Premium'), ('STANDARD', 'Standard'), ('BASIC', 'Basic')], default='STANDARD', help_text='Quality grade of the product', max_length=20)),
                ('image_url', models.URLField(blank=True, help_text='Primary product image URL', null=True)),
                ('images', models.JSONField(blank=True, default=list, help_text='List of product image URLs')),
                ('status', models.CharField(choices=[('ACTIVE', 'Active'), ('INACTIVE', 'Inactive'), ('EXPIRED', 'Expired'), ('PENDING', 'Pending Approval'), ('REJECTED', 'Rejected')], default='PENDING', help_text='Current product listing status', max_length=20)),
                ('listed_date', models.DateTimeField(auto_now_add=True, help_text='When the product was listed')),
                ('expiry_date', models.DateTimeField(blank=True, help_text='When the product listing expires', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Product creation timestamp')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Last update timestamp')),
                ('seller', models.ForeignKey(help_text='The seller who listed this product', on_delete=django.db.models.deletion.CASCADE, related_name='products', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Seller Product',
                'verbose_name_plural': 'Seller Products',
                'db_table': 'seller_products',
                'ordering': ['-created_at'],
            },
        ),
        
        # ==================== SellerOrder ====================
        migrations.CreateModel(
            name='SellerOrder',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('order_number', models.CharField(help_text='Unique order number', max_length=50, unique=True)),
                ('quantity', models.IntegerField(help_text='Quantity ordered')),
                ('price_per_unit', models.DecimalField(decimal_places=2, help_text='Price per unit at time of order', max_digits=10)),
                ('total_amount', models.DecimalField(decimal_places=2, help_text='Total order amount', max_digits=10)),
                ('status', models.CharField(choices=[('PENDING', 'Pending'), ('ACCEPTED', 'Accepted'), ('REJECTED', 'Rejected'), ('FULFILLED', 'Fulfilled'), ('DELIVERED', 'Delivered'), ('CANCELLED', 'Cancelled')], default='PENDING', help_text='Current order status', max_length=20)),
                ('rejection_reason', models.TextField(blank=True, help_text='Reason for order rejection (if rejected)', null=True)),
                ('delivery_location', models.TextField(blank=True, help_text='Delivery address', null=True)),
                ('delivery_date', models.DateTimeField(blank=True, help_text='Expected delivery date', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Order creation timestamp')),
                ('accepted_at', models.DateTimeField(blank=True, help_text='When order was accepted by seller', null=True)),
                ('fulfilled_at', models.DateTimeField(blank=True, help_text='When order was fulfilled/shipped', null=True)),
                ('delivered_at', models.DateTimeField(blank=True, help_text='When order was delivered', null=True)),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Last update timestamp')),
                ('buyer', models.ForeignKey(blank=True, help_text='The buyer who placed this order', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='buyer_orders', to=settings.AUTH_USER_MODEL)),
                ('product', models.ForeignKey(blank=True, help_text='The product being ordered', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='orders', to='users.sellerproduct')),
                ('seller', models.ForeignKey(help_text='The seller fulfilling this order', on_delete=django.db.models.deletion.CASCADE, related_name='seller_orders', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Seller Order',
                'verbose_name_plural': 'Seller Orders',
                'db_table': 'seller_orders',
                'ordering': ['-created_at'],
            },
        ),
        
        # ==================== SellToOPAS ====================
        migrations.CreateModel(
            name='SellToOPAS',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('submission_number', models.CharField(help_text='Unique submission number', max_length=50, unique=True)),
                ('quantity_offered', models.IntegerField(help_text='Total quantity offered to OPAS')),
                ('unit', models.CharField(default='kg', help_text='Unit of measurement', max_length=50)),
                ('offered_price', models.DecimalField(decimal_places=2, help_text='Price per unit offered by seller', max_digits=10)),
                ('approved_price', models.DecimalField(blank=True, decimal_places=2, help_text='Price approved by OPAS', max_digits=10, null=True)),
                ('quality_grade', models.CharField(choices=[('PREMIUM', 'Premium'), ('STANDARD', 'Standard'), ('BASIC', 'Basic')], default='STANDARD', help_text='Quality grade of the product', max_length=20)),
                ('status', models.CharField(choices=[('PENDING', 'Pending Review'), ('ACCEPTED', 'Accepted'), ('REJECTED', 'Rejected'), ('COMPLETED', 'Completed')], default='PENDING', help_text='Submission status', max_length=20)),
                ('rejection_reason', models.TextField(blank=True, help_text='Reason for rejection (if rejected)', null=True)),
                ('delivery_date', models.DateTimeField(blank=True, help_text='Expected delivery date', null=True)),
                ('pickup_location', models.TextField(blank=True, help_text='Location for OPAS to pick up product', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Submission creation timestamp')),
                ('accepted_at', models.DateTimeField(blank=True, help_text='When submission was accepted', null=True)),
                ('completed_at', models.DateTimeField(blank=True, help_text='When submission was completed', null=True)),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Last update timestamp')),
                ('product', models.ForeignKey(blank=True, help_text='The product being submitted', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='opas_submissions', to='users.sellerproduct')),
                ('seller', models.ForeignKey(help_text='The seller making the submission', on_delete=django.db.models.deletion.CASCADE, related_name='opas_submissions', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Sell to OPAS Submission',
                'verbose_name_plural': 'Sell to OPAS Submissions',
                'db_table': 'seller_sell_to_opas',
                'ordering': ['-created_at'],
            },
        ),
        
        # ==================== SellerPayout ====================
        migrations.CreateModel(
            name='SellerPayout',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('period_start', models.DateField(help_text='Start date of payout period')),
                ('period_end', models.DateField(help_text='End date of payout period')),
                ('total_earnings', models.DecimalField(decimal_places=2, help_text='Total earnings in this period', max_digits=12)),
                ('transaction_fees', models.DecimalField(decimal_places=2, default=0, help_text='Platform transaction fees', max_digits=12)),
                ('service_fee_percent', models.DecimalField(decimal_places=2, default=5.0, help_text='Service fee percentage', max_digits=5)),
                ('service_fee_amount', models.DecimalField(decimal_places=2, default=0, help_text='Calculated service fee', max_digits=12)),
                ('other_deductions', models.DecimalField(decimal_places=2, default=0, help_text='Other deductions', max_digits=12)),
                ('net_earnings', models.DecimalField(decimal_places=2, help_text='Net earnings after deductions', max_digits=12)),
                ('status', models.CharField(choices=[('PENDING', 'Pending'), ('PROCESSING', 'Processing'), ('COMPLETED', 'Completed'), ('FAILED', 'Failed')], default='PENDING', help_text='Payout status', max_length=20)),
                ('payment_method', models.CharField(choices=[('BANK_TRANSFER', 'Bank Transfer'), ('WALLET', 'Wallet'), ('CHECK', 'Check')], default='BANK_TRANSFER', help_text='Payment method used', max_length=50)),
                ('bank_account', models.CharField(blank=True, help_text='Bank account number (masked)', max_length=50, null=True)),
                ('transaction_id', models.CharField(blank=True, help_text='Transaction ID from payment processor', max_length=100, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Payout record creation timestamp')),
                ('processed_at', models.DateTimeField(blank=True, help_text='When payout was processed', null=True)),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Last update timestamp')),
                ('seller', models.ForeignKey(help_text='The seller receiving payout', on_delete=django.db.models.deletion.CASCADE, related_name='payouts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Seller Payout',
                'verbose_name_plural': 'Seller Payouts',
                'db_table': 'seller_payouts',
                'ordering': ['-period_end'],
                'unique_together': {('seller', 'period_start', 'period_end')},
            },
        ),
        
        # ==================== SellerForecast ====================
        migrations.CreateModel(
            name='SellerForecast',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('forecast_date', models.DateField(help_text='Date forecast was generated')),
                ('forecast_start', models.DateField(help_text='Start date of forecast period')),
                ('forecast_end', models.DateField(help_text='End date of forecast period')),
                ('forecasted_demand', models.IntegerField(help_text='Forecasted demand quantity')),
                ('actual_demand', models.IntegerField(blank=True, help_text='Actual demand (if period has passed)', null=True)),
                ('confidence_score', models.DecimalField(decimal_places=2, default=0, help_text='Forecast confidence (0-100%)', max_digits=5)),
                ('accuracy', models.DecimalField(blank=True, decimal_places=2, help_text='Forecast accuracy (0-100%)', max_digits=5, null=True)),
                ('surplus_probability', models.DecimalField(decimal_places=2, default=0, help_text='Probability of surplus (0-100%)', max_digits=5)),
                ('stockout_probability', models.DecimalField(decimal_places=2, default=0, help_text='Probability of stockout (0-100%)', max_digits=5)),
                ('recommended_stock', models.IntegerField(blank=True, help_text='Recommended stock level', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Forecast creation timestamp')),
                ('updated_at', models.DateTimeField(auto_now=True, help_text='Last update timestamp')),
                ('product', models.ForeignKey(blank=True, help_text='The product being forecasted', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='forecasts', to='users.sellerproduct')),
                ('seller', models.ForeignKey(help_text='The seller for whom forecast is made', on_delete=django.db.models.deletion.CASCADE, related_name='forecasts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Seller Forecast',
                'verbose_name_plural': 'Seller Forecasts',
                'db_table': 'seller_forecasts',
                'ordering': ['-forecast_date'],
            },
        ),
        
        # ==================== DATABASE INDEXES ====================
        migrations.AddIndex(
            model_name='sellerproduct',
            index=models.Index(fields=['seller', 'status'], name='seller_pro_seller_status_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerproduct',
            index=models.Index(fields=['product_type'], name='seller_pro_product_type_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerproduct',
            index=models.Index(fields=['expiry_date'], name='seller_pro_expiry_date_idx'),
        ),
        
        migrations.AddIndex(
            model_name='sellerorder',
            index=models.Index(fields=['seller', 'status'], name='seller_ord_seller_status_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerorder',
            index=models.Index(fields=['buyer', 'status'], name='seller_ord_buyer_status_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerorder',
            index=models.Index(fields=['order_number'], name='seller_ord_order_number_idx'),
        ),
        
        migrations.AddIndex(
            model_name='selltoopas',
            index=models.Index(fields=['seller', 'status'], name='seller_sell_seller_status_idx'),
        ),
        migrations.AddIndex(
            model_name='selltoopas',
            index=models.Index(fields=['submission_number'], name='seller_sell_submission_number_idx'),
        ),
        
        migrations.AddIndex(
            model_name='sellerpayout',
            index=models.Index(fields=['seller', 'status'], name='seller_pay_seller_status_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerpayout',
            index=models.Index(fields=['period_end'], name='seller_pay_period_end_idx'),
        ),
        
        migrations.AddIndex(
            model_name='sellerforecast',
            index=models.Index(fields=['seller', 'forecast_date'], name='seller_for_seller_forecast_date_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerforecast',
            index=models.Index(fields=['product', 'forecast_date'], name='seller_for_product_forecast_date_idx'),
        ),
    ]
