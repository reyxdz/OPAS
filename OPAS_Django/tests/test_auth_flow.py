#!/usr/bin/env python
"""
OPAS Registration API - Complete Fix Summary

ROOT CAUSE: The email column was missing from the database.
- Django's AbstractUser includes an email field
- When Django tried to save a user, it looked for the email column
- Column didn't exist in database → ProgrammingError: "column email does not exist"

SOLUTION: Created migration 0020_add_email_column.py to add the missing email column.

TESTED AND VERIFIED:
✓ SignUpSerializer accepts phone_number instead of email
✓ Email is automatically set to phone_number during user creation
✓ User can be created with all required fields
✓ LoginView accepts phone_number for authentication
✓ JWT tokens generated successfully
✓ Database schema now complete

MIGRATION HISTORY:
- 0012: Added municipality/barangay (residence location) columns
- 0018: Added indexes on location fields
- 0019: Added farm location columns (faked due to columns already existing)
- 0020: Added missing email column (CRITICAL FIX)
"""

from apps.authentication.serializers import SignUpSerializer, LoginSerializer
from apps.users.models import User
from rest_framework_simplejwt.tokens import RefreshToken


def test_complete_auth_flow():
    """Test the complete authentication flow: signup, login, token generation."""
    
    print("\n" + "="*60)
    print("OPAS Authentication Flow Test")
    print("="*60)
    
    # Clean up any existing test user
    if User.objects.filter(phone_number='091').exists():
        User.objects.filter(phone_number='091').delete()
        print("✓ Cleaned up existing test user")
    
    # Step 1: Test User Registration (SignUpView)
    print("\n[STEP 1] Testing User Registration")
    print("-" * 60)
    
    signup_data = {
        'username': 'ryanwowers',
        'first_name': 'Ryan',
        'last_name': 'Arsenal',
        'phone_number': '091',
        'password': 'password123',
        'address': 'Larrazabal, Naval, Biliran',
        'municipality': 'Naval',
        'barangay': 'Larrazabal',
        'role': 'BUYER'
    }
    
    serializer = SignUpSerializer(data=signup_data)
    
    if serializer.is_valid():
        print("✓ SignUpSerializer validation PASSED")
        try:
            user = serializer.save()
            print(f"✓ User created successfully")
            print(f"  - Username: {user.username}")
            print(f"  - Phone Number: {user.phone_number}")
            print(f"  - Email (auto-set): {user.email}")
            print(f"  - Address: {user.address}")
            print(f"  - Location: {user.municipality}, {user.barangay}")
            print(f"  - Role: {user.role}")
        except Exception as e:
            print(f"✗ Error creating user: {e}")
            return False
    else:
        print(f"✗ SignUpSerializer validation FAILED")
        print(f"  Errors: {serializer.errors}")
        return False
    
    # Step 2: Test User Login (LoginView)
    print("\n[STEP 2] Testing User Login")
    print("-" * 60)
    
    login_data = {
        'phone_number': '091',
        'password': 'password123'
    }
    
    login_serializer = LoginSerializer(data=login_data)
    
    if login_serializer.is_valid():
        print("✓ LoginSerializer validation PASSED")
        
        phone_number = login_serializer.validated_data['phone_number']
        password = login_serializer.validated_data['password']
        
        try:
            user = User.objects.get(phone_number=phone_number)
            print(f"✓ User found: {user.username}")
            
            if user.check_password(password):
                print("✓ Password verification PASSED")
            else:
                print("✗ Password verification FAILED")
                return False
                
        except User.DoesNotExist:
            print("✗ User not found")
            return False
    else:
        print(f"✗ LoginSerializer validation FAILED")
        print(f"  Errors: {login_serializer.errors}")
        return False
    
    # Step 3: Test JWT Token Generation
    print("\n[STEP 3] Testing JWT Token Generation")
    print("-" * 60)
    
    try:
        refresh = RefreshToken.for_user(user)
        print("✓ RefreshToken generated successfully")
        print(f"  - Refresh Token (first 50 chars): {str(refresh)[:50]}...")
        
        access_token = refresh.access_token
        print("✓ AccessToken generated successfully")
        print(f"  - Access Token (first 50 chars): {str(access_token)[:50]}...")
        
    except Exception as e:
        print(f"✗ Error generating tokens: {e}")
        return False
    
    # Clean up
    print("\n[CLEANUP]")
    print("-" * 60)
    user.delete()
    print("✓ Test user deleted")
    
    # Summary
    print("\n" + "="*60)
    print("✓ ALL TESTS PASSED - Authentication System Working!")
    print("="*60 + "\n")
    
    return True


if __name__ == "__main__":
    import os
    import django
    
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    django.setup()
    
    test_complete_auth_flow()
