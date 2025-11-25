"""
CORE PRINCIPLE: Admin-only audit log viewing
- Read-only access
- Comprehensive filtering
- Search capabilities
- Performance optimized
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from rest_framework.pagination import PageNumberPagination
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from django.db.models import Q, Count
from datetime import timedelta
import logging

from apps.core.audit_logger import AuditLog
from .serializers import AuditLogSerializer

logger = logging.getLogger('audit')


class AuditLogPagination(PageNumberPagination):
    """
    CORE PRINCIPLE: Efficient pagination for large audit logs
    """
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 500


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    CORE PRINCIPLE: Admin-only audit log viewer
    - Read-only for integrity
    - Comprehensive filtering
    - Efficient searching
    - Activity summaries
    
    Endpoints:
    - GET /api/admin/audit-logs/ - List all with filtering
    - GET /api/admin/audit-logs/{id}/ - Detail view
    - GET /api/admin/audit-logs/summary/today/ - Today's summary
    - GET /api/admin/audit-logs/user-activity/{user_id}/ - User's activity
    - POST /api/admin/audit-logs/export/ - Export filtered results
    """
    
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [IsAdminUser]
    pagination_class = AuditLogPagination
    
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = [
        'action',
        'resource_type',
        'status',
        'user',
        'created_at',
    ]
    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
        'resource_type',
        'details__approved_by',
        'details__rejected_by',
        'details__seller_email',
    ]
    ordering_fields = ['created_at', 'action', 'user', 'status']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """
        CORE PRINCIPLE: Efficient queries with select_related
        - Reduce N+1 queries
        - Prefetch user data
        """
        queryset = AuditLog.objects.select_related('user').order_by('-created_at')
        
        # Filter by action if provided
        action_filter = self.request.query_params.get('action')
        if action_filter:
            queryset = queryset.filter(action=action_filter)
        
        # Filter by resource type if provided
        resource_type = self.request.query_params.get('resource_type')
        if resource_type:
            queryset = queryset.filter(resource_type=resource_type)
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(created_at__gte=start_date)
        if end_date:
            queryset = queryset.filter(created_at__lte=end_date)
        
        # Filter by user
        user_id = self.request.query_params.get('user_id')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """
        CORE PRINCIPLE: Quick summary of recent activity
        Useful for admin dashboard
        
        GET /api/admin/audit-logs/summary/?days=7
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        logs = AuditLog.objects.filter(created_at__gte=start_date)
        
        summary = {
            'total_actions': logs.count(),
            'period_days': days,
            'start_date': start_date,
            'end_date': timezone.now(),
            
            'actions': dict(
                logs.values('action').annotate(count=Count('action')).values_list('action', 'count')
            ),
            
            'by_resource_type': dict(
                logs.values('resource_type').annotate(count=Count('resource_type')).values_list('resource_type', 'count')
            ),
            
            'by_status': dict(
                logs.values('status').annotate(count=Count('status')).values_list('status', 'count')
            ),
            
            'by_user': list(
                logs.values('user__email', 'user_id')
                    .annotate(count=Count('user_id'))
                    .order_by('-count')[:10]
            ),
            
            'registrations_approved': logs.filter(action='REGISTRATION_APPROVED').count(),
            'registrations_rejected': logs.filter(action='REGISTRATION_REJECTED').count(),
            'registrations_submitted': logs.filter(action='REGISTRATION_SUBMITTED').count(),
            'unauthorized_attempts': logs.filter(action='UNAUTHORIZED_ACCESS_ATTEMPT').count(),
        }
        
        return Response(summary)
    
    @action(detail=False, methods=['get'])
    def today(self, request):
        """
        CORE PRINCIPLE: Today's summary
        Quick view of current day's activity
        
        GET /api/admin/audit-logs/today/
        """
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        logs = AuditLog.objects.filter(created_at__gte=today_start)
        
        today_summary = {
            'date': today_start.date(),
            'total_actions': logs.count(),
            'actions': dict(
                logs.values('action').annotate(count=Count('action')).values_list('action', 'count')
            ),
            'top_users': list(
                logs.values('user__email', 'user_id')
                    .annotate(count=Count('user_id'))
                    .order_by('-count')[:5]
            ),
            'failed_actions': logs.filter(status='FAILED').count(),
        }
        
        return Response(today_summary)
    
    @action(detail=False, methods=['get'])
    def user_activity(self, request, user_id=None):
        """
        CORE PRINCIPLE: View all activity by specific user
        
        GET /api/admin/audit-logs/user_activity/?user_id=5
        """
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response(
                {'error': 'user_id parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        logs = AuditLog.objects.filter(user_id=user_id).order_by('-created_at')
        
        page = self.paginate_queryset(logs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(logs, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def resource_activity(self, request):
        """
        CORE PRINCIPLE: All activity for specific resource
        
        GET /api/admin/audit-logs/resource_activity/?resource_type=SellerRegistration&resource_id=5
        """
        resource_type = request.query_params.get('resource_type')
        resource_id = request.query_params.get('resource_id')
        
        if not resource_type or not resource_id:
            return Response(
                {'error': 'resource_type and resource_id parameters required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        logs = AuditLog.objects.filter(
            resource_type=resource_type,
            resource_id=resource_id
        ).order_by('-created_at')
        
        page = self.paginate_queryset(logs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(logs, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def export(self, request):
        """
        CORE PRINCIPLE: Export audit logs to CSV
        
        POST /api/admin/audit-logs/export/
        Body: {
            "start_date": "2024-01-01",
            "end_date": "2024-12-31",
            "actions": ["REGISTRATION_APPROVED", "REGISTRATION_REJECTED"],
            "status": "SUCCESS"
        }
        """
        import csv
        from django.http import HttpResponse
        
        start_date = request.data.get('start_date')
        end_date = request.data.get('end_date')
        actions = request.data.get('actions', [])
        status_filter = request.data.get('status')
        
        logs = AuditLog.objects.all()
        
        if start_date:
            logs = logs.filter(created_at__gte=start_date)
        if end_date:
            logs = logs.filter(created_at__lte=end_date)
        if actions:
            logs = logs.filter(action__in=actions)
        if status_filter:
            logs = logs.filter(status=status_filter)
        
        # Create CSV response
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="audit_logs.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Date', 'Time', 'User', 'Action', 'Resource Type', 
            'Resource ID', 'Status', 'Details'
        ])
        
        for log in logs.order_by('-created_at'):
            writer.writerow([
                log.created_at.date(),
                log.created_at.time(),
                log.user.email if log.user else 'System',
                log.action,
                log.resource_type,
                log.resource_id,
                log.status,
                str(log.details)[:100],
            ])
        
        logger.info(f"Audit logs exported by {request.user.email}: {logs.count()} records")
        
        return response
    
    @action(detail=False, methods=['get'])
    def failed_actions(self, request):
        """
        CORE PRINCIPLE: View only failed operations
        
        GET /api/admin/audit-logs/failed_actions/?days=30
        """
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days)
        
        logs = AuditLog.objects.filter(
            status='FAILED',
            created_at__gte=start_date
        ).order_by('-created_at')
        
        page = self.paginate_queryset(logs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(logs, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def unauthorized_access(self, request):
        """
        CORE PRINCIPLE: Security monitoring - view unauthorized access attempts
        
        GET /api/admin/audit-logs/unauthorized_access/?days=7
        """
        days = int(request.query_params.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)
        
        logs = AuditLog.objects.filter(
            action='UNAUTHORIZED_ACCESS_ATTEMPT',
            created_at__gte=start_date
        ).order_by('-created_at')
        
        page = self.paginate_queryset(logs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(logs, many=True)
        return Response(serializer.data)
