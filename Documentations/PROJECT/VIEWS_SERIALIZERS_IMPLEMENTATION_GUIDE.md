# 🛠️ Views & Serializers Implementation Guide
**Phase**: 1.3 - Complete Implementation  
**Target**: Add 25+ missing endpoints and serializers  

---

## 📋 PART 1: MISSING SERIALIZERS IMPLEMENTATION

### 1.1 AdminUserSerializer
**Status**: ❌ Missing  
**Priority**: HIGH  
**Location**: `apps/users/admin_serializers.py`

```python
# ==================== ADMIN USER SERIALIZERS ====================

class AdminUserSerializer(serializers.ModelSerializer):
    """Serializer for admin user profile and details."""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_full_name = serializers.CharField(source='user.full_name', read_only=True)
    permissions = serializers.SerializerMethodField()
    department_display = serializers.CharField(
        source='get_department_display', read_only=True
    )
    role_display = serializers.CharField(
        source='get_admin_role_display', read_only=True
    )
    
    class Meta:
        model = AdminUser
        fields = [
            'id', 'user_email', 'user_full_name', 'admin_role', 'role_display',
            'department', 'department_display', 'permissions',
            'is_active', 'last_login', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'user_email', 'user_full_name', 'last_login',
            'created_at', 'updated_at'
        ]
    
    def get_permissions(self, obj):
        """Get list of permissions for this admin role."""
        # Return permissions based on admin_role
        role_permissions = {
            'SUPER_ADMIN': ['all'],
            'SELLER_MANAGER': ['approve_sellers', 'suspend_sellers', 'view_sellers'],
            'PRICE_MANAGER': ['manage_prices', 'set_ceilings', 'create_advisories'],
            'OPAS_MANAGER': ['approve_submissions', 'manage_inventory'],
            'ANALYTICS_MANAGER': ['view_analytics', 'export_reports'],
            'SUPPORT_ADMIN': ['send_notifications', 'manage_announcements'],
        }
        return role_permissions.get(obj.admin_role, [])


class AdminUserCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating admin users."""
    
    class Meta:
        model = AdminUser
        fields = [
            'admin_role', 'department', 'is_active'
        ]
```

### 1.2 Dashboard Metrics Serializers
**Status**: ❌ Missing  
**Priority**: HIGH  
**Location**: `apps/users/admin_serializers.py`

```python
# ==================== DASHBOARD METRICS SERIALIZERS ====================

class SellerMetricsSerializer(serializers.Serializer):
    """Serializer for seller-related metrics."""
    total_sellers = serializers.IntegerField(read_only=True)
    pending_approvals = serializers.IntegerField(read_only=True)
    active_sellers = serializers.IntegerField(read_only=True)
    suspended_sellers = serializers.IntegerField(read_only=True)
    new_this_month = serializers.IntegerField(read_only=True)
    approval_rate = serializers.FloatField(read_only=True)
    avg_time_to_approve = serializers.FloatField(read_only=True, help_text="Days")


class MarketMetricsSerializer(serializers.Serializer):
    """Serializer for market-related metrics."""
    active_listings = serializers.IntegerField(read_only=True)
    total_sales_today = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    total_sales_month = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    avg_price_change = serializers.FloatField(read_only=True, help_text="Percentage")
    avg_transaction = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    total_orders = serializers.IntegerField(read_only=True)


class OPASMetricsSerializer(serializers.Serializer):
    """Serializer for OPAS-related metrics."""
    pending_submissions = serializers.IntegerField(read_only=True)
    approved_this_month = serializers.IntegerField(read_only=True)
    total_inventory = serializers.IntegerField(read_only=True, help_text="Units")
    low_stock_count = serializers.IntegerField(read_only=True)
    expiring_count = serializers.IntegerField(read_only=True)
    total_inventory_value = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )


class PriceComplianceSerializer(serializers.Serializer):
    """Serializer for price compliance metrics."""
    compliant_listings = serializers.IntegerField(read_only=True)
    non_compliant = serializers.IntegerField(read_only=True)
    compliance_rate = serializers.FloatField(read_only=True, help_text="Percentage")


class AlertsMetricsSerializer(serializers.Serializer):
    """Serializer for alert-related metrics."""
    price_violations = serializers.IntegerField(read_only=True)
    seller_issues = serializers.IntegerField(read_only=True)
    inventory_alerts = serializers.IntegerField(read_only=True)
    total_open_alerts = serializers.IntegerField(read_only=True)


class AdminDashboardStatsSerializer(serializers.Serializer):
    """Serializer for comprehensive admin dashboard statistics."""
    timestamp = serializers.DateTimeField(read_only=True)
    seller_metrics = SellerMetricsSerializer(read_only=True)
    market_metrics = MarketMetricsSerializer(read_only=True)
    opas_metrics = OPASMetricsSerializer(read_only=True)
    price_compliance = PriceComplianceSerializer(read_only=True)
    alerts = AlertsMetricsSerializer(read_only=True)
    marketplace_health_score = serializers.IntegerField(
        read_only=True, help_text="0-100 scale"
    )
```

