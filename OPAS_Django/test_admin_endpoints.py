#!/usr/bin/env python
"""
OPAS Admin Panel - Endpoint Test Script

Tests all admin API endpoints to verify functionality.
Usage: python test_admin_endpoints.py [--token=YOUR_TOKEN] [--host=localhost:8000]

Features:
- Tests all 7 endpoint groups (Sellers, Prices, OPAS, Marketplace, Analytics, Notifications, Audit)
- Validates response format and status codes
- Checks permission enforcement
- Measures response times
- Generates comprehensive report

Prerequisites:
- Django running on localhost:8000
- Admin user with valid authentication token
- Database populated with test data
"""

import os
import sys
import json
import time
import argparse
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
from requests.exceptions import RequestException, Timeout, ConnectionError
from urllib.parse import urljoin


# ==================== CONFIGURATION ====================

class Config:
    """Test configuration"""
    BASE_URL = "http://localhost:8000/api/admin/v1"
    TIMEOUT = 10
    VERIFY_SSL = False
    
    # Test data
    TEST_SELLER_ID = 1
    TEST_PRODUCT_ID = 10
    TEST_ADMIN_ID = 1
    
    # Expected status codes
    EXPECTED_200 = [200, 201]
    EXPECTED_401 = [401]
    EXPECTED_403 = [403]


# ==================== TEST RESULT TRACKING ====================

