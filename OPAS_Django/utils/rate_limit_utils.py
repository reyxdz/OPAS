"""
Rate limiting utilities for OPAS application.

Provides rate limiting decorators and throttle classes for:
- Endpoint-level rate limiting
- User-based throttling
- IP-based throttling
- Action-based rate limits (read, write, delete)
"""

import time
from functools import wraps
from typing import Callable, Optional, Tuple
from django.core.cache import cache
from django.conf import settings
from django.http import JsonResponse
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from rest_framework.response import Response
from rest_framework import status


class RateLimitConfig:
    """Rate limit configuration."""
    
    # Extract settings from Django config
    SETTINGS = settings.RATELIMIT_SETTINGS
    
    # Admin limits
    ADMIN_READ = SETTINGS.get('admin_read', '100/h')
    ADMIN_WRITE = SETTINGS.get('admin_write', '50/h')
    ADMIN_DELETE = SETTINGS.get('admin_delete', '20/h')
    ADMIN_ANALYTICS = SETTINGS.get('admin_analytics', '200/h')
    
    # Seller limits
    SELLER_READ = SETTINGS.get('seller_read', '500/h')
    SELLER_WRITE = SETTINGS.get('seller_write', '200/h')
    SELLER_UPLOAD = SETTINGS.get('seller_upload', '50/h')
    
    # Auth limits
    AUTH_LOGIN = SETTINGS.get('auth_login', '10/m')
    AUTH_REGISTER = SETTINGS.get('auth_register', '3/h')


def parse_rate_limit(rate_string: str) -> Tuple[int, int]:
    """
    Parse rate limit string to (requests, seconds).
    
    Args:
        rate_string: Rate limit in format "N/unit"
                    Units: 's' (second), 'm' (minute), 'h' (hour), 'd' (day)
    
    Returns:
        Tuple of (number of requests, time period in seconds)
    
    Example:
        parse_rate_limit('100/h')  # Returns (100, 3600)
        parse_rate_limit('10/m')   # Returns (10, 60)
    
    Raises:
        ValueError: If rate string format is invalid
    """
    try:
        requests, unit = rate_string.split('/')
        requests = int(requests)
        
        time_units = {
            's': 1,
            'm': 60,
            'h': 3600,
            'd': 86400,
        }
        
        if unit not in time_units:
            raise ValueError(f"Invalid time unit: {unit}")
        
        seconds = time_units[unit]
        return requests, seconds * requests  # Return total time window
    
    except (ValueError, AttributeError) as e:
        raise ValueError(f"Invalid rate limit format: {rate_string}") from e


def get_client_identifier(request) -> str:
    """
    Get unique identifier for client (user or IP).
    
    Args:
        request: Django request object
    
    Returns:
        Unique client identifier
    """
    if request.user and request.user.is_authenticated:
        return f"user_{request.user.id}"
    
    # Get client IP (handle proxies)
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    
    return f"ip_{ip}"