### 1.3 Audit Log Serializers
**Status**: ❌ Missing  
**Priority**: HIGH  
**Location**: `apps/users/admin_serializers.py`

```python
# ==================== AUDIT LOG SERIALIZERS ====================

class AdminAuditLogSerializer(serializers.ModelSerializer):
    """Serializer for audit log listing (lightweight)."""
    admin_name = serializers.CharField(source='admin.user.full_name', read_only=True)
    action_type_display = serializers.CharField(
        source='get_action_type_display', read_only=True
    )
    category_display = serializers.CharField(
        source='get_action_category_display', read_only=True
    )
    
    class Meta:
        model = AdminAuditLog
        fields = [
            'id', 'admin_name', 'action_type', 'action_type_display',
            'action_category', 'category_display', 'description',
            'created_at'
        ]
        read_only_fields = fields


class AdminAuditLogDetailedSerializer(serializers.ModelSerializer):
    """Serializer for detailed audit log with full context."""
    admin_name = serializers.CharField(source='admin.user.full_name', read_only=True)
    affected_seller_name = serializers.CharField(
        source='affected_seller.full_name', read_only=True, allow_null=True
    )
    affected_admin_name = serializers.CharField(
        source='affected_admin.user.full_name', read_only=True, allow_null=True
    )
    action_type_display = serializers.CharField(
        source='get_action_type_display', read_only=True
    )
    category_display = serializers.CharField(
        source='get_action_category_display', read_only=True
    )
    
    class Meta:
        model = AdminAuditLog
        fields = [
            'id', 'admin_name', 'action_type', 'action_type_display',
            'action_category', 'category_display', 'description',
            'affected_seller_id', 'affected_seller_name',
            'affected_admin_id', 'affected_admin_name',
            'old_value', 'new_value', 'changes', 'ip_address',
            'user_agent', 'created_at'
        ]
        read_only_fields = fields
```

### 1.4 Marketplace & Alert Serializers
**Status**: ⚠️ Partial  
**Priority**: MEDIUM  
**Location**: `apps/users/admin_serializers.py`

