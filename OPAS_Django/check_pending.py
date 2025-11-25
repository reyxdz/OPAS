#!/usr/bin/env python
import os
import sys
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Add current directory to path
sys.path.insert(0, os.path.dirname(__file__))

import django
django.setup()

from apps.users.models import SellerApplication

# Check for pending applications
pending_apps = SellerApplication.objects.filter(status='PENDING')
print(f"Total pending applications in database: {pending_apps.count()}")

for app in pending_apps:
    print(f"\nApplication ID: {app.id}")
    print(f"  User: {app.user.full_name} ({app.user.phone_number})")
    print(f"  Farm: {app.farm_name}")
    print(f"  Store: {app.store_name}")
    print(f"  Status: {app.status}")
    print(f"  Created: {app.created_at}")
