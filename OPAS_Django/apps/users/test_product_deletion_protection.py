"""
Test cases for Product Deletion Protection feature.

This test suite validates the order protection logic that prevents
sellers from deleting products that have associated orders.

Test Coverage:
- Test 1: Delete product with no orders (should succeed)
- Test 2: Delete product with pending order (should fail)
- Test 3: Delete product with multiple orders (should fail)
- Test 4: Delete product after order cancelled (should still fail)
"""

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from .models import User, UserRole, SellerStatus
from .seller_models import SellerProduct, SellerOrder, ProductStatus, OrderStatus

User = get_user_model()


class ProductDeletionProtectionTestCase(TestCase):
    """Test suite for product deletion protection feature"""

    def setUp(self):
        """Set up test fixtures"""
        # Create seller user
        self.seller = User.objects.create_user(
            username='seller_test',
            phone_number='+1234567890',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            first_name='Test',
            last_name='Seller'
        )

        # Create buyer user
        self.buyer = User.objects.create_user(
            username='buyer_test',
            phone_number='+0987654321',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER,
            first_name='Test',
            last_name='Buyer'
        )

        # Initialize API client
        self.client = APIClient()

    def _authenticate_seller(self):
        """Authenticate as seller"""
        self.client.force_authenticate(user=self.seller)

    def _create_product(self, name='Test Product', price=100.0, quantity=10):
        """Helper to create a product"""
        product = SellerProduct.objects.create(
            seller=self.seller,
            name=name,
            price=price,
            stock_level=quantity,
            status=ProductStatus.ACTIVE,
            description='Test product'
        )
        return product

    def _create_order(self, product, status_type=OrderStatus.PENDING):
        """Helper to create an order"""
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=product,
            order_number=f'ORD-{product.id}-{SellerOrder.objects.count()}',
            quantity=5,
            price_per_unit=product.price,
            total_amount=5 * product.price,
            status=status_type
        )
        return order

    def test_1_delete_product_with_no_orders(self):
        """Test 1: Delete product with no orders - should succeed (204 No Content)"""
        self._authenticate_seller()
        
        # Create a product
        product = self._create_product(name='Product Without Orders')
        product_id = product.id
        
        # Verify product exists
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())
        
        # Delete the product
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Assert success
        self.assertEqual(
            response.status_code,
            status.HTTP_204_NO_CONTENT,
            f"Expected 204 status code but got {response.status_code}"
        )
        
        # Verify product is deleted
        self.assertFalse(SellerProduct.objects.filter(id=product_id).exists())
        
        print("✅ Test 1 PASSED: Product with no orders was successfully deleted")

    def test_2_delete_product_with_pending_order(self):
        """Test 2: Delete product with pending order - should fail (400)"""
        self._authenticate_seller()
        
        # Create product and order
        product = self._create_product(name='Product With Pending Order')
        order = self._create_order(product, status_type=OrderStatus.PENDING)
        product_id = product.id
        
        # Verify order exists
        self.assertTrue(SellerOrder.objects.filter(id=order.id).exists())
        self.assertTrue(product.has_orders())
        
        # Try to delete the product
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Assert failure with 400 status
        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
            f"Expected 400 status code but got {response.status_code}"
        )
        
        # Verify error response contains order count
        response_data = response.json()
        self.assertIn('order_count', response_data)
        self.assertEqual(
            response_data['order_count'],
            1,
            f"Expected order_count=1 but got {response_data.get('order_count')}"
        )
        
        # Verify error message is helpful
        self.assertIn('message', response_data)
        self.assertIn('order', response_data['message'].lower())
        
        # Verify product still exists
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())
        
        print("✅ Test 2 PASSED: Product with pending order cannot be deleted (returns 400)")

    def test_3_delete_product_with_multiple_orders(self):
        """Test 3: Delete product with multiple orders - should fail (400)"""
        self._authenticate_seller()
        
        # Create product with multiple orders
        product = self._create_product(name='Product With Multiple Orders')
        order1 = self._create_order(product, status_type=OrderStatus.PENDING)
        order2 = self._create_order(product, status_type=OrderStatus.ACCEPTED)
        order3 = self._create_order(product, status_type=OrderStatus.FULFILLED)
        product_id = product.id
        
        # Verify multiple orders exist
        order_count = SellerOrder.objects.filter(product=product).count()
        self.assertEqual(order_count, 3)
        self.assertTrue(product.has_orders())
        
        # Try to delete the product
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Assert failure with 400 status
        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
            f"Expected 400 status code but got {response.status_code}"
        )
        
        # Verify error response shows correct order count
        response_data = response.json()
        self.assertIn('order_count', response_data)
        self.assertEqual(
            response_data['order_count'],
            3,
            f"Expected order_count=3 but got {response_data.get('order_count')}"
        )
        
        # Verify message mentions the order count
        self.assertIn('3', response_data['message'])
        
        # Verify product still exists
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())
        
        print("✅ Test 3 PASSED: Product with multiple orders cannot be deleted (returns 400 with count=3)")

    def test_4_delete_product_after_order_cancelled(self):
        """Test 4: Delete product after order cancelled - should still fail (business decision)"""
        self._authenticate_seller()
        
        # Create product and order
        product = self._create_product(name='Product With Cancelled Order')
        order = self._create_order(product, status_type=OrderStatus.PENDING)
        order.status = OrderStatus.CANCELLED
        order.save()
        product_id = product.id
        
        # Verify cancelled order exists
        self.assertTrue(SellerOrder.objects.filter(id=order.id).exists())
        self.assertEqual(order.status, OrderStatus.CANCELLED)
        
        # Per business decision: cancelled orders still prevent deletion
        # This protects the audit trail and order history
        self.assertTrue(product.has_orders())
        
        # Try to delete the product
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Assert failure with 400 status (cancelled orders still protect)
        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
            f"Expected 400 status code but got {response.status_code}"
        )
        
        # Verify error response contains order count
        response_data = response.json()
        self.assertIn('order_count', response_data)
        self.assertEqual(
            response_data['order_count'],
            1,
            f"Expected order_count=1 but got {response_data.get('order_count')}"
        )
        
        # Verify product still exists (protected by cancelled order)
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())
        
        print("✅ Test 4 PASSED: Product with cancelled order still cannot be deleted (business decision)")

    def test_has_orders_helper_method(self):
        """Test the has_orders() helper method"""
        product = self._create_product(name='Helper Test Product')
        
        # Should return False when no orders
        self.assertFalse(product.has_orders())
        
        # Create an order
        self._create_order(product)
        
        # Should return True when order exists
        self.assertTrue(product.has_orders())

    def test_get_order_count_helper_method(self):
        """Test the get_order_count() helper method"""
        product = self._create_product(name='Count Test Product')
        
        # Should return 0 when no orders
        self.assertEqual(product.get_order_count(), 0)
        
        # Create orders
        self._create_order(product)
        self._create_order(product)
        self._create_order(product)
        
        # Should return correct count
        self.assertEqual(product.get_order_count(), 3)

    def test_seller_authorization_on_delete(self):
        """Test that only the product owner can delete"""
        # Create another seller
        other_seller = User.objects.create_user(
            username='other_seller',
            phone_number='+9998887776',
            email='other@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        
        # Create product by first seller
        product = self._create_product(name='Authorization Test Product')
        product_id = product.id
        
        # Authenticate as different seller
        self.client.force_authenticate(user=other_seller)
        
        # Try to delete product of another seller
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Should fail with 404 (not found)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        
        # Original product should still exist
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())

    def test_error_response_format(self):
        """Test that error response has correct format"""
        self._authenticate_seller()
        
        product = self._create_product(name='Format Test Product')
        self._create_order(product)
        product_id = product.id
        
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Verify response structure
        response_data = response.json()
        self.assertIn('detail', response_data)
        self.assertIn('order_count', response_data)
        self.assertIn('message', response_data)
        
        # Verify values are correct types
        self.assertIsInstance(response_data['detail'], str)
        self.assertIsInstance(response_data['order_count'], int)
        self.assertIsInstance(response_data['message'], str)


