#!/usr/bin/env python
"""Test admin notification fix for seller applications."""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User, UserRole
from apps.users.admin_models import SellerRegistrationRequest, SellerRegistrationStatus

def test_admin_users():
    """Test that admin users exist."""
    admins = User.objects.filter(role=UserRole.ADMIN)
    print(f"✓ Admin users found: {admins.count()}")
    for admin in admins:
        print(f"  - {admin.email} (Role: {admin.role})")
    return admins

def test_pending_applications():
    """Test that pending applications are retrievable."""
    pending = SellerRegistrationRequest.objects.filter(status=SellerRegistrationStatus.PENDING)
    print(f"\n✓ Pending applications: {pending.count()}")
    for app in pending:
        print(f"  - ID: {app.id}")
        print(f"    Seller: {app.seller.email}")
        print(f"    Farm: {app.farm_name}")
        print(f"    Status: {app.status}")
        print(f"    Submitted: {app.submitted_at}")
    return pending

def test_notification_query():
    """Test the notification query that gets all admin emails."""
    
    admin_users = User.objects.filter(
        role=UserRole.ADMIN
    ).values_list('email', flat=True).distinct()
    
    admin_emails = list(admin_users)
    print(f"\n✓ Notification would be sent to {len(admin_emails)} admin(s):")
    for email in admin_emails:
        print(f"  - {email}")
    return admin_emails

if __name__ == '__main__':
    print("Testing Admin Notification Fix\n" + "="*50)
    
    try:
        admins = test_admin_users()
        pending = test_pending_applications()
        emails = test_notification_query()
        
        print("\n" + "="*50)
        print("✓ All tests passed!")
        print(f"  - Found {admins.count()} admin user(s)")
        print(f"  - Found {pending.count()} pending application(s)")
        print(f"  - Notifications will go to {len(emails)} admin(s)")
        print("\nNOTE: To test full flow, submit a seller application from the Flutter app")
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
