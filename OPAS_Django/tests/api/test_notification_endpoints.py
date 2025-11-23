"""
Test script for Notification and Announcement endpoints
Tests all endpoints with various scenarios
"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://127.0.0.1:8000/api/users"

# Test credentials - update with actual seller credentials
SELLER_EMAIL = "seller@test.com"  # Update with actual seller email
SELLER_PASSWORD = "testpass123"   # Update with actual seller password

class NotificationEndpointTester:
    def __init__(self, base_url=BASE_URL):
        self.base_url = base_url
        self.token = None
        self.user_id = None
        self.session = requests.Session()
        
    def get_token(self):
        """Authenticate and get JWT token"""
        try:
            # Get token from authentication endpoint
            auth_url = f"{self.base_url.replace('/api/users', '')}/api/token/"
            response = self.session.post(auth_url, json={
                "email": SELLER_EMAIL,
                "password": SELLER_PASSWORD
            })
            
            if response.status_code == 200:
                self.token = response.json().get('access')
                self.user_id = response.json().get('user_id')
                self.session.headers.update({
                    'Authorization': f'Bearer {self.token}',
                    'Content-Type': 'application/json'
                })
                print(f"✓ Authentication successful for {SELLER_EMAIL}")
                return True
            else:
                print(f"✗ Authentication failed: {response.status_code}")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Authentication error: {str(e)}")
            return False
    
    def test_get_notifications(self):
        """Test GET /api/users/seller/notifications/"""
        try:
            url = f"{self.base_url}/seller/notifications/"
            response = self.session.get(url)
            
            print(f"\n[GET] {url}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✓ Notifications retrieved successfully")
                print(f"  Count: {len(data) if isinstance(data, list) else data.get('count', 'N/A')}")
                print(f"  Response: {json.dumps(data, indent=2)[:500]}...")
                return True
            else:
                print(f"✗ Failed to get notifications")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Error getting notifications: {str(e)}")
            return False
    
    def test_get_notifications_filtered(self):
        """Test GET /api/users/seller/notifications/?type=Orders"""
        try:
            url = f"{self.base_url}/seller/notifications/?type=Orders"
            response = self.session.get(url)
            
            print(f"\n[GET] {url}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✓ Filtered notifications retrieved successfully")
                print(f"  Response: {json.dumps(data, indent=2)[:500]}...")
                return True
            else:
                print(f"✗ Failed to get filtered notifications")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Error getting filtered notifications: {str(e)}")
            return False
    
    def test_get_announcements(self):
        """Test GET /api/users/seller/announcements/"""
        try:
            url = f"{self.base_url}/seller/announcements/"
            response = self.session.get(url)
            
            print(f"\n[GET] {url}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✓ Announcements retrieved successfully")
                print(f"  Count: {len(data) if isinstance(data, list) else data.get('count', 'N/A')}")
                print(f"  Response: {json.dumps(data, indent=2)[:500]}...")
                return True
            else:
                print(f"✗ Failed to get announcements")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Error getting announcements: {str(e)}")
            return False
    
    def test_get_announcements_filtered(self):
        """Test GET /api/users/seller/announcements/?priority=HIGH"""
        try:
            url = f"{self.base_url}/seller/announcements/?priority=HIGH"
            response = self.session.get(url)
            
            print(f"\n[GET] {url}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✓ Filtered announcements retrieved successfully")
                print(f"  Response: {json.dumps(data, indent=2)[:500]}...")
                return True
            else:
                print(f"✗ Failed to get filtered announcements")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Error getting filtered announcements: {str(e)}")
            return False
    
    def test_mark_notification_read(self, notification_id=1):
        """Test POST /api/users/seller/notifications/{id}/mark_read/"""
        try:
            url = f"{self.base_url}/seller/notifications/{notification_id}/mark_read/"
            response = self.session.post(url)
            
            print(f"\n[POST] {url}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✓ Notification marked as read successfully")
                print(f"  Response: {json.dumps(data, indent=2)[:500]}...")
                return True
            elif response.status_code == 404:
                print(f"✗ Notification not found (404)")
                print(f"  Note: Create a notification first to test this endpoint")
                return False
            else:
                print(f"✗ Failed to mark notification as read")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Error marking notification as read: {str(e)}")
            return False
    
    def test_mark_announcement_read(self, announcement_id=1):
        """Test POST /api/users/seller/announcements/{id}/mark_read/"""
        try:
            url = f"{self.base_url}/seller/announcements/{announcement_id}/mark_read/"
            response = self.session.post(url)
            
            print(f"\n[POST] {url}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✓ Announcement marked as read successfully")
                print(f"  Response: {json.dumps(data, indent=2)[:500]}...")
                return True
            elif response.status_code == 404:
                print(f"✗ Announcement not found (404)")
                print(f"  Note: Create an announcement first to test this endpoint")
                return False
            else:
                print(f"✗ Failed to mark announcement as read")
                print(f"  Response: {response.text}")
                return False
        except Exception as e:
            print(f"✗ Error marking announcement as read: {str(e)}")
            return False
    
    def run_all_tests(self):
        """Run all tests"""
        print("=" * 70)
        print("NOTIFICATION & ANNOUNCEMENT ENDPOINTS TEST SUITE")
        print("=" * 70)
        
        # Authenticate first
        if not self.get_token():
            print("\n✗ Cannot proceed without authentication")
            return
        
        print("\n" + "=" * 70)
        print("RUNNING ENDPOINT TESTS")
        print("=" * 70)
        
        # Run all tests
        results = {
            "Get Notifications": self.test_get_notifications(),
            "Get Notifications (Filtered)": self.test_get_notifications_filtered(),
            "Get Announcements": self.test_get_announcements(),
            "Get Announcements (Filtered)": self.test_get_announcements_filtered(),
            "Mark Notification Read": self.test_mark_notification_read(),
            "Mark Announcement Read": self.test_mark_announcement_read(),
        }
        
        # Summary
        print("\n" + "=" * 70)
        print("TEST SUMMARY")
        print("=" * 70)
        
        passed = sum(1 for v in results.values() if v)
        total = len(results)
        
        for test_name, result in results.items():
            status = "✓ PASS" if result else "✗ FAIL"
            print(f"{status}: {test_name}")
        
        print(f"\nTotal: {passed}/{total} tests passed")
        print("=" * 70)


if __name__ == "__main__":
    # Update credentials before running
    print("Note: Update SELLER_EMAIL and SELLER_PASSWORD in the script before running")
    print(f"Current credentials: {SELLER_EMAIL} / {SELLER_PASSWORD}")
    
    tester = NotificationEndpointTester()
    tester.run_all_tests()
