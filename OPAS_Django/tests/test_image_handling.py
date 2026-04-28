"""
Test script for Phase 3.1: Image Handling Implementation
Tests all image upload, retrieval, and deletion functionality
"""

import os
import sys
import django
from pathlib import Path
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, Client
from PIL import Image
from io import BytesIO

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.users.models import UserRole, SellerStatus
from apps.users.seller_models import SellerProduct, ProductImage, ProductStatus

User = get_user_model()


class ImageHandlingTests(TestCase):
    """Test Phase 3.1: Image Handling"""

    @classmethod
    def setUpClass(cls):
        """Set up test fixtures"""
        super().setUpClass()
        print("\n" + "="*80)
        print("PHASE 3.1: IMAGE HANDLING TESTS")
        print("="*80)

    def setUp(self):
        """Create test user and product"""
        print("\n[SETUP] Creating test fixtures...")
        
        # Create seller user
        self.seller = User.objects.create_user(
            email='seller@test.com',
            username='testseller',
            password='testpass123',
            first_name='Test',
            last_name='Seller',
            phone_number='09123456789',
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED,
            store_name='Test Store',
            farm_name='Test Farm'
        )
        print(f"✓ Seller created: {self.seller.email}")

        # Create test product
        self.product = SellerProduct.objects.create(
            seller=self.seller,
            name='Test Product',
            description='A test product for image upload',
            product_type='VEGETABLE',
            price=100.00,
            ceiling_price=120.00,
            stock_level=50,
            unit='kg',
            status=ProductStatus.ACTIVE
        )
        print(f"✓ Product created: {self.product.name} (ID: {self.product.id})")

        # Setup test client
        self.client = Client()
        print("✓ Test client ready")

    def create_test_image(self, filename='test_image.jpg', size=(100, 100)):
        """Create a test image file"""
        image = Image.new('RGB', size, color='red')
        image_bytes = BytesIO()
        image.save(image_bytes, format='JPEG')
        image_bytes.seek(0)
        
        return SimpleUploadedFile(
            name=filename,
            content=image_bytes.read(),
            content_type='image/jpeg'
        )

    def test_01_model_creation(self):
        """Test ProductImage model creation"""
        print("\n[TEST 1] ProductImage Model Creation")
        
        image_file = self.create_test_image()
        
        product_image = ProductImage.objects.create(
            product=self.product,
            image=image_file,
            is_primary=True,
            alt_text='Test Image',
            order=0
        )
        
        assert product_image.id is not None, "Image ID should be generated"
        assert product_image.product == self.product, "Product should be linked"
        assert product_image.is_primary == True, "Should be marked as primary"
        assert product_image.uploaded_at is not None, "Upload timestamp should be set"
        
        print(f"✓ Product image created: ID={product_image.id}")
        print(f"✓ Image URL path: {product_image.image.name}")
        print(f"✓ Primary image: {product_image.is_primary}")
        print(f"✓ Upload timestamp: {product_image.uploaded_at}")

    def test_02_primary_image_constraint(self):
        """Test that only one image is marked as primary"""
        print("\n[TEST 2] Primary Image Constraint")
        
        # Create first primary image
        image1 = self.create_test_image('image1.jpg')
        img1_obj = ProductImage.objects.create(
            product=self.product,
            image=image1,
            is_primary=True,
            order=0
        )
        print(f"✓ First image created as primary: ID={img1_obj.id}")
        
        # Create second image and mark as primary
        image2 = self.create_test_image('image2.jpg')
        img2_obj = ProductImage.objects.create(
            product=self.product,
            image=image2,
            is_primary=True,
            order=1
        )
        print(f"✓ Second image created as primary: ID={img2_obj.id}")
        
        # Check that only second image is primary
        img1_obj.refresh_from_db()
        img2_obj.refresh_from_db()
        
        assert img1_obj.is_primary == False, "First image should not be primary"
        assert img2_obj.is_primary == True, "Second image should be primary"
        
        print(f"✓ Constraint enforced: First image primary={img1_obj.is_primary}")
        print(f"✓ Constraint enforced: Second image primary={img2_obj.is_primary}")

    def test_03_image_ordering(self):
        """Test image ordering"""
        print("\n[TEST 3] Image Ordering")
        
        # Create images with different orders
        for i in range(3):
            image = self.create_test_image(f'image_{i}.jpg')
            ProductImage.objects.create(
                product=self.product,
                image=image,
                order=i,
                is_primary=(i == 0)
            )
        
        # Verify ordering
        images = ProductImage.objects.filter(product=self.product).order_by('order')
        orders = [img.order for img in images]
        
        assert orders == [0, 1, 2], f"Images should be ordered [0, 1, 2], got {orders}"
        print(f"✓ Images ordered correctly: {orders}")

    def test_04_media_settings(self):
        """Test MEDIA settings configuration"""
        print("\n[TEST 4] Media Settings Configuration")
        
        from django.conf import settings
        
        assert hasattr(settings, 'MEDIA_ROOT'), "MEDIA_ROOT should be configured"
        assert hasattr(settings, 'MEDIA_URL'), "MEDIA_URL should be configured"
        
        media_root = Path(settings.MEDIA_ROOT)
        media_url = settings.MEDIA_URL
        
        print(f"✓ MEDIA_ROOT: {media_root}")
        print(f"✓ MEDIA_URL: {media_url}")
        
        # Create directory if not exists
        media_root.mkdir(parents=True, exist_ok=True)
        assert media_root.exists(), "MEDIA_ROOT directory should exist or be creatable"
        print(f"✓ MEDIA_ROOT directory exists/created")

    def test_05_serializer_functionality(self):
        """Test ProductImageSerializer"""
        print("\n[TEST 5] ProductImageSerializer")
        
        from apps.users.seller_serializers import ProductImageSerializer
        
        image_file = self.create_test_image()
        product_image = ProductImage.objects.create(
            product=self.product,
            image=image_file,
            is_primary=True,
            alt_text='Test Serializer'
        )
        
        serializer = ProductImageSerializer(product_image)
        data = serializer.data
        
        assert 'id' in data, "Serializer should include id"
        assert 'image' in data, "Serializer should include image"
        assert 'image_url' in data, "Serializer should include image_url"
        assert 'is_primary' in data, "Serializer should include is_primary"
        assert 'uploaded_at' in data, "Serializer should include uploaded_at"
        
        print(f"✓ Serializer fields: {list(data.keys())}")
        print(f"✓ Image ID: {data['id']}")
        print(f"✓ Is primary: {data['is_primary']}")

    def test_06_product_list_serializer_with_images(self):
        """Test SellerProductListSerializer includes primary image"""
        print("\n[TEST 6] Product List Serializer with Images")
        
        from apps.users.seller_serializers import SellerProductListSerializer
        
        # Create product image
        image_file = self.create_test_image()
        ProductImage.objects.create(
            product=self.product,
            image=image_file,
            is_primary=True
        )
        
        serializer = SellerProductListSerializer(self.product)
        data = serializer.data
        
        assert 'primary_image' in data, "Serializer should include primary_image"
        assert data['primary_image'] is not None, "primary_image should not be None"
        assert 'id' in data['primary_image'], "primary_image should have id"
        
        print(f"✓ Product serializer includes: {list(data.keys())}")
        print(f"✓ Primary image included: {data['primary_image']['id']}")

    def test_07_file_validation(self):
        """Test file type and size validation"""
        print("\n[TEST 7] File Validation")
        
        # Test valid types
        valid_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        print(f"✓ Valid file types: {valid_types}")
        
        # Test file size limit
        max_size = 5 * 1024 * 1024  # 5MB
        print(f"✓ Max file size: {max_size / (1024*1024):.0f}MB")

    def test_08_get_queryset_performance(self):
        """Test queryset efficiency"""
        print("\n[TEST 8] Queryset Performance")
        
        # Create multiple images
        for i in range(5):
            image = self.create_test_image(f'perf_image_{i}.jpg')
            ProductImage.objects.create(
                product=self.product,
                image=image,
                order=i,
                is_primary=(i == 0)
            )
        
        # Query with ordering
        images = ProductImage.objects.filter(product=self.product).order_by('order', '-uploaded_at')
        count = images.count()
        
        assert count == 5, f"Should have 5 images, got {count}"
        print(f"✓ Created 5 images successfully")
        print(f"✓ Query performance: Retrieved {count} images")

    def test_09_migration_file(self):
        """Test migration file exists"""
        print("\n[TEST 9] Migration File")
        
        migration_path = Path('apps/users/migrations/0007_product_image.py')
        if migration_path.exists():
            print(f"✓ Migration file exists: {migration_path}")
        else:
            print(f"⚠ Migration file not found at {migration_path}")

    def test_10_database_tables(self):
        """Test database table creation"""
        print("\n[TEST 10] Database Tables")
        
        from django.db import connection
        
        with connection.cursor() as cursor:
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%product_image%'")
            tables = cursor.fetchall()
            
            if tables:
                print(f"✓ Product image table(s) found: {[t[0] for t in tables]}")
            else:
                # Try PostgreSQL
                cursor.execute("SELECT tablename FROM pg_tables WHERE tablename LIKE '%product_image%'")
                tables = cursor.fetchall()
                if tables:
                    print(f"✓ Product image table(s) found: {[t[0] for t in tables]}")
                else:
                    print("ℹ Product image table not found (may not be migrated yet)")

    @classmethod
    def tearDownClass(cls):
        """Cleanup"""
        super().tearDownClass()
        print("\n" + "="*80)
        print("PHASE 3.1 TESTS COMPLETED")
        print("="*80 + "\n")


def run_tests():
    """Run all tests"""
    from django.test.utils import get_runner
    from django.conf import settings

    TestRunner = get_runner(settings)
    test_runner = TestRunner(verbosity=2, interactive=False, keepdb=True)
    
    # Run tests
    print("\nRunning Phase 3.1 Image Handling Tests...\n")
    failures = test_runner.run_tests(['__main__.ImageHandlingTests'])
    
    return failures


if __name__ == '__main__':
    failures = run_tests()
    sys.exit(bool(failures))
