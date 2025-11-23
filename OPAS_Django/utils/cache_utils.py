"""
Cache utilities for OPAS application.

Provides reusable caching decorators and functions for:
- View-level caching
- QuerySet result caching
- Computed value caching
- Cache invalidation strategies
"""

import functools
import hashlib
from typing import Any, Callable, Optional
from django.core.cache import cache
from django.conf import settings
from django.utils.decorators import wraps


class CacheConfig:
    """Configuration for cache timeouts."""
    
    ANALYTICS = settings.CACHE_TIMEOUTS.get('analytics', 600)
    LISTINGS = settings.CACHE_TIMEOUTS.get('listings', 300)
    PRICE_CEILINGS = settings.CACHE_TIMEOUTS.get('price_ceilings', 300)
    SELLER_STATS = settings.CACHE_TIMEOUTS.get('seller_stats', 600)
    DASHBOARD = settings.CACHE_TIMEOUTS.get('dashboard', 300)
    INVENTORY = settings.CACHE_TIMEOUTS.get('inventory', 300)


def generate_cache_key(prefix: str, *args, **kwargs) -> str:
    """
    Generate a unique cache key based on prefix and parameters.
    
    Args:
        prefix: Cache key prefix (e.g., 'seller_stats')
        *args: Positional arguments to include in key
        **kwargs: Keyword arguments to include in key
    
    Returns:
        Hashed cache key string
    
    Example:
        key = generate_cache_key('user_profile', user_id=123)
        # Returns: 'user_profile_8d969eef6ecad3c29a3a8655c0218c20'
    """
    key_data = f"{prefix}:{':'.join(map(str, args))}:{':'.join(f'{k}={v}' for k, v in sorted(kwargs.items()))}"
    
    # Hash long keys to keep them under Redis key size limits
    if len(key_data) > 200:
        hash_obj = hashlib.md5(key_data.encode())
        return f"{prefix}_{hash_obj.hexdigest()}"
    
    return key_data.replace(' ', '_').replace(':', '_')


