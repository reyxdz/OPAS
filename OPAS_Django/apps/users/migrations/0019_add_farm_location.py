# Generated migration for adding farm location fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0018_add_municipality_barangay_indexes'),
    ]

    operations = [
        # Add farm location fields for sellers
        migrations.AddField(
            model_name='user',
            name='farm_municipality',
            field=models.CharField(
                blank=True,
                max_length=50,
                null=True,
                help_text='Municipality where the farm is located (Biliran)'
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='farm_barangay',
            field=models.CharField(
                blank=True,
                max_length=100,
                null=True,
                help_text='Barangay where the farm is located within the selected municipality'
            ),
        ),
        # Add indexes for new farm location fields
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['farm_municipality'], name='users_farm_munic_idx'),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['farm_barangay'], name='users_farm_baran_idx'),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['farm_municipality', 'farm_barangay'], name='users_farm_munic_baran_idx'),
        ),
    ]

