"""
Signal handlers for auto-linking OPAS products to OPASProduct table.

When a SellerProduct is created by OPAS Admin (seller_id=58), automatically:
1. Check if matching OPASProduct exists (same category:type:subtype)
2. If exists: Link via OPASProductPosting
3. If not: Create new OPASProduct entry
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from apps.users.seller_models import SellerProduct
from apps.users.opas_models import OPASProduct, OPASProductSale


@receiver(post_save, sender=SellerProduct)
def auto_link_opas_product(sender, instance, created, **kwargs):
    """
    When OPAS Admin (seller_id=58) posts a product, auto-link to OPASProduct.
    
    This ensures:
    - OPAS postings are tracked in OPASProduct for forecasting
    - Sales data flows to forecasting system
    - Product classification is consistent
    """
    
    # Only process OPAS Admin products (seller_id=58)
    if instance.seller_id != 58:
        return
    
    # Only on creation
    if not created:
        return
    
    # Check if all classification fields are set
    if not instance.category_forecast or not instance.product_type:
        return
    
    # Build the forecast group key
    forecast_key = f"{instance.category_forecast}:{instance.product_type}:{instance.product_subtype or 'None'}"
    
    try:
        # Try to find matching OPASProduct
        opas_product = OPASProduct.objects.filter(
            category_forecast=instance.category_forecast,
            product_type=instance.product_type,
            product_subtype=instance.product_subtype
        ).first()
        
        # If no exact match, create a new OPASProduct
        if not opas_product:
            opas_product = OPASProduct.objects.create(
                name=instance.name,
                category_forecast=instance.category_forecast,
                product_type=instance.product_type,
                product_subtype=instance.product_subtype,
                forecast_group_key=forecast_key,
                is_active=True
            )
        
        # Store the link in SellerProduct for reference
        # This allows easy lookup of which OPASProduct a SellerProduct is linked to
        instance.opas_product_id = opas_product.id
        instance.save(update_fields=['opas_product_id'])
        
    except Exception as e:
        # Log error but don't fail the product creation
        print(f"Error auto-linking OPAS product {instance.name}: {str(e)}")


def record_opas_sale(seller_product, quantity, price_per_unit, sale_date=None):
    """
    Record a sale of an OPAS product for forecasting.
    
    Called when:
    - A buyer purchases an OPAS-posted product (SellerOrder created)
    
    This creates an OPASProductSale entry so the forecasting system
    has fresh sales data to work with.
    
    Args:
        seller_product: The SellerProduct that was sold
        quantity: Units sold
        price_per_unit: Price per unit
        sale_date: When the sale occurred (default: now)
    """
    
    if sale_date is None:
        sale_date = timezone.now()
    
    # Check if this is an OPAS product (posted by seller_id=58)
    if seller_product.seller_id != 58:
        return
    
    # Check if linked to OPASProduct
    if not hasattr(seller_product, 'opas_product_id') or not seller_product.opas_product_id:
        return
    
    try:
        opas_product = OPASProduct.objects.get(id=seller_product.opas_product_id)
        
        # Create sale record
        OPASProductSale.objects.create(
            opas_product=opas_product,
            seller_product=seller_product,
            quantity_sold=quantity,
            price_per_unit=price_per_unit,
            sale_date=sale_date
        )
        
    except OPASProduct.DoesNotExist:
        print(f"OPASProduct not found for seller_product {seller_product.id}")
    except Exception as e:
        print(f"Error recording OPAS sale: {str(e)}")