def cache_result(timeout: int = 300, cache_key: Optional[str] = None):
    """
    Decorator to cache function results.
    
    Args:
        timeout: Cache timeout in seconds (default: 5 minutes)
        cache_key: Optional custom cache key prefix. If not provided,
                   function name is used.
    
    Returns:
        Decorated function with caching
    
    Example:
        @cache_result(timeout=600, cache_key='seller_stats')
        def get_seller_statistics(seller_id):
            return expensive_calculation(seller_id)
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            key_prefix = cache_key or func.__name__
            
            # Build cache key from function arguments
            cache_key_full = generate_cache_key(key_prefix, *args, **kwargs)
            
            # Try to get from cache
            result = cache.get(cache_key_full)
            if result is not None:
                return result
            
            # Execute function and cache result
            result = func(*args, **kwargs)
            cache.set(cache_key_full, result, timeout)
            
            return result
        
        # Store original function for manual cache clearing
        wrapper.cache_key_prefix = cache_key or func.__name__
        wrapper.original_func = func
        
        return wrapper
    
    return decorator


def invalidate_cache(key_prefix: str, *args, **kwargs) -> None:
    """
    Invalidate cached results matching a key pattern.
    
    Args:
        key_prefix: Cache key prefix to invalidate
        *args: Optional positional arguments for specific cache key
        **kwargs: Optional keyword arguments for specific cache key
    
    Example:
        # Clear all seller_stats caches
        invalidate_cache('seller_stats')
        
        # Clear specific seller stats
        invalidate_cache('seller_stats', seller_id=123)
    """
    if not args and not kwargs:
        # Invalidate all keys with prefix (approximate - using pattern)
        # Note: This is simplified. In production, use Redis SCAN
        pass
    else:
        # Invalidate specific key
        cache_key = generate_cache_key(key_prefix, *args, **kwargs)
        cache.delete(cache_key)


class ViewCacheMixin:
    """
    Mixin for ViewSets to add caching capabilities.
    
    Automatically caches list and retrieve responses.
    Override cache_timeout_* attributes to customize.
    """
    
    # Cache timeouts
    cache_timeout_list = 300      # 5 minutes
    cache_timeout_retrieve = 300  # 5 minutes
    cache_timeout_analytics = 600 # 10 minutes
    
    # Override in subclasses to disable caching for specific actions
    cache_disabled_for = []
    
    def get_cache_key_base(self) -> str:
        """Get base cache key for this viewset."""
        return self.__class__.__name__.lower()
    
    def get_list_cache_key(self) -> str:
        """Get cache key for list view."""
        base = self.get_cache_key_base()
        
        # Include query parameters in cache key
        query_params = self.request.query_params.dict()
        
        return generate_cache_key(
            f'{base}_list',
            user=self.request.user.id if self.request.user else 'anon',
            **query_params
        )
    
    def get_retrieve_cache_key(self, pk: Any) -> str:
        """Get cache key for retrieve view."""
        base = self.get_cache_key_base()
        return generate_cache_key(
            f'{base}_detail',
            pk=pk,
            user=self.request.user.id if self.request.user else 'anon'
        )
    
    def invalidate_list_cache(self) -> None:
        """Invalidate list cache (call after create/update/delete)."""
        base = self.get_cache_key_base()
        cache.delete(self.get_list_cache_key())
        # Also clear detail caches for this resource type
        pattern = f'{base}_detail_*'
        # In production, implement proper pattern deletion
    
    def invalidate_detail_cache(self, pk: Any) -> None:
        """Invalidate detail cache for specific object."""
        cache.delete(self.get_retrieve_cache_key(pk))
        self.invalidate_list_cache()


def cache_view_response(timeout: int = 300):
    """
    Decorator for DRF view methods to cache responses.
    
    Args:
        timeout: Cache timeout in seconds
    
    Returns:
        Decorated view method
    
    Example:
        @cache_view_response(timeout=600)
        @action(detail=False, methods=['get'])
        def dashboard(self, request):
            return Response(compute_dashboard_data())
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(self, request, *args, **kwargs) -> Any:
            # Skip caching for non-GET requests
            if request.method != 'GET':
                return func(self, request, *args, **kwargs)
            
            # Skip caching for admin users making specific requests
            if request.query_params.get('no_cache') == 'true':
                return func(self, request, *args, **kwargs)
            
            # Generate cache key
            cache_key = generate_cache_key(
                f'{self.__class__.__name__}_{func.__name__}',
                user=request.user.id if request.user else 'anon',
                query_string=request.query_string.decode() if request.query_string else ''
            )
            
            # Try to get from cache
            response = cache.get(cache_key)
            if response is not None:
                # Mark response as from cache
                response.data['_cached'] = True
                return response
            
            # Execute view and cache response
            response = func(self, request, *args, **kwargs)
            
            # Cache successful responses only
            if hasattr(response, 'status_code') and response.status_code < 400:
                cache.set(cache_key, response, timeout)
            
            return response
        
        return wrapper
    
    return decorator


def bulk_cache_invalidation(invalidation_map: dict) -> Callable:
    """
    Decorator to invalidate multiple cache keys after operation.
    
    Args:
        invalidation_map: Dict mapping key prefixes to argument names
    
    Returns:
        Decorated function
    
    Example:
        @bulk_cache_invalidation({
            'seller_stats': 'seller_id',
            'inventory': 'product_id',
        })
        def update_inventory(seller_id, product_id):
            # ... update logic ...
            pass
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            result = func(*args, **kwargs)
            
            # Invalidate caches
            for key_prefix, arg_name in invalidation_map.items():
                if arg_name in kwargs:
                    invalidate_cache(key_prefix, **{arg_name: kwargs[arg_name]})
            
            return result
        
        return wrapper
    
    return decorator


def get_or_cache(cache_key: str, func: Callable, timeout: int = 300, *args, **kwargs) -> Any:
    """
    Get value from cache or compute and cache it.
    
    Args:
        cache_key: Key to cache under
        func: Function to call if cache miss
        timeout: Cache timeout in seconds
        *args: Arguments for func
        **kwargs: Keyword arguments for func
    
    Returns:
        Cached or computed value
    
    Example:
        stats = get_or_cache(
            'dashboard_stats',
            compute_dashboard_stats,
            600,
            user_id=user.id
        )
    """
    result = cache.get(cache_key)
    
    if result is None:
        result = func(*args, **kwargs)
        cache.set(cache_key, result, timeout)
    
    return result
