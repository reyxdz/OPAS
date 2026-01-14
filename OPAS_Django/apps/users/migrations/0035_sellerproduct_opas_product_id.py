from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0034_opasproduct_forecasting_opasproductsale'),
    ]

    operations = [
        migrations.AddField(
            model_name='sellerproduct',
            name='opas_product_id',
            field=models.BigIntegerField(
                blank=True,
                null=True,
                help_text='Links to OPASProduct for forecasting (only for OPAS Admin products)'
            ),
        ),
    ]
