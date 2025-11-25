# Generated migration for adding municipality and barangay fields to User model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0017_alter_user_admin_role'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='municipality',
            field=models.CharField(
                blank=True,
                max_length=50,
                null=True,
                help_text='Municipality of the user (Biliran)'
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='barangay',
            field=models.CharField(
                blank=True,
                max_length=100,
                null=True,
                help_text='Barangay of the user within the selected municipality'
            ),
        ),
        migrations.AlterField(
            model_name='user',
            name='address',
            field=models.TextField(
                blank=True,
                null=True,
                help_text='Full address combining barangay, municipality, and province'
            ),
        ),
    ]
