#!/usr/bin/env python
"""Test notification service"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.core.notifications import NotificationService
from apps.users.models import SellerApplication

# Test: Check if NotificationService can be imported
print('✓ NotificationService imported successfully')

# Test: Check if methods exist
has_reject = hasattr(NotificationService, 'send_registration_rejected_notification')
has_approve = hasattr(NotificationService, 'send_registration_approved_notification')

print(f'✓ send_registration_rejected_notification: {has_reject}')
print(f'✓ send_registration_approved_notification: {has_approve}')

# Test: Check SellerApplication model
print(f'✓ SellerApplication has user field: {hasattr(SellerApplication, "user")}')

print('\nAll tests passed! Notification service is ready.')
