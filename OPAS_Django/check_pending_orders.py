import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.seller_models import SellerOrder, OrderStatus
from django.contrib.auth import get_user_model

User = get_user_model()

# Check if there are any pending orders
pending = SellerOrder.objects.filter(status=OrderStatus.PENDING)
print(f'Total pending orders: {pending.count()}')

# Show details
for order in pending[:10]:
    seller_email = order.seller.email if order.seller else 'None'
    buyer_email = order.buyer.email if order.buyer else 'None'
    print(f'  Order #{order.order_number}: Seller={seller_email}, Buyer={buyer_email}, Status={order.status}, Amount={order.total_amount}')

# Check all orders
all_orders = SellerOrder.objects.all()
print(f'\nTotal orders in DB: {all_orders.count()}')
for order in all_orders[:10]:
    seller_email = order.seller.email if order.seller else 'None'
    status_display = order.get_status_display()
    print(f'  Order #{order.order_number}: Status={order.status} ({status_display}), Seller={seller_email}')

# Check specific users mentioned
print(f'\n--- Checking user 0913 and 09544498779 ---')
users_to_check = ['0913', '09544498779']
for phone in users_to_check:
    user = User.objects.filter(phone_number=phone).first()
    if user:
        print(f'\nUser {phone}: {user.email}')
        # Check orders where they are buyer
        buyer_orders = SellerOrder.objects.filter(buyer=user)
        print(f'  Orders as buyer: {buyer_orders.count()}')
        for order in buyer_orders:
            print(f'    Order #{order.order_number}: Status={order.status}, Seller={order.seller.email if order.seller else "None"}')
        
        # Check orders where they are seller
        seller_orders = SellerOrder.objects.filter(seller=user)
        print(f'  Orders as seller: {seller_orders.count()}')
        for order in seller_orders:
            print(f'    Order #{order.order_number}: Status={order.status}, Buyer={order.buyer.email if order.buyer else "None"}')
    else:
        print(f'\nUser with phone {phone}: NOT FOUND')
