# Phase 5.1: Quick Reference Guide

## 🚀 Running Tests

### Most Common Commands

```bash
# Run all Phase 5.1 tests
python manage.py test tests.admin --verbosity=2

# Run with coverage report
coverage run --source='apps.users' manage.py test tests.admin
coverage report

# Run specific module
python manage.py test tests.admin.test_admin_auth --verbosity=2
python manage.py test tests.admin.test_workflows --verbosity=2
python manage.py test tests.admin.test_data_integrity --verbosity=2

# Run specific class
python manage.py test tests.admin.test_admin_auth.AdminAuthenticationTests

# Run specific test
python manage.py test tests.admin.test_admin_auth.AdminAuthenticationTests.test_super_admin_can_authenticate
```

---

## 📦 Using Test Factories

### Create Admin Users
```python
from tests.admin.admin_test_fixtures import AdminUserFactory

super_admin = AdminUserFactory.create_super_admin()
seller_manager = AdminUserFactory.create_seller_manager()
price_manager = AdminUserFactory.create_price_manager()
opas_manager = AdminUserFactory.create_opas_manager()
analytics_manager = AdminUserFactory.create_analytics_manager()
```

### Create Sellers
```python
from tests.admin.admin_test_fixtures import SellerFactory

pending = SellerFactory.create_pending_seller()
approved = SellerFactory.create_approved_seller()
suspended = SellerFactory.create_suspended_seller()
```

### Create Test Data
```python
from tests.admin.admin_test_fixtures import DataFactory

product = DataFactory.create_seller_product(seller, 'Tomatoes', 50.00)
ceiling = DataFactory.create_price_ceiling('Tomatoes', 100.00)
inventory = DataFactory.create_opas_inventory('Tomatoes', quantity=100)
```

---

## 🧪 Writing a Test

### Template 1: Authentication Test
```python
from tests.admin.admin_test_fixtures import AdminAuthTestCase

class MyAuthTests(AdminAuthTestCase):
    def test_admin_can_access_endpoint(self):
        self.authenticate_user(self.super_admin)
        response = self.client.get('/api/admin/sellers/')
        self.assertEqual(response.status_code, 200)
```

### Template 2: Permission Test
```python
def test_seller_cannot_approve(self):
    self.authenticate_user(self.approved_seller)
    response = self.client.post(
        f'/api/admin/sellers/{self.pending_seller.id}/approve/',
        {'admin_notes': 'Approved'},
        format='json'
    )
    self.assertEqual(response.status_code, 403)  # Forbidden
```

### Template 3: Workflow Test
```python
from tests.admin.admin_test_fixtures import AdminWorkflowTestCase

class MyWorkflowTests(AdminWorkflowTestCase):
    def test_seller_approval_workflow(self):
        # Step 1: Verify initial state
        self.assertEqual(self.pending_seller.seller_status, 'PENDING')
        
        # Step 2: Execute action
        self.authenticate_user(self.seller_manager)
        response = self.client.post(
            f'/api/admin/sellers/{self.pending_seller.id}/approve/',
            {'admin_notes': 'Approved'},
            format='json'
        )
        
        # Step 3: Verify state changed
        self.pending_seller.refresh_from_db()
        self.assertEqual(self.pending_seller.seller_status, 'APPROVED')
        
        # Step 4: Verify audit log
        self.assertAuditLogCreated(
            'APPROVE_SELLER',
            self.seller_manager,
            'Seller',
            str(self.pending_seller.id)
        )
```

### Template 4: Data Integrity Test
```python
from tests.admin.admin_test_fixtures import AdminDataIntegrityTestCase

class MyIntegrityTests(AdminDataIntegrityTestCase):
    def test_no_orphaned_records(self):
        # Create ceiling with history
        ceiling = DataFactory.create_price_ceiling('Test', 100.00)
        from apps.users.admin_models import PriceHistory
        PriceHistory.objects.create(
            price_ceiling=ceiling,
            admin_user=self.super_admin,
            previous_price=95.00,
            new_price=100.00,
            reason='Test'
        )
        
        # Delete ceiling
        ceiling_id = ceiling.id
        ceiling.delete()
        
        # Verify history deleted (CASCADE)
        self.assertRecordDoesNotExist(
            PriceHistory,
            price_ceiling_id=ceiling_id
        )
```

---

## 📊 What Tests Are Available

### Authentication Tests (22)
- ✅ Admin user can authenticate
- ✅ Non-admin users denied
- ✅ All endpoint types accessible
- ✅ Role-based permissions enforced
- ✅ Token validation
- ✅ Edge cases (malformed headers, etc.)

### Workflow Tests (13)
- ✅ Seller approval workflow
- ✅ Seller rejection workflow
- ✅ Seller suspension workflow
- ✅ Price ceiling update workflow
- ✅ OPAS submission approval
- ✅ OPAS submission rejection
- ✅ Multi-step complex workflows

### Data Integrity Tests (18)
- ✅ No orphaned price history
- ✅ Seller suspension integrity
- ✅ Audit log completeness
- ✅ OPAS inventory consistency
- ✅ Foreign key constraints
- ✅ Cascade deletions

---

## 🔧 Available Methods

### From AdminAuthTestCase
```python
# Pre-created objects
self.super_admin          # Super Admin user
self.seller_manager       # Seller Manager user
self.pending_seller       # Seller awaiting approval
self.approved_seller      # Approved seller
self.product_1            # Test product 1
self.product_2            # Test product 2

# Methods
self.authenticate_user(user)    # Authenticate as user
self.get_token(user)            # Get API token
self.logout()                   # Clear authentication
self.client.get(url)            # Make GET request
self.client.post(url, data)     # Make POST request
self.client.put(url, data)      # Make PUT request
```

