"""
Verify that the notification and announcement endpoints are properly configured
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, 'c:\\BSCS-4B\\Thesis\\OPAS_Application\\OPAS_Django')
django.setup()

from django.urls import get_resolver
from django.urls.exceptions import Resolver404

# Get all URL patterns
resolver = get_resolver()

print("=" * 70)
print("VERIFYING NOTIFICATION AND ANNOUNCEMENT ENDPOINTS")
print("=" * 70)

# Check for notification endpoints
notification_patterns = [
    'api/users/seller/notifications/',
    'api/users/seller/notifications/mark_all_read/',
    'api/users/seller/announcements/',
]

print("\n[CHECKING URL PATTERNS]")
found_patterns = []
for pattern in resolver.url_patterns:
    pattern_str = str(pattern.pattern)
    if 'notifications' in pattern_str or 'announcements' in pattern_str:
        found_patterns.append(pattern_str)
        print(f"✓ Found: {pattern_str}")

if not found_patterns:
    print("✗ No notification/announcement patterns found!")
else:
    print(f"\n✓ Total patterns found: {len(found_patterns)}")

# Check models
print("\n[CHECKING MODELS]")
try:
    from apps.users.seller_models import Notification, Announcement, SellerAnnouncementRead
    print("✓ Notification model imported successfully")
    print("✓ Announcement model imported successfully")
    print("✓ SellerAnnouncementRead model imported successfully")
    
    # Check fields
    print("\n[CHECKING MODEL FIELDS]")
    notification_fields = [f.name for f in Notification._meta.get_fields()]
    print(f"Notification fields: {notification_fields}")
    
    if 'type' in notification_fields:
        print("✓ Notification.type field exists")
    else:
        print("✗ Notification.type field NOT found")
    
    announcement_fields = [f.name for f in Announcement._meta.get_fields()]
    print(f"\nAnnouncement fields: {announcement_fields}")
    
except ImportError as e:
    print(f"✗ Error importing models: {e}")

# Check serializers
print("\n[CHECKING SERIALIZERS]")
try:
    from apps.users.seller_serializers import (
        NotificationSerializer, NotificationListSerializer,
        AnnouncementSerializer, AnnouncementListSerializer
    )
    print("✓ NotificationSerializer imported successfully")
    print("✓ NotificationListSerializer imported successfully")
    print("✓ AnnouncementSerializer imported successfully")
    print("✓ AnnouncementListSerializer imported successfully")
except ImportError as e:
    print(f"✗ Error importing serializers: {e}")

# Check views
print("\n[CHECKING VIEWSETS]")
try:
    from apps.users.seller_views import NotificationViewSet, AnnouncementViewSet
    print("✓ NotificationViewSet imported successfully")
    print("✓ AnnouncementViewSet imported successfully")
    
    # Check available actions
    print("\nNotificationViewSet actions:")
    for action in ['list', 'retrieve', 'mark_read', 'mark_all_read']:
        if hasattr(NotificationViewSet, action):
            print(f"  ✓ {action}")
        else:
            print(f"  ✗ {action}")
    
    print("\nAnnouncementViewSet actions:")
    for action in ['list', 'retrieve', 'mark_read']:
        if hasattr(AnnouncementViewSet, action):
            print(f"  ✓ {action}")
        else:
            print(f"  ✗ {action}")
            
except ImportError as e:
    print(f"✗ Error importing views: {e}")

# Check database tables
print("\n[CHECKING DATABASE TABLES]")
try:
    from django.db import connection
    cursor = connection.cursor()
    
    # Get existing tables
    cursor.execute("""
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public'
    """)
    tables = [row[0] for row in cursor.fetchall()]
    
    expected_tables = ['seller_notifications', 'seller_announcements', 'seller_announcement_reads']
    for table in expected_tables:
        if table in tables:
            print(f"✓ Table '{table}' exists")
        else:
            print(f"✗ Table '{table}' NOT found")
    
    # Check table structure for seller_notifications
    if 'seller_notifications' in tables:
        cursor.execute("""
            SELECT column_name, data_type FROM information_schema.columns
            WHERE table_name = 'seller_notifications'
            ORDER BY ordinal_position
        """)
        columns = cursor.fetchall()
        print(f"\nColumns in seller_notifications:")
        for col_name, col_type in columns:
            print(f"  - {col_name} ({col_type})")
            
except Exception as e:
    print(f"✗ Error checking database: {e}")

print("\n" + "=" * 70)
print("VERIFICATION COMPLETE")
print("=" * 70)