```python
# ==================== MARKETPLACE ALERT SERIALIZERS ====================

class MarketplaceAlertSerializer(serializers.ModelSerializer):
    """Serializer for marketplace alerts."""
    created_by_name = serializers.CharField(
        source='created_by.user.full_name', read_only=True
    )
    resolved_by_name = serializers.CharField(
        source='resolved_by.user.full_name', read_only=True, allow_null=True
    )
    severity_display = serializers.CharField(
        source='get_severity_display', read_only=True
    )
    category_display = serializers.CharField(
        source='get_category_display', read_only=True
    )
    status_display = serializers.CharField(
        source='get_status_display', read_only=True
    )
    
    class Meta:
        model = MarketplaceAlert
        fields = [
            'id', 'category', 'category_display', 'severity', 'severity_display',
            'description', 'target_id', 'status', 'status_display',
            'created_by_name', 'resolved_by_name', 'resolution_notes',
            'created_at', 'resolved_at'
        ]
        read_only_fields = ['id', 'created_at']


class MarketplaceAlertResolutionSerializer(serializers.Serializer):
    """Serializer for resolving a marketplace alert."""
    resolution_notes = serializers.CharField(max_length=500)
    status = serializers.ChoiceField(
        choices=['RESOLVED', 'IGNORED', 'ESCALATED']
    )


# ==================== SYSTEM NOTIFICATION SERIALIZERS ====================

class SystemNotificationSerializer(serializers.ModelSerializer):
    """Serializer for system notifications."""
    recipient_name = serializers.CharField(
        source='recipient.full_name', read_only=True
    )
    created_by_name = serializers.CharField(
        source='created_by.user.full_name', read_only=True, allow_null=True
    )
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    
    class Meta:
        model = SystemNotification
        fields = [
            'id', 'recipient_id', 'recipient_name', 'title', 'message',
            'type', 'type_display', 'read_status', 'created_by_name',
            'created_at', 'read_at'
        ]
        read_only_fields = ['id', 'created_at']


class SystemNotificationBulkCreateSerializer(serializers.Serializer):
    """Serializer for bulk sending notifications."""
    recipient_ids = serializers.ListField(child=serializers.IntegerField())
    title = serializers.CharField(max_length=200)
    message = serializers.CharField(max_length=1000)
    notification_type = serializers.ChoiceField(
        choices=['ANNOUNCEMENT', 'ALERT', 'PRICE_UPDATE', 'SYSTEM', 'OTHER']
    )
```

### 1.5 Performance & Analytics Serializers
**Status**: ❌ Missing  
**Priority**: MEDIUM  
**Location**: `apps/users/admin_serializers.py`

```python
# ==================== PERFORMANCE & ANALYTICS SERIALIZERS ====================

class SellerPerformanceMetricsSerializer(serializers.Serializer):
    """Serializer for seller performance metrics."""
    seller_id = serializers.IntegerField(read_only=True)
    seller_name = serializers.CharField(read_only=True)
    total_products = serializers.IntegerField(read_only=True)
    avg_rating = serializers.FloatField(read_only=True)
    total_sales = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    avg_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, read_only=True
    )
    compliance_violations = serializers.IntegerField(read_only=True)
    days_active = serializers.IntegerField(read_only=True)
    performance_score = serializers.FloatField(read_only=True, help_text="0-100")


class PriceComplianceReportSerializer(serializers.Serializer):
    """Serializer for price compliance analysis."""
    total_listings = serializers.IntegerField(read_only=True)
    compliant_listings = serializers.IntegerField(read_only=True)
    non_compliant_listings = serializers.IntegerField(read_only=True)
    compliance_rate = serializers.FloatField(read_only=True, help_text="Percentage")
    avg_overage = serializers.FloatField(
        read_only=True, help_text="Average overage percentage"
    )
    sellers_with_violations = serializers.IntegerField(read_only=True)
    violations_by_product = serializers.ListField(
        child=serializers.DictField(), read_only=True
    )
    violations_by_seller = serializers.ListField(
        child=serializers.DictField(), read_only=True
    )


class OPASPurchaseHistorySerializer(serializers.ModelSerializer):
    """Serializer for OPAS purchase history."""
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = OPASPurchaseHistory
        fields = [
            'id', 'seller_id', 'seller_name', 'product_id', 'product_name',
            'quantity_offered', 'quantity_approved', 'offered_price',
            'final_price', 'status', 'quality_grade', 'created_at'
        ]
        read_only_fields = fields
```

---

## 📊 PART 2: MISSING VIEWSETS IMPLEMENTATION

### 2.1 Analytics Reporting ViewSet
**Status**: ❌ Missing  
**Priority**: HIGH  
**Location**: `apps/users/admin_viewsets.py`

