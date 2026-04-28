#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User, SellerApplication, UserRole, SellerStatus

# Get a test seller application
try:
    app = SellerApplication.objects.filter(status='PENDING').first()
    
    if not app:
        print("No pending applications found")
        exit(1)
    
    print(f"Found application: {app.id}")
    print(f"User: {app.user.email}")
    print(f"Current role: {app.user.role}")
    print(f"Current seller_status: {app.user.seller_status}")
    
    # Get admin user
    admin_user = User.objects.filter(role='ADMIN').first()
    if not admin_user:
        print("No admin user found")
        exit(1)
    
    print(f"\nAdmin user: {admin_user.email}")
    
    # Try to approve
    print("\nApproving application...")
    try:
        app.approve(admin_user=admin_user)
        print("✓ Approve successful!")
        
        # Refresh from database
        app.refresh_from_db()
        app.user.refresh_from_db()
        
        print(f"\nAfter approval:")
        print(f"App status: {app.status}")
        print(f"User role: {app.user.role}")
        print(f"User seller_status: {app.user.seller_status}")
        
    except Exception as e:
        print(f"✗ Error during approve: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
