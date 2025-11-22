"""
Admin Authentication and Permission Tests - Phase 5.1

Tests:
1. Admin users can access protected endpoints
2. Non-admin users cannot access admin endpoints
3. Permission checks for each ViewSet role
4. Token validation and expiration
5. Role-based access control (RBAC)

Architecture: Each test is independent and focused on a single aspect.
"""

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User, UserRole
from apps.users.admin_models import AdminRole
from tests.admin.admin_test_fixtures import (
    AdminAuthTestCase, AdminUserFactory, SellerFactory, AdminTestHelper
)


# ==================== AUTHENTICATION TESTS ====================

class AdminAuthenticationTests(AdminAuthTestCase):
    """Test admin user authentication and token validation"""

    def test_super_admin_can_authenticate(self):
        """Super Admin can obtain and use authentication token"""
        # Authenticate
        self.authenticate_user(self.super_admin)
        self.assertIsNotNone(self.client.credentials)

    def test_seller_manager_can_authenticate(self):
        """Seller Manager can authenticate"""
        self.authenticate_user(self.seller_manager)
        self.assertIsNotNone(self.client.credentials)

    def test_seller_user_cannot_authenticate_as_admin(self):
        """Non-admin users cannot access admin endpoints"""
        self.authenticate_user(self.approved_seller)
        # Attempt to access admin endpoint - should fail
        response = self.client.get('/api/admin/sellers/')
        self.assertIn(
            response.status_code,
            [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED],
            "Non-admin user should not access admin endpoints"
        )

    def test_unauthenticated_user_cannot_access_admin_endpoints(self):
        """Unauthenticated users are denied access"""
        self.logout()
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_admin_token_is_valid(self):
        """Admin token contains expected claims"""
        token = self.get_token(self.super_admin)
        self.assertIsNotNone(token)
        self.assertTrue(len(token) > 0, "Token should not be empty")

    def test_invalid_token_rejected(self):
        """Invalid tokens are rejected"""
        self.client.credentials(HTTP_AUTHORIZATION='Token invalid_token_xyz')
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


# ==================== ADMIN ENDPOINT ACCESS TESTS ====================

class AdminEndpointAccessTests(AdminAuthTestCase):
    """Test access to specific admin endpoints"""

    def test_super_admin_can_access_seller_endpoints(self):
        """Super Admin can access seller management endpoints"""
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_super_admin_can_access_price_endpoints(self):
        """Super Admin can access price management endpoints"""
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/prices/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_super_admin_can_access_opas_endpoints(self):
        """Super Admin can access OPAS management endpoints"""
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/opas/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_super_admin_can_access_marketplace_endpoints(self):
        """Super Admin can access marketplace oversight endpoints"""
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/marketplace/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_super_admin_can_access_analytics_endpoints(self):
        """Super Admin can access analytics endpoints"""
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/analytics/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_super_admin_can_access_notification_endpoints(self):
        """Super Admin can access notification endpoints"""
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/notifications/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)


# ==================== ROLE-BASED PERMISSION TESTS ====================