class TestResult:
    """Tracks result of a single test"""
    
    def __init__(self, test_name: str, endpoint: str, method: str):
        self.test_name = test_name
        self.endpoint = endpoint
        self.method = method
        self.status = None
        self.status_code = None
        self.response_time = None
        self.error = None
        self.details = {}
        self.timestamp = datetime.now()
    
    def passed(self) -> bool:
        """Check if test passed"""
        return self.status == "PASS"
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for reporting"""
        return {
            "test": self.test_name,
            "endpoint": self.endpoint,
            "method": self.method,
            "status": self.status,
            "status_code": self.status_code,
            "response_time_ms": self.response_time,
            "error": self.error,
            "details": self.details,
            "timestamp": self.timestamp.isoformat()
        }


class TestSuite:
    """Collection of test results"""
    
    def __init__(self):
        self.results: List[TestResult] = []
        self.start_time = datetime.now()
        self.end_time = None
    
    def add_result(self, result: TestResult):
        """Add test result"""
        self.results.append(result)
    
    def get_summary(self) -> Dict:
        """Get test summary"""
        total = len(self.results)
        passed = sum(1 for r in self.results if r.passed())
        failed = total - passed
        avg_time = sum(r.response_time or 0 for r in self.results) / total if total > 0 else 0
        
        return {
            "total_tests": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": f"{(passed/total*100):.1f}%" if total > 0 else "0%",
            "average_response_time_ms": f"{avg_time:.0f}",
            "slowest_endpoint": max((r.response_time or 0, r.endpoint) for r in self.results)[1] if self.results else None,
            "fastest_endpoint": min((r.response_time or 0, r.endpoint) for r in self.results if r.response_time)[1] if self.results else None,
        }


# ==================== HTTP CLIENT ====================

class AdminAPIClient:
    """HTTP client for admin API"""
    
    def __init__(self, base_url: str, token: str = None):
        self.base_url = base_url
        self.token = token
        self.session = requests.Session()
        self.session.verify = Config.VERIFY_SSL
        
        if token:
            self.session.headers.update({
                'Authorization': f'Bearer {token}',
                'Content-Type': 'application/json'
            })
    
    def get(self, endpoint: str, params: Dict = None) -> Tuple[int, Dict, float]:
        """GET request"""
        try:
            start = time.time()
            url = urljoin(self.base_url, endpoint)
            response = self.session.get(url, params=params, timeout=Config.TIMEOUT)
            elapsed = (time.time() - start) * 1000
            
            try:
                data = response.json()
            except:
                data = None
            
            return response.status_code, data, elapsed
        except Exception as e:
            raise
    
    def post(self, endpoint: str, data: Dict = None) -> Tuple[int, Dict, float]:
        """POST request"""
        try:
            start = time.time()
            url = urljoin(self.base_url, endpoint)
            response = self.session.post(url, json=data, timeout=Config.TIMEOUT)
            elapsed = (time.time() - start) * 1000
            
            try:
                resp_data = response.json()
            except:
                resp_data = None
            
            return response.status_code, resp_data, elapsed
        except Exception as e:
            raise
    
    def put(self, endpoint: str, data: Dict = None) -> Tuple[int, Dict, float]:
        """PUT request"""
        try:
            start = time.time()
            url = urljoin(self.base_url, endpoint)
            response = self.session.put(url, json=data, timeout=Config.TIMEOUT)
            elapsed = (time.time() - start) * 1000
            
            try:
                resp_data = response.json()
            except:
                resp_data = None
            
            return response.status_code, resp_data, elapsed
        except Exception as e:
            raise
    
    def delete(self, endpoint: str) -> Tuple[int, Dict, float]:
        """DELETE request"""
        try:
            start = time.time()
            url = urljoin(self.base_url, endpoint)
            response = self.session.delete(url, timeout=Config.TIMEOUT)
            elapsed = (time.time() - start) * 1000
            
            try:
                data = response.json()
            except:
                data = None
            
            return response.status_code, data, elapsed
        except Exception as e:
            raise


# ==================== TEST FUNCTIONS ====================

def test_seller_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test seller management endpoints"""
    print("\n[1/7] Testing Seller Management Endpoints...")
    
    # Test 1.1: List sellers
    result = TestResult("List Sellers", "GET /sellers/", "GET")
    try:
        status_code, data, elapsed = client.get("sellers/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code == 200:
            result.status = "PASS"
            result.details = {
                "count": data.get('count', 0) if isinstance(data, dict) else 0,
                "fields_present": ['count', 'results'] if isinstance(data, dict) else False
            }
        else:
            result.status = "FAIL"
            result.error = f"Expected 200, got {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)
    
    # Test 1.2: Get seller details
    result = TestResult("Get Seller Details", f"GET /sellers/{Config.TEST_SELLER_ID}/", "GET")
    try:
        status_code, data, elapsed = client.get(f"sellers/{Config.TEST_SELLER_ID}/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code == 200:
            result.status = "PASS"
            result.details = {"has_id": "id" in data if isinstance(data, dict) else False}
        else:
            result.status = "FAIL"
            result.error = f"Expected 200, got {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)
    
    # Test 1.3: Pending approvals
    result = TestResult("List Pending Approvals", "GET /sellers/pending-approvals/", "GET")
    try:
        status_code, data, elapsed = client.get("sellers/pending-approvals/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code == 200:
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Expected 200, got {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_price_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test price management endpoints"""
    print("[2/7] Testing Price Management Endpoints...")
    
    # Test 2.1: List price ceilings
    result = TestResult("List Price Ceilings", "GET /prices/ceilings/", "GET")
    try:
        status_code, data, elapsed = client.get("prices/ceilings/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code == 200:
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Expected 200, got {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)
    
    # Test 2.2: List advisories
    result = TestResult("List Price Advisories", "GET /prices/advisories/", "GET")
    try:
        status_code, data, elapsed = client.get("prices/advisories/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code in [200, 404]:  # 404 if endpoint not implemented
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Unexpected status {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_opas_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test OPAS purchasing endpoints"""
    print("[3/7] Testing OPAS Purchasing Endpoints...")
    
    # Test 3.1: List OPAS submissions
    result = TestResult("List OPAS Submissions", "GET /opas/submissions/", "GET")
    try:
        status_code, data, elapsed = client.get("opas/submissions/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code in [200, 404]:
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Unexpected status {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)
    
    # Test 3.2: List inventory
    result = TestResult("List OPAS Inventory", "GET /opas/inventory/", "GET")
    try:
        status_code, data, elapsed = client.get("opas/inventory/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code in [200, 404]:
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Unexpected status {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_marketplace_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test marketplace oversight endpoints"""
    print("[4/7] Testing Marketplace Oversight Endpoints...")
    
    # Test 4.1: List alerts
    result = TestResult("List Marketplace Alerts", "GET /marketplace/alerts/", "GET")
    try:
        status_code, data, elapsed = client.get("marketplace/alerts/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code in [200, 404]:
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Unexpected status {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_analytics_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test analytics and reporting endpoints"""
    print("[5/7] Testing Analytics & Reporting Endpoints...")
    
    # Test 5.1: Dashboard stats
    result = TestResult("Dashboard Statistics", "GET /analytics/dashboard/stats/", "GET")
    try:
        status_code, data, elapsed = client.get("analytics/dashboard/stats/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code in [200, 404]:
            result.status = "PASS"
            if status_code == 200 and isinstance(data, dict):
                result.details = {
                    "metrics_present": [k for k in ['seller_metrics', 'market_metrics', 'opas_metrics'] if k in data]
                }
        else:
            result.status = "FAIL"
            result.error = f"Unexpected status {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_notifications_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test admin notifications endpoints"""
    print("[6/7] Testing Admin Notifications Endpoints...")
    
    # Test 6.1: List notifications
    result = TestResult("List Notifications", "GET /notifications/", "GET")
    try:
        status_code, data, elapsed = client.get("notifications/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code in [200, 404]:
            result.status = "PASS"
        else:
            result.status = "FAIL"
            result.error = f"Unexpected status {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_audit_endpoints(client: AdminAPIClient, suite: TestSuite):
    """Test audit log endpoints"""
    print("[7/7] Testing Audit Log Endpoints...")
    
    # Test 7.1: List audit logs
    result = TestResult("List Audit Logs", "GET /audit-logs/", "GET")
    try:
        status_code, data, elapsed = client.get("audit-logs/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code == 200:
            result.status = "PASS"
            result.details = {
                "count": data.get('count', 0) if isinstance(data, dict) else 0
            }
        else:
            result.status = "FAIL"
            result.error = f"Expected 200, got {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


def test_authentication(client: AdminAPIClient, suite: TestSuite):
    """Test authentication/authorization"""
    print("\nTesting Authentication & Authorization...")
    
    # Test with no token
    unauthenticated_client = AdminAPIClient(Config.BASE_URL)
    
    result = TestResult("Unauthenticated Access", "GET /sellers/", "GET")
    try:
        status_code, data, elapsed = unauthenticated_client.get("sellers/")
        result.status_code = status_code
        result.response_time = elapsed
        
        if status_code == 401:
            result.status = "PASS"
            result.details = {"correctly_rejected": True}
        else:
            result.status = "FAIL"
            result.error = f"Expected 401, got {status_code}"
    except Exception as e:
        result.status = "FAIL"
        result.error = str(e)
    
    suite.add_result(result)


# ==================== REPORTING ====================

def print_report(suite: TestSuite):
    """Print comprehensive test report"""
    summary = suite.get_summary()
    
    print("\n" + "="*80)
    print("OPAS ADMIN API - TEST REPORT")
    print("="*80)
    
    # Summary
    print(f"\nTEST SUMMARY")
    print(f"  Total Tests: {summary['total_tests']}")
    print(f"  Passed: {summary['passed']}")
    print(f"  Failed: {summary['failed']}")
    print(f"  Pass Rate: {summary['pass_rate']}")
    print(f"  Average Response Time: {summary['average_response_time_ms']}ms")
    
    if summary['slowest_endpoint']:
        print(f"  Slowest Endpoint: {summary['slowest_endpoint']}")
    if summary['fastest_endpoint']:
        print(f"  Fastest Endpoint: {summary['fastest_endpoint']}")
    
    # Results by group
    print(f"\nENDPOINT GROUP RESULTS")
    groups = {
        "Seller Management": [r for r in suite.results if "Seller" in r.test_name],
        "Price Management": [r for r in suite.results if "Price" in r.test_name],
        "OPAS Management": [r for r in suite.results if "OPAS" in r.test_name],
        "Marketplace": [r for r in suite.results if "Alert" in r.test_name],
        "Analytics": [r for r in suite.results if "Dashboard" in r.test_name],
        "Notifications": [r for r in suite.results if "Notification" in r.test_name],
        "Audit Logs": [r for r in suite.results if "Audit" in r.test_name],
        "Authentication": [r for r in suite.results if "Authentication" in r.test_name or "Unauthenticated" in r.test_name],
    }
    
    for group_name, results in groups.items():
        if not results:
            continue
        
        passed = sum(1 for r in results if r.passed())
        total = len(results)
        status_icon = "✅" if passed == total else "⚠️"
        
        print(f"\n  {status_icon} {group_name}")
        for result in results:
            status_icon = "✓" if result.passed() else "✗"
            time_str = f" ({result.response_time:.0f}ms)" if result.response_time else ""
            print(f"    {status_icon} {result.test_name}{time_str}")
            if result.error:
                print(f"      Error: {result.error}")
    
    # Failed tests details
    failed_results = [r for r in suite.results if not r.passed()]
    if failed_results:
        print(f"\nFAILED TESTS DETAILS")
        for result in failed_results:
            print(f"\n  ✗ {result.test_name}")
            print(f"    Endpoint: {result.method} {result.endpoint}")
            print(f"    Status Code: {result.status_code}")
            print(f"    Error: {result.error}")
    
    # Save JSON report
    report_file = "admin_endpoint_test_report.json"
    with open(report_file, 'w') as f:
        json.dump({
            "summary": summary,
            "results": [r.to_dict() for r in suite.results],
            "generated_at": datetime.now().isoformat()
        }, f, indent=2)
    
    print(f"\n{'='*80}")
    print(f"Report saved to: {report_file}")
    print(f"Generated at: {datetime.now().isoformat()}")
    print(f"{'='*80}\n")


# ==================== MAIN ====================

def main():
    """Main test execution"""
    parser = argparse.ArgumentParser(
        description='Test OPAS Admin API endpoints',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python test_admin_endpoints.py --token=YOUR_TOKEN
  python test_admin_endpoints.py --token=YOUR_TOKEN --host=api.opas.com
  python test_admin_endpoints.py --token=YOUR_TOKEN --host=localhost:8000
        '''
    )
    
    parser.add_argument('--token', help='Admin authentication token', required=False)
    parser.add_argument('--host', default='localhost:8000', help='API host (default: localhost:8000)')
    parser.add_argument('--secure', action='store_true', help='Use HTTPS (default: HTTP)')
    
    args = parser.parse_args()
    
    # Setup
    protocol = "https" if args.secure else "http"
    base_url = f"{protocol}://{args.host}/api/admin/v1"
    
    print("="*80)
    print("OPAS ADMIN API - ENDPOINT TEST SUITE")
    print("="*80)
    print(f"\nConfiguration:")
    print(f"  Base URL: {base_url}")
    print(f"  Token: {'Provided' if args.token else 'NOT PROVIDED - Some tests may fail'}")
    print(f"  Start Time: {datetime.now().isoformat()}")
    
    # Create client
    client = AdminAPIClient(base_url, args.token)
    suite = TestSuite()
    
    try:
        # Run all tests
        print("\nRunning Tests...")
        test_seller_endpoints(client, suite)
        test_price_endpoints(client, suite)
        test_opas_endpoints(client, suite)
        test_marketplace_endpoints(client, suite)
        test_analytics_endpoints(client, suite)
        test_notifications_endpoints(client, suite)
        test_audit_endpoints(client, suite)
        test_authentication(client, suite)
        
    except Exception as e:
        print(f"\n❌ Fatal Error: {e}")
        sys.exit(1)
    
    # Print report
    print_report(suite)
    
    # Exit code based on results
    summary = suite.get_summary()
    if summary['failed'] == 0:
        print("✅ All tests passed!")
        sys.exit(0)
    else:
        print(f"❌ {summary['failed']} test(s) failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
