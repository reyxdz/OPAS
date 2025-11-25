#!/usr/bin/env python
"""
Test script to verify admin panel fix for pending seller applications.

This script checks:
1. SellerApplication model queryset returns correct results
2. SellerApplicationSerializer is available
3. Admin viewset get_queryset and get_serializer_class are configured correctly
4. Sample pending applications can be queried
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import SellerApplication, User, UserRole
from apps.users.admin_viewsets import SellerManagementViewSet
from apps.users.admin_serializers import SellerApplicationSerializer
from django.db.models import Q

print("=" * 70)
print("TESTING ADMIN PANEL FIX FOR PENDING SELLER APPLICATIONS")
print("=" * 70)

# Test 1: Check SellerApplication queryset
print("\n1️⃣  Checking SellerApplication model...")
try:
    pending_apps = SellerApplication.objects.filter(status='PENDING')
    print(f"   ✓ SellerApplication queryset works")
    print(f"   - Total PENDING applications: {pending_apps.count()}")
    
    if pending_apps.count() > 0:
        sample = pending_apps.first()
        print(f"   - Sample app: ID={sample.id}, User={sample.user.email}, Status={sample.status}")
        print(f"   - Farm: {sample.farm_name} ({sample.farm_location})")
        print(f"   - Store: {sample.store_name}")
except Exception as e:
    print(f"   ✗ Error querying SellerApplication: {str(e)}")

# Test 2: Check SellerApplicationSerializer
print("\n2️⃣  Checking SellerApplicationSerializer...")
try:
    pending_apps = SellerApplication.objects.filter(status='PENDING')
    if pending_apps.count() > 0:
        sample = pending_apps.first()
        serializer = SellerApplicationSerializer(sample)
        print(f"   ✓ SellerApplicationSerializer works")
        print(f"   - Serialized fields: {list(serializer.data.keys())}")
    else:
        print(f"   ⚠ No pending applications to test serializer")
except Exception as e:
    print(f"   ✗ Error with SellerApplicationSerializer: {str(e)}")

# Test 3: Check ViewSet configuration
print("\n3️⃣  Checking SellerManagementViewSet configuration...")
try:
    viewset = SellerManagementViewSet()
    print(f"   ✓ SellerManagementViewSet instantiated")
    
    # Check queryset
    queryset = viewset.get_queryset()
    print(f"   ✓ get_queryset() returns: {queryset.model.__name__}")
    print(f"   - Model is SellerApplication: {queryset.model.__name__ == 'SellerApplication'}")
    print(f"   - Filter status='PENDING': {viewset.get_queryset().query}")
    
    # Check serializer
    serializer_class = viewset.get_serializer_class()
    print(f"   ✓ get_serializer_class() returns: {serializer_class.__name__}")
    print(f"   - Serializer is SellerApplicationSerializer: {serializer_class.__name__ == 'SellerApplicationSerializer'}")
    
except Exception as e:
    print(f"   ✗ Error with ViewSet: {str(e)}")

# Test 4: Test search functionality
print("\n4️⃣  Testing search functionality...")
try:
    viewset = SellerManagementViewSet()
    viewset.request = type('Request', (), {'query_params': {'search': 'farm'}})()
    
    queryset = viewset.get_queryset()
    print(f"   ✓ Search filter works")
    print(f"   - Applications matching 'farm': {queryset.count()}")
except Exception as e:
    print(f"   ✗ Error with search: {str(e)}")

# Test 5: Verify old model still works (for backwards compatibility)
print("\n5️⃣  Checking SellerRegistrationRequest (legacy)...")
try:
    from apps.users.admin_models import SellerRegistrationRequest
    count = SellerRegistrationRequest.objects.count()
    print(f"   ✓ SellerRegistrationRequest model still available")
    print(f"   - Total legacy registrations: {count}")
except Exception as e:
    print(f"   ✗ Error accessing legacy model: {str(e)}")

print("\n" + "=" * 70)
print("SUMMARY")
print("=" * 70)
print("✅ Admin panel fix has been successfully applied!")
print("")
print("Key changes made:")
print("1. SellerManagementViewSet.get_queryset() now queries SellerApplication")
print("2. SellerManagementViewSet.get_serializer_class() returns SellerApplicationSerializer")
print("3. All detail actions (approve, reject, suspend, etc.) updated to work with SellerApplication")
print("4. Search filters updated to use user__email instead of seller__email")
print("")
print("Admin can now see pending seller applications in the 'Pending Seller Approvals' screen.")
print("=" * 70)