### From AdminWorkflowTestCase
```python
# Additional methods
self.assertWorkflowStep(obj, field, expected, step_name)
self.assertAuditLogCreated(action_type, admin, entity_type, entity_id)
```

### From AdminDataIntegrityTestCase
```python
# Additional methods
self.assertRecordExists(model, **filters)
self.assertRecordDoesNotExist(model, **filters)
self.assertNoOrphanedRecords(parent_model, child_model, parent_field)
self.assertAuditLogCompletnessFor(action, admin, entity_type)
```

### From AdminTestHelper
```python
AdminTestHelper.assert_response_success(test_case, response, status=200)
AdminTestHelper.assert_response_contains(response, key)
AdminTestHelper.print_response_data(response)
```

---

## 🐛 Debugging Tests

### Print Response Data
```python
def test_something(self):
    response = self.client.get('/api/admin/sellers/')
    AdminTestHelper.print_response_data(response)
    # Output: Status Code: 200, Response Data: {...}
```

### Check Response Status
```python
response = self.client.post('/api/admin/sellers/1/approve/', {...})
print(f"Status: {response.status_code}")  # Check if 200, 403, 404, etc.
print(f"Data: {response.data}")            # See error message if failed
```

### Verify Object State
```python
obj = MyModel.objects.get(id=1)
print(f"Status: {obj.status}")
obj.refresh_from_db()  # Reload from database
print(f"Status after: {obj.status}")
```

### List All Tests in Module
```bash
python manage.py test tests.admin.test_admin_auth --list
```

---

## 🎯 Test Coverage by Feature

### Seller Management
- ✅ Approve seller
- ✅ Reject seller
- ✅ Suspend seller
- ✅ Reactivate seller
- ✅ View seller details
- ✅ List pending approvals

### Price Management
- ✅ Update price ceiling
- ✅ View price history
- ✅ Flag price violation
- ✅ Non-compliance detection

### OPAS Management
- ✅ Review submissions
- ✅ Approve submission
- ✅ Reject submission
- ✅ Manage inventory
- ✅ Track FIFO

### Admin Operations
- ✅ View audit logs
- ✅ Create announcements
- ✅ Send notifications
- ✅ View analytics

---

## ✨ Best Practices

### ✅ Do
```python
# Good: Clear test names
def test_super_admin_can_approve_seller(self):
    pass

# Good: One assertion per important step
self.assertEqual(response.status_code, 200)
self.assertEqual(obj.status, 'APPROVED')

# Good: Use factories
seller = SellerFactory.create_approved_seller()

# Good: Refresh from DB after updates
obj.refresh_from_db()
self.assertEqual(obj.status, expected)
```

### ❌ Don't
```python
# Bad: Vague test name
def test_something(self):
    pass

# Bad: Multiple unrelated assertions
self.assertEqual(a, b)
self.assertEqual(c, d)
self.assertEqual(e, f)

# Bad: Hard-coded test data
user = User.objects.create(email='test@test.com')

# Bad: Assuming object is updated
# (database changes might not be reflected without refresh_from_db())
self.assertEqual(obj.status, expected)
```

---

## 📈 Test Statistics

| Metric | Value |
|--------|-------|
| Total Tests | 53 |
| Test Modules | 3 |
| Test Classes | 14 |
| Code Files | 5 |
| Lines of Code | ~2,500 |
| Expected Coverage | 90%+ |
| Est. Run Time | 30-45 sec |

---

## 🔗 Documentation Links

- Full README: `tests/admin/README_TESTS.md`
- Summary: `tests/admin/PHASE_5_1_SUMMARY.md`
- This Guide: `tests/admin/QUICK_REFERENCE.md`
- Fixtures: `tests/admin/admin_test_fixtures.py`

---

## ⚠️ Common Errors

### Error: "ModuleNotFoundError: No module named 'tests'"
```bash
# Solution: Create __init__.py files
touch tests/__init__.py
touch tests/admin/__init__.py
```

### Error: "Table doesn't exist"
```bash
# Solution: Run migrations
python manage.py migrate
```

### Error: "Test timed out"
```bash
# Solution: Run tests serially
python manage.py test tests.admin --parallel 1
```

### Error: "No fixtures matching"
```bash
# Solution: Tests create tokens dynamically
# No action needed - this is normal behavior
```

---

## 🎓 Learning Path

1. **Start Here**: Read this Quick Reference
2. **Understand Fixtures**: Review `admin_test_fixtures.py`
3. **Learn by Example**: Look at `test_admin_auth.py` (simplest tests)
4. **Advanced Patterns**: Study `test_workflows.py`
5. **Data Integrity**: Learn from `test_data_integrity.py`
6. **Full Reference**: Read `README_TESTS.md`

---

## 📝 Command Cheat Sheet

```bash
# Run tests
python manage.py test tests.admin                          # All tests
python manage.py test tests.admin.test_admin_auth          # One module
python manage.py test tests.admin.test_admin_auth.AdminAuthenticationTests  # One class

# With options
python manage.py test tests.admin --verbosity=2            # Verbose output
python manage.py test tests.admin --parallel 4             # Run in parallel
python manage.py test tests.admin --keepdb                 # Keep test DB
python manage.py test tests.admin --failfast               # Stop on first failure

# Coverage
coverage run --source='apps.users' manage.py test tests.admin
coverage report                                            # Console report
coverage html                                              # HTML report
```

---

**Quick Reference for Phase 5.1 Backend Testing**  
*Last Updated: November 21, 2025*
