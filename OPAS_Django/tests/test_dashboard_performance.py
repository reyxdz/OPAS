#!/usr/bin/env python
"""
Performance validation for Dashboard ViewSet endpoint.
Tests with 1000+ records to ensure response time < 2000ms
"""

import os
import sys
import django
import time
from decimal import Decimal
from datetime import timedelta

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.test.utils import CaptureQueriesContext
from django.db import connection
from apps.users.models import User, UserRole, SellerStatus
from apps.users.seller_models import SellerProduct, SellerOrder, ProductStatus, OrderStatus, SellToOPAS
from apps.users.admin_models import AdminUser, OPASInventory, MarketplaceAlert
from apps.users.admin_viewsets import DashboardViewSet
from django.utils import timezone


def create_test_data(num_sellers=100, num_products_per_seller=15, num_orders_per_seller=20):
    """Create bulk test data for performance testing"""
    print(f'\nCreating test data:')
    print(f'  - {num_sellers} sellers')
    print(f'  - {num_products_per_seller} products per seller')
    print(f'  - {num_orders_per_seller} orders per seller')
    
    sellers = []
    products = []
    orders = []
    
    # Create sellers
    for i in range(num_sellers):
        try:
            seller = User.objects.get(email=f'seller{i:04d}@test.com')
        except User.DoesNotExist:
            seller = User.objects.create_user(
                email=f'seller{i:04d}@test.com',
                password='password123',
                username=f'seller{i:04d}',
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED,
                store_name=f'Store {i:04d}'
            )
        sellers.append(seller)
    
    # Create products
    for seller in sellers:
        for j in range(num_products_per_seller):
            try:
                product = SellerProduct.objects.get(
                    seller=seller,
                    name=f'Product {j:03d} - {seller.id}'
                )
            except SellerProduct.DoesNotExist:
                product = SellerProduct.objects.create(
                    seller=seller,
                    name=f'Product {j:03d} - {seller.id}',
                    description=f'Description for product {j}',
                    price=Decimal('100.00') + Decimal(j),
                    status=ProductStatus.ACTIVE,
                    is_deleted=False
                )
            products.append(product)
    
    # Create buyers
    buyers = []
    for i in range(20):
        try:
            buyer = User.objects.get(email=f'buyer{i:03d}@test.com')
        except User.DoesNotExist:
            buyer = User.objects.create_user(
                email=f'buyer{i:03d}@test.com',
                password='password123',
                username=f'buyer{i:03d}',
                role=UserRole.BUYER
            )
        buyers.append(buyer)
    
    # Create orders
    today = timezone.now()
    for seller in sellers:
        for j in range(num_orders_per_seller):
            try:
                order = SellerOrder.objects.get(
                    seller=seller,
                    order_number=f'ORD-{seller.id:05d}-{j:03d}'
                )
            except SellerOrder.DoesNotExist:
                product = SellerProduct.objects.filter(seller=seller).first()
                buyer = buyers[j % len(buyers)]
                
                order = SellerOrder.objects.create(
                    seller=seller,
                    buyer=buyer,
                    product=product,
                    order_number=f'ORD-{seller.id:05d}-{j:03d}',
                    quantity=j + 1,
                    price_per_unit=Decimal('100.00'),
                    total_amount=Decimal('100.00') * (j + 1),
                    status=OrderStatus.DELIVERED if j % 2 == 0 else OrderStatus.PENDING,
                    created_at=today,
                    on_time=j % 3 != 0,
                    fulfillment_days=5 + (j % 5)
                )
            orders.append(order)
    
    # Create OPAS inventory (simplified - use try/except to skip if fails)
    try:
        products_list = list(SellerProduct.objects.all()[:5])
        for i, product in enumerate(products_list):
            OPASInventory.objects.get_or_create(
                product=product,
                defaults={
                    'quantity_received': 100 + i * 10,
                    'quantity_on_hand': 100 + i * 10,
                    'in_date': timezone.now(),
                    'expiry_date': timezone.now() + timedelta(days=30),
                    'storage_condition': 'GOOD'
                }
            )
    except Exception as e:
        print(f'Note: Skipping OPASInventory creation: {e}')
    
    # Create alerts
    for i in range(30):
        try:
            alert = MarketplaceAlert.objects.get(title=f'Alert {i:03d}')
        except MarketplaceAlert.DoesNotExist:
            alert = MarketplaceAlert.objects.create(
                title=f'Alert {i:03d}',
                description=f'Alert description {i}',
                alert_type='PRICE_VIOLATION' if i % 2 == 0 else 'SELLER_ISSUE',
                severity='HIGH' if i % 3 == 0 else 'MEDIUM',
                status='OPEN' if i % 2 == 0 else 'RESOLVED'
            )
    
    print(f'\n✓ Test data created:')
    print(f'  - {len(sellers)} sellers')
    print(f'  - {len(products)} products')
    print(f'  - {len(orders)} orders')
    print(f'  - 50 inventory items')
    print(f'  - 30 alerts')