def rate_limit(limit: str, key_func: Optional[Callable] = None):
    """
    Decorator for rate limiting view functions and methods.
    
    Args:
        limit: Rate limit string (e.g., '100/h', '10/m')
        key_func: Optional function to generate cache key.
                 If None, uses client identifier
    
    Returns:
        Decorated function with rate limiting
    
    Example:
        @rate_limit('100/h')
        def my_view(request):
            return Response({'status': 'ok'})
        
        @rate_limit('50/h', key_func=lambda req: f"user_{req.user.id}_sales")
        def sales_report(request):
            return Response({...})
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(request=None, *args, **kwargs):
            # For class-based views, request is self
            if hasattr(request, 'request'):
                actual_request = request.request
            else:
                actual_request = request
            
            if not actual_request:
                return func(request, *args, **kwargs)
            
            # Generate cache key
            if key_func:
                cache_key = f"ratelimit_{key_func(actual_request)}"
            else:
                client_id = get_client_identifier(actual_request)
                cache_key = f"ratelimit_{client_id}_{func.__name__}"
            
            # Parse rate limit
            requests, seconds = parse_rate_limit(limit)
            
            # Get current request count
            request_count = cache.get(cache_key, 0)
            
            if request_count >= requests:
                # Rate limit exceeded
                response = Response(
                    {
                        'detail': f'Rate limit exceeded. {requests} requests per {seconds // 60 if seconds >= 60 else seconds}{"m" if seconds >= 60 else "s"}',
                        'retry_after': seconds,
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )
                response['Retry-After'] = seconds
                return response
            
            # Increment counter
            cache.set(cache_key, request_count + 1, seconds)
            
            # Execute function
            response = func(request, *args, **kwargs)
            
            # Add rate limit headers
            if hasattr(response, '__setitem__'):
                response['X-RateLimit-Limit'] = requests
                response['X-RateLimit-Remaining'] = requests - request_count - 1
                response['X-RateLimit-Reset'] = int(time.time()) + seconds
            
            return response
        
        return wrapper
    
    return decorator


class AdminReadThrottle(UserRateThrottle):
    """Rate throttle for admin read operations."""
    scope = 'admin_read'
    THROTTLE_RATES = {
        'admin_read': RateLimitConfig.ADMIN_READ,
    }


class AdminWriteThrottle(UserRateThrottle):
    """Rate throttle for admin write operations."""
    scope = 'admin_write'
    THROTTLE_RATES = {
        'admin_write': RateLimitConfig.ADMIN_WRITE,
    }


class AdminDeleteThrottle(UserRateThrottle):
    """Rate throttle for admin delete operations."""
    scope = 'admin_delete'
    THROTTLE_RATES = {
        'admin_delete': RateLimitConfig.ADMIN_DELETE,
    }


class AdminAnalyticsThrottle(UserRateThrottle):
    """Rate throttle for analytics endpoints."""
    scope = 'admin_analytics'
    THROTTLE_RATES = {
        'admin_analytics': RateLimitConfig.ADMIN_ANALYTICS,
    }


class SellerReadThrottle(UserRateThrottle):
    """Rate throttle for seller read operations."""
    scope = 'seller_read'
    THROTTLE_RATES = {
        'seller_read': RateLimitConfig.SELLER_READ,
    }


class SellerWriteThrottle(UserRateThrottle):
    """Rate throttle for seller write operations."""
    scope = 'seller_write'
    THROTTLE_RATES = {
        'seller_write': RateLimitConfig.SELLER_WRITE,
    }


class SellerUploadThrottle(UserRateThrottle):
    """Rate throttle for seller upload operations."""
    scope = 'seller_upload'
    THROTTLE_RATES = {
        'seller_upload': RateLimitConfig.SELLER_UPLOAD,
    }


class AuthLoginThrottle(AnonRateThrottle):
    """Rate throttle for login attempts."""
    scope = 'auth_login'
    THROTTLE_RATES = {
        'anon': RateLimitConfig.AUTH_LOGIN,
    }


class AuthRegisterThrottle(AnonRateThrottle):
    """Rate throttle for registration attempts."""
    scope = 'auth_register'
    THROTTLE_RATES = {
        'anon': RateLimitConfig.AUTH_REGISTER,
    }


def throttle_action(throttle_classes: list):
    """
    Decorator to apply throttles to specific view actions.
    
    Args:
        throttle_classes: List of throttle classes to apply
    
    Returns:
        Decorated action method
    
    Example:
        @action(detail=False, methods=['post'])
        @throttle_action([AdminWriteThrottle])
        def create_ceiling(self, request):
            ...
    """
    def decorator(func: Callable) -> Callable:
        func.throttle_classes = throttle_classes
        return func
    
    return decorator


class RateLimitMiddleware:
    """
    Middleware for global rate limiting.
    
    Rate limits requests by IP address at the middleware level.
    Useful for DDoS protection.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.limit_per_ip = '1000/h'  # Configurable
    
    def __call__(self, request):
        # Get client IP
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        
        # Check rate limit
        cache_key = f"middleware_ratelimit_{ip}"
        requests, seconds = parse_rate_limit(self.limit_per_ip)
        request_count = cache.get(cache_key, 0)
        
        if request_count >= requests:
            return JsonResponse(
                {'detail': 'Too many requests from this IP address'},
                status=429
            )
        
        # Increment counter
        cache.set(cache_key, request_count + 1, seconds)
        
        response = self.get_response(request)
        return response


def get_rate_limit_stats(request) -> dict:
    """
    Get current rate limit statistics for a request.
    
    Args:
        request: Django request object
    
    Returns:
        Dictionary with current rate limit info
    
    Example:
        stats = get_rate_limit_stats(request)
        # Returns: {
        #     'client_id': 'user_123',
        #     'limits': {
        #         'read': {'used': 25, 'limit': 100},
        #         'write': {'used': 5, 'limit': 50},
        #     }
        # }
    """
    client_id = get_client_identifier(request)
    
    limits = {}
    
    # Check various rate limits
    for action in ['read', 'write', 'delete']:
        cache_key = f"ratelimit_{client_id}_{action}"
        used = cache.get(cache_key, 0)
        
        # Get configured limit (if exists)
        if hasattr(request.user, 'role'):
            limit_key = f"user_{action}"
        else:
            limit_key = f"anon_{action}"
        
        # Default limits
        default_limits = {
            'user_read': 500,
            'user_write': 100,
            'user_delete': 20,
            'anon_read': 100,
        }
        
        limit = default_limits.get(limit_key, 100)
        limits[action] = {
            'used': used,
            'limit': limit,
            'remaining': max(0, limit - used),
        }
    
    return {
        'client_id': client_id,
        'is_authenticated': request.user and request.user.is_authenticated,
        'limits': limits,
    }
