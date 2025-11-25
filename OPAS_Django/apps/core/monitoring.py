"""
CORE PRINCIPLE: Performance monitoring and metrics collection
- Track API response times
- Monitor resource usage
- Identify performance bottlenecks
- Database query optimization
"""

from django.db import models
from django.utils import timezone
from django.core.cache import cache
from django.db.models import Avg, Max, Min, Count
import logging
import time
from functools import wraps
from contextlib import contextmanager

logger = logging.getLogger('monitoring')


class APIMetric(models.Model):
    """
    CORE PRINCIPLE: Track API performance metrics
    - Response times
    - Status codes
    - Resource usage
    - Error rates
    """
    
    ENDPOINT_CHOICES = [
        ('POST:/api/sellers/register-application/', 'Seller Registration'),
        ('GET:/api/sellers/my-registration/', 'Get My Registration'),
        ('GET:/api/sellers/registrations/:id/', 'Get Registration Details'),
        ('POST:/api/admin/sellers/:id/approve/', 'Approve Registration'),
        ('POST:/api/admin/sellers/:id/reject/', 'Reject Registration'),
        ('GET:/api/admin/audit-logs/', 'Get Audit Logs'),
        ('POST:/api/notifications/send/', 'Send Notification'),
    ]
    
    endpoint = models.CharField(
        max_length=100,
        choices=ENDPOINT_CHOICES,
        db_index=True,
        help_text='API endpoint path'
    )
    
    method = models.CharField(
        max_length=10,
        db_index=True,
        help_text='HTTP method (GET, POST, etc)'
    )
    
    status_code = models.IntegerField(
        db_index=True,
        help_text='HTTP response status code'
    )
    
    response_time_ms = models.IntegerField(
        help_text='Response time in milliseconds'
    )
    
    user_id = models.IntegerField(
        null=True,
        blank=True,
        db_index=True,
        help_text='User ID making the request'
    )
    
    request_size_bytes = models.IntegerField(
        default=0,
        help_text='Request payload size'
    )
    
    response_size_bytes = models.IntegerField(
        default=0,
        help_text='Response payload size'
    )
    
    database_queries = models.IntegerField(
        default=0,
        help_text='Number of database queries executed'
    )
    
    database_time_ms = models.IntegerField(
        default=0,
        help_text='Total database query time'
    )
    
    cache_hits = models.IntegerField(
        default=0,
        help_text='Number of cache hits'
    )
    
    cache_misses = models.IntegerField(
        default=0,
        help_text='Number of cache misses'
    )
    
    error_message = models.TextField(
        blank=True,
        help_text='Error message if request failed'
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True
    )
    
    class Meta:
        db_table = 'core_api_metric'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['endpoint', '-created_at']),
            models.Index(fields=['status_code', '-created_at']),
            models.Index(fields=['user_id', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.method} {self.endpoint} - {self.status_code} ({self.response_time_ms}ms)"
    
    @classmethod
    def get_stats(cls, endpoint=None, days=7):
        """
        CORE PRINCIPLE: Performance analytics
        Get performance statistics for monitoring
        """
        start_date = timezone.now() - timezone.timedelta(days=days)
        
        queryset = cls.objects.filter(created_at__gte=start_date)
        
        if endpoint:
            queryset = queryset.filter(endpoint=endpoint)
        
        stats = queryset.aggregate(
            avg_response_time=Avg('response_time_ms'),
            max_response_time=Max('response_time_ms'),
            min_response_time=Min('response_time_ms'),
            avg_db_time=Avg('database_time_ms'),
            total_requests=Count('id'),
            p95_response_time=None,  # Requires raw SQL
            p99_response_time=None,
            error_count=Count('id', filter=models.Q(status_code__gte=400)),
        )
        
        return stats
    
    @classmethod
    def get_slowest_endpoints(cls, limit=10, days=7):
        """Get endpoints with slowest average response time"""
        start_date = timezone.now() - timezone.timedelta(days=days)
        
        return cls.objects.filter(
            created_at__gte=start_date
        ).values('endpoint').annotate(
            avg_time=Avg('response_time_ms'),
            request_count=Count('id')
        ).order_by('-avg_time')[:limit]
    
    @classmethod
    def get_error_rate(cls, endpoint=None, days=7):
        """Calculate error rate percentage"""
        start_date = timezone.now() - timezone.timedelta(days=days)
        
        queryset = cls.objects.filter(created_at__gte=start_date)
        if endpoint:
            queryset = queryset.filter(endpoint=endpoint)
        
        total = queryset.count()
        if total == 0:
            return 0
        
        errors = queryset.filter(status_code__gte=400).count()
        return (errors / total) * 100


class DatabaseQueryMetric(models.Model):
    """
    CORE PRINCIPLE: Database performance monitoring
    - Track slow queries
    - Identify N+1 problems
    - Monitor connections
    """
    
    query_type = models.CharField(
        max_length=50,
        db_index=True,
        choices=[
            ('SELECT', 'Select Query'),
            ('INSERT', 'Insert Query'),
            ('UPDATE', 'Update Query'),
            ('DELETE', 'Delete Query'),
        ]
    )
    
    table_name = models.CharField(
        max_length=100,
        db_index=True
    )
    
    execution_time_ms = models.FloatField(
        help_text='Query execution time in milliseconds'
    )
    
    query_hash = models.CharField(
        max_length=64,
        db_index=True,
        help_text='Hash of query for deduplication'
    )
    
    rows_affected = models.IntegerField(
        default=0,
        help_text='Number of rows affected/returned'
    )
    
    is_slow = models.BooleanField(
        default=False,
        db_index=True,
        help_text='True if execution time > 100ms'
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True
    )
    
    class Meta:
        db_table = 'core_database_query_metric'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['is_slow', '-created_at']),
            models.Index(fields=['table_name', '-created_at']),
            models.Index(fields=['query_type', '-created_at']),
        ]
    
    @classmethod
    def get_slow_queries(cls, limit=20, days=7):
        """Get slowest database queries"""
        start_date = timezone.now() - timezone.timedelta(days=days)
        
        return cls.objects.filter(
            is_slow=True,
            created_at__gte=start_date
        ).values('query_hash', 'table_name').annotate(
            avg_time=Avg('execution_time_ms'),
            count=Count('id'),
            max_time=Max('execution_time_ms')
        ).order_by('-avg_time')[:limit]


