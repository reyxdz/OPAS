"""
Unit Tests for Permission Classes (Phase 7.1)

Tests for admin-only access, role-based permissions,
and authentication requirements for forecasting endpoints.
"""

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase, APIClient
from rest_framework import status

from apps.users.models import Admin
from apps.forecasting.permissions import IsAdminForForecasting

User = get_user_model()


class IsAdminForForecastingPermissionTestCase(TestCase):
    """Test permission class for forecasting access"""
    
    def setUp(self):
        """Set up test users"""
        # Create super admin user
        self.super_admin_user = User.objects.create_user(
            email='superadmin@test.com',
            password='testpass123',
            first_name='Super',
            last_name='Admin'
        )
        self.super_admin = Admin.objects.create(
            user=self.super_admin_user,
            admin_role='SUPER_ADMIN'
        )
        
        # Create analytics admin user
        self.analytics_admin_user = User.objects.create_user(
            email='analytics@test.com',
            password='testpass123',
            first_name='Analytics',
            last_name='Admin'
        )
        self.analytics_admin = Admin.objects.create(
            user=self.analytics_admin_user,
            admin_role='ANALYTICS_ADMIN'
        )
        
        # Create regular admin user (not for forecasting)
        self.regular_admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            first_name='Regular',
            last_name='Admin'
        )
        self.regular_admin = Admin.objects.create(
            user=self.regular_admin_user,
            admin_role='OPERATIONS_ADMIN'
        )
        
        # Create regular user
        self.regular_user = User.objects.create_user(
            email='user@test.com',
            password='testpass123',
            first_name='Regular',
            last_name='User'
        )
        
        # Create permission instance
        self.permission = IsAdminForForecasting()
    
    def test_super_admin_has_permission(self):
        """Test that super admin can access forecasting"""
        request = type('Request', (), {'user': self.super_admin_user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertTrue(has_perm)
    
    def test_analytics_admin_has_permission(self):
        """Test that analytics admin can access forecasting"""
        request = type('Request', (), {'user': self.analytics_admin_user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertTrue(has_perm)
    
    def test_regular_admin_denied(self):
        """Test that non-forecasting admin is denied"""
        request = type('Request', (), {'user': self.regular_admin_user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertFalse(has_perm)
    
    def test_regular_user_denied(self):
        """Test that regular user is denied"""
        request = type('Request', (), {'user': self.regular_user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertFalse(has_perm)
    
    def test_unauthenticated_user_denied(self):
        """Test that unauthenticated user is denied"""
        request = type('Request', (), {'user': None})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertFalse(has_perm)
    
    def test_deleted_admin_denied(self):
        """Test that deleted admin is denied"""
        self.super_admin.is_deleted = True
        self.super_admin.save()
        
        request = type('Request', (), {'user': self.super_admin_user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertFalse(has_perm)


class ForecastingAPIAuthenticationTestCase(APITestCase):
    """Test authentication and authorization on forecasting endpoints"""
    
    def setUp(self):
        """Set up test users and client"""
        self.client = APIClient()
        
        # Create super admin
        self.super_admin_user = User.objects.create_user(
            email='superadmin@test.com',
            password='testpass123'
        )
        self.super_admin = Admin.objects.create(
            user=self.super_admin_user,
            admin_role='SUPER_ADMIN'
        )
        
        # Create regular user
        self.regular_user = User.objects.create_user(
            email='user@test.com',
            password='testpass123'
        )
    
    def test_forecast_list_requires_authentication(self):
        """Test that forecast list requires authentication"""
        response = self.client.get('/api/admin/forecasts/')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_forecast_list_requires_admin_role(self):
        """Test that forecast list requires admin role"""
        self.client.force_authenticate(user=self.regular_user)
        
        response = self.client.get('/api/admin/forecasts/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_admin_can_access_forecast_list(self):
        """Test that admin can access forecast list"""
        self.client.force_authenticate(user=self.super_admin_user)
        
        response = self.client.get('/api/admin/forecasts/')
        
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST])
    
    def test_forecast_detail_requires_authentication(self):
        """Test that forecast detail requires authentication"""
        response = self.client.get('/api/admin/forecasts/1/')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_refresh_requires_super_admin(self):
        """Test that refresh endpoint requires super admin"""
        # Create analytics admin (should be denied)
        analytics_user = User.objects.create_user(
            email='analytics@test.com',
            password='testpass123'
        )
        Admin.objects.create(
            user=analytics_user,
            admin_role='ANALYTICS_ADMIN'
        )
        
        self.client.force_authenticate(user=analytics_user)
        
        response = self.client.post('/api/admin/forecasts/refresh/')
        
        # Should either be forbidden or not found (not authenticated)
        self.assertIn(response.status_code, [
            status.HTTP_403_FORBIDDEN,
            status.HTTP_404_NOT_FOUND
        ])


class AdminRolePermissionTestCase(TestCase):
    """Test role-based admin permissions"""
    
    def setUp(self):
        """Set up test admins with various roles"""
        self.roles = ['SUPER_ADMIN', 'ANALYTICS_ADMIN', 'OPERATIONS_ADMIN', 'SELLER_SUPPORT_ADMIN']
        self.admins = {}
        
        for role in self.roles:
            user = User.objects.create_user(
                email=f'{role.lower()}@test.com',
                password='testpass123'
            )
            admin = Admin.objects.create(
                user=user,
                admin_role=role
            )
            self.admins[role] = admin
        
        self.permission = IsAdminForForecasting()
    
    def test_super_admin_forecast_access(self):
        """Test SUPER_ADMIN has forecast access"""
        request = type('Request', (), {'user': self.admins['SUPER_ADMIN'].user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertTrue(has_perm)
    
    def test_analytics_admin_forecast_access(self):
        """Test ANALYTICS_ADMIN has forecast access"""
        request = type('Request', (), {'user': self.admins['ANALYTICS_ADMIN'].user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertTrue(has_perm)
    
    def test_operations_admin_denied(self):
        """Test OPERATIONS_ADMIN is denied"""
        request = type('Request', (), {'user': self.admins['OPERATIONS_ADMIN'].user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertFalse(has_perm)
    
    def test_seller_support_admin_denied(self):
        """Test SELLER_SUPPORT_ADMIN is denied"""
        request = type('Request', (), {'user': self.admins['SELLER_SUPPORT_ADMIN'].user})()
        
        has_perm = self.permission.has_permission(request, None)
        
        self.assertFalse(has_perm)


class TokenAuthenticationTestCase(APITestCase):
    """Test token-based authentication for forecasting API"""
    
    def setUp(self):
        """Set up test users and tokens"""
        self.user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123'
        )
        Admin.objects.create(
            user=self.user,
            admin_role='SUPER_ADMIN'
        )
    
    def test_api_token_authentication(self):
        """Test API endpoint authentication with token"""
        # Obtain token
        response = self.client.post('/api/token/', {
            'email': 'admin@test.com',
            'password': 'testpass123'
        })
        
        if response.status_code == status.HTTP_200_OK:
            token = response.data.get('access') or response.data.get('token')
            
            # Use token to access endpoint
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
            forecast_response = self.client.get('/api/admin/forecasts/')
            
            self.assertNotEqual(forecast_response.status_code, status.HTTP_401_UNAUTHORIZED)


class PermissionObjectLevelTestCase(TestCase):
    """Test object-level permissions for forecasts"""
    
    def setUp(self):
        """Set up test data"""
        # Create two different admins
        self.admin1_user = User.objects.create_user(email='admin1@test.com', password='pass123')
        self.admin1 = Admin.objects.create(user=self.admin1_user, admin_role='SUPER_ADMIN')
        
        self.admin2_user = User.objects.create_user(email='admin2@test.com', password='pass123')
        self.admin2 = Admin.objects.create(user=self.admin2_user, admin_role='ANALYTICS_ADMIN')
    
    def test_all_admins_can_view_all_forecasts(self):
        """Test that all authorized admins can view all forecasts"""
        # Both admins should be able to view forecasts
        request1 = type('Request', (), {'user': self.admin1_user})()
        request2 = type('Request', (), {'user': self.admin2_user})()
        
        permission = IsAdminForForecasting()
        
        self.assertTrue(permission.has_permission(request1, None))
        self.assertTrue(permission.has_permission(request2, None))
