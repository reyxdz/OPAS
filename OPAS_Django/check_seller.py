from apps.users.seller_models import SellerProduct

products = SellerProduct.objects.all()[:5]
for p in products:
    print(f'{p.name}: seller_id={p.seller_id}')