```python
# ==================== ANALYTICS & REPORTING VIEWSET ====================

class AnalyticsReportingViewSet(viewsets.ViewSet):
    """
    ViewSet for admin analytics and reporting.
    
    Provides comprehensive marketplace metrics, seller performance,
    price compliance analysis, and revenue reporting.
    """
    permission_classes = [IsAuthenticated, IsAdmin, CanViewAnalytics]
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """
        Get comprehensive dashboard statistics.
        
        Returns: All critical metrics in one endpoint
        """
        from django.utils import timezone
        from datetime import timedelta
        
        # Calculate all metrics
        today = timezone.now().date()
        month_start = today.replace(day=1)
        
        seller_metrics = {
            'total_sellers': User.objects.filter(role=UserRole.SELLER).count(),
            'pending_approvals': User.objects.filter(
                role=UserRole.SELLER, seller_status=SellerStatus.PENDING
            ).count(),
            'active_sellers': User.objects.filter(
                role=UserRole.SELLER, seller_status=SellerStatus.APPROVED
            ).count(),
            'suspended_sellers': User.objects.filter(
                role=UserRole.SELLER, seller_status=SellerStatus.SUSPENDED
            ).count(),
        }
        
        market_metrics = {
            'active_listings': SellerProduct.objects.filter(is_deleted=False).count(),
            'total_sales_today': (
                SellerOrder.objects.filter(created_at__date=today)
                .aggregate(total=Sum('total_price'))['total'] or 0
            ),
            'total_sales_month': (
                SellerOrder.objects.filter(created_at__date__gte=month_start)
                .aggregate(total=Sum('total_price'))['total'] or 0
            ),
        }
        
        opas_metrics = {
            'pending_submissions': SellToOPAS.objects.filter(
                status='PENDING'
            ).count(),
            'total_inventory': (
                OPASInventory.objects.aggregate(total=Sum('quantity_on_hand'))['total'] or 0
            ),
            'low_stock_count': OPASInventory.objects.filter(is_low_stock=True).count(),
            'expiring_count': OPASInventory.objects.filter(is_expiring=True).count(),
        }
        
        # Calculate compliance
        compliant = SellerProduct.objects.filter(
            current_price__lte=F('price_ceiling')
        ).count()
        non_compliant = SellerProduct.objects.filter(
            current_price__gt=F('price_ceiling')
        ).count()
        
        compliance_metrics = {
            'compliant_listings': compliant,
            'non_compliant': non_compliant,
            'compliance_rate': (
                (compliant / (compliant + non_compliant) * 100)
                if (compliant + non_compliant) > 0 else 0
            ),
        }
        
        alerts = {
            'price_violations': PriceNonCompliance.objects.filter(
                status='ACTIVE'
            ).count(),
            'inventory_alerts': MarketplaceAlert.objects.filter(
                category='INVENTORY_ALERT', status='OPEN'
            ).count(),
            'total_open_alerts': MarketplaceAlert.objects.filter(
                status='OPEN'
            ).count(),
        }
        
        data = {
            'timestamp': timezone.now(),
            'seller_metrics': seller_metrics,
            'market_metrics': market_metrics,
            'opas_metrics': opas_metrics,
            'price_compliance': compliance_metrics,
            'alerts': alerts,
            'marketplace_health_score': 85,  # Calculate from weighted metrics
        }
        
        serializer = AdminDashboardStatsSerializer(data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def seller_metrics(self, request):
        """Get seller performance metrics with sorting and filtering."""
        sellers = User.objects.filter(role=UserRole.SELLER).annotate(
            total_products=Count('products'),
            avg_rating=Avg('seller_rating'),
            total_sales=Sum('orders__total_price'),
        ).order_by('-total_sales')
        
        serializer = SellerPerformanceMetricsSerializer(sellers, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def price_analysis(self, request):
        """Analyze price compliance and violations."""
        # Get compliance report
        compliant = SellerProduct.objects.filter(
            current_price__lte=F('price_ceiling')
        ).count()
        non_compliant = SellerProduct.objects.filter(
            current_price__gt=F('price_ceiling')
        ).count()
        
        violations = PriceNonCompliance.objects.filter(status='ACTIVE')
        
        data = {
            'total_listings': compliant + non_compliant,
            'compliant_listings': compliant,
            'non_compliant_listings': non_compliant,
            'compliance_rate': (
                compliant / (compliant + non_compliant) * 100
                if (compliant + non_compliant) > 0 else 0
            ),
            'avg_overage': (
                violations.aggregate(avg=Avg('overage_percentage'))['avg'] or 0
            ),
            'sellers_with_violations': violations.values('seller').distinct().count(),
        }
        
        serializer = PriceComplianceReportSerializer(data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def inventory_report(self, request):
        """Get comprehensive inventory report."""
        inventory = OPASInventory.objects.all()
        
        total_value = inventory.aggregate(
            total=Sum(F('quantity_on_hand') * F('unit_price'), output_field=DecimalField())
        )['total'] or 0
        
        data = {
            'total_items': inventory.count(),
            'total_quantity': inventory.aggregate(Sum('quantity_on_hand'))['quantity_on_hand__sum'] or 0,
            'low_stock_items': inventory.filter(is_low_stock=True).count(),
            'expiring_items': inventory.filter(is_expiring=True).count(),
            'total_value': total_value,
        }
        
        return Response(data)
    
    @action(detail=False, methods=['get'])
    def market_trends(self, request):
        """Analyze market trends."""
        from datetime import timedelta
        from django.utils import timezone
        
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)
        
        daily_sales = (
            SellerOrder.objects.filter(created_at__date__gte=start_date)
            .extra(select={'date': 'DATE(created_at)'})
            .values('date')
            .annotate(total=Sum('total_price'), count=Count('id'))
            .order_by('date')
        )
        
        return Response(list(daily_sales))
    
    @action(detail=False, methods=['get'])
    def compliance_report(self, request):
        """Generate compliance report."""
        # Audit logs, violations, issues
        recent_violations = AdminAuditLog.objects.filter(
            action_type__icontains='violation'
        ).order_by('-created_at')[:10]
        
        serializer = AdminAuditLogSerializer(recent_violations, many=True)
        return Response({
            'recent_violations': serializer.data,
            'total_actions_today': AdminAuditLog.objects.filter(
                created_at__date=timezone.now().date()
            ).count(),
        })
    
    @action(detail=False, methods=['get'])
    def revenue_report(self, request):
        """Generate revenue report."""
        from datetime import timedelta
        from django.utils import timezone
        
        period = request.query_params.get('period', 'month')  # day, week, month, year
        
        if period == 'month':
            start_date = timezone.now().replace(day=1)
        elif period == 'year':
            start_date = timezone.now().replace(month=1, day=1)
        elif period == 'week':
            start_date = timezone.now() - timedelta(days=7)
        else:
            start_date = timezone.now() - timedelta(days=1)
        
        revenue_data = SellerOrder.objects.filter(
            created_at__gte=start_date
        ).aggregate(
            total_revenue=Sum('total_price'),
            total_orders=Count('id'),
            avg_order_value=Avg('total_price'),
        )
        
        return Response(revenue_data)
```

