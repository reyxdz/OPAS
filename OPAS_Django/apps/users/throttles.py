"""
Phase 6: Rate Limiting Middleware
Implements sliding-window rate limiting for all endpoints

CORE PRINCIPLE: Backend Principles - Rate Limiting
Prevent abuse and denial-of-service attacks
"""

from django.core.cache import cache
from django.http import JsonResponse
from rest_framework.throttling import SimpleRateThrottle
from rest_framework.exceptions import Throttled
from datetime import timedelta
import time


class SlidingWindowThrottle(SimpleRateThrottle):
    """
    Sliding window rate throttle implementation.
    
    Advantages over fixed window:
    - Prevents burst attacks at window boundaries
    - More accurate request distribution
    - Better user experience
    """
    
    scope = "default"
    cache_format = "throttle_%(scope)s_%(ident)s"
    
    def throttle_success(self):
        """
        Implement the check to see if the request should be throttled.
        
        Returns `True` if the request should be allowed, `False` otherwise.
        """
        self.key = self.cache_format % {
            "scope": self.scope,
            "ident": self.get_ident(),
        }
        
        self.history = self.cache.get(self.key, [])
        self.now = time.time()
        
        # Drop requests that are older than the throttle window
        # (Sliding window: only consider recent requests)
        while self.history and self.history[-1] <= self.now - self.duration:
            self.history.pop()
        
        if len(self.history) >= self.num_requests:
            return False
        
        self.history.insert(0, self.now)
        self.cache.set(self.key, self.history, self.duration)
        return True
    
    def throttle_failure(self):
        """
        Called when a request to the API has failed due to throttling.
        """
        return False


# ============================================================================
# ENDPOINT-SPECIFIC THROTTLE CLASSES
# ============================================================================

class SellerRegistrationThrottle(SlidingWindowThrottle):
    """
    Seller registration throttle: 5 registrations per hour per user.
    
    Prevents spam registrations.
    CORE PRINCIPLE: Security - Rate Limiting
    """
    scope = "seller_registration"
    rate = "5/hour"


class SellerRegistrationListThrottle(SlidingWindowThrottle):
    """
    Seller registration list throttle: 30 requests per hour per user.
    
    Prevents excessive list queries (cheaper operation than submit).
    """
    scope = "seller_registration_list"
    rate = "30/hour"


class AdminApprovalThrottle(SlidingWindowThrottle):
    """
    Admin approval throttle: 60 approvals per hour per admin.
    
    Prevents accidental bulk approvals, reasonable limit for admin work.
    CORE PRINCIPLE: Security - Rate Limiting
    """
    scope = "admin_approval"
    rate = "60/hour"


class AdminListThrottle(SlidingWindowThrottle):
    """
    Admin list throttle: 100 requests per hour per admin.
    
    Admins need flexibility to review registrations.
    """
    scope = "admin_list"
    rate = "100/hour"


class LoginThrottle(SlidingWindowThrottle):
    """
    Login throttle: 10 attempts per hour per IP/user.
    
    Prevents brute force attacks.
    CORE PRINCIPLE: Security - Prevent Unauthorized Access
    """
    scope = "login"
    rate = "10/hour"
    
    def get_ident(self):
        """
        Override to use IP address instead of user ID.
        Prevents authenticated bypass.
        """
        # Use X-Forwarded-For if available (behind proxy)
        if "HTTP_X_FORWARDED_FOR" in self.request.META:
            return self.request.META["HTTP_X_FORWARDED_FOR"].split(",")[0].strip()
        return self.request.META.get("REMOTE_ADDR", "")


class TokenRefreshThrottle(SlidingWindowThrottle):
    """
    Token refresh throttle: 100 refreshes per hour per user.
    
    Allows frequent refreshes but prevents abuse.
    """
    scope = "token_refresh"
    rate = "100/hour"


class DefaultThrottle(SlidingWindowThrottle):
    """
    Default throttle for other endpoints: 1000 requests per hour per user.
    
    CORE PRINCIPLE: Security - Protect against DoS
    """
    scope = "default"
    rate = "1000/hour"