class CacheMetric(models.Model):
    """Track cache performance"""
    
    cache_key = models.CharField(
        max_length=255,
        db_index=True
    )
    
    operation = models.CharField(
        max_length=20,
        choices=[
            ('GET', 'Cache Get'),
            ('SET', 'Cache Set'),
            ('DELETE', 'Cache Delete'),
            ('CLEAR', 'Cache Clear'),
        ]
    )
    
    hit = models.BooleanField(
        default=False,
        help_text='True if cache hit, False if miss'
    )
    
    size_bytes = models.IntegerField(
        default=0,
        help_text='Size of cached data'
    )
    
    ttl_seconds = models.IntegerField(
        default=0,
        help_text='Time to live for cached data'
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True
    )
    
    class Meta:
        db_table = 'core_cache_metric'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['cache_key', '-created_at']),
            models.Index(fields=['hit', '-created_at']),
        ]
    
    @classmethod
    def get_cache_hit_rate(cls, days=7):
        """Calculate cache hit rate percentage"""
        start_date = timezone.now() - timezone.timedelta(days=days)
        
        queryset = cls.objects.filter(created_at__gte=start_date)
        total = queryset.count()
        
        if total == 0:
            return 0
        
        hits = queryset.filter(hit=True).count()
        return (hits / total) * 100


def track_api_performance(endpoint_name):
    """
    CORE PRINCIPLE: Decorator to automatically track API metrics
    Usage:
        @track_api_performance('POST:/api/sellers/register-application/')
        def register_application(request):
            ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(request, *args, **kwargs):
            start_time = time.time()
            
            try:
                # Execute the view
                response = func(request, *args, **kwargs)
                
                # Calculate metrics
                response_time_ms = int((time.time() - start_time) * 1000)
                
                # Log metrics
                APIMetric.objects.create(
                    endpoint=endpoint_name,
                    method=request.method,
                    status_code=response.status_code if hasattr(response, 'status_code') else 200,
                    response_time_ms=response_time_ms,
                    user_id=request.user.id if request.user.is_authenticated else None,
                    request_size_bytes=len(request.body) if request.body else 0,
                    response_size_bytes=len(response.content) if hasattr(response, 'content') else 0,
                )
                
                return response
            
            except Exception as e:
                response_time_ms = int((time.time() - start_time) * 1000)
                
                APIMetric.objects.create(
                    endpoint=endpoint_name,
                    method=request.method,
                    status_code=500,
                    response_time_ms=response_time_ms,
                    user_id=request.user.id if request.user.is_authenticated else None,
                    error_message=str(e)
                )
                
                raise
        
        return wrapper
    return decorator


@contextmanager
def monitor_database_query(query_type, table_name):
    """
    CORE PRINCIPLE: Context manager for database query monitoring
    Usage:
        with monitor_database_query('SELECT', 'seller_registration'):
            result = SellerRegistration.objects.all()
    """
    import hashlib
    
    start_time = time.time()
    
    try:
        yield
    finally:
        execution_time_ms = (time.time() - start_time) * 1000
        
        # Create metric
        query_hash = hashlib.md5(f"{query_type}_{table_name}".encode()).hexdigest()
        
        DatabaseQueryMetric.objects.create(
            query_type=query_type,
            table_name=table_name,
            execution_time_ms=execution_time_ms,
            query_hash=query_hash,
            is_slow=execution_time_ms > 100,
        )
        
        if execution_time_ms > 100:
            logger.warning(
                f"Slow query detected: {query_type} on {table_name} took {execution_time_ms:.2f}ms"
            )


@contextmanager
def monitor_cache_operation(operation, cache_key, ttl=None):
    """
    CORE PRINCIPLE: Monitor cache operations
    Usage:
        with monitor_cache_operation('GET', 'user_123', ttl=3600):
            data = cache.get('user_123')
    """
    try:
        yield
    finally:
        # Log cache operation
        try:
            CacheMetric.objects.create(
                cache_key=cache_key,
                operation=operation,
                hit=(cache.get(cache_key) is not None),
                ttl_seconds=ttl or 0,
            )
        except Exception as e:
            logger.error(f"Error logging cache metric: {e}")