### 2.2 Admin Notifications ViewSet
**Status**: ❌ Missing  
**Priority**: HIGH  
**Location**: `apps/users/admin_viewsets.py`

```python
# ==================== ADMIN NOTIFICATIONS VIEWSET ====================

class AdminNotificationsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for admin notifications and announcements.
    
    Handles creation, distribution, and management of system notifications
    and broadcasts to sellers and admins.
    """
    permission_classes = [IsAuthenticated, IsAdmin, CanManageNotifications]
    serializer_class = SystemNotificationSerializer
    
    def get_queryset(self):
        """Get notifications for current user or all for super admin."""
        user = self.request.user
        if user.is_superuser:
            return SystemNotification.objects.all()
        return SystemNotification.objects.filter(recipient=user)
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get count of unread notifications for current user."""
        count = SystemNotification.objects.filter(
            recipient=request.user, read_status=False
        ).count()
        return Response({'unread_count': count})
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark a notification as read."""
        notification = self.get_object()
        notification.read_status = True
        notification.read_at = timezone.now()
        notification.save()
        serializer = self.get_serializer(notification)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def broadcast_announcement(self, request):
        """
        Broadcast announcement to all sellers or selected group.
        
        Request body:
        {
            "title": "Price Update Notice",
            "message": "Prices updated for agricultural products",
            "notification_type": "ANNOUNCEMENT",
            "target_group": "all_sellers",  # or "admin_only", or "specific_ids"
            "recipient_ids": [1, 2, 3]  # if specific_ids
        }
        """
        serializer = SystemNotificationBulkCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        admin_user = AdminUser.objects.get(user=request.user)
        recipient_ids = serializer.validated_data['recipient_ids']
        
        notifications = []
        for recipient_id in recipient_ids:
            notifications.append(
                SystemNotification(
                    recipient_id=recipient_id,
                    title=serializer.validated_data['title'],
                    message=serializer.validated_data['message'],
                    type=serializer.validated_data['notification_type'],
                    created_by=admin_user,
                )
            )
        
        created = SystemNotification.objects.bulk_create(notifications)
        return Response({
            'count': len(created),
            'message': f'Broadcast sent to {len(created)} recipients'
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['post'])
    def schedule_announcement(self, request):
        """Schedule announcement for future sending."""
        # Implementation for scheduled announcements
        return Response({
            'message': 'Scheduling feature - to be implemented'
        })
    
    @action(detail=False, methods=['post'])
    def notify_sellers(self, request):
        """Send notification to specific sellers."""
        seller_ids = request.data.get('seller_ids', [])
        title = request.data.get('title')
        message = request.data.get('message')
        notification_type = request.data.get('type', 'ALERT')
        
        # Get sellers and create notifications
        sellers = User.objects.filter(id__in=seller_ids, role=UserRole.SELLER)
        admin_user = AdminUser.objects.get(user=request.user)
        
        notifications = [
            SystemNotification(
                recipient=seller,
                title=title,
                message=message,
                type=notification_type,
                created_by=admin_user,
            )
            for seller in sellers
        ]
        
        created = SystemNotification.objects.bulk_create(notifications)
        return Response({
            'count': len(created),
            'message': f'Notifications sent to {len(created)} sellers'
        })
```

