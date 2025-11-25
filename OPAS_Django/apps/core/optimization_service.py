"""
CORE PRINCIPLE: Performance optimization service
- Query optimization
- Caching strategies
- Database indexing
- Bulk operations
- Lazy loading
"""

from django.core.cache import cache
from django.db import connection
from django.db.models import Prefetch, F, Q
import logging
import hashlib
from functools import wraps
from datetime import timedelta
from django.utils import timezone

logger = logging.getLogger('optimization')


class QueryOptimizer:
    """
    CORE PRINCIPLE: Optimize database queries
    - Reduce N+1 queries
    - Use select_related/prefetch_related
    - Batch operations
    """
    
    @staticmethod
    def get_seller_registrations_optimized(status=None, limit=100):
        """
        CORE PRINCIPLE: Optimized query with proper joins
        Prevents N+1 query problem
        """
        queryset = None
        
        # Use select_related for FK relations
        try:
            from apps.users.admin_models import SellerRegistrationRequest
            
            queryset = SellerRegistrationRequest.objects.select_related(
                'seller',
            ).filter(
                created_at__gte=timezone.now() - timedelta(days=90)
            )
            
            if status:
                queryset = queryset.filter(status=status)
            
            return queryset[:limit]
        except ImportError:
            logger.warning("SellerRegistrationRequest model not found")
            return []
    
    @staticmethod
    def get_audit_logs_optimized(user_id=None, limit=1000):
        """
        CORE PRINCIPLE: Optimized audit log queries
        Uses indexes and select_related
        """
        try:
            from apps.core.audit_logger import AuditLog
            
            queryset = AuditLog.objects.select_related('user').only(
                'id',
                'action',
                'user_id',
                'user__email',
                'resource_type',
                'resource_id',
                'status',
                'created_at',
            )
            
            if user_id:
                queryset = queryset.filter(user_id=user_id)
            
            return queryset.order_by('-created_at')[:limit]
        except ImportError:
            logger.warning("AuditLog model not found")
            return []
    
    @staticmethod
    def batch_update_registrations(registrations, **kwargs):
        """
        CORE PRINCIPLE: Bulk update instead of individual saves
        Reduces database round trips
        """
        try:
            from apps.users.admin_models import SellerRegistrationRequest
            
            updates = []
            for reg in registrations:
                for key, value in kwargs.items():
                    setattr(reg, key, value)
                updates.append(reg)
            
            updated_count = len(updates)
            if updated_count > 0:
                SellerRegistrationRequest.objects.bulk_update(
                    updates,
                    list(kwargs.keys()),
                    batch_size=500
                )
                logger.info(f"Bulk updated {updated_count} registrations")
            
            return updated_count
        except Exception as e:
            logger.error(f"Bulk update failed: {e}")
            return 0


class CachingStrategy:
    """
    CORE PRINCIPLE: Intelligent caching
    - Cache frequently accessed data
    - TTL management
    - Invalidation strategy
    """
    
    # Cache key patterns
    USER_REGISTRATION_KEY = 'reg:user:{user_id}'
    PENDING_REGISTRATIONS_KEY = 'reg:pending:{page}'
    ADMIN_STATS_KEY = 'admin:stats'
    AUDIT_LOG_KEY = 'audit:logs:{user_id}:{page}'
    
    @staticmethod
    def cache_user_registration(user_id, data, ttl=3600):
        """
        CORE PRINCIPLE: Cache registration with TTL
        """
        cache_key = CachingStrategy.USER_REGISTRATION_KEY.format(user_id=user_id)
        cache.set(cache_key, data, ttl)
        logger.debug(f"Cached registration for user {user_id}")
    
    @staticmethod
    def get_cached_registration(user_id):
        """
        CORE PRINCIPLE: Get from cache, fallback to DB
        """
        cache_key = CachingStrategy.USER_REGISTRATION_KEY.format(user_id=user_id)
        return cache.get(cache_key)
    
    @staticmethod
    def invalidate_user_registration(user_id):
        """
        CORE PRINCIPLE: Invalidate on updates
        """
        cache_key = CachingStrategy.USER_REGISTRATION_KEY.format(user_id=user_id)
        cache.delete(cache_key)
    
    @staticmethod
    def cache_admin_stats(stats, ttl=1800):
        """
        CORE PRINCIPLE: Cache admin dashboard stats
        Expensive aggregations cached for 30 minutes
        """
        cache.set(CachingStrategy.ADMIN_STATS_KEY, stats, ttl)
    
    @staticmethod
    def get_cached_admin_stats():
        """Get cached admin stats"""
        return cache.get(CachingStrategy.ADMIN_STATS_KEY)
    
    @staticmethod
    def invalidate_admin_stats():
        """Invalidate stats on data change"""
        cache.delete(CachingStrategy.ADMIN_STATS_KEY)


class IndexOptimization:
    """
    CORE PRINCIPLE: Database indexing strategy
    Indexes on frequently queried columns
    """
    
    CRITICAL_INDEXES = [
        # Registration model
        ('seller_registration_request', 'status'),
        ('seller_registration_request', 'seller_id'),
        ('seller_registration_request', 'created_at'),
        ('seller_registration_request', 'submitted_at'),
        
        # Audit log model
        ('core_audit_log', 'user_id'),
        ('core_audit_log', 'action'),
        ('core_audit_log', 'created_at'),
        ('core_audit_log', 'status'),
        
        # Notification model
        ('core_notification_log', 'user_id'),
        ('core_notification_log', 'created_at'),
        ('core_notification_log', 'status'),
        
        # API metrics
        ('core_api_metric', 'endpoint'),
        ('core_api_metric', 'created_at'),
        ('core_api_metric', 'status_code'),
    ]
    
    @staticmethod
    def verify_indexes():
        """
        CORE PRINCIPLE: Check if recommended indexes exist
        """
        missing_indexes = []
        
        with connection.cursor() as cursor:
            for table, column in IndexOptimization.CRITICAL_INDEXES:
                index_name = f"{table}_{column}_idx"
                
                # SQL to check if index exists (MySQL)
                cursor.execute(f"""
                    SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS 
                    WHERE TABLE_NAME = %s AND COLUMN_NAME = %s
                """, [table, column])
                
                if not cursor.fetchone():
                    missing_indexes.append((table, column))
        
        if missing_indexes:
            logger.warning(f"Missing indexes: {missing_indexes}")
        
        return missing_indexes


