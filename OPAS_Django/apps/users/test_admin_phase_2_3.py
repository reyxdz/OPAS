"""
Test suite for Phase 2.3 - Admin Model Methods & Custom Managers

Tests verify:
1. AdminUser methods and custom managers
2. SellerRegistrationRequest approve/reject methods
3. PriceCeiling compliance checking
4. OPASInventory low stock and expiring alerts
5. AdminAuditLog immutability
6. Custom QuerySet managers for all models
"""

from django.test import TestCase
from django.utils import timezone
from django.core.exceptions import ValidationError
from datetime import timedelta
from decimal import Decimal

from .models import User, UserRole, SellerStatus
from .admin_models import (
    AdminUser,
    AdminRole,
    SellerRegistrationRequest,
    SellerRegistrationStatus,
    SellerApprovalHistory,
    PriceCeiling,
    OPASInventory,
    AdminAuditLog,
    MarketplaceAlert,
    AlertSeverity,
)


class AdminUserModelMethodsTest(TestCase):
    """Test AdminUser model methods and manager"""
    
    def setUp(self):
        """Create test data"""
        # Create test users
        self.user1 = User.objects.create_user(
            username='super_admin',
            email='super_admin@opas.com',
            password='testpass123',
            first_name='Super',
            last_name='Admin',
            role=UserRole.OPAS_ADMIN
        )
        self.user2 = User.objects.create_user(
            username='seller_manager',
            email='seller_manager@opas.com',
            password='testpass123',
            first_name='Seller',
            last_name='Manager',
            role=UserRole.OPAS_ADMIN
        )
        self.user3 = User.objects.create_user(
            username='inactive_admin',
            email='inactive_admin@opas.com',
            password='testpass123',
            first_name='Inactive',
            last_name='Admin',
            role=UserRole.OPAS_ADMIN
        )
        
        # Create admin profiles
        self.super_admin = AdminUser.objects.create(
            user=self.user1,
            admin_role=AdminRole.SUPER_ADMIN,
            department='Executive'
        )
        self.seller_manager = AdminUser.objects.create(
            user=self.user2,
            admin_role=AdminRole.SELLER_MANAGER,
            department='Seller Onboarding'
        )
        self.inactive_admin = AdminUser.objects.create(
            user=self.user3,
            admin_role=AdminRole.SELLER_MANAGER,
            department='Seller Onboarding',
            is_active=False
        )
    
    def test_admin_user_str_method(self):
        """Test __str__ returns email + role"""
        expected = f"{self.user1.email} ({AdminRole.SUPER_ADMIN})"
        self.assertEqual(str(self.super_admin), expected)
    
    def test_get_permissions_super_admin(self):
        """Test super admin has all permissions"""
        permissions = self.super_admin.get_permissions()
        
        self.assertIn('view_all_data', permissions)
        self.assertIn('approve_sellers', permissions)
        self.assertIn('manage_prices', permissions)
        self.assertIn('manage_opas', permissions)
        self.assertIn('view_analytics', permissions)
        self.assertIn('manage_admins', permissions)
        self.assertIn('export_data', permissions)
    
    def test_get_permissions_seller_manager(self):
        """Test seller manager has correct permissions"""
        permissions = self.seller_manager.get_permissions()
        
        self.assertIn('approve_sellers', permissions)
        self.assertIn('suspend_sellers', permissions)
        self.assertIn('view_seller_data', permissions)
    
    def test_admin_role_permissions(self):
        """Test role-based permission methods"""
        self.assertTrue(self.super_admin.can_approve_sellers())
        self.assertTrue(self.super_admin.can_manage_prices())
        self.assertTrue(self.super_admin.can_manage_opas())
        self.assertTrue(self.super_admin.can_view_analytics())
        
        self.assertTrue(self.seller_manager.can_approve_sellers())
        self.assertFalse(self.seller_manager.can_manage_prices())
    
    def test_admin_user_manager_active(self):
        """Test AdminUserManager.active() returns only active admins"""
        active_admins = AdminUser.objects.active()
        
        self.assertEqual(active_admins.count(), 2)
        self.assertIn(self.super_admin, active_admins)
        self.assertIn(self.seller_manager, active_admins)
        self.assertNotIn(self.inactive_admin, active_admins)
    
    def test_admin_user_manager_super_admins(self):
        """Test AdminUserManager.super_admins() returns only super admins"""
        super_admins = AdminUser.objects.super_admins()
        
        self.assertEqual(super_admins.count(), 1)
        self.assertIn(self.super_admin, super_admins)
        self.assertNotIn(self.seller_manager, super_admins)
    
    def test_admin_user_manager_by_role(self):
        """Test AdminUserManager.by_role() filters by role"""
        managers = AdminUser.objects.by_role(AdminRole.SELLER_MANAGER)
        
        self.assertEqual(managers.count(), 2)  # Both active and inactive
        self.assertIn(self.seller_manager, managers)
        self.assertIn(self.inactive_admin, managers)
    
    def test_update_last_activity(self):
        """Test update_last_activity() updates timestamp"""
        original_activity = self.super_admin.last_activity
        
        self.super_admin.update_last_activity()
        
        self.assertIsNotNone(self.super_admin.last_activity)
        self.assertGreater(self.super_admin.last_activity, original_activity or timezone.now() - timedelta(seconds=1))