### 2.3 Marketplace Oversight ViewSet (Complete)
**Status**: ⚠️ Partial  
**Priority**: HIGH  
**Location**: `apps/users/admin_viewsets.py` - Enhance existing

```python
# Add these methods to MarketplaceOversightViewSet:

@action(detail=False, methods=['get'])
def list_alerts(self, request):
    """List all marketplace alerts with filtering."""
    queryset = MarketplaceAlert.objects.all()
    
    # Filter by status
    status_filter = request.query_params.get('status')
    if status_filter:
        queryset = queryset.filter(status=status_filter)
    
    # Filter by category
    category_filter = request.query_params.get('category')
    if category_filter:
        queryset = queryset.filter(category=category_filter)
    
    # Filter by severity
    severity_filter = request.query_params.get('severity')
    if severity_filter:
        queryset = queryset.filter(severity=severity_filter)
    
    serializer = MarketplaceAlertSerializer(queryset, many=True)
    return Response({
        'count': queryset.count(),
        'results': serializer.data
    })

@action(detail=True, methods=['post'])
def resolve_alert(self, request, pk=None):
    """Resolve a marketplace alert."""
    alert = self.get_object()
    serializer = MarketplaceAlertResolutionSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    
    admin_user = AdminUser.objects.get(user=request.user)
    alert.status = serializer.validated_data['status']
    alert.resolved_by = admin_user
    alert.resolution_notes = serializer.validated_data['resolution_notes']
    alert.resolved_at = timezone.now()
    alert.save()
    
    response_serializer = MarketplaceAlertSerializer(alert)
    return Response(response_serializer.data)
```

### 2.4 Admin Audit ViewSet
**Status**: ❌ Missing  
**Priority**: MEDIUM  
**Location**: `apps/users/admin_viewsets.py`

```python
# ==================== ADMIN AUDIT VIEWSET ====================

class AdminAuditViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for admin audit logging (read-only for compliance).
    
    Provides immutable audit trail for all admin actions.
    """
    permission_classes = [IsAuthenticated, IsAdmin, CanAccessAuditLogs]
    queryset = AdminAuditLog.objects.all()
    serializer_class = AdminAuditLogDetailedSerializer
    
    def get_queryset(self):
        """Get audit logs with filtering."""
        queryset = AdminAuditLog.objects.all()
        
        # Filter by admin
        admin_id = self.request.query_params.get('admin_id')
        if admin_id:
            queryset = queryset.filter(admin_id=admin_id)
        
        # Filter by action type
        action_type = self.request.query_params.get('action_type')
        if action_type:
            queryset = queryset.filter(action_type=action_type)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        if start_date and end_date:
            queryset = queryset.filter(
                created_at__date__range=[start_date, end_date]
            )
        
        return queryset.order_by('-created_at')
    
    @action(detail=False, methods=['get'])
    def search(self, request):
        """Search audit logs by query."""
        query = request.query_params.get('q', '')
        action_type = request.query_params.get('action_type')
        
        queryset = self.get_queryset()
        
        if query:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(description__icontains=query) |
                Q(admin__user__email__icontains=query)
            )
        
        if action_type:
            queryset = queryset.filter(action_type=action_type)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
```