class LazyLoadingOptimizer:
    """
    CORE PRINCIPLE: Lazy load related data
    Don't fetch unnecessary data upfront
    """
    
    @staticmethod
    def serialize_registration_lightweight(registration):
        """
        CORE PRINCIPLE: Serialize only essential fields
        Avoid nested serialization
        """
        return {
            'id': registration.id,
            'status': registration.status,
            'farm_name': registration.farm_name,
            'store_name': registration.store_name,
            'seller_id': registration.seller_id,
            'submitted_at': registration.submitted_at.isoformat(),
            'created_at': registration.created_at.isoformat(),
        }
    
    @staticmethod
    def serialize_documents_lazy(registration):
        """
        CORE PRINCIPLE: Load documents only when requested
        """
        return {
            'id': registration.id,
            'documents_count': registration.documents.count(),
            'verified_count': registration.documents.filter(status='VERIFIED').count(),
            'pending_count': registration.documents.filter(status='PENDING').count(),
            'rejected_count': registration.documents.filter(status='REJECTED').count(),
        }


def cached_response(ttl=3600):
    """
    CORE PRINCIPLE: Decorator for caching view responses
    
    Usage:
        @cached_response(ttl=1800)
        def get_admin_stats(request):
            ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and args
            cache_key = f"{func.__name__}:{str(args)}{str(kwargs)}"
            cache_key = hashlib.md5(cache_key.encode()).hexdigest()
            
            # Try to get from cache
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                logger.debug(f"Cache hit for {func.__name__}")
                return cached_data
            
            # Execute function
            result = func(*args, **kwargs)
            
            # Cache result
            cache.set(cache_key, result, ttl)
            logger.debug(f"Cached {func.__name__} for {ttl}s")
            
            return result
        
        return wrapper
    return decorator


class BatchProcessor:
    """
    CORE PRINCIPLE: Process large datasets efficiently
    - Batch operations
    - Progress tracking
    - Error handling
    """
    
    @staticmethod
    def process_registrations_batch(queryset, processor_func, batch_size=100):
        """
        CORE PRINCIPLE: Process in batches to manage memory
        """
        total = queryset.count()
        processed = 0
        failed = 0
        
        for i in range(0, total, batch_size):
            batch = queryset[i:i + batch_size]
            
            for item in batch:
                try:
                    processor_func(item)
                    processed += 1
                except Exception as e:
                    failed += 1
                    logger.error(f"Error processing item {item.id}: {e}")
        
        logger.info(
            f"Batch processing complete: {processed} processed, {failed} failed"
        )
        
        return {
            'processed': processed,
            'failed': failed,
            'total': total,
        }
    
    @staticmethod
    def bulk_send_notifications(notifications_data, batch_size=50):
        """
        CORE PRINCIPLE: Send notifications in batches
        Efficient API usage
        """
        from apps.core.notifications import NotificationService
        
        total = len(notifications_data)
        sent = 0
        failed = 0
        
        for i in range(0, total, batch_size):
            batch = notifications_data[i:i + batch_size]
            
            for notif_data in batch:
                try:
                    # Send notification
                    NotificationService.send_registration_submitted_notification(
                        notif_data['registration']
                    )
                    sent += 1
                except Exception as e:
                    failed += 1
                    logger.error(f"Error sending notification: {e}")
        
        return {
            'sent': sent,
            'failed': failed,
            'total': total,
        }


class PerformanceProfiler:
    """
    CORE PRINCIPLE: Profile code execution time
    Identify optimization opportunities
    """
    
    @staticmethod
    def profile_query_performance(queryset, label='Query'):
        """
        CORE PRINCIPLE: Measure query execution time
        """
        import time
        
        start = time.time()
        result = list(queryset)
        duration = time.time() - start
        
        logger.info(
            f"{label} executed in {duration:.2f}s, "
            f"returned {len(result)} items"
        )
        
        return result, duration
    
    @staticmethod
    def compare_query_strategies():
        """
        CORE PRINCIPLE: Compare optimized vs unoptimized queries
        """
        try:
            from apps.users.admin_models import SellerRegistrationRequest
            import time
            
            # Unoptimized query
            start = time.time()
            registrations_unopt = list(SellerRegistrationRequest.objects.all()[:100])
            unopt_time = time.time() - start
            
            # Optimized query
            start = time.time()
            registrations_opt = list(
                QueryOptimizer.get_seller_registrations_optimized(limit=100)
            )
            opt_time = time.time() - start
            
            improvement = ((unopt_time - opt_time) / unopt_time * 100)
            
            logger.info(
                f"Query optimization comparison:\n"
                f"Unoptimized: {unopt_time:.3f}s\n"
                f"Optimized: {opt_time:.3f}s\n"
                f"Improvement: {improvement:.1f}%"
            )
            
            return {
                'unoptimized_time': unopt_time,
                'optimized_time': opt_time,
                'improvement_percent': improvement,
            }
        except Exception as e:
            logger.error(f"Error comparing query strategies: {e}")
            return None
