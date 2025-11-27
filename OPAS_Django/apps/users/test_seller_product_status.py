from django.test import TestCase
from django.utils import timezone

from .models import User, UserRole
from .seller_models import SellerProduct, ProductStatus
from .seller_serializers import SellerProductCreateUpdateSerializer


class SellerProductStatusTests(TestCase):
    """Tests for previous_status handling on SellerProduct"""

    def setUp(self):
        self.seller = User.objects.create_user(
            username='seller_status',
            email='seller_status@example.com',
            password='testpass123',
            role=UserRole.SELLER
        )

    def test_mark_expired_records_previous_status(self):
        """When updating a product to EXPIRED, the serializer should persist previous_status"""
        product = SellerProduct.objects.create(
            seller=self.seller,
            name='Eggs',
            product_type='Poultry',
            price=100,
            status=ProductStatus.PENDING,
        )

        serializer = SellerProductCreateUpdateSerializer(product, data={'status': ProductStatus.EXPIRED}, partial=True)
        self.assertTrue(serializer.is_valid(), msg=f"Errors: {serializer.errors}")
        updated = serializer.save()

        product.refresh_from_db()
        self.assertEqual(product.status, ProductStatus.EXPIRED)
        self.assertEqual(product.previous_status, ProductStatus.PENDING)

    def test_reactivate_restores_previous_status_and_clears(self):
        """If a product is EXPIRED and has previous_status, updating it away from EXPIRED should clear previous_status"""
        product = SellerProduct.objects.create(
            seller=self.seller,
            name='Honey',
            product_type='Pantry',
            price=250,
            status=ProductStatus.EXPIRED,
            previous_status=ProductStatus.PENDING,
        )

        # Reactivate back to previous_status (simulate reactivation flow)
        serializer = SellerProductCreateUpdateSerializer(product, data={'status': ProductStatus.PENDING}, partial=True)
        self.assertTrue(serializer.is_valid(), msg=f"Errors: {serializer.errors}")
        updated = serializer.save()

        product.refresh_from_db()
        self.assertEqual(product.status, ProductStatus.PENDING)
        self.assertIsNone(product.previous_status)
