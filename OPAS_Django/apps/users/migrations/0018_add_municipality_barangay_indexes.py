# Generated migration for adding indexes on municipality and barangay fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0012_add_municipality_barangay'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['municipality'], name='users_munic_idx'),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['barangay'], name='users_baran_idx'),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['municipality', 'barangay'], name='users_munic_baran_idx'),
        ),
    ]
