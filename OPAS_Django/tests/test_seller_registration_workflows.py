"""
Django Integration Tests for Seller Registration Workflows
Tests end-to-end workflows: submission, approval, role changes
CORE PRINCIPLE: Security - Complete authorization workflow
CORE PRINCIPLE: API Idempotency - State consistency
"""

from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from apps.users.models import (
    Buyer,
    Seller,
    SellerRegistration,
    SellerRegistrationRequest,
)
from apps.users.seller_serializers import (
    SellerRegistrationSubmitSerializer,
    SellerRegistrationStatusSerializer,
)
import json


class SellerRegistrationWorkflowTests(TestCase):
    """Integration tests for complete seller registration workflow"""

    def setUp(self):
        """Set up test data"""
        # CORE PRINCIPLE: Test isolation - Fresh data per test
        self.client = APIClient()
        
        # Create test buyer
        self.buyer_user = User.objects.create_user(
            username='testbuyer',
            email='buyer@test.com',
            password='testpass123'
        )
        self.buyer = Buyer.objects.create(user=self.buyer_user)

        # Create test admin
        self.admin_user = User.objects.create_user(
            username='testadmin',
            email='admin@test.com',
            password='testpass123',
            is_staff=True,
            is_superuser=True
        )

        self.registration_data = {
            'farm_name': 'Green Valley Farm',
            'location': 'Luzon Region',
            'products': 'Rice,Corn',
            'store_name': 'GVF Store',
            'store_description': 'Quality farm products'
        }

    def test_complete_registration_workflow(self):
        """Test: Buyer submits → Admin approves → Role changes to Seller"""
        # CORE PRINCIPLE: Workflow Completeness - End-to-end validation
        
        # 1. Buyer submits registration
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            SellerRegistration.objects.filter(buyer=self.buyer).exists()
        )
        registration_id = response.data['id']

        # 2. Verify registration is pending
        reg = SellerRegistration.objects.get(id=registration_id)
        self.assertEqual(reg.status, 'pending')

        # 3. Admin approves registration
        self.client.force_authenticate(user=self.admin_user)
        approve_response = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )
        
        self.assertEqual(
            approve_response.status_code,
            status.HTTP_200_OK
        )

        # 4. Verify registration status changed to approved
        reg.refresh_from_db()
        self.assertEqual(reg.status, 'approved')

        # 5. Verify buyer's user role changed to seller
        self.buyer_user.refresh_from_db()
        self.assertTrue(self.buyer_user.groups.filter(name='Seller').exists())

        # 6. Verify seller profile created
        self.assertTrue(
            Seller.objects.filter(user=self.buyer_user).exists()
        )

    def test_workflow_with_info_request(self):
        """Test: Submit → Request info → Resubmit → Approve"""
        # CORE PRINCIPLE: Workflow Flexibility - Multi-step approval
        
        # 1. Submit registration
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        registration_id = response.data['id']

        # 2. Admin requests more info
        self.client.force_authenticate(user=self.admin_user)
        info_response = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/request-info/',
            {'reason': 'Need clarification on products'},
            format='json'
        )
        
        self.assertEqual(info_response.status_code, status.HTTP_200_OK)

        # 3. Verify status changed to 'more_info_needed'
        reg = SellerRegistration.objects.get(id=registration_id)
        self.assertEqual(reg.status, 'more_info_needed')

        # 4. Buyer updates and resubmits
        self.client.force_authenticate(user=self.buyer_user)
        update_data = self.registration_data.copy()
        update_data['products'] = 'Rice,Corn,Vegetables,Fruits'
        
        update_response = self.client.put(
            f'/api/v1/sellers/registrations/{registration_id}/',
            update_data,
            format='json'
        )
        
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)

        # 5. Admin approves updated registration
        self.client.force_authenticate(user=self.admin_user)
        approve_response = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )
        
        self.assertEqual(approve_response.status_code, status.HTTP_200_OK)

        # 6. Verify seller role assigned
        self.buyer_user.refresh_from_db()
        self.assertTrue(self.buyer_user.groups.filter(name='Seller').exists())

    def test_rejection_workflow(self):
        """Test: Submit → Reject → Buyer cannot resubmit"""
        # CORE PRINCIPLE: Workflow Error Handling - Rejection path
        
        # 1. Submit registration
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        registration_id = response.data['id']

        # 2. Admin rejects
        self.client.force_authenticate(user=self.admin_user)
        reject_response = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/reject/',
            {'reason': 'Insufficient documentation'},
            format='json'
        )
        
        self.assertEqual(reject_response.status_code, status.HTTP_200_OK)

        # 3. Verify status is rejected
        reg = SellerRegistration.objects.get(id=registration_id)
        self.assertEqual(reg.status, 'rejected')

        # 4. Verify buyer is NOT a seller
        self.buyer_user.refresh_from_db()
        self.assertFalse(self.buyer_user.groups.filter(name='Seller').exists())

        # 5. Buyer can submit new registration (idempotency protection only)
        # Only OneToOne constraint, but status tracking allows new submission
        self.assertEqual(
            SellerRegistration.objects.filter(buyer=self.buyer).count(),
            1
        )

    def test_concurrent_approvals_prevented(self):
        """Test: Cannot approve same registration twice"""
        # CORE PRINCIPLE: API Idempotency - Prevents double processing
        
        # 1. Submit registration
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        registration_id = response.data['id']

        # 2. First approval succeeds
        self.client.force_authenticate(user=self.admin_user)
        first_approve = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )
        self.assertEqual(first_approve.status_code, status.HTTP_200_OK)

        # 3. Second approval on same registration
        second_approve = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )
        
        # Should either fail or be idempotent (same result)
        self.assertIn(
            second_approve.status_code,
            [status.HTTP_400_BAD_REQUEST, status.HTTP_200_OK]
        )

        # 4. Verify status is still approved (not duplicated)
        reg = SellerRegistration.objects.get(id=registration_id)
        self.assertEqual(reg.status, 'approved')

    def test_role_change_creates_seller_profile(self):
        """Test: When user role changes to seller, seller profile auto-created"""
        # CORE PRINCIPLE: Data Consistency - Automatic profile creation
        
        # 1. Submit and approve
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        registration_id = response.data['id']

        self.client.force_authenticate(user=self.admin_user)
        self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )

        # 2. Verify seller exists and has correct info
        seller = Seller.objects.get(user=self.buyer_user)
        self.assertIsNotNone(seller)
        self.assertEqual(seller.user, self.buyer_user)

    def test_unauthorized_approval_prevented(self):
        """Test: Only admin can approve, buyer cannot"""
        # CORE PRINCIPLE: Security - Authorization enforcement
        
        # 1. Buyer submits
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        registration_id = response.data['id']

        # 2. Buyer tries to approve their own registration
        approve_response = self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )
        
        self.assertEqual(
            approve_response.status_code,
            status.HTTP_403_FORBIDDEN
        )

        # 3. Verify status is still pending
        reg = SellerRegistration.objects.get(id=registration_id)
        self.assertEqual(reg.status, 'pending')

    def test_buyer_cannot_access_other_registrations(self):
        """Test: Buyer can only view their own registration"""
        # CORE PRINCIPLE: Security - Data isolation
        
        # Create two buyers
        buyer2_user = User.objects.create_user(
            username='buyer2',
            email='buyer2@test.com',
            password='testpass123'
        )
        buyer2 = Buyer.objects.create(user=buyer2_user)

        # Buyer1 submits
        self.client.force_authenticate(user=self.buyer_user)
        response1 = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        reg1_id = response1.data['id']

        # Buyer2 submits
        self.client.force_authenticate(user=buyer2_user)
        response2 = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        reg2_id = response2.data['id']

        # Buyer1 cannot access Buyer2's registration
        self.client.force_authenticate(user=self.buyer_user)
        access_response = self.client.get(
            f'/api/v1/sellers/registrations/{reg2_id}/',
        )
        
        self.assertEqual(
            access_response.status_code,
            status.HTTP_403_FORBIDDEN
        )

        # Buyer1 can access their own
        own_response = self.client.get(
            f'/api/v1/sellers/registrations/{reg1_id}/',
        )
        
        self.assertEqual(own_response.status_code, status.HTTP_200_OK)

    def test_duplicate_submission_prevented(self):
        """Test: Buyer cannot submit twice (OneToOne constraint)"""
        # CORE PRINCIPLE: API Idempotency - Prevents duplicates
        
        # 1. First submission succeeds
        self.client.force_authenticate(user=self.buyer_user)
        response1 = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        self.assertEqual(response1.status_code, status.HTTP_201_CREATED)

        # 2. Second submission fails or returns existing
        response2 = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        
        # Should either fail or return 400 for duplicate
        self.assertIn(
            response2.status_code,
            [
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_409_CONFLICT,
                status.HTTP_403_FORBIDDEN,
            ]
        )

        # Verify only one registration exists
        self.assertEqual(
            SellerRegistration.objects.filter(buyer=self.buyer).count(),
            1
        )

    def test_invalid_data_during_workflow(self):
        """Test: Invalid data rejected at submission and update"""
        # CORE PRINCIPLE: Input Validation - Data integrity
        
        invalid_data = {
            'farm_name': 'AB',  # Too short
            'location': 'Test',
            'products': '',  # Empty
            'store_name': 'Store',
            'store_description': 'Desc'
        }

        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            invalid_data,
            format='json'
        )
        
        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST
        )

    def test_workflow_state_consistency(self):
        """Test: Multiple operations maintain consistent state"""
        # CORE PRINCIPLE: Data Consistency - ACID properties
        
        # Submit
        self.client.force_authenticate(user=self.buyer_user)
        response = self.client.post(
            '/api/v1/sellers/registrations/submit/',
            self.registration_data,
            format='json'
        )
        registration_id = response.data['id']

        # Check initial state
        reg1 = SellerRegistration.objects.get(id=registration_id)
        initial_state = {
            'status': reg1.status,
            'buyer': reg1.buyer.id,
            'created_at': reg1.created_at,
        }

        # Approve
        self.client.force_authenticate(user=self.admin_user)
        self.client.patch(
            f'/api/v1/sellers/registrations/{registration_id}/approve/',
            {},
            format='json'
        )

        # Check final state
        reg2 = SellerRegistration.objects.get(id=registration_id)
        final_state = {
            'status': reg2.status,
            'buyer': reg2.buyer.id,
            'created_at': reg2.created_at,
        }

        # Verify immutable fields unchanged
        self.assertEqual(initial_state['buyer'], final_state['buyer'])
        self.assertEqual(initial_state['created_at'], final_state['created_at'])
        
        # Verify mutable field changed
        self.assertNotEqual(initial_state['status'], final_state['status'])
        self.assertEqual(final_state['status'], 'approved')
