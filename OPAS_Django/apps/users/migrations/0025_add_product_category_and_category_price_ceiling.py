from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0024_alter_sellerproduct_previous_status'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProductCategory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('slug', models.SlugField(max_length=120, unique=True, help_text='Canonical slug (e.g., TOMATO)')),
                ('name', models.CharField(max_length=255, help_text='Human-friendly name')),
                ('description', models.TextField(blank=True, null=True)),
                ('active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('parent', models.ForeignKey(blank=True, null=True, on_delete=models.SET_NULL, related_name='children', to='users.productcategory')),
            ],
            options={
                'db_table': 'product_categories',
                'verbose_name': 'Product Category',
                'verbose_name_plural': 'Product Categories',
            },
        ),
        migrations.CreateModel(
            name='CategoryPriceCeiling',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('ceiling_price', models.DecimalField(decimal_places=2, max_digits=10)),
                ('active', models.BooleanField(default=True)),
                ('start_date', models.DateTimeField(blank=True, null=True)),
                ('end_date', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('category', models.ForeignKey(on_delete=models.CASCADE, related_name='category_price_ceilings', to='users.productcategory')),
            ],
            options={
                'db_table': 'category_price_ceilings',
                'verbose_name': 'Category Price Ceiling',
                'verbose_name_plural': 'Category Price Ceilings',
            },
        ),
        migrations.AddField(
            model_name='sellerproduct',
            name='category',
            field=models.ForeignKey(blank=True, null=True, on_delete=models.SET_NULL, related_name='products', to='users.productcategory'),
        ),
        migrations.AlterIndexTogether(
            name='categorypriceceiling',
            index_together={('category', 'active')},
        ),
    ]
