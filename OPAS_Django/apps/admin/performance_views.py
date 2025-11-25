"""
CORE PRINCIPLE: Admin dashboard for performance monitoring
- Real-time metrics visualization
- Historical trends
- Alert configuration
- Performance optimization recommendations
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.utils import timezone
from django.db.models import Avg, Max, Min, Count
from datetime import timedelta
import logging

from apps.core.monitoring import APIMetric, DatabaseQueryMetric, CacheMetric

logger = logging.getLogger('monitoring')


class PerformanceMetricsViewSet(viewsets.ViewSet):
    """
    CORE PRINCIPLE: Admin-only performance monitoring dashboard
    
    Endpoints:
    - GET /api/admin/metrics/dashboard/ - Overall metrics summary
    - GET /api/admin/metrics/api-performance/ - API endpoint metrics
    - GET /api/admin/metrics/database/ - Database query metrics
    - GET /api/admin/metrics/cache/ - Cache hit/miss rates
    - GET /api/admin/metrics/slowest-endpoints/ - Performance bottlenecks
    - GET /api/admin/metrics/error-rates/ - Error rate analysis
    - GET /api/admin/metrics/trending/ - 7-day trends
    """
    
    permission_classes = [IsAdminUser]
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """
        CORE PRINCIPLE: Executive summary of system performance
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        # Get metrics
        api_metrics = APIMetric.objects.filter(created_at__gte=start_date)
        db_metrics = DatabaseQueryMetric.objects.filter(created_at__gte=start_date)
        cache_metrics = CacheMetric.objects.filter(created_at__gte=start_date)
        
        # API performance
        api_stats = api_metrics.aggregate(
            avg_response_time=Avg('response_time_ms'),
            max_response_time=Max('response_time_ms'),
            min_response_time=Min('response_time_ms'),
            total_requests=Count('id'),
            error_count=Count('id', filter=__import__('django.db.models', fromlist=['Q']).Q(status_code__gte=400))
        )
        
        # Database performance
        db_stats = db_metrics.aggregate(
            avg_query_time=Avg('execution_time_ms'),
            max_query_time=Max('execution_time_ms'),
            slow_queries=Count('id', filter=__import__('django.db.models', fromlist=['Q']).Q(is_slow=True)),
            total_queries=Count('id')
        )
        
        # Cache performance
        total_cache_ops = cache_metrics.count()
        cache_hits = cache_metrics.filter(hit=True).count()
        cache_hit_rate = (cache_hits / total_cache_ops * 100) if total_cache_ops > 0 else 0
        
        # Error rate
        total_api = api_stats['total_requests'] or 1
        error_rate = (api_stats['error_count'] / total_api * 100) if total_api > 0 else 0
        
        dashboard_data = {
            'period_days': days,
            'generated_at': timezone.now(),
            
            'api_performance': {
                'avg_response_time_ms': round(api_stats['avg_response_time'] or 0, 2),
                'max_response_time_ms': api_stats['max_response_time'] or 0,
                'min_response_time_ms': api_stats['min_response_time'] or 0,
                'total_requests': api_stats['total_requests'] or 0,
                'error_count': api_stats['error_count'] or 0,
                'error_rate_percent': round(error_rate, 2),
            },
            
            'database_performance': {
                'avg_query_time_ms': round(db_stats['avg_query_time'] or 0, 2),
                'max_query_time_ms': db_stats['max_query_time'] or 0,
                'slow_queries': db_stats['slow_queries'] or 0,
                'total_queries': db_stats['total_queries'] or 0,
                'slow_query_percent': round(
                    (db_stats['slow_queries'] / db_stats['total_queries'] * 100) 
                    if db_stats['total_queries'] else 0, 2
                ),
            },
            
            'cache_performance': {
                'cache_hit_rate_percent': round(cache_hit_rate, 2),
                'total_operations': total_cache_ops,
                'cache_hits': cache_hits,
                'cache_misses': total_cache_ops - cache_hits,
            },
            
            'health_status': self._calculate_health_status(
                api_stats, db_stats, cache_hit_rate
            ),
            
            'recommendations': self._generate_recommendations(
                api_stats, db_stats, cache_hit_rate, error_rate
            ),
        }
        
        return Response(dashboard_data)
    
    @action(detail=False, methods=['get'])
    def api_performance(self, request):
        """
        CORE PRINCIPLE: Detailed API endpoint performance analysis
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        endpoint_stats = APIMetric.objects.filter(
            created_at__gte=start_date
        ).values('endpoint').annotate(
            avg_response_time=Avg('response_time_ms'),
            max_response_time=Max('response_time_ms'),
            min_response_time=Min('response_time_ms'),
            request_count=Count('id'),
            error_count=Count('id', filter=__import__('django.db.models', fromlist=['Q']).Q(status_code__gte=400)),
        ).order_by('-avg_response_time')
        
        endpoints = []
        for stat in endpoint_stats:
            endpoints.append({
                'endpoint': stat['endpoint'],
                'avg_response_time_ms': round(stat['avg_response_time'], 2),
                'max_response_time_ms': stat['max_response_time'],
                'min_response_time_ms': stat['min_response_time'],
                'request_count': stat['request_count'],
                'error_count': stat['error_count'],
                'error_rate_percent': round(
                    (stat['error_count'] / stat['request_count'] * 100) 
                    if stat['request_count'] else 0, 2
                ),
            })
        
        return Response({
            'period_days': days,
            'endpoints': endpoints,
            'total_endpoints': len(endpoints),
        })
    
    @action(detail=False, methods=['get'])
    def database(self, request):
        """
        CORE PRINCIPLE: Database performance metrics
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        # Slow queries
        slow_queries = DatabaseQueryMetric.objects.filter(
            is_slow=True,
            created_at__gte=start_date
        ).values('table_name', 'query_type').annotate(
            avg_time=Avg('execution_time_ms'),
            max_time=Max('execution_time_ms'),
            count=Count('id'),
        ).order_by('-avg_time')
        
        # Query breakdown by type
        query_breakdown = DatabaseQueryMetric.objects.filter(
            created_at__gte=start_date
        ).values('query_type').annotate(
            count=Count('id'),
            avg_time=Avg('execution_time_ms'),
            total_time=__import__('django.db.models', fromlist=['Sum']).Sum('execution_time_ms'),
        )
        
        return Response({
            'period_days': days,
            'slow_queries': list(slow_queries),
            'query_breakdown': list(query_breakdown),
            'total_slow_queries': DatabaseQueryMetric.objects.filter(
                is_slow=True,
                created_at__gte=start_date
            ).count(),
        })
    
    @action(detail=False, methods=['get'])
    def cache(self, request):
        """
        CORE PRINCIPLE: Cache performance metrics
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        cache_metrics = CacheMetric.objects.filter(created_at__gte=start_date)
        
        # Overall hit rate
        total = cache_metrics.count()
        hits = cache_metrics.filter(hit=True).count()
        hit_rate = (hits / total * 100) if total > 0 else 0
        
        # Per-key stats
        key_stats = cache_metrics.values('cache_key').annotate(
            operations=Count('id'),
            hits=Count('id', filter=__import__('django.db.models', fromlist=['Q']).Q(hit=True)),
            misses=Count('id', filter=__import__('django.db.models', fromlist=['Q']).Q(hit=False)),
        ).order_by('-operations')
        
        # By operation
        operation_stats = cache_metrics.values('operation').annotate(
            count=Count('id'),
        )
        
        return Response({
            'period_days': days,
            'overall_hit_rate_percent': round(hit_rate, 2),
            'total_operations': total,
            'total_hits': hits,
            'total_misses': total - hits,
            'top_keys': list(key_stats[:20]),
            'operations_breakdown': list(operation_stats),
        })
    
    @action(detail=False, methods=['get'])
    def slowest_endpoints(self, request):
        """
        CORE PRINCIPLE: Identify performance bottlenecks
        """
        limit = int(request.query_params.get('limit', 10))
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        slowest = APIMetric.objects.filter(
            created_at__gte=start_date
        ).values('endpoint').annotate(
            avg_response_time=Avg('response_time_ms'),
            max_response_time=Max('response_time_ms'),
            request_count=Count('id'),
        ).order_by('-avg_response_time')[:limit]
        
        return Response({
            'slowest_endpoints': list(slowest),
            'period_days': days,
        })
    
    @action(detail=False, methods=['get'])
    def error_rates(self, request):
        """
        CORE PRINCIPLE: Error rate analysis
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        # By endpoint
        endpoint_errors = APIMetric.objects.filter(
            created_at__gte=start_date
        ).values('endpoint', 'status_code').annotate(
            count=Count('id'),
        ).order_by('endpoint', '-count')
        
        # By status code
        status_breakdown = APIMetric.objects.filter(
            created_at__gte=start_date,
            status_code__gte=400
        ).values('status_code').annotate(
            count=Count('id'),
        ).order_by('-count')
        
        # Overall error rate
        total = APIMetric.objects.filter(created_at__gte=start_date).count()
        error_count = APIMetric.objects.filter(
            created_at__gte=start_date,
            status_code__gte=400
        ).count()
        error_rate = (error_count / total * 100) if total > 0 else 0
        
        return Response({
            'overall_error_rate_percent': round(error_rate, 2),
            'total_errors': error_count,
            'total_requests': total,
            'errors_by_endpoint': list(endpoint_errors),
            'errors_by_status': list(status_breakdown),
            'period_days': days,
        })
    
    @action(detail=False, methods=['get'])
    def trending(self, request):
        """
        CORE PRINCIPLE: 7-day performance trends
        """
        days = 7
        
        daily_metrics = []
        for day in range(days):
            day_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=day)
            day_end = day_start + timedelta(days=1)
            
            day_data = APIMetric.objects.filter(
                created_at__gte=day_start,
                created_at__lt=day_end
            ).aggregate(
                avg_response_time=Avg('response_time_ms'),
                request_count=Count('id'),
                error_count=Count('id', filter=__import__('django.db.models', fromlist=['Q']).Q(status_code__gte=400)),
            )
            
            daily_metrics.append({
                'date': day_start.date(),
                'avg_response_time_ms': round(day_data['avg_response_time'] or 0, 2),
                'request_count': day_data['request_count'] or 0,
                'error_count': day_data['error_count'] or 0,
            })
        
        return Response({
            'daily_metrics': daily_metrics,
            'trend': 'improving' if daily_metrics[-1]['avg_response_time_ms'] < daily_metrics[0]['avg_response_time_ms'] else 'degrading',
        })
    
    def _calculate_health_status(self, api_stats, db_stats, cache_hit_rate):
        """
        CORE PRINCIPLE: Health score calculation
        Returns: EXCELLENT, GOOD, FAIR, POOR
        """
        score = 100
        
        # API performance
        avg_response = api_stats['avg_response_time'] or 0
        if avg_response > 1000:
            score -= 30
        elif avg_response > 500:
            score -= 15
        elif avg_response > 200:
            score -= 5
        
        # Error rate
        if api_stats['total_requests']:
            error_rate = (api_stats['error_count'] / api_stats['total_requests'] * 100)
            if error_rate > 5:
                score -= 30
            elif error_rate > 2:
                score -= 15
            elif error_rate > 0.5:
                score -= 5
        
        # Database performance
        slow_query_pct = (db_stats['slow_queries'] / db_stats['total_queries'] * 100) if db_stats['total_queries'] else 0
        if slow_query_pct > 10:
            score -= 20
        
        # Cache hit rate
        if cache_hit_rate < 50:
            score -= 15
        
        if score >= 90:
            return 'EXCELLENT'
        elif score >= 75:
            return 'GOOD'
        elif score >= 50:
            return 'FAIR'
        else:
            return 'POOR'
    
    def _generate_recommendations(self, api_stats, db_stats, cache_hit_rate, error_rate):
        """
        CORE PRINCIPLE: Automatic optimization recommendations
        """
        recommendations = []
        
        # API performance recommendations
        if api_stats['avg_response_time'] and api_stats['avg_response_time'] > 500:
            recommendations.append({
                'severity': 'HIGH',
                'area': 'API Performance',
                'recommendation': 'Average response time exceeds 500ms. Consider implementing caching or query optimization.',
            })
        
        # Error rate recommendations
        if error_rate > 2:
            recommendations.append({
                'severity': 'HIGH',
                'area': 'Error Handling',
                'recommendation': f'Error rate is {round(error_rate, 1)}%. Investigate error causes and fix critical issues.',
            })
        
        # Slow query recommendations
        if db_stats['slow_queries'] and db_stats['total_queries']:
            slow_pct = (db_stats['slow_queries'] / db_stats['total_queries'] * 100)
            if slow_pct > 10:
                recommendations.append({
                    'severity': 'MEDIUM',
                    'area': 'Database Optimization',
                    'recommendation': f'{slow_pct:.1f}% of queries are slow. Add indexes or optimize queries.',
                })
        
        # Cache recommendations
        if cache_hit_rate < 60:
            recommendations.append({
                'severity': 'MEDIUM',
                'area': 'Caching Strategy',
                'recommendation': f'Cache hit rate is {round(cache_hit_rate, 1)}%. Consider increasing TTL or caching more frequently accessed data.',
            })
        
        return recommendations