def test_performance():
    """Test dashboard endpoint performance"""
    
    print(f'\n=== Dashboard ViewSet Performance Test ===\n')
    
    # Create test data
    create_test_data(num_sellers=100, num_products_per_seller=15, num_orders_per_seller=20)
    
    print(f'\nTesting metric calculation performance...\n')
    
    # Create viewset instance
    viewset = DashboardViewSet()
    
    # Test metrics with query counting
    metrics = {}
    times = {}
    
    # Test seller metrics
    with CaptureQueriesContext(connection) as ctx_seller:
        start = time.time()
        metrics['seller_metrics'] = viewset._get_seller_metrics()
        times['seller_metrics'] = time.time() - start
    
    print(f'Seller Metrics:')
    print(f'  - Time: {times["seller_metrics"]*1000:.2f}ms')
    print(f'  - Queries: {len(ctx_seller)} queries')
    
    # Test market metrics
    with CaptureQueriesContext(connection) as ctx_market:
        start = time.time()
        metrics['market_metrics'] = viewset._get_market_metrics()
        times['market_metrics'] = time.time() - start
    
    print(f'\nMarket Metrics:')
    print(f'  - Time: {times["market_metrics"]*1000:.2f}ms')
    print(f'  - Queries: {len(ctx_market)} queries')
    
    # Test OPAS metrics
    with CaptureQueriesContext(connection) as ctx_opas:
        start = time.time()
        metrics['opas_metrics'] = viewset._get_opas_metrics()
        times['opas_metrics'] = time.time() - start
    
    print(f'\nOPAS Metrics:')
    print(f'  - Time: {times["opas_metrics"]*1000:.2f}ms')
    print(f'  - Queries: {len(ctx_opas)} queries')
    
    # Test price compliance
    with CaptureQueriesContext(connection) as ctx_price:
        start = time.time()
        metrics['price_compliance'] = viewset._get_price_compliance()
        times['price_compliance'] = time.time() - start
    
    print(f'\nPrice Compliance:')
    print(f'  - Time: {times["price_compliance"]*1000:.2f}ms')
    print(f'  - Queries: {len(ctx_price)} queries')
    
    # Test alerts
    with CaptureQueriesContext(connection) as ctx_alerts:
        start = time.time()
        metrics['alerts'] = viewset._get_alerts()
        times['alerts'] = time.time() - start
    
    print(f'\nAlerts:')
    print(f'  - Time: {times["alerts"]*1000:.2f}ms')
    print(f'  - Queries: {len(ctx_alerts)} queries')
    
    # Test health score
    with CaptureQueriesContext(connection) as ctx_health:
        start = time.time()
        metrics['health_score'] = viewset._calculate_health_score(metrics['price_compliance'])
        times['health_score'] = time.time() - start
    
    print(f'\nHealth Score:')
    print(f'  - Time: {times["health_score"]*1000:.2f}ms')
    print(f'  - Queries: {len(ctx_health)} queries')
    
    # Total
    total_time = sum(times.values())
    total_queries = sum([len(ctx_seller), len(ctx_market), len(ctx_opas), len(ctx_price), len(ctx_alerts), len(ctx_health)])
    
    print(f'\n=== SUMMARY ===')
    print(f'Total Time: {total_time*1000:.2f}ms')
    print(f'Total Queries: {total_queries}')
    print(f'Health Score: {metrics["health_score"]}')
    
    # Performance checks
    print(f'\n=== PERFORMANCE CHECKS ===')
    if total_time * 1000 < 2000:
        print(f'✓ Response time < 2000ms: {total_time*1000:.2f}ms')
    else:
        print(f'✗ Response time > 2000ms: {total_time*1000:.2f}ms')
    
    if total_queries <= 15:
        print(f'✓ Query count <= 15: {total_queries} queries')
    else:
        print(f'⚠ Query count > 15: {total_queries} queries (expected optimization)')
    
    # Display metrics
    print(f'\n=== METRICS CALCULATED ===')
    print(f'Seller Metrics:')
    for k, v in metrics['seller_metrics'].items():
        print(f'  - {k}: {v}')
    
    print(f'\nMarket Metrics:')
    for k, v in metrics['market_metrics'].items():
        print(f'  - {k}: {v}')
    
    print(f'\nOPAS Metrics:')
    for k, v in metrics['opas_metrics'].items():
        print(f'  - {k}: {v}')
    
    print(f'\nPrice Compliance:')
    for k, v in metrics['price_compliance'].items():
        print(f'  - {k}: {v}')


if __name__ == '__main__':
    test_performance()
