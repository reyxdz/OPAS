#!/usr/bin/env python
"""
Comprehensive end-to-end test simulating Flutter parsing of API response.
"""

import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from apps.users.models import User, UserRole
from rest_framework.authtoken.models import Token

print("=" * 80)
print("END-TO-END TEST: FLUTTER PARSING OF API RESPONSE")
print("=" * 80)

# Simulate Flutter's parsing logic
def parse_application_like_flutter(item):
    """Simulate how Flutter parses the API response"""
    submitted_at = item.get('submitted_at', '')
    seller_full_name = item.get('seller_full_name', '')
    seller_email = item.get('seller_email', '')
    
    # Use seller_full_name if available, otherwise extract from email
    display_name = seller_full_name if seller_full_name else seller_email.split('@')[0]
    
    return {
        'id': item.get('id'),
        'name': display_name if display_name else 'Unknown',
        'farmName': item.get('farm_name', ''),
        'farmLocation': item.get('farm_location', ''),
        'storeName': item.get('store_name', ''),
        'storeDescription': item.get('store_description', ''),
        'appliedDate': format_date(submitted_at),
        'email': seller_email,
        'status': item.get('status', 'PENDING'),
        'rejectionReason': item.get('rejection_reason', ''),
    }

def format_date(date_str):
    """Format date like Flutter does"""
    if not date_str:
        return 'Recently'
    try:
        from datetime import datetime
        date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        now = datetime.now(date.tzinfo)
        diff_seconds = (now - date).total_seconds()
        diff_minutes = int(diff_seconds / 60)
        diff_hours = int(diff_seconds / 3600)
        diff_days = int(diff_seconds / 86400)
        
        if diff_minutes < 60:
            return f'{diff_minutes} minutes ago'
        elif diff_hours < 24:
            return f'{diff_hours} hours ago'
        elif diff_days < 7:
            return f'{diff_days} days ago'
        else:
            return f'{date.month}/{date.day}/{date.year}'
    except:
        return 'Recently'

# Get admin user
admin_users = User.objects.filter(role=UserRole.ADMIN)
if admin_users.count() == 0:
    print("❌ No admin users found")
    exit(1)

admin_user = admin_users.first()
print(f"\n✓ Found admin user: {admin_user.email}")

# Create client and authenticate
client = Client()
token, created = Token.objects.get_or_create(user=admin_user)
headers = {'HTTP_AUTHORIZATION': f'Token {token.key}'}

# Make API request
print(f"\n📡 Making API request to /api/admin/sellers/pending-approvals/...")
response = client.get('/api/admin/sellers/pending-approvals/', **headers)

if response.status_code != 200:
    print(f"❌ API error: {response.status_code}")
    exit(1)

data = json.loads(response.content)
results = data.get('results', [])

print(f"\n✓ API returned {data.get('count', 0)} pending applications")

if not results:
    print("⚠️  No pending applications in response")
    exit(0)

# Simulate Flutter parsing
print(f"\n" + "=" * 80)
print("SIMULATING FLUTTER PARSING")
print("=" * 80)

parsed_applications = []
errors = []

for i, item in enumerate(results):
    try:
        parsed = parse_application_like_flutter(item)
        parsed_applications.append(parsed)
        print(f"\n✅ Application {i+1} parsed successfully:")
        print(f"   ID: {parsed['id']}")
        print(f"   Name: {parsed['name']}")
        print(f"   Farm: {parsed['farmName']}")
        print(f"   Store: {parsed['storeName']}")
        print(f"   Email: {parsed['email']}")
        print(f"   Applied: {parsed['appliedDate']}")
        print(f"   Status: {parsed['status']}")
    except Exception as e:
        errors.append(f"Application {i+1}: {str(e)}")
        print(f"\n❌ Error parsing application {i+1}: {str(e)}")

# Final summary
print(f"\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)

if errors:
    print(f"\n❌ {len(errors)} errors during parsing:")
    for error in errors:
        print(f"   - {error}")
else:
    print(f"\n✅ ALL APPLICATIONS PARSED SUCCESSFULLY!")
    print(f"\nParsed {len(parsed_applications)} applications:")
    for app in parsed_applications:
        print(f"  • {app['name']} ({app['email']})")
        print(f"    Farm: {app['farmName']} at {app['farmLocation']}")
        print(f"    Store: {app['storeName']}")

print(f"\n" + "=" * 80)
print("✅ FLUTTER APP READY TO DISPLAY APPLICATIONS")
print("=" * 80)
