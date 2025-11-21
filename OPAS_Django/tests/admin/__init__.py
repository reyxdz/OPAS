"""
Phase 5.1: Backend Testing Suite

This package contains comprehensive tests for the OPAS Admin Panel backend.

Test Modules:
    - admin_test_fixtures: Reusable test fixtures, factories, and base classes
    - test_admin_auth: Authentication, permission, and token validation tests
    - test_workflows: End-to-end workflow testing (seller approval, price updates, OPAS submissions)
    - test_data_integrity: Data consistency, orphaned records, audit log completeness

Quick Start:
    # Run all admin tests
    python manage.py test tests.admin --verbosity=2

    # Run specific test class
    python manage.py test tests.admin.test_admin_auth.AdminAuthenticationTests

    # Run with coverage
    coverage run --source='apps.users' manage.py test tests.admin
    coverage report

Architecture:
    - DRY Principle: Shared fixtures in admin_test_fixtures.py
    - Clean Separation: Each test module focuses on one area
    - Factory Pattern: AdminUserFactory, SellerFactory, DataFactory
    - Base Classes: AdminAuthTestCase, AdminWorkflowTestCase, AdminDataIntegrityTestCase
    - Helper Methods: AdminTestHelper for common assertions

Features:
    ✅ Authentication & Authorization Tests
    ✅ Permission-based Access Control Tests
    ✅ Role-based Workflow Tests
    ✅ Data Integrity & Consistency Tests
    ✅ Audit Log Completeness Tests
    ✅ Complex Multi-step Workflow Tests
    ✅ Cascading Deletion & Foreign Key Tests
"""

from .admin_test_fixtures import (
    AdminAuthTestCase,
    AdminWorkflowTestCase,
    AdminDataIntegrityTestCase,
    AdminUserFactory,
    SellerFactory,
    DataFactory,
    AdminTestHelper,
)

__all__ = [
    'AdminAuthTestCase',
    'AdminWorkflowTestCase',
    'AdminDataIntegrityTestCase',
    'AdminUserFactory',
    'SellerFactory',
    'DataFactory',
    'AdminTestHelper',
]

__version__ = '1.0.0'
__author__ = 'OPAS Development Team'