class ProductDeletionProtectionIntegrationTest(TestCase):
    """Integration tests for product deletion protection"""

    def setUp(self):
        """Set up test fixtures"""
        self.seller = User.objects.create_user(
            username='seller_integ',
            phone_number='+1112223334',
            email='seller@test.com',
            password='testpass123',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )
        self.buyer = User.objects.create_user(
            username='buyer_integ',
            phone_number='+5556667778',
            email='buyer@test.com',
            password='testpass123',
            role=UserRole.BUYER
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.seller)

    def test_complete_workflow(self):
        """Test complete workflow: create product -> create order -> try delete -> fail"""
        # Create product
        product = SellerProduct.objects.create(
            seller=self.seller,
            name='Workflow Test Product',
            price=100.0,
            stock_level=10,
            status=ProductStatus.ACTIVE,
            description='Test'
        )
        product_id = product.id
        
        # Verify product created
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())
        
        # Create order for product
        order = SellerOrder.objects.create(
            seller=self.seller,
            buyer=self.buyer,
            product=product,
            order_number='WF-TEST-001',
            quantity=5,
            price_per_unit=100.0,
            total_amount=500.0,
            status=OrderStatus.PENDING
        )
        
        # Verify order created
        self.assertTrue(SellerOrder.objects.filter(id=order.id).exists())
        
        # Try to delete product - should fail
        response = self.client.delete(f'/api/users/seller/products/{product_id}/')
        
        # Verify failure
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Verify product still exists
        self.assertTrue(SellerProduct.objects.filter(id=product_id).exists())
        
        print("✅ Integration Test PASSED: Complete workflow validated")


# Run tests with: python manage.py test apps.users.test_product_deletion_protection
if __name__ == '__main__':
    import unittest
    unittest.main()
