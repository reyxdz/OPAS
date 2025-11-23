"""
Django Unit Tests for Seller Registration System
Tests models, serializers, and API endpoints
CORE PRINCIPLE: Input Validation - Server-side validation enforced
CORE PRINCIPLE: Security & Authorization - Permission checks on all endpoints
"""

from django.test import TestCase, APITestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from datetime import datetime, timedelta
import json

from apps.users.models import SellerRegistrationRequest, SellerDocumentVerification
from apps.users.serializers import (
    SellerRegistrationSubmitSerializer,
    SellerDocumentVerificationSerializer,
    SellerRegistrationRequestSerializer,
    SellerRegistrationStatusSerializer,
)

User = get_user_model()


class SellerRegistrationModelTests(TestCase):
    """Test SellerRegistrationRequest model"""

    def setUp(self):
        """Create test buyer user"""
        self.buyer = User.objects.create_user(
            username='testbuyer',
            email='buyer@test.com',
            password='testpass123',
            user_type='BUYER'
        )

    def test_create_seller_registration(self):
        """Test creating a seller registration request"""
        registration = SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits', 'Vegetables'],
            store_name='Test Store',
            store_description='A test store',
            status='PENDING'
        )

        self.assertEqual(registration.seller, self.buyer)
        self.assertEqual(registration.farm_name, 'Test Farm')
        self.assertEqual(registration.status, 'PENDING')
        self.assertIsNotNone(registration.submitted_at)

    def test_registration_status_methods(self):
        """Test registration status checking methods"""
        registration = SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Test Store',
            store_description='Test description',
            status='PENDING'
        )

        # CORE PRINCIPLE: Input Validation - Status tracking
        self.assertTrue(registration.is_pending())
        self.assertFalse(registration.is_approved())
        self.assertFalse(registration.is_rejected())

    def test_one_registration_per_user(self):
        """Test OneToOne constraint on seller"""
        SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Farm 1',
            farm_location='City 1',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Store 1',
            store_description='Description 1',
            status='PENDING'
        )

        # CORE PRINCIPLE: API Idempotency - Prevent duplicates
        with self.assertRaises(Exception):
            SellerRegistrationRequest.objects.create(
                seller=self.buyer,
                farm_name='Farm 2',
                farm_location='City 2',
                farm_size='10 hectares',
                products_grown=['Vegetables'],
                store_name='Store 2',
                store_description='Description 2',
                status='PENDING'
            )

    def test_days_pending_calculation(self):
        """Test days_pending property"""
        registration = SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Test Store',
            store_description='Test description',
            status='PENDING',
            submitted_at=datetime.now() - timedelta(days=5)
        )

        # Should be approximately 5 days (allow 1 day variance)
        self.assertGreaterEqual(registration.days_pending, 4)
        self.assertLessEqual(registration.days_pending, 6)


class SellerRegistrationSerializerTests(TestCase):
    """Test all serializers"""

    def setUp(self):
        """Create test users"""
        self.buyer = User.objects.create_user(
            username='testbuyer',
            email='buyer@test.com',
            password='testpass123',
            user_type='BUYER'
        )

    def test_submit_serializer_validation(self):
        """Test SellerRegistrationSubmitSerializer validation"""
        # Valid data
        data = {
            'farm_name': 'Test Farm',
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits', 'Vegetables'],
            'store_name': 'Test Store',
            'store_description': 'A test store with quality products',
        }

        serializer = SellerRegistrationSubmitSerializer(data=data)
        self.assertTrue(serializer.is_valid())

    def test_submit_serializer_validation_fails_short_farm_name(self):
        """Test farm name minimum length validation"""
        # CORE PRINCIPLE: Input Validation - Enforce constraints
        data = {
            'farm_name': 'AB',  # Too short
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits'],
            'store_name': 'Test Store',
            'store_description': 'A test store description',
        }

        serializer = SellerRegistrationSubmitSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('farm_name', serializer.errors)

    def test_submit_serializer_validation_fails_short_description(self):
        """Test store description minimum length validation"""
        data = {
            'farm_name': 'Test Farm',
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits'],
            'store_name': 'Test Store',
            'store_description': 'Short',  # Too short
        }

        serializer = SellerRegistrationSubmitSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('store_description', serializer.errors)

    def test_status_serializer_creates_registration(self):
        """Test that SellerRegistrationStatusSerializer returns proper status"""
        registration = SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Test Store',
            store_description='Test store description here',
            status='PENDING'
        )

        serializer = SellerRegistrationStatusSerializer(registration)
        data = serializer.data

        self.assertEqual(data['status'], 'PENDING')
        self.assertIn('status_display', data)


