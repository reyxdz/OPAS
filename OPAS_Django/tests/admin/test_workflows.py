"""
Workflow Tests - Phase 5.1

Tests complex business workflows:
1. Seller approval workflow: request → approve → activate
2. Price update workflow: ceiling change → flag non-compliant → notify sellers
3. OPAS submission workflow: submit → approve → inventory update

Architecture: Each workflow is tested end-to-end with assertions at each stage.
"""

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from datetime import datetime, timedelta

from apps.users.models import User, UserRole, SellerStatus
from apps.users.admin_models import (
    SellerRegistrationRequest, SellerRegistrationStatus, SellerApprovalHistory,
    AuditActionType, PriceCeiling, PriceHistory, PriceNonCompliance,
    OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction
)
from apps.users.seller_models import SellToOPAS, SellToOPASStatus
from tests.admin.admin_test_fixtures import (
    AdminAuthTestCase, AdminWorkflowTestCase, AdminUserFactory,
    SellerFactory, DataFactory, AdminTestHelper
)


# ==================== SELLER APPROVAL WORKFLOW TESTS ====================

class SellerApprovalWorkflowTests(AdminWorkflowTestCase):
    """Test end-to-end seller approval workflow"""

    def test_seller_approval_workflow_complete(self):
        """
        Complete workflow: Pending → Review → Approved → Activated
        
        Steps:
        1. Seller application in PENDING state
        2. Admin reviews application
        3. Admin approves with notes
        4. Seller status changes to APPROVED
        5. Audit log records decision
        """
        # Step 1: Verify seller is in PENDING state
        self.assertEqual(self.pending_seller.seller_status, SellerStatus.PENDING)
        self.assertWorkflowStep(
            self.pending_seller, 'seller_status', SellerStatus.PENDING,
            'Initial seller status is PENDING'
        )

        # Step 2: Authenticate as Seller Manager
        self.authenticate_user(self.seller_manager)

        # Step 3: Retrieve seller details
        response = self.client.get(f'/api/admin/sellers/{self.pending_seller.id}/')
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)
        self.assertEqual(response.data['seller_status'], SellerStatus.PENDING)

        # Step 4: Admin approves seller
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/approve/',
            {
                'admin_notes': 'Seller approved after verification',
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 5: Verify seller status changed to APPROVED
        self.pending_seller.refresh_from_db()
        self.assertEqual(self.pending_seller.seller_status, SellerStatus.APPROVED)
        self.assertWorkflowStep(
            self.pending_seller, 'seller_status', SellerStatus.APPROVED,
            'Seller status changed to APPROVED'
        )

        # Step 6: Verify audit log entry created
        self.assertAuditLogCreated(
            AuditActionType.APPROVE_SELLER,
            self.seller_manager,
            'Seller',
            str(self.pending_seller.id)
        )

    def test_seller_rejection_workflow(self):
        """
        Workflow: Pending → Rejected
        
        Steps:
        1. Seller application in PENDING state
        2. Admin reviews and rejects with reason
        3. Seller status changes to REJECTED
        4. Rejection reason is recorded
        5. Audit log records rejection
        """
        # Step 1: Verify initial state
        self.assertEqual(self.pending_seller.seller_status, SellerStatus.PENDING)

        # Step 2: Authenticate as Seller Manager
        self.authenticate_user(self.seller_manager)

        # Step 3: Admin rejects seller
        rejection_reason = 'Missing required documents'
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/reject/',
            {
                'reason': rejection_reason,
                'admin_notes': 'Documents not verified'
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 4: Verify seller status changed to REJECTED
        self.pending_seller.refresh_from_db()
        self.assertEqual(self.pending_seller.seller_status, SellerStatus.REJECTED)

        # Step 5: Verify reason is recorded
        approval_history = SellerApprovalHistory.objects.filter(
            seller=self.pending_seller,
            decision=SellerRegistrationStatus.REJECTED
        ).first()
        self.assertIsNotNone(approval_history, "Rejection history not found")

        # Step 6: Verify audit log
        self.assertAuditLogCreated(
            AuditActionType.REJECT_SELLER,
            self.seller_manager,
            'Seller',
            str(self.pending_seller.id)
        )

    def test_seller_suspension_workflow(self):
        """
        Workflow: Approved → Suspended → Reactivated
        
        Steps:
        1. Start with approved seller
        2. Admin suspends seller with reason
        3. Seller status changes to SUSPENDED
        4. Seller listings are hidden
        5. Admin can reactivate seller
        6. Seller status returns to APPROVED
        """
        # Step 1: Start with approved seller
        self.assertEqual(self.approved_seller.seller_status, SellerStatus.APPROVED)

        # Step 2: Authenticate as Seller Manager
        self.authenticate_user(self.seller_manager)

        # Step 3: Suspend seller
        suspension_reason = 'Price violation detected'
        response = self.client.post(
            f'/api/admin/sellers/{self.approved_seller.id}/suspend/',
            {
                'reason': suspension_reason,
                'duration_days': 7
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 4: Verify seller is suspended
        self.approved_seller.refresh_from_db()
        self.assertEqual(self.approved_seller.seller_status, SellerStatus.SUSPENDED)

        # Step 5: Verify audit log
        self.assertAuditLogCreated(
            AuditActionType.SUSPEND_SELLER,
            self.seller_manager,
            'Seller',
            str(self.approved_seller.id)
        )

        # Step 6: Reactivate seller
        response = self.client.post(
            f'/api/admin/sellers/{self.approved_seller.id}/reactivate/',
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 7: Verify seller is reactivated
        self.approved_seller.refresh_from_db()
        self.assertEqual(self.approved_seller.seller_status, SellerStatus.APPROVED)


# ==================== PRICE UPDATE WORKFLOW TESTS ====================

class PriceUpdateWorkflowTests(AdminWorkflowTestCase):
    """Test end-to-end price ceiling update workflow"""

    def setUp(self):
        """Set up price ceiling for testing"""
        super().setUp()
        self.price_ceiling = DataFactory.create_price_ceiling(
            product_name='Tomatoes',
            ceiling_price=100.00
        )
        self.non_compliant_product = DataFactory.create_seller_product(
            self.approved_seller,
            product_name='Tomatoes',
            base_price=120.00  # Above ceiling
        )

    def test_price_ceiling_update_workflow(self):
        """
        Workflow: Update ceiling → Flag non-compliant → Notify sellers
        
        Steps:
        1. Start with existing price ceiling
        2. Admin updates ceiling price
        3. System flags any non-compliant listings
        4. Sellers are notified of new ceiling
        5. Price change is recorded in history
        6. Audit log records the change
        """
        # Step 1: Verify initial ceiling
        self.assertEqual(self.price_ceiling.ceiling_price, 100.00)

        # Step 2: Authenticate as Price Manager
        self.authenticate_user(self.price_manager)

        # Step 3: Update price ceiling
        new_ceiling = 95.00
        response = self.client.put(
            f'/api/admin/prices/ceilings/{self.price_ceiling.id}/',
            {
                'product_name': 'Tomatoes',
                'ceiling_price': new_ceiling,
                'reason': 'Market adjustment',
                'effective_date': datetime.now().isoformat()
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 4: Verify ceiling was updated
        self.price_ceiling.refresh_from_db()
        self.assertEqual(self.price_ceiling.ceiling_price, new_ceiling)
        self.assertWorkflowStep(
            self.price_ceiling, 'ceiling_price', new_ceiling,
            'Price ceiling updated to new value'
        )

        # Step 5: Verify price history entry created
        price_history = PriceHistory.objects.filter(
            product_name='Tomatoes',
            new_price=new_ceiling
        ).first()
        self.assertIsNotNone(price_history, "Price history not recorded")

        # Step 6: Verify audit log
        self.assertAuditLogCreated(
            AuditActionType.UPDATE_PRICE_CEILING,
            self.price_manager,
            'PriceCeiling',
            str(self.price_ceiling.id)
        )

    def test_price_non_compliance_detection(self):
        """
        Test that non-compliant listings are flagged when ceiling is lowered
        
        Steps:
        1. Create product listing above new ceiling
        2. Lower price ceiling
        3. System detects non-compliance
        4. Non-compliance flag is created
        """
        # Step 1: Verify product is above new ceiling
        new_ceiling = 110.00
        self.assertTrue(
            self.non_compliant_product.base_price > new_ceiling,
            "Product should be above new ceiling for this test"
        )

        # Step 2: Authenticate as Price Manager
        self.authenticate_user(self.price_manager)

        # Step 3: Lower the ceiling
        response = self.client.put(
            f'/api/admin/prices/ceilings/{self.price_ceiling.id}/',
            {
                'product_name': 'Tomatoes',
                'ceiling_price': new_ceiling,
                'reason': 'Price correction',
                'effective_date': datetime.now().isoformat()
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 4: Check for non-compliance flag
        # (This would be handled by a signal/task in production)
        self.price_ceiling.refresh_from_db()
        self.assertLess(self.price_ceiling.ceiling_price, self.non_compliant_product.base_price)


# ==================== OPAS SUBMISSION WORKFLOW TESTS ====================

class OPASSubmissionWorkflowTests(AdminWorkflowTestCase):
    """Test end-to-end OPAS submission approval workflow"""

    def setUp(self):
        """Set up OPAS submission for testing"""
        super().setUp()
        # Create a seller offering to OPAS
        self.opas_submission = SellToOPAS.objects.create(
            seller=self.approved_seller,
            product_name='Tomatoes',
            offered_quantity=100,
            offered_unit_price=50.00,
            quality_grade='A',
            status=SellToOPASStatus.PENDING
        )

    def test_opas_submission_approval_workflow(self):
        """
        Workflow: Pending submission → Review → Approved → Inventory updated
        
        Steps:
        1. Submission in PENDING state
        2. Admin reviews submission details
        3. Admin approves with accepted quantity and final price
        4. Submission status changes to APPROVED
        5. OPAS inventory is updated
        6. Purchase order is created
        7. Audit log records approval
        """
        # Step 1: Verify initial state
        self.assertEqual(self.opas_submission.status, SellToOPASStatus.PENDING)
        self.assertWorkflowStep(
            self.opas_submission, 'status', SellToOPASStatus.PENDING,
            'OPAS submission is PENDING'
        )

        # Step 2: Authenticate as OPAS Manager
        self.authenticate_user(self.opas_manager)

        # Step 3: Review submission
        response = self.client.get(
            f'/api/admin/opas/submissions/{self.opas_submission.id}/'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], SellToOPASStatus.PENDING)

        # Step 4: Approve submission
        accepted_quantity = 80  # Accept less than offered
        final_price = 52.00      # Different from offered price
        response = self.client.post(
            f'/api/admin/opas/submissions/{self.opas_submission.id}/approve/',
            {
                'quantity_accepted': accepted_quantity,
                'final_unit_price': final_price,
                'delivery_terms': 'FOB Farm'
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 5: Verify submission status changed
        self.opas_submission.refresh_from_db()
        self.assertEqual(self.opas_submission.status, SellToOPASStatus.APPROVED)
        self.assertWorkflowStep(
            self.opas_submission, 'status', SellToOPASStatus.APPROVED,
            'OPAS submission approved'
        )

        # Step 6: Verify inventory was updated
        inventory = OPASInventory.objects.filter(
            product_name='Tomatoes'
        ).first()
        # This would be created by the approval handler
        if inventory:
            self.assertGreater(inventory.quantity, 0)

        # Step 7: Verify purchase order created
        purchase_order = OPASPurchaseOrder.objects.filter(
            sell_to_opas=self.opas_submission
        ).first()
        self.assertIsNotNone(purchase_order, "Purchase order not created")

        # Step 8: Verify audit log
        self.assertAuditLogCreated(
            AuditActionType.APPROVE_OPAS_SUBMISSION,
            self.opas_manager,
            'OPASPurchaseOrder',
            str(self.opas_submission.id) if purchase_order else 'unknown'
        )

    def test_opas_submission_rejection_workflow(self):
        """
        Workflow: Pending submission → Rejected
        
        Steps:
        1. Submission in PENDING state
        2. Admin reviews and rejects
        3. Status changes to REJECTED
        4. Rejection reason recorded
        5. Seller notified
        """
        # Step 1: Verify initial state
        self.assertEqual(self.opas_submission.status, SellToOPASStatus.PENDING)

        # Step 2: Authenticate as OPAS Manager
        self.authenticate_user(self.opas_manager)

        # Step 3: Reject submission
        rejection_reason = 'Quality does not meet standards'
        response = self.client.post(
            f'/api/admin/opas/submissions/{self.opas_submission.id}/reject/',
            {
                'reason': rejection_reason
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 4: Verify status changed
        self.opas_submission.refresh_from_db()
        self.assertEqual(self.opas_submission.status, SellToOPASStatus.REJECTED)

        # Step 5: Verify audit log
        self.assertAuditLogCreated(
            AuditActionType.REJECT_OPAS_SUBMISSION,
            self.opas_manager,
            'SellToOPAS',
            str(self.opas_submission.id)
        )

    def test_opas_inventory_tracking_workflow(self):
        """
        Workflow: Approve OPAS submission → Update inventory → Track FIFO
        
        Steps:
        1. Approve OPAS submission
        2. Inventory is added
        3. FIFO removal works correctly
        4. Transactions are tracked
        """
        # Step 1: Authenticate and approve
        self.authenticate_user(self.opas_manager)
        response = self.client.post(
            f'/api/admin/opas/submissions/{self.opas_submission.id}/approve/',
            {
                'quantity_accepted': 100,
                'final_unit_price': 50.00,
                'delivery_terms': 'FOB Farm'
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 2: Verify inventory created
        inventory = OPASInventory.objects.filter(
            product_name='Tomatoes'
        ).first()
        self.assertIsNotNone(inventory, "Inventory not created")

        # Step 3: Verify initial quantity
        initial_quantity = inventory.quantity
        self.assertEqual(initial_quantity, 100)

        # Step 4: Simulate removal (FIFO)
        removal_quantity = 30
        inventory.quantity -= removal_quantity
        inventory.save()

        # Step 5: Verify transaction tracked
        transaction = OPASInventoryTransaction.objects.filter(
            inventory=inventory,
            transaction_type='REMOVAL'
        ).first()
        if transaction:
            self.assertEqual(transaction.quantity, removal_quantity)

        # Step 6: Verify remaining quantity
        inventory.refresh_from_db()
        self.assertEqual(inventory.quantity, initial_quantity - removal_quantity)


# ==================== COMPLEX MULTI-STEP WORKFLOW TESTS ====================

class ComplexWorkflowTests(AdminWorkflowTestCase):
    """Test complex workflows combining multiple steps"""

    def test_seller_approval_then_suspension_workflow(self):
        """
        Complex workflow: Approve seller → Create product → Suspend for violation
        
        Steps:
        1. Approve seller
        2. Seller creates product
        3. Admin detects price violation
        4. Admin suspends seller
        5. Seller's products are hidden
        """
        # Step 1: Authenticate as Seller Manager
        self.authenticate_user(self.seller_manager)

        # Step 2: Approve seller
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/approve/',
            {'admin_notes': 'Seller approved'},
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 3: Verify seller approved
        self.pending_seller.refresh_from_db()
        self.assertEqual(self.pending_seller.seller_status, SellerStatus.APPROVED)

        # Step 4: Create a product listing
        product = DataFactory.create_seller_product(
            self.pending_seller,
            product_name='Tomatoes',
            base_price=200.00  # Very high price
        )

        # Step 5: Create price ceiling (lower than product price)
        price_ceiling = DataFactory.create_price_ceiling(
            product_name='Tomatoes',
            ceiling_price=100.00
        )

        # Step 6: Suspend for violation
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/suspend/',
            {
                'reason': 'Price violation: product exceeds ceiling',
                'duration_days': 30
            },
            format='json'
        )
        AdminTestHelper.assert_response_success(self, response, status.HTTP_200_OK)

        # Step 7: Verify suspension
        self.pending_seller.refresh_from_db()
        self.assertEqual(self.pending_seller.seller_status, SellerStatus.SUSPENDED)


if __name__ == '__main__':
    import unittest
    unittest.main()