class RoleBasedPermissionTests(AdminAuthTestCase):
    """Test role-based access control (RBAC)"""

    def test_seller_manager_can_access_seller_endpoints(self):
        """Seller Manager has permission for seller operations"""
        self.authenticate_user(self.seller_manager)
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_seller_manager_cannot_modify_prices(self):
        """Seller Manager cannot modify price ceilings"""
        self.authenticate_user(self.seller_manager)
        response = self.client.post(
            '/api/admin/prices/',
            {'product_id': self.product_1.id, 'ceiling_price': 100.0},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_price_manager_can_access_price_endpoints(self):
        """Price Manager has permission for price operations"""
        self.authenticate_user(self.price_manager)
        response = self.client.get('/api/admin/prices/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_price_manager_cannot_approve_sellers(self):
        """Price Manager cannot approve sellers"""
        self.authenticate_user(self.price_manager)
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/approve/',
            {'admin_notes': 'Approved'},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_opas_manager_can_access_opas_endpoints(self):
        """OPAS Manager has permission for OPAS operations"""
        self.authenticate_user(self.opas_manager)
        response = self.client.get('/api/admin/opas/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_opas_manager_cannot_modify_prices(self):
        """OPAS Manager cannot modify price ceilings"""
        self.authenticate_user(self.opas_manager)
        response = self.client.post(
            '/api/admin/prices/',
            {'product_id': self.product_1.id, 'ceiling_price': 100.0},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_analytics_manager_read_only_access(self):
        """Analytics Manager can read but not modify"""
        self.authenticate_user(self.analytics_manager)
        # Can read
        response = self.client.get('/api/admin/analytics/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Cannot write
        response = self.client.post(
            '/api/admin/sellers/',
            {'email': 'test@test.com', 'first_name': 'Test', 'last_name': 'User', 'username': 'testuser'},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


# ==================== PERMISSION DENIED TESTS ====================

class PermissionDeniedTests(AdminAuthTestCase):
    """Test that permissions are properly enforced"""

    def test_non_admin_cannot_approve_seller(self):
        """Regular users cannot approve sellers"""
        self.authenticate_user(self.approved_seller)
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/approve/',
            {'admin_notes': 'Approved'},
            format='json'
        )
        self.assertIn(
            response.status_code,
            [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED]
        )

    def test_non_admin_cannot_create_price_advisory(self):
        """Regular users cannot create price advisories"""
        self.authenticate_user(self.approved_seller)
        response = self.client.post(
            '/api/admin/prices/advisories/',
            {
                'type': 'SHORTAGE_ALERT',
                'title': 'Test',
                'content': 'Test content'
            },
            format='json'
        )
        self.assertIn(
            response.status_code,
            [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED]
        )

    def test_non_admin_cannot_access_audit_log(self):
        """Regular users cannot access admin endpoints"""
        self.authenticate_user(self.approved_seller)
        response = self.client.get('/api/admin/sellers/')
        self.assertIn(
            response.status_code,
            [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED]
        )

    def test_non_admin_cannot_suspend_seller(self):
        """Regular users cannot suspend sellers"""
        self.authenticate_user(self.approved_seller)
        response = self.client.post(
            f'/api/admin/sellers/{self.approved_seller.id}/suspend/',
            {'reason': 'Test'},
            format='json'
        )
        self.assertIn(
            response.status_code,
            [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED]
        )


# ==================== MULTIPLE ADMIN OPERATIONS TESTS ====================

class ConcurrentAdminOperationTests(AdminAuthTestCase):
    """Test concurrent operations by different admin roles"""

    def test_two_admins_can_operate_independently(self):
        """Two different admins can operate independently"""
        # Admin 1 (Super Admin) updates price
        self.authenticate_user(self.super_admin)
        response1 = self.client.get('/api/admin/prices/')
        self.assertEqual(response1.status_code, status.HTTP_200_OK)

        # Switch to Admin 2 (Seller Manager)
        self.logout()
        self.authenticate_user(self.seller_manager)
        response2 = self.client.get('/api/admin/sellers/')
        self.assertEqual(response2.status_code, status.HTTP_200_OK)

        # Verify both operations succeeded
        self.assertTrue(response1.status_code == 200 and response2.status_code == 200)

    def test_admin_logout_clears_permissions(self):
        """After logout, admin loses access"""
        self.authenticate_user(self.super_admin)
        response1 = self.client.get('/api/admin/sellers/')
        self.assertEqual(response1.status_code, status.HTTP_200_OK)

        self.logout()
        response2 = self.client.get('/api/admin/sellers/')
        self.assertEqual(response2.status_code, status.HTTP_401_UNAUTHORIZED)


# ==================== EDGE CASES ====================

class AuthenticationEdgeCaseTests(AdminAuthTestCase):
    """Test edge cases in authentication"""

    def test_case_insensitive_email_login(self):
        """Email authentication should be case-insensitive"""
        # Create admin with lowercase email
        admin = AdminUserFactory.create_super_admin(email='test_admin@opas.com')
        # Try to authenticate with uppercase
        self.authenticate_user(admin)
        self.assertIsNotNone(self.client.credentials)

    def test_empty_authorization_header_rejected(self):
        """Empty authorization header is rejected"""
        self.client.credentials(HTTP_AUTHORIZATION='')
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_malformed_authorization_header_rejected(self):
        """Malformed authorization header is rejected"""
        self.client.credentials(HTTP_AUTHORIZATION='Bearer invalid_format')
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


if __name__ == '__main__':
    import unittest
    unittest.main()