class SellerRegistrationApproveRejectTest(TestCase):
    """Test SellerRegistrationRequest approve() and reject() methods"""
    
    def setUp(self):
        """Create test data"""
        # Create admin
        admin_user = User.objects.create_user(
            username='admin',
            email='admin@opas.com',
            password='testpass123',
            first_name='Admin',
            last_name='User',
            role=UserRole.OPAS_ADMIN
        )
        self.admin = AdminUser.objects.create(
            user=admin_user,
            admin_role=AdminRole.SELLER_MANAGER
        )
        
        # Create seller
        seller_user = User.objects.create_user(
            username='seller',
            email='seller@farm.com',
            password='testpass123',
            first_name='John',
            last_name='Farmer',
            role=UserRole.SELLER,
            seller_status=SellerStatus.PENDING
        )
        
        # Create registration request
        self.registration = SellerRegistrationRequest.objects.create(
            seller=seller_user,
            farm_name='John\'s Farm',
            farm_location='Bulacan',
            store_name='John\'s Organic Vegetables',
            store_description='Fresh organic vegetables'
        )
    
    def test_approve_seller_registration(self):
        """Test approve() method updates status and creates history"""
        self.assertEqual(self.registration.status, SellerRegistrationStatus.PENDING)
        
        self.registration.approve(self.admin, "All documents verified")
        
        # Refresh from database
        self.registration.refresh_from_db()
        self.seller = self.registration.seller
        self.seller.refresh_from_db()
        
        # Check status updated
        self.assertEqual(self.registration.status, SellerRegistrationStatus.APPROVED)
        self.assertIsNotNone(self.registration.approved_at)
        self.assertIsNotNone(self.registration.reviewed_at)
        
        # Check seller updated
        self.assertEqual(self.seller.seller_status, SellerStatus.APPROVED)
        self.assertTrue(self.seller.is_seller_approved)
        
        # Check history created
        history = SellerApprovalHistory.objects.filter(seller=self.seller).first()
        self.assertIsNotNone(history)
        self.assertEqual(history.decision, 'APPROVED')
        self.assertEqual(history.admin, self.admin)
        
        # Check audit log created
        audit = AdminAuditLog.objects.filter(
            affected_seller=self.seller,
            action_type='SELLER_APPROVED'
        ).first()
        self.assertIsNotNone(audit)
    
    def test_reject_seller_registration(self):
        """Test reject() method updates status and creates history"""
        self.registration.reject(
            self.admin,
            "Tax ID document is invalid",
            "Document appears to be expired"
        )
        
        # Refresh from database
        self.registration.refresh_from_db()
        self.seller = self.registration.seller
        self.seller.refresh_from_db()
        
        # Check status updated
        self.assertEqual(self.registration.status, SellerRegistrationStatus.REJECTED)
        self.assertEqual(self.registration.rejection_reason, "Tax ID document is invalid")
        self.assertIsNotNone(self.registration.rejected_at)
        
        # Check seller updated
        self.assertEqual(self.seller.seller_status, SellerStatus.REJECTED)
        self.assertFalse(self.seller.is_seller_approved)
        
        # Check history created
        history = SellerApprovalHistory.objects.filter(seller=self.seller).first()
        self.assertIsNotNone(history)
        self.assertEqual(history.decision, 'REJECTED')
        self.assertEqual(history.decision_reason, "Tax ID document is invalid")
    
    def test_cannot_approve_already_approved(self):
        """Test cannot approve already approved registration"""
        self.registration.approve(self.admin)
        
        with self.assertRaises(ValidationError):
            self.registration.approve(self.admin)
    
    def test_cannot_reject_already_rejected(self):
        """Test cannot reject already rejected registration"""
        self.registration.reject(self.admin, "Invalid documents")
        
        with self.assertRaises(ValidationError):
            self.registration.reject(self.admin, "Another reason")
    
    def test_cannot_approve_rejected(self):
        """Test cannot approve a rejected registration"""
        self.registration.reject(self.admin, "Invalid")
        
        with self.assertRaises(ValidationError):
            self.registration.approve(self.admin)