class SellerRegistrationAPITests(APITestCase):
    """Test API endpoints"""

    def setUp(self):
        """Setup test users and client"""
        self.client = APIClient()
        
        # Create buyer
        self.buyer = User.objects.create_user(
            username='testbuyer',
            email='buyer@test.com',
            password='testpass123',
            user_type='BUYER'
        )

        # Create admin
        self.admin = User.objects.create_user(
            username='testadmin',
            email='admin@test.com',
            password='testpass123',
            user_type='SELLER_MANAGER'
        )

        # Create approved seller
        self.seller = User.objects.create_user(
            username='testseller',
            email='seller@test.com',
            password='testpass123',
            user_type='SELLER'
        )

    def test_submit_registration_success(self):
        """Test successful registration submission"""
        self.client.force_authenticate(user=self.buyer)

        data = {
            'farm_name': 'Test Farm',
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits', 'Vegetables'],
            'store_name': 'Test Store',
            'store_description': 'A test store with quality produce',
        }

        response = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )

        # CORE PRINCIPLE: Resource Management - Efficient response
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'PENDING')

    def test_submit_registration_unauthenticated(self):
        """Test registration requires authentication"""
        # CORE PRINCIPLE: Security & Authorization - Check authentication
        data = {
            'farm_name': 'Test Farm',
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits'],
            'store_name': 'Test Store',
            'store_description': 'A test store with good products',
        }

        response = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_submit_registration_invalid_data(self):
        """Test registration validation on API"""
        # CORE PRINCIPLE: Input Validation - Reject invalid data
        self.client.force_authenticate(user=self.buyer)

        data = {
            'farm_name': 'AB',  # Too short
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': [],  # Empty
            'store_name': 'TS',  # Too short
            'store_description': 'Short',  # Too short
        }

        response = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('farm_name', response.data)

    def test_get_my_registration(self):
        """Test buyer can get their registration status"""
        # Create registration
        SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Test Store',
            store_description='A quality store',
            status='PENDING'
        )

        self.client.force_authenticate(user=self.buyer)
        response = self.client.get('/api/sellers/my-registration/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'PENDING')

    def test_get_my_registration_not_found(self):
        """Test 404 when no registration exists"""
        self.client.force_authenticate(user=self.buyer)
        response = self.client.get('/api/sellers/my-registration/')

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_get_registration_details_buyer_can_view_own(self):
        """Test buyer can view their own registration"""
        registration = SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Test Store',
            store_description='Quality products store',
            status='PENDING'
        )

        self.client.force_authenticate(user=self.buyer)
        response = self.client.get(f'/api/sellers/registrations/{registration.id}/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['farm_name'], 'Test Farm')

    def test_get_registration_details_buyer_cannot_view_others(self):
        """Test buyer cannot view other registrations"""
        # CORE PRINCIPLE: Security & Authorization - Ownership verification
        other_buyer = User.objects.create_user(
            username='otherbuyer',
            email='other@test.com',
            password='testpass123',
            user_type='BUYER'
        )

        registration = SellerRegistrationRequest.objects.create(
            seller=other_buyer,
            farm_name='Other Farm',
            farm_location='Other City',
            farm_size='10 hectares',
            products_grown=['Vegetables'],
            store_name='Other Store',
            store_description='Another quality store here',
            status='PENDING'
        )

        self.client.force_authenticate(user=self.buyer)
        response = self.client.get(f'/api/sellers/registrations/{registration.id}/')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_duplicate_registration_prevented(self):
        """Test that duplicate registrations are prevented"""
        # CORE PRINCIPLE: API Idempotency - Prevent duplicates
        data = {
            'farm_name': 'Test Farm',
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits'],
            'store_name': 'Test Store',
            'store_description': 'A store with fresh produce daily',
        }

        self.client.force_authenticate(user=self.buyer)

        # First submission should succeed
        response1 = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )
        self.assertEqual(response1.status_code, status.HTTP_201_CREATED)

        # Second submission should fail
        response2 = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )
        self.assertEqual(response2.status_code, status.HTTP_400_BAD_REQUEST)


