"""
Signal handlers for forecasting app.

Automatically updates HistoricalTransactions when SellerOrder status changes.
"""

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from decimal import Decimal
from apps.users.models import SellerOrder, OrderStatus
from apps.forecasting.models import HistoricalTransactions
from apps.forecasting.services.data_aggregator import DataAggregator


@receiver(post_save, sender=SellerOrder)
def update_historical_transactions_on_order_fulfilled(sender, instance, created, **kwargs):
    """
    Signal handler triggered when SellerOrder is saved.
    
    If order status is FULFILLED or DELIVERED, update HistoricalTransactions
    with this transaction.
    
    Args:
        sender: SellerOrder model
        instance: SellerOrder instance that was saved
        created: Boolean indicating if this is a new instance
        **kwargs: Additional signal arguments
    """
    # Only process if order is in a completed state
    if instance.status not in [OrderStatus.FULFILLED, OrderStatus.DELIVERED]:
        return
    
    try:
        # Determine transaction date (use fulfilled_at if available, else created_at)
        transaction_date = instance.fulfilled_at or instance.created_at
        
        # Get the product
        product = instance.product
        
        # Calculate quantity and price
        quantity_kg = Decimal(str(instance.quantity))
        price_per_kg = instance.price_per_unit
        total_revenue = quantity_kg * price_per_kg
        
        # Extract just the date (without time)
        if hasattr(transaction_date, 'date'):
            transaction_date = transaction_date.date()
        
        # Create or update HistoricalTransaction
        # Using update_or_create to handle duplicate orders gracefully
        obj, created = HistoricalTransactions.objects.update_or_create(
            product=product,
            transaction_date=transaction_date,
            defaults={
                'quantity_sold_kg': quantity_kg,
                'average_price_per_kg': price_per_kg,
                'total_revenue': total_revenue,
                'data_quality_score': 100,  # Individual transactions are complete
                'is_complete': True,
            }
        )
        
    except Exception as e:
        # Log error but don't break the signal chain
        import logging
        logger = logging.getLogger(__name__)
        logger.error(
            f"Error updating HistoricalTransactions for SellerOrder {instance.id}: {str(e)}"
        )


@receiver(post_delete, sender=SellerOrder)
def cleanup_historical_transactions_on_order_delete(sender, instance, **kwargs):
    """
    Signal handler triggered when SellerOrder is deleted.
    
    Attempts to recalculate the HistoricalTransaction for that date
    by querying remaining orders. If no orders remain for that date,
    deletes the HistoricalTransaction record.
    
    Args:
        sender: SellerOrder model
        instance: SellerOrder instance that was deleted
        **kwargs: Additional signal arguments
    """
    try:
        # Determine transaction date
        transaction_date = instance.fulfilled_at or instance.created_at
        if hasattr(transaction_date, 'date'):
            transaction_date = transaction_date.date()
        
        product = instance.product
        
        # Query remaining completed orders for this product on this date
        remaining_orders = SellerOrder.objects.filter(
            product=product,
            status__in=[OrderStatus.FULFILLED, OrderStatus.DELIVERED],
            created_at__date=transaction_date
        )
        
        # If no remaining orders, delete the HistoricalTransaction
        if not remaining_orders.exists():
            HistoricalTransactions.objects.filter(
                product=product,
                transaction_date=transaction_date
            ).delete()
        else:
            # Recalculate the aggregates for this date
            total_quantity = Decimal('0')
            total_price_sum = Decimal('0')
            count = 0
            
            for order in remaining_orders:
                total_quantity += Decimal(str(order.quantity))
                total_price_sum += order.price_per_unit
                count += 1
            
            # Calculate aggregates
            avg_price = total_price_sum / count if count > 0 else Decimal('0')
            total_revenue = total_quantity * avg_price
            
            # Update the HistoricalTransaction
            HistoricalTransactions.objects.filter(
                product=product,
                transaction_date=transaction_date
            ).update(
                quantity_sold_kg=total_quantity,
                average_price_per_kg=avg_price,
                total_revenue=total_revenue,
                data_quality_score=100,
                is_complete=True,
            )
    
    except Exception as e:
        # Log error but don't break the signal chain
        import logging
        logger = logging.getLogger(__name__)
        logger.error(
            f"Error cleaning up HistoricalTransactions for deleted SellerOrder {instance.id}: {str(e)}"
        )


def ready():
    """
    Called when the app is ready.
    Import signals here to register them.
    """
    pass
