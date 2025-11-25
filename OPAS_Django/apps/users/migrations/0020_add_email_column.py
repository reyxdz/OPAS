# Generated migration to add email column

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0019_add_farm_location'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='email',
            field=models.EmailField(max_length=254, default='', blank=True),
            preserve_default=False,
        ),
    ]
