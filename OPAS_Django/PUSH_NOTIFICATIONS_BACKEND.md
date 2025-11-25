"""
Django Backend: Sending Push Notifications via FCM
Add this to your Django OPAS backend

Installation:
    pip install firebase-admin

Setup:
    1. Download Firebase service account key from Firebase Console
    2. Place in your project as 'firebase_service_account.json'
    3. Initialize Firebase Admin SDK (see __init__.py below)

NOTE: This is a reference guide. Copy code sections to your Django files.
"""

# ============================================================================
# FILE: settings.py
# ============================================================================
import os
import json

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH = os.path.join(BASE_DIR, 'firebase_service_account.json')

# Use environment variable in production
if os.getenv('FIREBASE_CREDENTIALS'):
    FIREBASE_CREDS_JSON = json.loads(os.getenv('FIREBASE_CREDENTIALS'))
else:
    with open(FIREBASE_CREDENTIALS_PATH, 'r') as f:
        FIREBASE_CREDS_JSON = json.load(f)


# apps.py - Initialize Firebase on startup
import firebase_admin
from firebase_admin import credentials

class YourAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'your_app_name'
    
    def ready(self):
        """Initialize Firebase Admin SDK when app is ready"""
        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(settings.FIREBASE_CREDS_JSON)
                firebase_admin.initialize_app(cred)
                print("✅ Firebase Admin SDK initialized")
        except Exception as e:
            print(f"⚠️ Firebase initialization error: {e}")


# models.py - Add FCM token field to User model
from django.contrib.auth.models import User

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    fcm_token = models.CharField(
        max_length=255,
        blank=True,
        help_text="Firebase Cloud Messaging token for push notifications"
    )
    updated_at = models.DateTimeField(auto_now=True)


# api/serializers.py
from rest_framework import serializers

class FCMTokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=255)


# api/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from firebase_admin import messaging

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_fcm_token(request):
    """
    Register/update FCM token for the logged-in user
    
    POST /api/v1/users/fcm-token/
    {
        "token": "..."
    }
    """
    serializer = FCMTokenSerializer(data=request.data)
    if serializer.is_valid():
        token = serializer.validated_data['token']
        
        # Update user's FCM token
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile.fcm_token = token
        profile.save()
        
        print(f"✅ FCM token registered for user {request.user.id}")
        return Response(
            {"detail": "FCM token registered successfully"},
            status=status.HTTP_200_OK
        )
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# utils/notifications.py - Notification helper functions
from firebase_admin import messaging
from apps.users.models import UserProfile

class PushNotificationService:
    """Service for sending push notifications to mobile users"""
    
    ACTIONS = {
        'REGISTRATION_APPROVED': 'Registration Approved',
        'REGISTRATION_REJECTED': 'Registration Rejected',
        'INFO_REQUESTED': 'Information Requested',
        'AUDIT_LOG': 'Audit Log Update',
    }
    
    @staticmethod
    def send_to_user(user, title: str, body: str, action: str, data: dict = None):
        """
        Send notification to a specific user via FCM
        
        Args:
            user: Django User instance
            title: Notification title
            body: Notification body
            action: Action type (see ACTIONS)
            data: Additional data to send
        """
        try:
            profile = UserProfile.objects.get(user=user)
            if not profile.fcm_token:
                print(f"⚠️ No FCM token for user {user.id}")
                return False
            
            message_data = {
                'action': action,
                **(data or {})
            }
            
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=message_data,
                token=profile.fcm_token,
            )
            
            response = messaging.send(message)
            print(f"✅ Notification sent to user {user.id}: {response}")
            return True
            
        except UserProfile.DoesNotExist:
            print(f"⚠️ No profile for user {user.id}")
            return False
        except Exception as e:
            print(f"❌ Error sending notification: {e}")
            return False
    
    @staticmethod
    def send_to_role(role: str, title: str, body: str, action: str):
        """
        Send notification to all users with specific role
        
        Args:
            role: User role (SELLER, ADMIN, BUYER)
            title: Notification title
            body: Notification body
            action: Action type
        """
        users = User.objects.filter(groups__name=role)
        success_count = 0
        
        for user in users:
            if PushNotificationService.send_to_user(
                user, title, body, action
            ):
                success_count += 1
        
        print(f"📊 Sent to {success_count}/{users.count()} {role} users")
        return success_count
    
    @staticmethod
    def send_registration_approval(seller_registration):
        """Send approval notification"""
        return PushNotificationService.send_to_user(
            user=seller_registration.seller.user,
            title="Registration Approved ✅",
            body="Your seller registration has been approved!",
            action="REGISTRATION_APPROVED",
            data={
                'registration_id': str(seller_registration.id),
            }
        )
    
    @staticmethod
    def send_registration_rejection(seller_registration, reason: str = ""):
        """Send rejection notification"""
        return PushNotificationService.send_to_user(
            user=seller_registration.seller.user,
            title="Registration Rejected ❌",
            body=reason or "Your registration was not approved.",
            action="REGISTRATION_REJECTED",
            data={
                'registration_id': str(seller_registration.id),
            }
        )
    
    @staticmethod
    def send_info_requested(seller_registration):
        """Send info request notification"""
        return PushNotificationService.send_to_user(
            user=seller_registration.seller.user,
            title="Information Needed",
            body="Please provide additional information for your application.",
            action="INFO_REQUESTED",
            data={
                'registration_id': str(seller_registration.id),
            }
        )


# Example usage in views.py

@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdmin])
def approve_registration(request, registration_id):
    """Approve seller registration and send notification"""
    registration = SellerRegistration.objects.get(id=registration_id)
    registration.status = 'APPROVED'
    registration.save()
    
    # Send push notification
    PushNotificationService.send_registration_approval(registration)
    
    return Response({"detail": "Registration approved and user notified"})


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdmin])
def reject_registration(request, registration_id):
    """Reject seller registration and send notification"""
    registration = SellerRegistration.objects.get(id=registration_id)
    registration.status = 'REJECTED'
    registration.reject_reason = request.data.get('reason', '')
    registration.save()
    
    # Send push notification
    PushNotificationService.send_registration_rejection(
        registration,
        reason=registration.reject_reason
    )
    
    return Response({"detail": "Registration rejected and user notified"})


# api/urls.py
from django.urls import path
from .views import register_fcm_token, approve_registration, reject_registration

urlpatterns = [
    # ... other urls
    path('users/fcm-token/', register_fcm_token, name='register-fcm-token'),
    path('registrations/<int:registration_id>/approve/', approve_registration),
    path('registrations/<int:registration_id>/reject/', reject_registration),
]


# requirements.txt
firebase-admin>=6.2.0


# Testing in Django shell
# python manage.py shell

from apps.users.models import User, UserProfile
from utils.notifications import PushNotificationService

# Get a user
user = User.objects.first()

# Send test notification
PushNotificationService.send_to_user(
    user=user,
    title="Test Notification",
    body="This is a test from Django backend!",
    action="TEST",
    data={"test_id": "123"}
)

# Send to all admins
PushNotificationService.send_to_role(
    role='ADMIN',
    title="System Alert",
    body="All admin users see this",
    action="ALERT"
)
