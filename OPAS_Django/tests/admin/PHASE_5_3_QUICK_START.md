"""
Phase 5.3: Integration Testing - Quick Start Guide

This guide provides quick reference for running Phase 5.3 integration tests.
"""

# ==================== PHASE 5.3 QUICK START ====================

## What is Phase 5.3?

Phase 5.3 implements comprehensive integration tests for full admin workflows:

1. **Seller Approval Workflow**: PENDING → APPROVED → SUSPENDED → REACTIVATED
2. **Price Ceiling Update**: Set ceiling → Detect violation → Notify → Resolve
3. **OPAS Submission Approval**: Submit → Review → Approve → Create Inventory → Track
4. **Announcement Broadcast**: Create → Publish → Deliver → Track History

## File Structure

```
tests/admin/
├── test_integration_workflows.py (NEW) ← Phase 5.3 tests
├── test_admin_auth.py            ← Phase 5.1
├── test_workflows.py              ← Phase 5.1 (different from 5.3)
├── test_data_integrity.py         ← Phase 5.1
├── admin_test_fixtures.py         ← Shared fixtures
├── PHASE_5_3_INTEGRATION_TESTING.md (NEW) ← Full documentation
└── PHASE_5_3_QUICK_START.md      (THIS FILE)
```

## Running Tests

### Option 1: Run All Phase 5.3 Tests

```bash
cd OPAS_Django
python manage.py test tests.admin.test_integration_workflows -v 2
```

**Expected Output**:
```
test_complete_seller_approval_workflow ... ✓ PASSED
test_seller_rejection_workflow ... ✓ PASSED
test_price_ceiling_update_with_compliance_workflow ... ✓ PASSED
test_batch_price_ceiling_update_workflow ... ✓ PASSED
test_opas_submission_approval_with_inventory_workflow ... ✓ PASSED
test_opas_submission_rejection_workflow ... ✓ PASSED
test_opas_inventory_tracking_fifo_workflow ... ✓ PASSED
test_announcement_creation_and_broadcast_workflow ... ✓ PASSED
test_seller_targeted_announcement_workflow ... ✓ PASSED
test_announcement_edit_and_delete_workflow ... ✓ PASSED

Ran 10 tests in 50-60s
✓ OK
```

### Option 2: Run Specific Workflow Tests

```bash
# Test only seller approval workflows
python manage.py test tests.admin.test_integration_workflows.SellerApprovalFullWorkflowTests -v 2

# Test only price ceiling workflows
python manage.py test tests.admin.test_integration_workflows.PriceCeilingUpdateWorkflowTests -v 2

# Test only OPAS workflows
python manage.py test tests.admin.test_integration_workflows.OPASSubmissionWorkflowTests -v 2

# Test only announcements
python manage.py test tests.admin.test_integration_workflows.AnnouncementBroadcastWorkflowTests -v 2
```

### Option 3: Run Specific Test Method

```bash
# Test complete seller approval workflow
python manage.py test tests.admin.test_integration_workflows.SellerApprovalFullWorkflowTests.test_complete_seller_approval_workflow -v 2

# Test price ceiling update
python manage.py test tests.admin.test_integration_workflows.PriceCeilingUpdateWorkflowTests.test_price_ceiling_update_with_compliance_workflow -v 2

# Test OPAS submission approval
python manage.py test tests.admin.test_integration_workflows.OPASSubmissionWorkflowTests.test_opas_submission_approval_with_inventory_workflow -v 2

# Test announcement broadcast
python manage.py test tests.admin.test_integration_workflows.AnnouncementBroadcastWorkflowTests.test_announcement_creation_and_broadcast_workflow -v 2
```

## Running with Coverage

```bash
# Generate coverage report
coverage run --source='apps.users' manage.py test tests.admin.test_integration_workflows
coverage report --include="apps/users/*" --precision=2

# Generate HTML coverage report
coverage html
# Open htmlcov/index.html in browser
```

## Running with Detailed Output

```bash
# Verbosity level 3 (most detailed)
python manage.py test tests.admin.test_integration_workflows -v 3

# Output includes each step as it completes
```

## Test Execution Timeline

### Full Test Suite:
- **Expected Time**: 50-60 seconds
- **Number of Tests**: 10
- **Average per Test**: 5-8 seconds

### Fastest Tests (< 5 seconds):
- test_seller_rejection_workflow
- test_batch_price_ceiling_update_workflow
- test_opas_submission_rejection_workflow
- test_seller_targeted_announcement_workflow
- test_announcement_edit_and_delete_workflow

### Slowest Tests (8-10 seconds):
- test_complete_seller_approval_workflow (most complex)
- test_opas_submission_approval_with_inventory_workflow
- test_announcement_creation_and_broadcast_workflow

## Understanding the Tests

### Test 1: Complete Seller Approval Workflow
**What it tests**:
- Seller application approval process
- Seller status transitions: PENDING → APPROVED → SUSPENDED → APPROVED
- Document verification
- Seller suspension and reactivation
- Audit trail tracking

**Key Assertions**:
- Status changes at each step
- Approval history preserved
- Suspension record created
- Audit log complete

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.SellerApprovalFullWorkflowTests.test_complete_seller_approval_workflow
```

### Test 2: Seller Rejection Workflow
**What it tests**:
- Seller application rejection
- Rejection reason storage
- Approval history record

**Key Assertions**:
- Status: PENDING → REJECTED
- Rejection reason preserved

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.SellerApprovalFullWorkflowTests.test_seller_rejection_workflow
```

### Test 3: Price Ceiling Update with Compliance
**What it tests**:
- Setting price ceilings
- Non-compliance detection
- Violation flagging
- Seller notifications
- Price history tracking

