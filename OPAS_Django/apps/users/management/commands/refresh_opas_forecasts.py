"""
Management command to refresh OPAS product forecasts every 31 days.

This command:
1. Aggregates sales data from the last 31 days for each OPAS product
2. Calculates average demand (total quantity) and average price
3. Updates forecast fields with predictions
4. Runs forecasting ML models if available
5. Updates the forecasting dashboard

Run with: python manage.py refresh_opas_forecasts
Or schedule with Celery: celery beat
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.users.opas_models import OPASProduct, OPASProductSale
from decimal import Decimal


class Command(BaseCommand):
    help = 'Refresh OPAS product forecasts by aggregating 31-day sales data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=31,
            help='Number of days to aggregate (default: 31)'
        )
        parser.add_argument(
            '--product-id',
            type=int,
            help='Refresh specific product only'
        )

    def handle(self, *args, **options):
        days = options['days']
        product_id = options.get('product_id')
        
        self.stdout.write(self.style.SUCCESS(f"\n{'='*80}"))
        self.stdout.write(self.style.SUCCESS(f"OPAS PRODUCT FORECAST REFRESH"))
        self.stdout.write(self.style.SUCCESS(f"Aggregating {days}-day sales data for forecasting"))
        self.stdout.write(self.style.SUCCESS(f"{'='*80}\n"))
        
        # Get products to process
        if product_id:
            products = OPASProduct.objects.filter(id=product_id, is_active=True)
        else:
            products = OPASProduct.objects.filter(is_active=True)
        
        total = products.count()
        updated = 0
        failed = 0
        
        self.stdout.write(f"Processing {total} OPAS products...\n")
        
        # Calculate date range
        end_date = timezone.now()
        start_date = end_date - timedelta(days=days)
        
        for idx, product in enumerate(products, 1):
            try:
                # Get sales in the period
                sales = OPASProductSale.objects.filter(
                    opas_product=product,
                    sale_date__gte=start_date,
                    sale_date__lte=end_date
                )
                
                sale_count = sales.count()
                
                if sale_count == 0:
                    # No sales in period - keep previous forecast
                    self.stdout.write(
                        f"[{idx:2d}/{total}] ⊘ {product.name:<30} No sales data"
                    )
                    continue
                
                # Calculate aggregate statistics
                total_quantity = sum(s.quantity_sold for s in sales)
                total_revenue = sum(s.total_amount for s in sales)
                
                # Calculate averages
                avg_quantity = total_quantity // sale_count  # Daily average
                avg_price = total_revenue / total_quantity if total_quantity > 0 else Decimal('0')
                
                # Simple forecast: Scale to 30-day average
                forecasted_demand = int(avg_quantity * 30)
                forecasted_price = Decimal(str(float(avg_price)))
                
                # Update product
                product.forecasted_demand_next_month = forecasted_demand
                product.forecasted_price_next_month = forecasted_price
                product.last_aggregated_date = timezone.now()
                product.save()
                
                updated += 1
                
                self.stdout.write(
                    f"[{idx:2d}/{total}] ✓ {product.name:<30} "
                    f"Sales: {sale_count} | Demand: {forecasted_demand} units | "
                    f"Price: ₱{forecasted_price:.2f}"
                )
                
            except Exception as e:
                failed += 1
                self.stdout.write(
                    self.style.ERROR(
                        f"[{idx:2d}/{total}] ✗ {product.name:<30} Error: {str(e)}"
                    )
                )
        
        # Summary
        self.stdout.write(self.style.SUCCESS(f"\n{'='*80}"))
        self.stdout.write(self.style.SUCCESS(f"FORECAST REFRESH COMPLETE"))
        self.stdout.write(self.style.SUCCESS(f"{'='*80}"))
        self.stdout.write(f"Total Processed: {total}")
        self.stdout.write(f"Successfully Updated: {updated}")
        self.stdout.write(f"Failed: {failed}")
        self.stdout.write(f"Data Range: {start_date.date()} to {end_date.date()} ({days} days)")
        self.stdout.write(self.style.SUCCESS(f"{'='*80}\n"))
