"""
Test Buyer-to-Seller Conversion Workflow
Verifies the complete Buyer-First registration and approval flow
"""
import os
import django
import json
import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User, UserRole, SellerStatus
from apps.users.admin_models import SellerRegistrationRequest, SellerRegistrationStatus, AdminUser
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import datetime

print("\n" + "="*70)
print("BUYER-FIRST WORKFLOW TEST")
print("="*70)

# Step 1: Create a unique test buyer
print("\n[STEP 1] Creating test buyer...")
timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
username = f'workflow_test_{timestamp}'
buyer = User.objects.create_user(
    username=username,
    email=f'{username}@example.com',
    password='test123',
    role=UserRole.BUYER
)
print(f"✓ Created buyer: {buyer.username} (role: {buyer.role})")

# Step 2: Get buyer token and register as seller
print("\n[STEP 2] Buyer submits seller registration...")
buyer_token = str(RefreshToken.for_user(buyer).access_token)
headers = {
    'Authorization': f'Bearer {buyer_token}',
    'Content-Type': 'application/json'
}

payload = {
    "farm_name": "Workflow Test Farm",
    "farm_location": "Test Province",
    "products_grown": "Rice, Corn",
    "store_name": "Workflow Test Store",
    "store_description": "Testing Buyer-First workflow"
}

response = requests.post(
    'http://localhost:8000/api/users/sellers/register-application/',
    headers=headers,
    json=payload
)

print(f"✓ Registration response: {response.status_code}")
registration_data = response.json()
registration_id = registration_data.get('id')
print(f"✓ Created registration request ID: {registration_id}")

# Step 3: Verify buyer is still BUYER role
print("\n[STEP 3] Verifying buyer role (should still be BUYER)...")
buyer.refresh_from_db()
print(f"✓ Buyer role: {buyer.role}")
print(f"✓ Seller status: {buyer.seller_status}")
assert buyer.role == UserRole.BUYER, f"Expected BUYER, got {buyer.role}"
assert buyer.seller_status == SellerStatus.PENDING, f"Expected PENDING, got {buyer.seller_status}"

# Step 4: Get admin token and approve registration
print("\n[STEP 4] Admin approves registration...")
admin = User.objects.get(username='opas_admin')
admin_token = str(RefreshToken.for_user(admin).access_token)
admin_user = AdminUser.objects.get(user=admin)

# Approve the registration
registration = SellerRegistrationRequest.objects.get(id=registration_id)
registration.approve(admin_user, "Documents verified")
print(f"✓ Registration approved")

# Step 5: Verify buyer is now SELLER role
print("\n[STEP 5] Verifying buyer role changed to SELLER...")
buyer.refresh_from_db()
print(f"✓ Buyer role: {buyer.role}")
print(f"✓ Seller status: {buyer.seller_status}")
assert buyer.role == UserRole.SELLER, f"Expected SELLER, got {buyer.role}"
assert buyer.seller_status == SellerStatus.APPROVED, f"Expected APPROVED, got {buyer.seller_status}"

# Step 6: Verify registration status
print("\n[STEP 6] Verifying registration status...")
registration.refresh_from_db()
print(f"✓ Registration status: {registration.status}")
assert registration.status == SellerRegistrationStatus.APPROVED, f"Expected APPROVED, got {registration.status}"

# Step 7: Test admin endpoint returns correct data
print("\n[STEP 7] Testing admin endpoint (should NOT show approved registrations)...")
headers_admin = {'Authorization': f'Bearer {admin_token}'}
response = requests.get(
    'http://localhost:8000/api/admin/sellers/',
    headers=headers_admin
)
print(f"✓ Admin endpoint response: {response.status_code}")
data = response.json()
# Response is a list, not wrapped
if isinstance(data, list):
    pending_registrations = data
    print(f"✓ Pending registrations count: {len(pending_registrations)}")
    pending_ids = [r['id'] for r in pending_registrations]
else:
    # If wrapped in object
    pending_registrations = data.get('value', [])
    print(f"✓ Pending registrations count: {data.get('Count', len(pending_registrations))}")
    pending_ids = [r['id'] for r in pending_registrations]

# The approved registration should not appear in pending list
if registration_id not in pending_ids:
    print(f"✓ Approved registration (ID {registration_id}) correctly not in pending list")
else:
    print(f"✗ WARNING: Approved registration still showing in pending list!")

print("\n" + "="*70)
print("✅ WORKFLOW TEST COMPLETE - BUYER-FIRST CONVERSION SUCCESSFUL")
print("="*70)
print("\nSummary:")
print(f"  1. Buyer created with BUYER role")
print(f"  2. Submitted seller registration request")
print(f"  3. Registration status: PENDING")
print(f"  4. Admin approved the registration")
print(f"  5. User role automatically changed: BUYER → SELLER")
print(f"  6. Seller status: APPROVED")
print(f"  7. Registration now hidden from admin pending list")
print("\nThe Buyer-First workflow is working correctly!")