### 2.5 Dashboard ViewSet
**Status**: ❌ Missing  
**Priority**: HIGH  
**Location**: `apps/users/admin_viewsets.py`

```python
# ==================== DASHBOARD VIEWSET ====================

class DashboardViewSet(viewsets.ViewSet):
    """
    ViewSet for admin dashboard endpoints.
    
    Provides quick stats for demo and monitoring.
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get comprehensive dashboard statistics."""
        # All metric calculations
        data = {
            'timestamp': timezone.now(),
            'seller_metrics': {...},
            'market_metrics': {...},
            # ... all metrics
        }
        serializer = AdminDashboardStatsSerializer(data)
        return Response(serializer.data)
```

---

## 🔐 PART 3: MISSING PERMISSIONS IMPLEMENTATION

**Status**: ⚠️ Partial (6/14 implemented)  
**Location**: `apps/users/admin_permissions.py`  
**Priority**: MEDIUM

```python
# Add these permission classes to admin_permissions.py:

class IsActiveAdmin(permissions.BasePermission):
    """Check if admin account is active."""
    message = "Your admin account is not active."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            return admin_user.is_active
        except AdminUser.DoesNotExist:
            return False


class CanViewSellerDetails(permissions.BasePermission):
    """Permission to view seller private information."""
    message = "You do not have permission to view seller details."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'SELLER_MANAGER', 'ANALYTICS_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanEditSellerInfo(permissions.BasePermission):
    """Permission to edit seller information."""
    message = "You do not have permission to edit seller info."
    
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'SELLER_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanViewComplianceReports(permissions.BasePermission):
    """Permission to view compliance reports."""
    message = "You do not have permission to view compliance reports."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'ANALYTICS_MANAGER', 'PRICE_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanExportData(permissions.BasePermission):
    """Permission to export admin data."""
    message = "You do not have permission to export data."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            return admin_user.admin_role == 'SUPER_ADMIN'
        except AdminUser.DoesNotExist:
            return False


class CanAccessAuditLogs(permissions.BasePermission):
    """Permission to view immutable audit logs."""
    message = "You do not have permission to access audit logs."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'ANALYTICS_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanBroadcastAnnouncements(permissions.BasePermission):
    """Permission to broadcast to all sellers."""
    message = "You do not have permission to broadcast announcements."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'SUPPORT_ADMIN']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanModerateAlerts(permissions.BasePermission):
    """Permission to create and resolve alerts."""
    message = "You do not have permission to moderate alerts."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = [
                'SUPER_ADMIN', 'SELLER_MANAGER', 'PRICE_MANAGER',
                'MARKETPLACE_MONITOR'
            ]
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanAccessFinancialData(permissions.BasePermission):
    """Permission to view financial/revenue data."""
    message = "You do not have permission to access financial data."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'ANALYTICS_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False
```

---

## 📝 Implementation Sequence

**Recommended Order**:
1. ✅ Add missing serializers (2 hours)
2. ✅ Add missing permissions (1 hour)
3. ✅ Create AnalyticsReportingViewSet (1.5 hours)
4. ✅ Create AdminNotificationsViewSet (1 hour)
5. ✅ Create AdminAuditViewSet (0.5 hours)
6. ✅ Create DashboardViewSet (0.5 hours)
7. ✅ Complete MarketplaceOversightViewSet (0.5 hours)
8. ✅ Update URL configuration (0.5 hours)

**Total Estimated Time**: 7-8 hours

---

**Document Version**: 1.0  
**Status**: Ready for Implementation  
**Next**: Apply these changes to complete Views & Serializers
