from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0033_add_opas_products'),
    ]

    operations = [
        # Add forecasting result fields to OPASProduct
        migrations.AddField(
            model_name='opasproduct',
            name='forecasted_demand_next_month',
            field=models.IntegerField(
                blank=True,
                null=True,
                help_text='Predicted demand quantity for next 30 days'
            ),
        ),
        migrations.AddField(
            model_name='opasproduct',
            name='forecasted_price_next_month',
            field=models.DecimalField(
                max_digits=10,
                decimal_places=2,
                blank=True,
                null=True,
                help_text='Predicted average price for next 30 days'
            ),
        ),
        migrations.AddField(
            model_name='opasproduct',
            name='last_aggregated_date',
            field=models.DateTimeField(
                blank=True,
                null=True,
                help_text='When sales data was last aggregated for forecasting'
            ),
        ),
        
        # Create OPASProductSale model
        migrations.CreateModel(
            name='OPASProductSale',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('quantity_sold', models.IntegerField(help_text='Quantity sold in this transaction')),
                ('price_per_unit', models.DecimalField(decimal_places=2, max_digits=10, help_text='Price per unit at time of sale')),
                ('total_amount', models.DecimalField(blank=True, decimal_places=2, max_digits=12, help_text='Total sale amount (auto-calculated)')),
                ('sale_date', models.DateTimeField(help_text='When the sale occurred')),
                ('recorded_at', models.DateTimeField(auto_now_add=True, help_text='When this sale record was created')),
                ('opas_product', models.ForeignKey(help_text='The OPAS product being sold', on_delete=django.db.models.deletion.CASCADE, related_name='sales', to='users.opasproduct')),
                ('seller_product', models.ForeignKey(blank=True, help_text='The marketplace product (if purchased from OPAS posting)', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='opas_sales', to='users.sellerproduct')),
            ],
            options={
                'verbose_name': 'OPAS Product Sale',
                'verbose_name_plural': 'OPAS Product Sales',
                'db_table': 'opas_product_sales',
            },
        ),
        
        # Add indexes
        migrations.AddIndex(
            model_name='opasproductsale',
            index=models.Index(fields=['opas_product', 'sale_date'], name='opas_prod_opas_pr_idx'),
        ),
        migrations.AddIndex(
            model_name='opasproductsale',
            index=models.Index(fields=['sale_date'], name='opas_prod_sale_date_idx'),
        ),
    ]