# ============================================================================
# THROTTLE MAPPING BY ENDPOINT
# ============================================================================

THROTTLE_MAPPING = {
    # Seller endpoints
    "seller.register_application": SellerRegistrationThrottle,
    "seller.list": SellerRegistrationListThrottle,
    "seller.retrieve": SellerRegistrationListThrottle,
    "seller.my_registration": SellerRegistrationListThrottle,
    
    # Admin endpoints
    "admin.approve_registration": AdminApprovalThrottle,
    "admin.reject_registration": AdminApprovalThrottle,
    "admin.request_info": AdminApprovalThrottle,
    "admin.list": AdminListThrottle,
    "admin.retrieve": AdminListThrottle,
    
    # Auth endpoints
    "auth.login": LoginThrottle,
    "auth.token_refresh": TokenRefreshThrottle,
}


def get_throttle_classes(view_name):
    """
    Get appropriate throttle class for given view name.
    
    Args:
        view_name: Django view name (e.g., "seller.register_application")
    
    Returns:
        List of throttle classes to apply
    """
    throttle_class = THROTTLE_MAPPING.get(view_name, DefaultThrottle)
    return [throttle_class]


# ============================================================================
# THROTTLE ERROR RESPONSE HANDLER
# ============================================================================

class ThrottledErrorHandler:
    """
    Custom error handler for throttled requests.
    
    Provides clear feedback to client with retry information.
    """
    
    @staticmethod
    def get_throttled_response(request, exception, throttle):
        """
        Generate throttled response with retry info.
        
        CORE PRINCIPLE: User Experience - Clear error messaging
        """
        retry_after = exception.wait()
        
        return JsonResponse(
            {
                "error": "Too many requests",
                "message": f"Rate limit exceeded. Please retry after {int(retry_after)} seconds.",
                "retry_after": int(retry_after),
                "status": 429,
            },
            status=429,
            headers={"Retry-After": str(int(retry_after))},
        )


# ============================================================================
# MONITORING & METRICS
# ============================================================================

class RateLimitMetrics:
    """
    Track rate limiting metrics for monitoring.
    
    CORE PRINCIPLE: Backend Principles - Monitoring
    """
    
    def __init__(self):
        self.throttled_requests = {}
        self.throttle_by_endpoint = {}
    
    def record_throttle(self, endpoint, user_id, reason):
        """Record a throttled request."""
        key = f"{endpoint}:{user_id}"
        self.throttled_requests[key] = self.throttled_requests.get(key, 0) + 1
        
        endpoint_key = endpoint
        self.throttle_by_endpoint[endpoint_key] = self.throttle_by_endpoint.get(
            endpoint_key, 0
        ) + 1
    
    def get_stats(self):
        """Get throttle statistics."""
        return {
            "total_throttled_requests": sum(self.throttled_requests.values()),
            "unique_throttled_users": len(self.throttled_requests),
            "throttled_by_endpoint": self.throttle_by_endpoint,
        }


# Global metrics instance
throttle_metrics = RateLimitMetrics()


# ============================================================================
# CONFIGURATION FOR settings.py
# ============================================================================

"""
Add to Django settings.py:

# Rate limiting (sliding window)
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'apps.users.throttles.DefaultThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'seller_registration': '5/hour',
        'seller_registration_list': '30/hour',
        'admin_approval': '60/hour',
        'admin_list': '100/hour',
        'login': '10/hour',
        'token_refresh': '100/hour',
        'default': '1000/hour',
    }
}

# Cache backend for throttling (Redis recommended)
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        ...
    }
}

# Monitoring
THROTTLE_MONITORING_ENABLED = True
THROTTLE_ALERT_THRESHOLD = 100  # Alert if >100 throttles/hour on same endpoint
"""

print("""
✅ Rate Limiting Module Configured:
   - Sliding window throttle implementation
   - Endpoint-specific limits
   - User-friendly error responses
   - Metrics tracking for monitoring
   - All CORE PRINCIPLES applied
""")
