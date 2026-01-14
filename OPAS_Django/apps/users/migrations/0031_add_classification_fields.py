# Generated migration for adding product classification fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0030_add_fulfillment_methods_to_sellerproduct'),
    ]

    operations = [
        migrations.AddField(
            model_name='sellerproduct',
            name='category_forecast',
            field=models.CharField(blank=True, default='', help_text='Product category for forecasting (e.g., VEGETABLE)', max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='sellerproduct',
            name='product_type',
            field=models.CharField(blank=True, default='', help_text='Product type (e.g., Leafy Greens)', max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='sellerproduct',
            name='product_subtype',
            field=models.CharField(blank=True, default='', help_text='Product subtype (e.g., Tomato)', max_length=100, null=True),
        ),
        migrations.AddIndex(
            model_name='sellerproduct',
            index=models.Index(fields=['category_forecast', 'product_type', 'product_subtype'], name='seller_prod_categor_idx'),
        ),
        migrations.AddIndex(
            model_name='sellerproduct',
            index=models.Index(fields=['is_deleted', 'status'], name='seller_prod_status_idx'),
        ),
    ]