class PriceCeilingComplianceTest(TestCase):
    """Test PriceCeiling.check_compliance() method"""
    
    def setUp(self):
        """Create test data"""
        # Create seller and product (minimum needed)
        seller = User.objects.create_user(
            username='seller_price',
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        
        # Create product - NOTE: SellerProduct model needs to be imported
        # For now, we'll use a mock approach in the test
        from django.db import models as django_models
        
        # Create a minimal product instance
        from apps.sellers.models import SellerProduct
        self.product = SellerProduct.objects.create(
            seller=seller,
            name='Tomatoes',
            category='Vegetables',
            price=Decimal('100.00')
        )
        
        # Create price ceiling
        self.ceiling = PriceCeiling.objects.create(
            product=self.product,
            ceiling_price=Decimal('120.00')
        )
    
    def test_compliant_price(self):
        """Test check_compliance with compliant price"""
        result = self.ceiling.check_compliance(100.00)
        
        self.assertTrue(result['is_compliant'])
        self.assertEqual(result['listed_price'], 100.00)
        self.assertEqual(result['ceiling_price'], 120.00)
        self.assertEqual(result['overage_amount'], 0.0)
        self.assertEqual(result['overage_percentage'], 0.0)
        self.assertEqual(result['status'], 'COMPLIANT')
    
    def test_non_compliant_price(self):
        """Test check_compliance with non-compliant price"""
        result = self.ceiling.check_compliance(150.00)
        
        self.assertFalse(result['is_compliant'])
        self.assertEqual(result['listed_price'], 150.00)
        self.assertEqual(result['ceiling_price'], 120.00)
        self.assertEqual(result['overage_amount'], 30.0)
        self.assertEqual(result['overage_percentage'], 25.0)
        self.assertEqual(result['status'], 'NON_COMPLIANT')
    
    def test_exact_ceiling_price(self):
        """Test check_compliance with exact ceiling price"""
        result = self.ceiling.check_compliance(120.00)
        
        self.assertTrue(result['is_compliant'])
        self.assertEqual(result['overage_amount'], 0.0)


class OPASInventoryStockAlertTest(TestCase):
    """Test OPASInventory.is_low_stock() and is_expiring() methods"""
    
    def setUp(self):
        """Create test data"""
        # Create product
        from apps.sellers.models import SellerProduct
        seller = User.objects.create_user(
            username='seller_inv1',
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        self.product = SellerProduct.objects.create(
            seller=seller,
            name='Rice',
            category='Grains',
            price=Decimal('50.00')
        )
        
        # Create inventory with low stock threshold
        now = timezone.now()
        self.inventory = OPASInventory.objects.create(
            product=self.product,
            quantity_received=100,
            quantity_on_hand=50,
            in_date=now - timedelta(days=10),
            expiry_date=now + timedelta(days=30),
            low_stock_threshold=50
        )
    
    def test_is_low_stock_true(self):
        """Test check_is_low_stock() returns True at threshold"""
        self.assertTrue(self.inventory.check_is_low_stock())
    
    def test_is_low_stock_false(self):
        """Test check_is_low_stock() returns False above threshold"""
        self.inventory.quantity_on_hand = 100
        self.assertFalse(self.inventory.check_is_low_stock())
    
    def test_is_expiring_true(self):
        """Test check_is_expiring() returns True within 7 days"""
        now = timezone.now()
        self.inventory.expiry_date = now + timedelta(days=3)
        self.assertTrue(self.inventory.check_is_expiring())
    
    def test_is_expiring_false(self):
        """Test check_is_expiring() returns False after 7 days"""
        now = timezone.now()
        self.inventory.expiry_date = now + timedelta(days=10)
        self.assertFalse(self.inventory.check_is_expiring())
    
    def test_is_expiring_on_boundary(self):
        """Test check_is_expiring() on exact 7-day boundary"""
        now = timezone.now()
        self.inventory.expiry_date = now + timedelta(days=7)
        self.assertTrue(self.inventory.check_is_expiring())


class OPASInventoryManagerTest(TestCase):
    """Test OPASInventory custom manager methods"""
    
    def setUp(self):
        """Create test data"""
        from apps.sellers.models import SellerProduct
        seller = User.objects.create_user(
            username='seller_inv2',
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        
        now = timezone.now()
        
        # Create multiple inventories
        product1 = SellerProduct.objects.create(
            seller=seller,
            name='Rice',
            category='Grains',
            price=Decimal('50.00')
        )
        product2 = SellerProduct.objects.create(
            seller=seller,
            name='Corn',
            category='Grains',
            price=Decimal('45.00')
        )
        product3 = SellerProduct.objects.create(
            seller=seller,
            name='Tomatoes',
            category='Vegetables',
            price=Decimal('80.00')
        )
        
        # Low stock inventory
        self.low_stock = OPASInventory.objects.create(
            product=product1,
            quantity_received=50,
            quantity_on_hand=5,
            in_date=now - timedelta(days=5),
            expiry_date=now + timedelta(days=30),
            low_stock_threshold=10,
            is_low_stock=True
        )
        
        # Expiring inventory
        self.expiring = OPASInventory.objects.create(
            product=product2,
            quantity_received=100,
            quantity_on_hand=80,
            in_date=now - timedelta(days=10),
            expiry_date=now + timedelta(days=3),
            low_stock_threshold=5,
            is_expiring=True
        )
        
        # Normal inventory
        self.normal = OPASInventory.objects.create(
            product=product3,
            quantity_received=200,
            quantity_on_hand=150,
            in_date=now - timedelta(days=2),
            expiry_date=now + timedelta(days=60),
            low_stock_threshold=10
        )
    
    def test_low_stock_manager(self):
        """Test OPASInventory.objects.low_stock()"""
        low_stock_items = OPASInventory.objects.low_stock()
        
        self.assertIn(self.low_stock, low_stock_items)
        self.assertNotIn(self.normal, low_stock_items)
    
    def test_expiring_soon_manager(self):
        """Test OPASInventory.objects.expiring_soon()"""
        expiring_items = OPASInventory.objects.expiring_soon()
        
        self.assertIn(self.expiring, expiring_items)
        self.assertNotIn(self.normal, expiring_items)
    
    def test_by_location_manager(self):
        """Test OPASInventory.objects.by_location()"""
        self.low_stock.storage_location = "Warehouse A"
        self.low_stock.save()
        
        self.expiring.storage_location = "Warehouse B"
        self.expiring.save()
        
        warehouse_a_stock = OPASInventory.objects.by_location("Warehouse A")
        
        self.assertIn(self.low_stock, warehouse_a_stock)
        self.assertNotIn(self.expiring, warehouse_a_stock)


class AdminAuditLogImmutabilityTest(TestCase):
    """Test AdminAuditLog immutability and __str__ method"""
    
    def setUp(self):
        """Create test data"""
        admin_user = User.objects.create_user(
            email='admin@opas.com',
            password='testpass123',
            role=UserRole.OPAS_ADMIN
        )
        self.admin = AdminUser.objects.create(
            user=admin_user,
            admin_role=AdminRole.SELLER_MANAGER
        )
        
        seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER,
            full_name='John Farmer'
        )
        
        self.audit = AdminAuditLog.objects.create(
            admin=self.admin,
            action_type='SELLER_APPROVED',
            action_category='SELLER_APPROVAL',
            affected_seller=seller,
            description='Seller approved'
        )
    
    def test_audit_log_str_method(self):
        """Test __str__ returns formatted audit log"""
        result = str(self.audit)
        
        self.assertIn('Audit:', result)
        self.assertIn('SELLER_APPROVED', result)
        self.assertIn('admin@opas.com', result)
        self.assertIn('@', result)  # Timestamp separator
    
    def test_cannot_update_audit_log(self):
        """Test that audit logs cannot be updated"""
        self.audit.description = "Updated description"
        
        with self.assertRaises(ValidationError):
            self.audit.save()
    
    def test_cannot_delete_audit_log(self):
        """Test that audit logs cannot be deleted"""
        with self.assertRaises(ValidationError):
            self.audit.delete()


class SellerRegistrationManagerTest(TestCase):
    """Test SellerRegistrationRequest custom manager methods"""
    
    def setUp(self):
        """Create test data"""
        seller = User.objects.create_user(
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        
        now = timezone.now()
        
        # Pending registration
        self.pending = SellerRegistrationRequest.objects.create(
            seller=seller,
            farm_name='Farm 1',
            farm_location='Location 1',
            store_name='Store 1',
            store_description='Description 1',
            status=SellerRegistrationStatus.PENDING
        )
        
        # Awaiting review registration
        seller2 = User.objects.create_user(
            email='seller2@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        self.awaiting_review = SellerRegistrationRequest.objects.create(
            seller=seller2,
            farm_name='Farm 2',
            farm_location='Location 2',
            store_name='Store 2',
            store_description='Description 2',
            status=SellerRegistrationStatus.REQUEST_MORE_INFO
        )
        
        # Approved registration
        seller3 = User.objects.create_user(
            email='seller3@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        self.approved = SellerRegistrationRequest.objects.create(
            seller=seller3,
            farm_name='Farm 3',
            farm_location='Location 3',
            store_name='Store 3',
            store_description='Description 3',
            status=SellerRegistrationStatus.APPROVED,
            approved_at=now
        )
    
    def test_pending_manager(self):
        """Test SellerRegistrationRequest.objects.pending()"""
        pending = SellerRegistrationRequest.objects.pending()
        
        self.assertIn(self.pending, pending)
        self.assertNotIn(self.awaiting_review, pending)
        self.assertNotIn(self.approved, pending)
    
    def test_awaiting_review_manager(self):
        """Test SellerRegistrationRequest.objects.awaiting_review()"""
        awaiting = SellerRegistrationRequest.objects.awaiting_review()
        
        self.assertIn(self.pending, awaiting)
        self.assertIn(self.awaiting_review, awaiting)
        self.assertNotIn(self.approved, awaiting)
    
    def test_recent_manager(self):
        """Test SellerRegistrationRequest.objects.recent()"""
        recent = SellerRegistrationRequest.objects.recent(days=1)
        
        # All registrations created just now should be in recent
        self.assertIn(self.pending, recent)
        self.assertIn(self.approved, recent)


class MarketplaceAlertManagerTest(TestCase):
    """Test MarketplaceAlert custom manager methods"""
    
    def setUp(self):
        """Create test data"""
        from apps.sellers.models import SellerProduct
        
        seller = User.objects.create_user(
            username='seller_alert',
            email='seller@farm.com',
            password='testpass123',
            role=UserRole.SELLER
        )
        
        product = SellerProduct.objects.create(
            seller=seller,
            name='Test Product',
            category='Test',
            price=Decimal('100.00')
        )
        
        # Open critical alert
        self.critical_open = MarketplaceAlert.objects.create(
            title='Price Violation',
            description='Seller price exceeds ceiling by 50%',
            alert_type='PRICE_VIOLATION',
            severity=AlertSeverity.CRITICAL,
            affected_seller=seller,
            affected_product=product,
            status='OPEN'
        )
        
        # Open warning alert
        self.warning_open = MarketplaceAlert.objects.create(
            title='Low Stock',
            description='Product stock is low',
            alert_type='INVENTORY_ALERT',
            severity=AlertSeverity.WARNING,
            affected_seller=seller,
            affected_product=product,
            status='OPEN'
        )
        
        # Resolved alert
        self.resolved = MarketplaceAlert.objects.create(
            title='Issue Resolved',
            description='Previously flagged issue',
            alert_type='SELLER_ISSUE',
            severity=AlertSeverity.WARNING,
            affected_seller=seller,
            affected_product=product,
            status='RESOLVED'
        )
    
    def test_open_alerts_manager(self):
        """Test MarketplaceAlert.objects.open_alerts()"""
        open_alerts = MarketplaceAlert.objects.open_alerts()
        
        self.assertIn(self.critical_open, open_alerts)
        self.assertIn(self.warning_open, open_alerts)
        self.assertNotIn(self.resolved, open_alerts)
    
    def test_critical_alerts_manager(self):
        """Test MarketplaceAlert.objects.critical()"""
        critical = MarketplaceAlert.objects.critical()
        
        self.assertIn(self.critical_open, critical)
        self.assertNotIn(self.warning_open, critical)
        self.assertNotIn(self.resolved, critical)
    
    def test_recent_alerts_manager(self):
        """Test MarketplaceAlert.objects.recent()"""
        recent = MarketplaceAlert.objects.recent(days=1)
        
        # All alerts created just now should be in recent
        self.assertIn(self.critical_open, recent)
        self.assertIn(self.warning_open, recent)
        self.assertIn(self.resolved, recent)
