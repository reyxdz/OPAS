# Generated migration for ProductImage model

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0006_seller_models'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProductImage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', models.ImageField(help_text='Product image file', upload_to='product_images/%Y/%m/')),
                ('is_primary', models.BooleanField(default=False, help_text='Whether this is the primary product image')),
                ('order', models.PositiveIntegerField(default=0, help_text='Display order for images')),
                ('alt_text', models.CharField(blank=True, help_text='Alt text for image accessibility', max_length=255)),
                ('uploaded_at', models.DateTimeField(auto_now_add=True, help_text='Image upload timestamp')),
                ('product', models.ForeignKey(help_text='The product this image belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='product_images', to='users.sellerproduct')),
            ],
            options={
                'verbose_name': 'Product Image',
                'verbose_name_plural': 'Product Images',
                'db_table': 'seller_product_images',
                'ordering': ['order', '-uploaded_at'],
            },
        ),
        migrations.AddIndex(
            model_name='productimage',
            index=models.Index(fields=['product', 'is_primary'], name='seller_pro_product_idx1'),
        ),
        migrations.AddIndex(
            model_name='productimage',
            index=models.Index(fields=['product', 'order'], name='seller_pro_product_idx2'),
        ),
    ]