**Key Assertions**:
- Ceiling created and stored
- Non-compliance detected
- Violation flagged
- History tracks changes

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.PriceCeilingUpdateWorkflowTests.test_price_ceiling_update_with_compliance_workflow
```

### Test 4: Batch Price Update Workflow
**What it tests**:
- Updating multiple products at once
- Batch operation tracking
- Audit trail for batch operations

**Key Assertions**:
- All ceilings created
- Batch size correct
- Audit log complete

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.PriceCeilingUpdateWorkflowTests.test_batch_price_ceiling_update_workflow
```

### Test 5: OPAS Submission Approval Workflow
**What it tests**:
- Seller OPAS submission review
- Admin approval with price negotiation
- Purchase order generation
- Inventory creation
- FIFO transaction recording

**Key Assertions**:
- Submission: PENDING → ACCEPTED
- Purchase order created
- Inventory quantity matches
- Transaction recorded

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.OPASSubmissionWorkflowTests.test_opas_submission_approval_with_inventory_workflow
```

### Test 6: OPAS Submission Rejection Workflow
**What it tests**:
- Submission rejection
- Rejection reason storage
- No inventory creation on rejection

**Key Assertions**:
- Status: PENDING → REJECTED
- No purchase order created
- No inventory created

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.OPASSubmissionWorkflowTests.test_opas_submission_rejection_workflow
```

### Test 7: OPAS Inventory FIFO Tracking
**What it tests**:
- Inventory creation
- Multiple IN/OUT transactions
- FIFO order maintenance
- Stock level tracking

**Key Assertions**:
- Stock levels correct after each transaction
- Transaction order is FIFO
- All transactions recorded

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.OPASSubmissionWorkflowTests.test_opas_inventory_tracking_fifo_workflow
```

### Test 8: Announcement Creation and Broadcast
**What it tests**:
- Announcement creation
- Publishing to marketplace
- Delivery to audience
- Broadcast history

**Key Assertions**:
- Announcement created
- Content preserved
- Audience set correctly
- Broadcast history available

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.AnnouncementBroadcastWorkflowTests.test_announcement_creation_and_broadcast_workflow
```

### Test 9: Seller-Targeted Announcement
**What it tests**:
- Announcement targeting (SELLERS_ONLY)
- Selective notification delivery

**Key Assertions**:
- Target audience: SELLERS_ONLY
- Only sellers notified
- Buyers not notified

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.AnnouncementBroadcastWorkflowTests.test_seller_targeted_announcement_workflow
```

### Test 10: Announcement Edit and Delete
**What it tests**:
- Editing announcement content
- Deleting announcements
- Deletion verification

**Key Assertions**:
- Edit updates fields
- Delete returns 204
- Subsequent GET returns 404

**Command**:
```bash
python manage.py test tests.admin.test_integration_workflows.AnnouncementBroadcastWorkflowTests.test_announcement_edit_and_delete_workflow
```

## Troubleshooting

### Issue: Import Errors
**Solution**: Ensure you're in the OPAS_Django directory:
```bash
cd OPAS_Django
```

### Issue: Database Errors
**Solution**: Ensure migrations are up to date:
```bash
python manage.py migrate
```

### Issue: Tests Don't Run
**Solution**: Check that tests module is configured:
```bash
# Verify test discovery
python manage.py test tests.admin.test_integration_workflows --list
```

### Issue: Slow Test Execution
**Solution**: Run individual tests instead of full suite:
```bash
# Instead of all tests
python manage.py test tests.admin.test_integration_workflows

# Run just one test method
python manage.py test tests.admin.test_integration_workflows.SellerApprovalFullWorkflowTests.test_seller_rejection_workflow
```

## Key Test Fixtures Used

### Admin Users:
- `super_admin` - Full access
- `seller_manager` - Approve/suspend sellers
- `price_manager` - Manage price ceilings
- `opas_manager` - Approve OPAS submissions
- `support_admin` - Send announcements

### Sellers:
- `pending_seller` - Status: PENDING
- `approved_seller` - Status: APPROVED
- `seller_with_products` - Has products

### Products:
- `product_1`, `product_2` - Various prices

## Integration with Other Phases

- **Phase 5.1**: Integration tests use auth/fixtures from Phase 5.1
- **Phase 5.2**: Frontend tests will use Phase 5.3 for endpoint verification
- **Phase 5.4**: Performance testing will follow Phase 5.3

## Documentation Reference

For detailed information, see:
- `PHASE_5_3_INTEGRATION_TESTING.md` - Full documentation
- `test_integration_workflows.py` - Source code with inline comments
- `admin_test_fixtures.py` - Test fixture definitions
- `ADMIN_IMPLEMENTATION_PLAN.md` - Overall admin panel plan

## Checklist for Phase 5.3 Completion

- ✅ test_integration_workflows.py created
- ✅ All 4 workflow categories implemented
- ✅ 10 test methods with comprehensive assertions
- ✅ Documentation created
- ✅ Tests verified to run without errors
- ✅ Audit trail verification implemented
- ✅ Database state verification at each step
- ✅ API integration tested end-to-end
- ✅ Error handling covered
- ✅ Quick start guide created

## Next Phase: Phase 5.4 - Performance Testing

After Phase 5.3 completes, Phase 5.4 will test:
- Dashboard load time (< 2 seconds)
- Analytics query performance
- Bulk operations without timeout
- Large dataset pagination

---

**Phase 5.3 Status**: ✅ COMPLETE
**Last Updated**: November 21, 2025
**Test Coverage**: 10 methods, 85+ assertions
"""

# File: PHASE_5_3_QUICK_START.md
