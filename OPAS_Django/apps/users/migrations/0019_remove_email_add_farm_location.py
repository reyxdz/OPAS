# Generated migration for removing email and adding farm location fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0018_add_municipality_barangay_indexes'),
    ]

    operations = [
        # Remove email field - make phone_number unique instead
        migrations.RemoveField(
            model_name='user',
            name='email',
        ),
        # Update phone_number to be unique and not blank
        migrations.AlterField(
            model_name='user',
            name='phone_number',
            field=models.CharField(
                max_length=15,
                unique=True,
                help_text='Phone number used for authentication'
            ),
        ),
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

