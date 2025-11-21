"""
Test Runner for Phase 5.1 Backend Testing

Usage:
    python manage.py test tests.admin.test_admin_auth --verbosity=2
    python manage.py test tests.admin.test_workflows --verbosity=2
    python manage.py test tests.admin.test_data_integrity --verbosity=2
    python manage.py test tests.admin --verbosity=2  # Run all Phase 5.1 tests

Coverage:
    coverage run --source='apps.users' manage.py test tests.admin
    coverage report
    coverage html  # Generate HTML report
"""

import os
import sys
import django
from django.conf import settings
from django.test.utils import get_runner

if __name__ == "__main__":
    os.environ['DJANGO_SETTINGS_MODULE'] = 'core.settings'
    django.setup()
    TestRunner = get_runner(settings)
    test_runner = TestRunner(verbosity=2, interactive=True, keepdb=True)
    
    # Run specific test suite
    test_labels = [
        'tests.admin.test_admin_auth.AdminAuthenticationTests',
        'tests.admin.test_admin_auth.AdminEndpointAccessTests',
        'tests.admin.test_admin_auth.RoleBasedPermissionTests',
        'tests.admin.test_workflows.SellerApprovalWorkflowTests',
        'tests.admin.test_workflows.PriceUpdateWorkflowTests',
        'tests.admin.test_workflows.OPASSubmissionWorkflowTests',
        'tests.admin.test_data_integrity.PriceHistoryIntegrityTests',
        'tests.admin.test_data_integrity.SellerSuspensionIntegrityTests',
        'tests.admin.test_data_integrity.AuditLogCompletenessTests',
        'tests.admin.test_data_integrity.OPASInventoryIntegrityTests',
    ]
    
    failures = test_runner.run_tests(test_labels)
    sys.exit(bool(failures))
