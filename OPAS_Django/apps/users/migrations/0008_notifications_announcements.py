# Generated migration for Notification, Announcement, and SellerAnnouncementRead models

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0007_product_image'),
    ]

    operations = [
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('type', models.CharField(
                    choices=[
                        ('Orders', 'Order Notification'),
                        ('Payments', 'Payment Notification'),
                        ('System', 'System Alert'),
                    ],
                    default='System',
                    help_text='Notification type',
                    max_length=20
                )),
                ('title', models.CharField(help_text='Notification title', max_length=255)),
                ('message', models.TextField(help_text='Notification message')),
                ('is_read', models.BooleanField(default=False, help_text='Whether notification has been read')),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Notification creation timestamp')),
                ('read_at', models.DateTimeField(
                    blank=True,
                    help_text='When notification was read',
                    null=True
                )),
                ('seller', models.ForeignKey(
                    help_text='The seller receiving the notification',
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='notifications',
                    to=settings.AUTH_USER_MODEL
                )),
            ],
            options={
                'verbose_name': 'Seller Notification',
                'verbose_name_plural': 'Seller Notifications',
                'db_table': 'seller_notifications',
                'ordering': ['-created_at'],
            },
        ),

        # Create Announcement model
        migrations.CreateModel(
            name='Announcement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(help_text='Announcement title', max_length=255)),
                ('content', models.TextField(help_text='Announcement content')),
                ('type', models.CharField(
                    choices=[
                        ('Features', 'New Features'),
                        ('Maintenance', 'Maintenance Notice'),
                        ('Policy', 'Policy Update'),
                        ('Action Required', 'Action Required'),
                    ],
                    default='Features',
                    help_text='Announcement type',
                    max_length=20
                )),
                ('priority', models.CharField(
                    choices=[
                        ('LOW', 'Low'),
                        ('MEDIUM', 'Medium'),
                        ('HIGH', 'High'),
                    ],
                    default='MEDIUM',
                    help_text='Announcement priority',
                    max_length=10
                )),
                ('created_by', models.CharField(
                    default='Admin',
                    help_text='Who created this announcement',
                    max_length=255
                )),
                ('created_at', models.DateTimeField(
                    auto_now_add=True,
                    help_text='Announcement creation timestamp'
                )),
                ('updated_at', models.DateTimeField(
                    auto_now=True,
                    help_text='Last update timestamp'
                )),
                ('expires_at', models.DateTimeField(
                    blank=True,
                    help_text='When announcement expires',
                    null=True
                )),
            ],
            options={
                'verbose_name': 'Seller Announcement',
                'verbose_name_plural': 'Seller Announcements',
                'db_table': 'seller_announcements',
                'ordering': ['-created_at'],
            },
        ),

        # Create SellerAnnouncementRead model
        migrations.CreateModel(
            name='SellerAnnouncementRead',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('is_read', models.BooleanField(default=True, help_text='Whether seller has read the announcement')),
                ('read_at', models.DateTimeField(auto_now_add=True, help_text='When the announcement was marked as read')),
                ('announcement', models.ForeignKey(
                    help_text='The announcement',
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='seller_announcement_reads',
                    to='users.announcement'
                )),
                ('seller', models.ForeignKey(
                    help_text='Seller who read the announcement',
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='announcement_reads',
                    to=settings.AUTH_USER_MODEL
                )),
            ],
            options={
                'verbose_name': 'Seller Announcement Read',
                'verbose_name_plural': 'Seller Announcement Reads',
                'db_table': 'seller_announcement_reads',
                'unique_together': {('announcement', 'seller')},
            },
        ),

        # Add indexes for performance
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['seller', 'is_read'], name='seller_notif_seller_idx1'),
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['seller', 'created_at'], name='seller_notif_seller_idx2'),
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['type', 'created_at'], name='seller_notif_type_idx'),
        ),
        migrations.AddIndex(
            model_name='announcement',
            index=models.Index(fields=['expires_at', 'created_at'], name='seller_annc_expiry_idx'),
        ),
        migrations.AddIndex(
            model_name='announcement',
            index=models.Index(fields=['priority', 'created_at'], name='seller_annc_priority_idx'),
        ),
    ]