class AdminAPITests(APITestCase):
    """Test admin-only endpoints"""

    def setUp(self):
        """Setup admin and registrations"""
        self.client = APIClient()

        self.admin = User.objects.create_user(
            username='testadmin',
            email='admin@test.com',
            password='testpass123',
            user_type='SELLER_MANAGER'
        )

        self.buyer = User.objects.create_user(
            username='testbuyer',
            email='buyer@test.com',
            password='testpass123',
            user_type='BUYER'
        )

        self.registration = SellerRegistrationRequest.objects.create(
            seller=self.buyer,
            farm_name='Test Farm',
            farm_location='Test City',
            farm_size='5 hectares',
            products_grown=['Fruits'],
            store_name='Test Store',
            store_description='Fresh farm produce online',
            status='PENDING'
        )

    def test_list_registrations_admin_only(self):
        """Test only admin can list registrations"""
        # CORE PRINCIPLE: Security & Authorization - Admin-only operations
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/sellers/registrations/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_list_registrations_buyer_denied(self):
        """Test buyer cannot list registrations"""
        self.client.force_authenticate(user=self.buyer)
        response = self.client.get('/api/admin/sellers/registrations/')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_approve_registration(self):
        """Test admin can approve registration"""
        self.client.force_authenticate(user=self.admin)

        data = {'admin_notes': 'Approved after verification'}

        response = self.client.post(
            f'/api/admin/sellers/registrations/{self.registration.id}/approve/',
            data,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify registration status changed
        self.registration.refresh_from_db()
        self.assertEqual(self.registration.status, 'APPROVED')

    def test_reject_registration(self):
        """Test admin can reject registration"""
        self.client.force_authenticate(user=self.admin)

        data = {
            'rejection_reason': 'Insufficient documentation',
            'admin_notes': 'Please resubmit with complete documents'
        }

        response = self.client.post(
            f'/api/admin/sellers/registrations/{self.registration.id}/reject/',
            data,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify status changed
        self.registration.refresh_from_db()
        self.assertEqual(self.registration.status, 'REJECTED')

    def test_request_more_info(self):
        """Test admin can request more information"""
        self.client.force_authenticate(user=self.admin)

        data = {
            'required_info': 'Please provide certificate of land ownership',
            'deadline_in_days': 7
        }

        response = self.client.post(
            f'/api/admin/sellers/registrations/{self.registration.id}/request-info/',
            data,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify status changed
        self.registration.refresh_from_db()
        self.assertEqual(self.registration.status, 'REQUEST_MORE_INFO')


class PermissionTests(APITestCase):
    """Test permission classes"""

    def setUp(self):
        """Setup test users"""
        self.buyer = User.objects.create_user(
            username='testbuyer',
            email='buyer@test.com',
            password='testpass123',
            user_type='BUYER'
        )

        self.seller = User.objects.create_user(
            username='testseller',
            email='seller@test.com',
            password='testpass123',
            user_type='SELLER'
        )

        self.admin = User.objects.create_user(
            username='testadmin',
            email='admin@test.com',
            password='testpass123',
            user_type='SELLER_MANAGER'
        )

        self.client = APIClient()

    def test_only_buyer_can_submit_registration(self):
        """Test IsBuyerOrApprovedSeller permission"""
        # CORE PRINCIPLE: Security & Authorization - Role-based access
        data = {
            'farm_name': 'Test Farm',
            'farm_location': 'Test City',
            'farm_size': '5 hectares',
            'products_grown': ['Fruits'],
            'store_name': 'Test Store',
            'store_description': 'Farm store with fresh products',
        }

        # Admin cannot submit
        self.client.force_authenticate(user=self.admin)
        response = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Buyer can submit
        self.client.force_authenticate(user=self.buyer)
        response = self.client.post(
            '/api/sellers/register-application/',
            data,
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
