from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0031_add_classification_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='sellerproduct',
            name='is_opas_managed',
            field=models.BooleanField(
                default=False,
                help_text='True if product is managed by OPAS Admin (CSV imports, forecasting data). Only OPAS Admin can edit these products.'
            ),
        ),
        migrations.AddIndex(
            model_name='sellerproduct',
            index=models.Index(fields=['is_opas_managed', 'is_deleted'], name='is_opas_managed_idx'),
        ),
    ]
