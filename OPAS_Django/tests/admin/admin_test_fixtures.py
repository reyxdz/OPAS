"""
Reusable Test Fixtures and Base Classes for Admin Testing

Architecture: Clean separation of test data setup, factories, and common test utilities.
DRY Principle: Fixtures are shared across all admin tests.
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase, APIClient
from rest_framework.authtoken.models import Token
from datetime import datetime, timedelta
import uuid

from apps.users.models import User, UserRole, SellerStatus
from apps.users.admin_models import (
    AdminRole, AdminUser, SellerRegistrationRequest, SellerRegistrationStatus,
    SellerDocumentVerification, DocumentVerificationStatus, SellerApprovalHistory,
    SellerSuspension, PriceCeiling, PriceChangeReason, PriceHistory,
    PriceNonCompliance, OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction,
    OPASPurchaseHistory, AdminAuditLog, MarketplaceAlert,
    SystemNotification
)
from apps.users.seller_models import SellerProduct


# ==================== FACTORIES ====================

class AdminUserFactory:
    """Factory for creating admin users with different roles"""

    @staticmethod
    def create_super_admin(email='super_admin@opas.com', **kwargs):
        """Create a Super Admin user"""
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Super',
            'last_name': 'Admin',
            'role': UserRole.ADMIN,
            'password': 'secure_password_123'
        }
        user_data.update(kwargs)
        user = User.objects.create_user(**user_data)
        AdminUser.objects.create(user=user, admin_role=AdminRole.SUPER_ADMIN)
        return user

    @staticmethod
    def create_seller_manager(email='seller_manager@opas.com', **kwargs):
        """Create a Seller Manager admin"""
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Seller',
            'last_name': 'Manager',
            'role': UserRole.ADMIN,
            'password': 'secure_password_123'
        }
        user_data.update(kwargs)
        user = User.objects.create_user(**user_data)
        AdminUser.objects.create(user=user, admin_role=AdminRole.SELLER_MANAGER)
        return user

    @staticmethod
    def create_price_manager(email='price_manager@opas.com', **kwargs):
        """Create a Price Manager admin"""
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Price',
            'last_name': 'Manager',
            'role': UserRole.ADMIN,
            'password': 'secure_password_123'
        }
        user_data.update(kwargs)
        user = User.objects.create_user(**user_data)
        AdminUser.objects.create(user=user, admin_role=AdminRole.PRICE_MANAGER)
        return user

    @staticmethod
    def create_opas_manager(email='opas_manager@opas.com', **kwargs):
        """Create an OPAS Manager admin"""
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'OPAS',
            'last_name': 'Manager',
            'role': UserRole.ADMIN,
            'password': 'secure_password_123'
        }
        user_data.update(kwargs)
        user = User.objects.create_user(**user_data)
        AdminUser.objects.create(user=user, admin_role=AdminRole.OPAS_MANAGER)
        return user

    @staticmethod
    def create_analytics_manager(email='analytics_manager@opas.com', **kwargs):
        """Create an Analytics Manager admin (read-only)"""
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Analytics',
            'last_name': 'Manager',
            'role': UserRole.ADMIN,
            'password': 'secure_password_123'
        }
        user_data.update(kwargs)
        user = User.objects.create_user(**user_data)
        AdminUser.objects.create(user=user, admin_role=AdminRole.ANALYTICS_MANAGER)
        return user


class SellerFactory:
    """Factory for creating seller users with various states"""

    @staticmethod
    def create_pending_seller(email=None, business_name=None, contact_email=None, **kwargs):
        """Create a seller with PENDING status
        
        Args:
            email: Email for User account (auto-generated if not provided)
            business_name: Business name (stored separately, not in User model)
            contact_email: Contact email (stored separately, not in User model)
            **kwargs: Additional User model fields
        """
        # Generate unique username if not explicitly provided
        if email is None:
            unique_id = str(uuid.uuid4())[:8]
            email = f'seller_pending_{unique_id}@opas.com'
        
        # Extract non-User fields
        extra_data = {}
        if business_name is not None:
            extra_data['business_name'] = business_name
        if contact_email is not None:
            extra_data['contact_email'] = contact_email
        
        # Remove these from kwargs if present (they're not User model fields)
        kwargs.pop('business_name', None)
        kwargs.pop('contact_email', None)
        
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Pending',
            'last_name': 'Seller',
            'role': UserRole.SELLER,
            'seller_status': SellerStatus.PENDING,
            'password': 'password123'
        }
        user_data.update(kwargs)
        return User.objects.create_user(**user_data)

    @staticmethod
    def create_approved_seller(email=None, business_name=None, contact_email=None, **kwargs):
        """Create a seller with APPROVED status
        
        Args:
            email: Email for User account (auto-generated if not provided)
            business_name: Business name (stored separately, not in User model)
            contact_email: Contact email (stored separately, not in User model)
            **kwargs: Additional User model fields
        """
        # Generate unique username if not explicitly provided
        if email is None:
            unique_id = str(uuid.uuid4())[:8]
            email = f'seller_approved_{unique_id}@opas.com'
        
        # Extract non-User fields
        extra_data = {}
        if business_name is not None:
            extra_data['business_name'] = business_name
        if contact_email is not None:
            extra_data['contact_email'] = contact_email
        
        # Remove these from kwargs if present (they're not User model fields)
        kwargs.pop('business_name', None)
        kwargs.pop('contact_email', None)
        
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Approved',
            'last_name': 'Seller',
            'role': UserRole.SELLER,
            'seller_status': SellerStatus.APPROVED,
            'password': 'password123'
        }
        user_data.update(kwargs)
        return User.objects.create_user(**user_data)

    @staticmethod
    def create_suspended_seller(email=None, business_name=None, contact_email=None, **kwargs):
        """Create a seller with SUSPENDED status
        
        Args:
            email: Email for User account (auto-generated if not provided)
            business_name: Business name (stored separately, not in User model)
            contact_email: Contact email (stored separately, not in User model)
            **kwargs: Additional User model fields
        """
        # Generate unique username if not explicitly provided
        if email is None:
            unique_id = str(uuid.uuid4())[:8]
            email = f'seller_suspended_{unique_id}@opas.com'
        
        # Extract non-User fields
        extra_data = {}
        if business_name is not None:
            extra_data['business_name'] = business_name
        if contact_email is not None:
            extra_data['contact_email'] = contact_email
        
        # Remove these from kwargs if present (they're not User model fields)
        kwargs.pop('business_name', None)
        kwargs.pop('contact_email', None)
        
        user_data = {
            'username': email.split('@')[0] + '_' + str(uuid.uuid4())[:4],
            'email': email,
            'first_name': 'Suspended',
            'last_name': 'Seller',
            'role': UserRole.SELLER,
            'seller_status': SellerStatus.SUSPENDED,
            'password': 'password123'
        }
        user_data.update(kwargs)
        return User.objects.create_user(**user_data)


class DataFactory:
    """Factory for creating test data (products, prices, etc.)"""

    @staticmethod
    def create_seller_product(seller, name='Test Product', price=100.00, **kwargs):
        """Create a seller product"""
        product_data = {
            'seller': seller,
            'name': name,
            'description': 'Test product description',
            'price': price,
            'stock_level': 100,
            'product_type': 'vegetables',
            'unit': 'kg',
        }
        product_data.update(kwargs)
        return SellerProduct.objects.create(**product_data)

    @staticmethod
    def create_price_ceiling(product, ceiling_price=150.00, **kwargs):
        """Create a price ceiling"""
        ceiling_data = {
            'product': product,
            'ceiling_price': ceiling_price,
            'effective_from': datetime.now(),
        }
        ceiling_data.update(kwargs)
        return PriceCeiling.objects.create(**ceiling_data)

    @staticmethod
    def create_opas_inventory(product, quantity_received=50, **kwargs):
        """Create OPAS inventory"""
        inventory_data = {
            'product': product,
            'quantity_received': quantity_received,
            'quantity_on_hand': quantity_received,
            'storage_location': 'Storage A',
            'in_date': datetime.now(),
            'expiry_date': datetime.now() + timedelta(days=30),
        }
        inventory_data.update(kwargs)
        return OPASInventory.objects.create(**inventory_data)


# ==================== BASE TEST CLASSES ====================

class AdminAuthTestCase(APITestCase):
    """Base test case for admin authentication tests"""

    def setUp(self):
        """Set up test fixtures"""
        self.client = APIClient()

        # Create admin users with different roles
        self.super_admin = AdminUserFactory.create_super_admin()
        self.seller_manager = AdminUserFactory.create_seller_manager()
        self.price_manager = AdminUserFactory.create_price_manager()
        self.opas_manager = AdminUserFactory.create_opas_manager()
        self.analytics_manager = AdminUserFactory.create_analytics_manager()

        # Create seller users
        self.pending_seller = SellerFactory.create_pending_seller()
        self.approved_seller = SellerFactory.create_approved_seller()
        self.suspended_seller = SellerFactory.create_suspended_seller()

        # Create test products
        self.product_1 = DataFactory.create_seller_product(
            self.approved_seller,
            name='Tomatoes',
            price=50.00
        )
        self.product_2 = DataFactory.create_seller_product(
            self.approved_seller,
            name='Potatoes',
            price=30.00
        )

    def authenticate_user(self, user):
        """Authenticate a user for API requests"""
        token, _ = Token.objects.get_or_create(user=user)
        self.client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)

    def get_token(self, user):
        """Get token for a user"""
        token, _ = Token.objects.get_or_create(user=user)
        return token.key

    def logout(self):
        """Clear authentication"""
        self.client.credentials()


class AdminWorkflowTestCase(AdminAuthTestCase):
    """Base test case for workflow testing"""

    def assertWorkflowStep(self, obj, field, expected_value, step_name):
        """Helper to assert workflow progression"""
        obj.refresh_from_db()
        actual_value = getattr(obj, field)
        self.assertEqual(
            actual_value, 
            expected_value,
            f"Workflow step '{step_name}' failed: {field} = {actual_value}, expected {expected_value}"
        )

    def assertAuditLogCreated(self, action_type, admin_user, entity_type=None, entity_id=None):
        """Verify audit log entry was created
        
        Args:
            action_type: The action type to search for
            admin_user: Can be a User or AdminUser instance
            entity_type: Legacy parameter, ignored
            entity_id: Legacy parameter, ignored
        """
        # Handle both User and AdminUser instances
        if hasattr(admin_user, 'admin_profile'):
            # It's a User with admin_profile FK
            admin_obj = admin_user.admin_profile
        else:
            # Assume it's already an AdminUser
            admin_obj = admin_user
            
        audit_log = AdminAuditLog.objects.filter(
            action_type=action_type,
            admin=admin_obj
        ).first()
        self.assertIsNotNone(
            audit_log,
            f"Audit log not found for {action_type} by {admin_user}"
        )
        return audit_log


class AdminDataIntegrityTestCase(AdminAuthTestCase):
    """Base test case for data integrity testing"""

    def assertRecordExists(self, model_class, **filters):
        """Assert a record exists with given filters"""
        self.assertTrue(
            model_class.objects.filter(**filters).exists(),
            f"Record not found in {model_class.__name__} with filters: {filters}"
        )

    def assertRecordDoesNotExist(self, model_class, **filters):
        """Assert a record does not exist with given filters"""
        self.assertFalse(
            model_class.objects.filter(**filters).exists(),
            f"Record unexpectedly found in {model_class.__name__} with filters: {filters}"
        )

    def assertNoOrphanedRecords(self, parent_model, child_model, parent_field):
        """
        Assert no child records exist for deleted parent records.
        
        Example: No PriceHistory records reference deleted PriceCeiling
        """
        parent_ids = set(parent_model.objects.values_list('id', flat=True))
        child_records = child_model.objects.all()

        for child in child_records:
            parent_id = getattr(child, parent_field + '_id')
            self.assertIn(
                parent_id,
                parent_ids,
                f"Orphaned record found: {child_model.__name__}.{parent_field}_id = {parent_id}"
            )

    def assertAuditLogCompletnessFor(self, action, admin_user, entity_type):
        """Assert audit log contains expected entries"""
        audit_logs = AdminAuditLog.objects.filter(
            action_type=action,
            admin_user=admin_user,
            entity_type=entity_type
        )
        self.assertTrue(
            audit_logs.exists(),
            f"No audit logs found for {action} on {entity_type} by {admin_user.email}"
        )
        return audit_logs


# ==================== UTILITY HELPERS ====================

class AdminTestHelper:
    """Helper methods for admin testing"""

    @staticmethod
    def print_response_data(response):
        """Pretty print API response for debugging"""
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response Data: {response.data}")

    @staticmethod
    def assert_response_success(test_case, response, expected_status=200):
        """Assert API response is successful"""
        test_case.assertEqual(
            response.status_code,
            expected_status,
            f"Expected {expected_status}, got {response.status_code}. Response: {response.data}"
        )

    @staticmethod
    def assert_response_contains(response, key):
        """Assert response contains a specific key"""
        if isinstance(response.data, dict):
            assert key in response.data, f"Key '{key}' not found in response"
        else:
            raise AssertionError("Response is not a dictionary")


if __name__ == '__main__':
    print("Admin Test Fixtures and Base Classes")
    print("=" * 60)
    print("Use these classes as base classes for your test cases.")
    print("\nExample:")
    print("    class TestAdminAuth(AdminAuthTestCase):")
    print("        def test_super_admin_access(self):")
    print("            self.authenticate_user(self.super_admin)")
    print("            response = self.client.get('/api/admin/sellers/')")
    print("            self.assertEqual(response.status_code, 200)")

