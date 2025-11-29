from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0021_user_fcm_token'),
    ]

    operations = [
        migrations.AddField(
            model_name='sellerproduct',
            name='previous_status',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
    ]
