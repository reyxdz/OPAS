"""
Phase 3.2: Business Logic - Comprehensive Test Suite
Tests for:
1. Price Ceiling Validation
2. Stock Level Management  
3. Order Fulfillment Flow

Run with: python manage.py shell < test_phase_3_2.py
Or:      python test_phase_3_2.py
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, '/path/to/OPAS_Django')
django.setup()

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from decimal import Decimal
from apps.users.models import UserRole, SellerStatus
from apps.users.seller_models import (
    SellerProduct, SellerOrder, ProductStatus, OrderStatus
)

User = get_user_model()

class Phase32TestCase(TestCase):
    """Test Phase 3.2: Business Logic"""

    def setUp(self):
        """Setup test data"""
        # Create test seller user
        self.seller = User.objects.create_user(
            email='seller@test.com',
            username='seller_user',
            password='testpass123',
            phone_number='09123456789',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            store_name='Test Store',
            farm_name='Test Farm'
        )

        # Create test buyer user
        self.buyer = User.objects.create_user(
            email='buyer@test.com',
            username='buyer_user',
            password='testpass123',
            phone_number='09987654321',
            role=UserRole.BUYER,
        )

        # Create test product with stock
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Tomatoes',
            product_type='VEGETABLE',
            price=Decimal('50.00'),
            ceiling_price=Decimal('75.00'),
            unit='kg',
            stock_level=100,
            minimum_stock=10,
            status=ProductStatus.ACTIVE
        )

        # Setup API client with authentication
        self.client = APIClient()
        self.refresh = RefreshToken.for_user(self.seller)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.refresh.access_token}')

    def test_01_price_ceiling_validation(self):
        """
        Test 1: Price Ceiling Validation
        Ensures product prices don't exceed admin-set ceiling
        """
        print("\n" + "="*60)
        print("TEST 1: Price Ceiling Validation")
        print("="*60)

        # Test checking ceiling price
        response = self.client.post(
            '/api/users/seller/products/check_ceiling_price/',
            {
                'product_id': self.product.id,
            },
            format='json'
        )

        print(f"✓ Check Ceiling Price Response: {response.status_code}")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"

        data = response.json()
        print(f"  - Price: ₱{data['price']}")
        print(f"  - Ceiling: ₱{data['ceiling_price']}")
        print(f"  - Exceeds: {data['exceeds_ceiling']}")
        
        # Verify ceiling check
        assert data['exceeds_ceiling'] == False, "Price should not exceed ceiling"
        print("✓ Price is within ceiling limits")

    def test_02_stock_availability_check(self):
        """
        Test 2: Stock Availability Check
        Verifies stock check endpoint for orders
        """
        print("\n" + "="*60)
        print("TEST 2: Stock Availability Check")
        print("="*60)

        # Test sufficient stock
        response = self.client.post(
            '/api/users/seller/products/check_stock_availability/',
            {
                'product_id': self.product.id,
                'quantity_required': 50,
            },
            format='json'
        )

        print(f"✓ Stock Check Response: {response.status_code}")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"

        data = response.json()
        print(f"  - Available Stock: {data['current_stock']}")
        print(f"  - Required: {data['required_quantity']}")
        print(f"  - Stock Available: {data['available']}")
        
        assert data['available'] == True, "Should have sufficient stock"
        print("✓ Stock availability confirmed")

        # Test insufficient stock
        response = self.client.post(
            '/api/users/seller/products/check_stock_availability/',
            {
                'product_id': self.product.id,
                'quantity_required': 150,  # More than available
            },
            format='json'
        )

        data = response.json()
        print(f"\n✓ Insufficient Stock Check:")
        print(f"  - Available: {data['current_stock']}")
        print(f"  - Required: {data['required_quantity']}")
        print(f"  - Shortage: {data.get('shortage', 'N/A')}")
        
        assert data['available'] == False, "Should indicate insufficient stock"
        assert 'shortage' in data, "Should include shortage info"
        print("✓ Insufficient stock correctly identified")

    def test_03_order_acceptance_with_stock_check(self):
        """
        Test 3: Order Acceptance with Stock Check
        Ensures orders can only be accepted if stock is available
        """
        print("\n" + "="*60)
        print("TEST 3: Order Acceptance with Stock Check")
        print("="*60)

        # Create test order with sufficient stock
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product,
            order_number=f'ORD-{self.product.id}-001',
            quantity=50,
            price_per_unit=Decimal('50.00'),
            total_amount=Decimal('2500.00'),
            status=OrderStatus.PENDING,
            delivery_location='Test Address'
        )

        print(f"✓ Test Order Created: {order.order_number}")
        print(f"  - Quantity: {order.quantity} units")
        print(f"  - Product Stock: {self.product.stock_level} units")

        # Authenticate as seller
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.refresh.access_token}')

        # Accept order
        response = self.client.post(
            f'/api/users/seller/orders/{order.id}/accept/',
            format='json'
        )

        print(f"✓ Accept Order Response: {response.status_code}")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"

        data = response.json()
        print(f"  - Order Status: {data['status']}")
        assert data['status'] == OrderStatus.ACCEPTED, "Order should be accepted"
        print("✓ Order accepted successfully with stock validation")

    def test_04_prevent_double_accept(self):
        """
        Test 4: Prevent Double-Accepting Orders
        Ensures the same order cannot be accepted twice
        """
        print("\n" + "="*60)
        print("TEST 4: Prevent Double-Accepting Orders")
        print("="*60)

        # Create test order
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product,
            order_number=f'ORD-{self.product.id}-002',
            quantity=30,
            price_per_unit=Decimal('50.00'),
            total_amount=Decimal('1500.00'),
            status=OrderStatus.PENDING,
            delivery_location='Test Address'
        )

        print(f"✓ Test Order Created: {order.order_number}")

        # First acceptance
        response1 = self.client.post(
            f'/api/users/seller/orders/{order.id}/accept/',
            format='json'
        )
        print(f"✓ First Accept Response: {response1.status_code}")
        assert response1.status_code == 200, "First acceptance should succeed"

        # Attempt second acceptance (should fail)
        response2 = self.client.post(
            f'/api/users/seller/orders/{order.id}/accept/',
            format='json'
        )
        print(f"✓ Second Accept Response: {response2.status_code}")
        assert response2.status_code == 400, "Second acceptance should fail with 400"

        data = response2.json()
        print(f"  - Error Message: {data.get('error', 'N/A')}")
        assert 'Cannot accept order' in str(data), "Should indicate order already processed"
        print("✓ Double-accept prevention working correctly")

    def test_05_auto_update_stock_on_fulfill(self):
        """
        Test 5: Auto-Update Stock on Fulfillment
        Stock should be automatically decremented when order is fulfilled
        """
        print("\n" + "="*60)
        print("TEST 5: Auto-Update Stock on Fulfillment")
        print("="*60)

        initial_stock = self.product.stock_level
        print(f"✓ Initial Stock: {initial_stock} units")

        # Create and accept order
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product,
            order_number=f'ORD-{self.product.id}-003',
            quantity=25,
            price_per_unit=Decimal('50.00'),
            total_amount=Decimal('1250.00'),
            status=OrderStatus.ACCEPTED,
            delivery_location='Test Address'
        )
        from django.utils import timezone
        order.accepted_at = timezone.now()
        order.save()

        print(f"✓ Order Created and Accepted: {order.order_number}")
        print(f"  - Order Quantity: {order.quantity} units")

        # Mark as fulfilled
        response = self.client.post(
            f'/api/users/seller/orders/{order.id}/mark_fulfilled/',
            format='json'
        )

        print(f"✓ Mark Fulfilled Response: {response.status_code}")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"

        # Check stock update
        self.product.refresh_from_db()
        new_stock = self.product.stock_level

        print(f"✓ Stock After Fulfillment: {new_stock} units")
        print(f"  - Stock Deducted: {initial_stock - new_stock} units")

        expected_stock = initial_stock - order.quantity
        assert new_stock == expected_stock, f"Stock should be {expected_stock}, got {new_stock}"
        print("✓ Stock automatically updated correctly")

    def test_06_low_stock_alert_endpoint(self):
        """
        Test 6: Low Stock Alert Endpoint
        Tests retrieval of products with stock below minimum level
        """
        print("\n" + "="*60)
        print("TEST 6: Low Stock Alert Endpoint")
        print("="*60)

        # Create product with low stock
        low_stock_product = SellerProduct.objects.create(
            seller=self.seller,
            name='Peppers',
            product_type='VEGETABLE',
            price=Decimal('40.00'),
            unit='kg',
            stock_level=5,  # Below minimum
            minimum_stock=10,
            status=ProductStatus.ACTIVE
        )

        print(f"✓ Low Stock Product Created: {low_stock_product.name}")
        print(f"  - Stock: {low_stock_product.stock_level}")
        print(f"  - Minimum: {low_stock_product.minimum_stock}")

        # Fetch low stock alerts
        response = self.client.get(
            '/api/users/seller/inventory/low_stock/',
            format='json'
        )

        print(f"✓ Low Stock Alerts Response: {response.status_code}")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"

        data = response.json()
        products = data.get('low_stock_products', [])
        
        print(f"  - Total Low Stock Products: {data.get('total_low_stock_count')}")
        print(f"  - Critical Count: {data.get('critical_count')}")
        print(f"  - Warning Count: {data.get('warning_count')}")

        # Verify low stock product is in response
        product_names = [p['name'] for p in products]
        assert low_stock_product.name in product_names, "Low stock product should be in alerts"
        print(f"✓ Low stock alerts correctly showing {low_stock_product.name}")

    def test_07_stock_below_minimum_after_fulfill(self):
        """
        Test 7: Stock Below Minimum After Fulfillment
        Tests that system alerts when stock falls below minimum after order fulfillment
        """
        print("\n" + "="*60)
        print("TEST 7: Stock Below Minimum After Fulfillment")
        print("="*60)

        # Create product with stock close to minimum
        test_product = SellerProduct.objects.create(
            seller=self.seller,
            name='Carrots',
            product_type='VEGETABLE',
            price=Decimal('35.00'),
            unit='kg',
            stock_level=15,  # Just above minimum
            minimum_stock=10,
            status=ProductStatus.ACTIVE
        )

        print(f"✓ Test Product: {test_product.name}")
        print(f"  - Initial Stock: {test_product.stock_level}")
        print(f"  - Minimum: {test_product.minimum_stock}")

        # Create order that will make stock go below minimum
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=test_product,
            order_number=f'ORD-{test_product.id}-LOW',
            quantity=10,  # Will leave only 5 units (below min of 10)
            price_per_unit=Decimal('35.00'),
            total_amount=Decimal('350.00'),
            status=OrderStatus.ACCEPTED,
            delivery_location='Test Address'
        )
        from django.utils import timezone
        order.accepted_at = timezone.now()
        order.save()

        # Fulfill order
        response = self.client.post(
            f'/api/users/seller/orders/{order.id}/mark_fulfilled/',
            format='json'
        )

        print(f"✓ Order Fulfilled: {response.status_code}")
        
        # Check response includes stock info
        data = response.json()
        stock_info = data.get('stock_info', {})

        print(f"\n✓ Stock Update Information:")
        print(f"  - Before: {stock_info.get('stock_before')} units")
        print(f"  - After: {stock_info.get('stock_after')} units")
        print(f"  - Is Low Stock: {stock_info.get('is_low_stock')}")

        assert stock_info.get('is_low_stock') == True, "Stock should be flagged as low"
        print("✓ Low stock correctly flagged after fulfillment")

    def test_08_insufficient_stock_prevents_accept(self):
        """
        Test 8: Insufficient Stock Prevents Order Acceptance
        Orders should not be accepted if seller doesn't have enough stock
        """
        print("\n" + "="*60)
        print("TEST 8: Insufficient Stock Prevents Order Acceptance")
        print("="*60)

        # Set product stock to low level
        self.product.stock_level = 10
        self.product.save()

        print(f"✓ Product Stock: {self.product.stock_level} units")

        # Create order for more than available
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=self.product,
            order_number=f'ORD-{self.product.id}-EXCEED',
            quantity=20,  # More than 10 available
            price_per_unit=Decimal('50.00'),
            total_amount=Decimal('1000.00'),
            status=OrderStatus.PENDING,
            delivery_location='Test Address'
        )

        print(f"✓ Order Created: {order.order_number}")
        print(f"  - Order Quantity: {order.quantity} units")
        print(f"  - Available Stock: {self.product.stock_level} units")

        # Attempt to accept order
        response = self.client.post(
            f'/api/users/seller/orders/{order.id}/accept/',
            format='json'
        )

        print(f"✓ Accept Response: {response.status_code}")
        assert response.status_code == 400, "Should reject due to insufficient stock"

        data = response.json()
        print(f"  - Error: {data.get('error')}")
        assert 'Insufficient stock' in str(data), "Should indicate insufficient stock"
        print("✓ Insufficient stock correctly prevents order acceptance")


def run_all_tests():
    """Run all Phase 3.2 tests"""
    print("\n" + "="*60)
    print("PHASE 3.2: BUSINESS LOGIC - TEST SUITE")
    print("="*60)

    from django.test.utils import get_runner
    from django.conf import settings

    TestRunner = get_runner(settings)
    test_runner = TestRunner(verbosity=2, interactive=True, keepdb=False)

    # Run tests
    failures = test_runner.run_tests([
        'test_phase_3_2.Phase32TestCase.test_01_price_ceiling_validation',
        'test_phase_3_2.Phase32TestCase.test_02_stock_availability_check',
        'test_phase_3_2.Phase32TestCase.test_03_order_acceptance_with_stock_check',
        'test_phase_3_2.Phase32TestCase.test_04_prevent_double_accept',
        'test_phase_3_2.Phase32TestCase.test_05_auto_update_stock_on_fulfill',
        'test_phase_3_2.Phase32TestCase.test_06_low_stock_alert_endpoint',
        'test_phase_3_2.Phase32TestCase.test_07_stock_below_minimum_after_fulfill',
        'test_phase_3_2.Phase32TestCase.test_08_insufficient_stock_prevents_accept',
    ])

    print("\n" + "="*60)
    if failures:
        print(f"❌ TESTS FAILED: {failures} failure(s)")
    else:
        print("✅ ALL TESTS PASSED!")
    print("="*60)

    return failures


if __name__ == '__main__':
    # For standalone execution
    import unittest
    
    suite = unittest.TestLoader().loadTestsFromTestCase(Phase32TestCase)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)
