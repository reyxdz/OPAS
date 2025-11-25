"""
Admin API Serializers for OPAS platform.

Comprehensive serializers for admin panel REST API endpoints.
Organized by feature area (seller management, pricing, OPAS, marketplace, analytics, notifications).
"""

from rest_framework import serializers
from django.utils import timezone
from django.db.models import Count, Q, Sum

from apps.users.models import User, SellerProduct, SellToOPAS, SellerApplication
from apps.users.admin_models import (
    AdminUser, SellerRegistrationRequest, SellerDocumentVerification,
    SellerApprovalHistory, SellerSuspension,
    PriceCeiling, PriceAdvisory, PriceHistory, PriceNonCompliance,
    OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction, OPASPurchaseHistory,
    AdminAuditLog, MarketplaceAlert, SystemNotification,
)



# ==================== SELLER MANAGEMENT SERIALIZERS ====================

class SellerApprovalHistorySerializer(serializers.ModelSerializer):
    """Serializer for seller approval/rejection history."""
    admin_name = serializers.CharField(source='admin.user.full_name', read_only=True)
    
    class Meta:
        model = SellerApprovalHistory
        fields = [
            'id', 'admin_name', 'decision', 'decision_reason', 'admin_notes',
            'effective_from', 'effective_until', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class SellerDocumentVerificationSerializer(serializers.ModelSerializer):
    """Serializer for seller document verification status."""
    verified_by_name = serializers.CharField(source='verified_by.user.full_name', read_only=True)
    
    class Meta:
        model = SellerDocumentVerification
        fields = [
            'id', 'document_type', 'document_url', 'status',
            'verified_by_name', 'verification_notes', 'uploaded_at',
            'verified_at', 'expires_at'
        ]
        read_only_fields = ['id', 'uploaded_at']


class SellerApplicationSerializer(serializers.ModelSerializer):
    """Serializer for seller applications from buyers."""
    user_email = serializers.CharField(source='user.email', read_only=True)
    seller_email = serializers.CharField(source='user.email', read_only=True)  # Alias for Flutter
    seller_full_name = serializers.CharField(source='user.full_name', read_only=True)  # For Flutter
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)  # Get from related User
    submitted_at = serializers.DateTimeField(source='created_at', read_only=True)  # Alias for Flutter
    reviewed_by_name = serializers.CharField(source='reviewed_by.full_name', read_only=True, allow_null=True)
    
    class Meta:
        model = SellerApplication
        fields = [
            'id', 'user', 'user_email', 'seller_email', 'seller_full_name',
            'phone_number', 'farm_name', 'farm_location', 'store_name', 'store_description',
            'status', 'rejection_reason', 'created_at', 'submitted_at',
            'updated_at', 'reviewed_at', 'reviewed_by', 'reviewed_by_name'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at', 'reviewed_at', 'reviewed_by', 'submitted_at']


class SellerManagementListSerializer(serializers.ModelSerializer):
    """Serializer for seller list view (lightweight)."""
    full_name = serializers.CharField(read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number', 'store_name',
            'seller_status', 'seller_approval_date', 'seller_documents_verified',
            'created_at'
        ]
        read_only_fields = fields


class SellerManagementSerializer(serializers.ModelSerializer):
    """Serializer for seller list view (primary - alias for compatibility)."""
    full_name = serializers.CharField(read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number', 'store_name',
            'seller_status', 'seller_approval_date', 'seller_documents_verified',
            'created_at'
        ]
        read_only_fields = fields


class SellerDetailsSerializer(serializers.ModelSerializer):
    """Serializer for detailed seller view with history and documents."""
    full_name = serializers.CharField(read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number', 'address',
            'store_name', 'store_description', 'role', 'seller_status',
            'seller_approval_date', 'seller_documents_verified',
            'suspension_reason', 'suspended_at', 'created_at', 'updated_at'
        ]
        read_only_fields = fields


class SellerApprovalRequestSerializer(serializers.Serializer):
    """Serializer for seller approval request (POST)."""
    seller_id = serializers.IntegerField()
    approval_notes = serializers.CharField(required=False, allow_blank=True, max_length=500)
    
    class Meta:
        fields = ['seller_id', 'approval_notes']


class SellerRejectionRequestSerializer(serializers.Serializer):
    """Serializer for seller rejection request (POST)."""
    seller_id = serializers.IntegerField()
    rejection_reason = serializers.CharField(max_length=500, help_text="Reason for rejection")
    
    class Meta:
        fields = ['seller_id', 'rejection_reason']


class SellerSuspensionRequestSerializer(serializers.Serializer):
    """Serializer for seller suspension request (POST)."""
    seller_id = serializers.IntegerField()
    suspension_reason = serializers.CharField(max_length=500, help_text="Reason for suspension")
    is_permanent = serializers.BooleanField(default=False)
    
    class Meta:
        fields = ['seller_id', 'suspension_reason', 'is_permanent']


class SellerSuspensionSerializer(serializers.ModelSerializer):
    """Serializer for seller suspension records."""
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    suspended_by_name = serializers.CharField(source='suspended_by.user.full_name', read_only=True)
    
    class Meta:
        model = SellerSuspension
        fields = [
            'id', 'seller_name', 'suspension_reason', 'is_permanent',
            'suspended_by_name', 'suspended_at', 'lifted_at'
        ]
        read_only_fields = ['id', 'suspended_at']


# ==================== PRICE MANAGEMENT SERIALIZERS ====================

class PriceCeilingSerializer(serializers.ModelSerializer):
    """Serializer for price ceiling listing and details."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_type = serializers.CharField(source='product.product_type', read_only=True)
    set_by_name = serializers.CharField(source='set_by.user.full_name', read_only=True)
    
    class Meta:
        model = PriceCeiling
        fields = [
            'id', 'product_name', 'product_type', 'ceiling_price',
            'previous_ceiling', 'effective_from', 'effective_until',
            'set_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class PriceCeilingCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new price ceiling."""
    product_id = serializers.IntegerField()
    
    class Meta:
        model = PriceCeiling
        fields = ['product_id', 'ceiling_price', 'effective_from', 'effective_until']
    
    def create(self, validated_data):
        product_id = validated_data.pop('product_id')
        product = SellerProduct.objects.get(id=product_id)
        return PriceCeiling.objects.create(product=product, **validated_data)


class PriceHistorySerializer(serializers.ModelSerializer):
    """Serializer for price change history."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    admin_name = serializers.CharField(source='admin.user.full_name', read_only=True)
    
    class Meta:
        model = PriceHistory
        fields = [
            'id', 'product_name', 'old_price', 'new_price', 'change_reason',
            'reason_notes', 'affected_sellers_count', 'non_compliant_count',
            'admin_name', 'changed_at'
        ]
        read_only_fields = fields


class PriceAdvisorySerializer(serializers.ModelSerializer):
    """Serializer for price advisory/announcement."""
    created_by_name = serializers.CharField(source='created_by.user.full_name', read_only=True)
    
    class Meta:
        model = PriceAdvisory
        fields = [
            'id', 'title', 'content', 'advisory_type', 'target_audience',
            'is_active', 'effective_from', 'effective_until',
            'created_by_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class PriceAdvisoryCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating price advisory."""
    class Meta:
        model = PriceAdvisory
        fields = [
            'title', 'content', 'advisory_type', 'target_audience',
            'effective_from', 'effective_until'
        ]


class PriceNonComplianceSerializer(serializers.ModelSerializer):
    """Serializer for price non-compliance violations."""
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    detected_by_name = serializers.CharField(source='detected_by.user.full_name', read_only=True)
    
    class Meta:
        model = PriceNonCompliance
        fields = [
            'id', 'seller_name', 'product_name', 'listed_price', 'ceiling_price',
            'overage_percentage', 'status', 'warning_issued_at', 'warning_expires_at',
            'resolved_at', 'resolution_notes', 'detected_by_name', 'detected_at'
        ]
        read_only_fields = ['id', 'detected_at']


# ==================== OPAS PURCHASING SERIALIZERS ====================

class OPASPurchaseOrderSerializer(serializers.ModelSerializer):
    """Serializer for OPAS purchase order listing."""
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.user.full_name', read_only=True)
    
    class Meta:
        model = OPASPurchaseOrder
        fields = [
            'id', 'seller_name', 'product_name', 'status',
            'offered_quantity', 'offered_price', 'approved_quantity', 'final_price',
            'quality_grade', 'delivery_terms', 'admin_notes', 'rejection_reason',
            'submitted_at', 'reviewed_at', 'approved_at', 'reviewed_by_name'
        ]
        read_only_fields = ['id', 'submitted_at']


class OPASPurchaseOrderApprovalSerializer(serializers.Serializer):
    """Serializer for approving OPAS purchase order."""
    approved_quantity = serializers.DecimalField(max_digits=10, decimal_places=2)
    final_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    quality_grade = serializers.ChoiceField(choices=['A', 'B', 'C', 'STANDARD'])
    admin_notes = serializers.CharField(required=False, max_length=500)


class OPASPurchaseOrderRejectionSerializer(serializers.Serializer):
    """Serializer for rejecting OPAS purchase order."""
    rejection_reason = serializers.CharField(max_length=500)


class OPASInventoryTransactionSerializer(serializers.ModelSerializer):
    """Serializer for inventory transaction."""
    processed_by_name = serializers.CharField(source='processed_by.user.full_name', read_only=True)
    
    class Meta:
        model = OPASInventoryTransaction
        fields = [
            'id', 'transaction_type', 'quantity', 'reference_number', 'reason',
            'is_fifo_compliant', 'batch_id', 'processed_by_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class OPASInventorySerializer(serializers.ModelSerializer):
    """Serializer for OPAS inventory stock."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    transactions = OPASInventoryTransactionSerializer(many=True, read_only=True)
    
    class Meta:
        model = OPASInventory
        fields = [
            'id', 'product_name', 'quantity_received', 'quantity_on_hand',
            'quantity_consumed', 'quantity_spoiled', 'storage_location',
            'storage_condition', 'received_at', 'in_date', 'expiry_date',
            'low_stock_threshold', 'is_low_stock', 'is_expiring',
            'transactions'
        ]
        read_only_fields = ['id', 'received_at']


class OPASInventoryAdjustmentSerializer(serializers.Serializer):
    """Serializer for manual inventory adjustment."""
    transaction_type = serializers.ChoiceField(choices=['IN', 'OUT', 'ADJUSTMENT', 'SPOILAGE'])
    quantity = serializers.DecimalField(max_digits=10, decimal_places=2)
    reason = serializers.CharField(max_length=300)


class OPASPurchaseHistorySerializer(serializers.ModelSerializer):
    """Serializer for OPAS purchase history/audit."""
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = OPASPurchaseHistory
        fields = [
            'id', 'seller_name', 'product_name', 'quantity', 'unit_price',
            'total_price', 'quality_grade', 'payment_status', 'paid_at',
            'purchased_at'
        ]
        read_only_fields = fields


# ==================== MARKETPLACE OVERSIGHT SERIALIZERS ====================

class ProductListingSerializer(serializers.ModelSerializer):
    """Serializer for marketplace product listings."""
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    
    class Meta:
        model = SellerProduct
        fields = [
            'id', 'seller_name', 'name', 'product_type', 'price',
            'stock_level', 'status', 'created_at'
        ]
        read_only_fields = fields


class ProductListingFlagSerializer(serializers.Serializer):
    """Serializer for flagging marketplace listing."""
    reason = serializers.CharField(max_length=300, help_text="Reason for flagging")
    severity = serializers.ChoiceField(choices=['LOW', 'MEDIUM', 'HIGH'])


class MarketplaceAlertSerializer(serializers.ModelSerializer):
    """Serializer for marketplace alerts."""
    seller_name = serializers.CharField(source='affected_seller.full_name', read_only=True)
    product_name = serializers.CharField(source='affected_product.name', read_only=True)
    acknowledged_by_name = serializers.CharField(source='acknowledged_by.user.full_name', read_only=True)
    
    class Meta:
        model = MarketplaceAlert
        fields = [
            'id', 'title', 'description', 'alert_type', 'severity', 'status',
            'seller_name', 'product_name', 'acknowledged_by_name',
            'resolution_notes', 'created_at', 'acknowledged_at', 'resolved_at'
        ]
        read_only_fields = ['id', 'created_at']


# ==================== ANALYTICS REPORTING SERIALIZERS ====================

class DashboardStatsSerializer(serializers.Serializer):
    """Serializer for admin dashboard statistics."""
    total_sellers = serializers.IntegerField(help_text='Total approved sellers')
    pending_approvals = serializers.IntegerField(help_text='Sellers pending approval')
    suspended_sellers = serializers.IntegerField(help_text='Suspended sellers count')
    total_listings = serializers.IntegerField(help_text='Active marketplace listings')
    price_violations = serializers.IntegerField(help_text='Price ceiling violations')
    opas_submissions = serializers.IntegerField(help_text='Pending OPAS submissions')
    inventory_low_stock = serializers.IntegerField(help_text='Low stock items')
    inventory_expiring = serializers.IntegerField(help_text='Items expiring soon')
    
    class Meta:
        fields = [
            'total_sellers', 'pending_approvals', 'suspended_sellers',
            'total_listings', 'price_violations', 'opas_submissions',
            'inventory_low_stock', 'inventory_expiring'
        ]


class PriceTrendSerializer(serializers.Serializer):
    """Serializer for price trend analysis."""
    date = serializers.DateField()
    product_name = serializers.CharField()
    average_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    min_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    max_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    ceiling_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    violation_count = serializers.IntegerField()


class SalesReportSerializer(serializers.Serializer):
    """Serializer for sales report."""
    date_from = serializers.DateTimeField()
    date_to = serializers.DateTimeField()
    total_transactions = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=2)
    average_transaction = serializers.DecimalField(max_digits=10, decimal_places=2)
    top_products = serializers.ListField(child=serializers.DictField())


class OPASReportSerializer(serializers.Serializer):
    """Serializer for OPAS purchase report."""
    total_submissions = serializers.IntegerField()
    approved_count = serializers.IntegerField()
    rejected_count = serializers.IntegerField()
    total_quantity = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    average_submission_value = serializers.DecimalField(max_digits=10, decimal_places=2)


class SellerParticipationReportSerializer(serializers.Serializer):
    """Serializer for seller participation report."""
    seller_name = serializers.CharField()
    listings_count = serializers.IntegerField()
    total_sales = serializers.DecimalField(max_digits=15, decimal_places=2)
    opas_submissions = serializers.IntegerField()
    compliance_violations = serializers.IntegerField()
    suspension_count = serializers.IntegerField()


# ==================== ADMIN ACTIVITY SERIALIZERS ====================

class AdminAuditLogSerializer(serializers.ModelSerializer):
    """Serializer for admin audit log."""
    admin_name = serializers.CharField(source='admin.user.full_name', read_only=True)
    seller_name = serializers.CharField(source='affected_seller.full_name', read_only=True)
    product_name = serializers.CharField(source='affected_product.name', read_only=True)
    
    class Meta:
        model = AdminAuditLog
        fields = [
            'id', 'admin_name', 'action_type', 'action_category', 'description',
            'seller_name', 'product_name', 'old_value', 'new_value', 'created_at'
        ]
        read_only_fields = fields


class AdminUserSerializer(serializers.ModelSerializer):
    """Serializer for admin user profile."""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    
    class Meta:
        model = AdminUser
        fields = [
            'id', 'user_email', 'user_name', 'admin_role', 'department',
            'is_active', 'last_activity', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


# ==================== ADMIN NOTIFICATIONS SERIALIZERS ====================

class SystemNotificationSerializer(serializers.ModelSerializer):
    """Serializer for system notifications."""
    recipient_name = serializers.CharField(source='recipient.user.full_name', read_only=True)
    seller_name = serializers.CharField(source='related_seller.full_name', read_only=True)
    product_name = serializers.CharField(source='related_product.name', read_only=True)
    
    class Meta:
        model = SystemNotification
        fields = [
            'id', 'recipient_name', 'title', 'message', 'notification_type',
            'seller_name', 'product_name', 'is_read', 'read_at', 'priority',
            'created_at', 'expires_at'
        ]
        read_only_fields = ['id', 'created_at']


class AnnouncementSerializer(serializers.Serializer):
    """Serializer for creating/updating announcements."""
    title = serializers.CharField(max_length=255)
    message = serializers.CharField(help_text="Announcement content")
    announcement_type = serializers.ChoiceField(
        choices=['PRICE', 'MAINTENANCE', 'APPROVAL', 'GENERAL', 'WARNING']
    )
    target_audience = serializers.ChoiceField(
        choices=['ALL', 'SELLERS', 'BUYERS', 'ADMINS']
    )


# ==================== DASHBOARD SERIALIZERS ====================

class DashboardStatsSerializer(serializers.Serializer):
    """Serializer for dashboard statistics."""
    total_sellers = serializers.IntegerField()
    active_listings = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=2)
    orders_today = serializers.IntegerField()
    pending_approvals = serializers.IntegerField()
    price_violations = serializers.IntegerField()
    system_health = serializers.FloatField()
    marketplace_health = serializers.FloatField()


# ==================== COMPATIBILITY ALIASES ====================
SellerListSerializer = SellerManagementListSerializer
ApproveSellerSerializer = SellerApprovalRequestSerializer
SuspendUserSerializer = SellerSuspensionRequestSerializer
UserManagementSerializer = SellerDetailsSerializer
SellerApplicationDetailSerializer = SellerApplicationSerializer


# ==================== ADMIN USER MANAGEMENT SERIALIZERS ====================

class AdminUserSerializer(serializers.ModelSerializer):
    """Serializer for admin user details."""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    
    class Meta:
        model = AdminUser
        fields = [
            'id', 'user_email', 'user_name', 'admin_role', 'is_active',
            'permissions_customized', 'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AdminUserCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating admin users."""
    user_id = serializers.IntegerField()
    
    class Meta:
        model = AdminUser
        fields = ['user_id', 'admin_role', 'permissions_customized', 'notes']


# ==================== AUDIT LOG SERIALIZERS ====================

class AdminAuditLogDetailedSerializer(serializers.ModelSerializer):
    """Detailed serializer for audit logs with full context."""
    admin_name = serializers.CharField(source='admin.user.full_name', read_only=True)
    admin_email = serializers.CharField(source='admin.user.email', read_only=True)
    seller_name = serializers.CharField(source='affected_seller.full_name', read_only=True, allow_null=True)
    
    class Meta:
        model = AdminAuditLog
        fields = [
            'id', 'admin_name', 'admin_email', 'action_type', 'action_category',
            'description', 'affected_seller_name', 'seller_name', 'old_value',
            'new_value', 'ip_address', 'user_agent', 'status', 'error_message',
            'created_at'
        ]
        read_only_fields = fields


# ==================== DASHBOARD METRICS SERIALIZERS ====================

class SellerMetricsSerializer(serializers.Serializer):
    """Serializer for seller-related metrics."""
    total_sellers = serializers.IntegerField()
    pending_approvals = serializers.IntegerField()
    active_sellers = serializers.IntegerField()
    suspended_sellers = serializers.IntegerField()
    new_this_month = serializers.IntegerField()
    approval_rate = serializers.FloatField()


class MarketMetricsSerializer(serializers.Serializer):
    """Serializer for market/marketplace metrics."""
    active_listings = serializers.IntegerField()
    total_sales_today = serializers.FloatField()
    total_sales_month = serializers.FloatField()
    avg_price_change = serializers.FloatField()
    avg_transaction = serializers.FloatField()


class OPASMetricsSerializer(serializers.Serializer):
    """Serializer for OPAS purchasing metrics."""
    pending_submissions = serializers.IntegerField()
    approved_this_month = serializers.IntegerField()
    total_inventory = serializers.IntegerField()
    low_stock_count = serializers.IntegerField()
    expiring_count = serializers.IntegerField()
    total_inventory_value = serializers.FloatField()


class PriceComplianceMetricsSerializer(serializers.Serializer):
    """Serializer for price compliance metrics."""
    compliant_listings = serializers.IntegerField()
    non_compliant = serializers.IntegerField()
    compliance_rate = serializers.FloatField()


class AlertsMetricsSerializer(serializers.Serializer):
    """Serializer for marketplace alerts metrics."""
    price_violations = serializers.IntegerField()
    seller_issues = serializers.IntegerField()
    inventory_alerts = serializers.IntegerField()
    total_open_alerts = serializers.IntegerField()


class AdminDashboardStatsSerializer(serializers.Serializer):
    """Comprehensive serializer for admin dashboard stats per Phase 3.2 specification."""
    timestamp = serializers.DateTimeField()
    seller_metrics = SellerMetricsSerializer()
    market_metrics = MarketMetricsSerializer()
    opas_metrics = OPASMetricsSerializer()
    price_compliance = PriceComplianceMetricsSerializer()
    alerts = AlertsMetricsSerializer()
    marketplace_health_score = serializers.IntegerField()


class SellerPerformanceMetricsSerializer(serializers.Serializer):
    """Serializer for seller performance analysis."""
    seller_id = serializers.IntegerField()
    seller_name = serializers.CharField()
    total_listings = serializers.IntegerField()
    average_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    compliance_score = serializers.FloatField()
    violations_count = serializers.IntegerField()
    customer_rating = serializers.FloatField()
    orders_fulfilled = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=2)


class PriceComplianceReportDetailedSerializer(serializers.Serializer):
    """Detailed serializer for price compliance reports."""
    report_date = serializers.DateField()
    total_products_monitored = serializers.IntegerField()
    violations = serializers.ListField(child=serializers.DictField())
    compliance_percentage = serializers.FloatField()
    top_violators = serializers.ListField(child=serializers.DictField())
    trends = serializers.DictField()


# ==================== ALERT AND NOTIFICATION SERIALIZERS ====================

class MarketplaceAlertDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for marketplace alerts."""
    seller_name = serializers.CharField(source='affected_seller.full_name', read_only=True)
    product_name = serializers.CharField(source='affected_product.name', read_only=True)
    acknowledged_by_name = serializers.CharField(source='acknowledged_by.user.full_name', read_only=True)
    
    class Meta:
        model = MarketplaceAlert
        fields = [
            'id', 'title', 'description', 'alert_type', 'severity', 'status',
            'seller_name', 'product_name', 'acknowledged_by_name',
            'resolution_notes', 'created_at', 'acknowledged_at', 'resolved_at'
        ]
        read_only_fields = fields


class SystemNotificationBulkCreateSerializer(serializers.Serializer):
    """Serializer for bulk creating system notifications."""
    title = serializers.CharField(max_length=255)
    message = serializers.CharField()
    notification_type = serializers.CharField(max_length=50)
    target_audience = serializers.ChoiceField(choices=['ALL', 'SELLERS', 'BUYERS', 'ADMINS'])
    priority = serializers.ChoiceField(choices=['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])
    expires_in_days = serializers.IntegerField(default=7, min_value=1)


__all__ = [
    'AdminUserSerializer',
    'AdminUserCreateSerializer',
    'SellerApprovalHistorySerializer',
    'SellerDocumentVerificationSerializer',
    'SellerManagementListSerializer',
    'SellerManagementSerializer',
    'SellerDetailsSerializer',
    'SellerApprovalRequestSerializer',
    'SellerRejectionRequestSerializer',
    'SellerSuspensionRequestSerializer',
    'SellerSuspensionSerializer',
    'PriceCeilingSerializer',
    'PriceCeilingCreateSerializer',
    'PriceHistorySerializer',
    'PriceAdvisorySerializer',
    'PriceAdvisoryCreateSerializer',
    'PriceNonComplianceSerializer',
    'OPASPurchaseOrderSerializer',
    'OPASPurchaseOrderApprovalSerializer',
    'OPASPurchaseOrderRejectionSerializer',
    'OPASInventoryTransactionSerializer',
    'OPASInventorySerializer',
    'OPASInventoryAdjustmentSerializer',
    'OPASPurchaseHistorySerializer',
    'ProductListingSerializer',
    'ProductListingFlagSerializer',
    'MarketplaceAlertSerializer',
    'MarketplaceAlertDetailSerializer',
    'DashboardStatsSerializer',
    'AdminDashboardStatsSerializer',
    'SellerMetricsSerializer',
    'MarketMetricsSerializer',
    'OPASMetricsSerializer',
    'PriceComplianceMetricsSerializer',
    'AlertsMetricsSerializer',
    'PriceTrendSerializer',
    'SalesReportSerializer',
    'OPASReportSerializer',
    'SellerParticipationReportSerializer',
    'AdminAuditLogSerializer',
    'AdminAuditLogDetailedSerializer',
    'SellerPerformanceMetricsSerializer',
    'PriceComplianceReportDetailedSerializer',
    'SystemNotificationSerializer',
    'SystemNotificationBulkCreateSerializer',
    'AnnouncementSerializer',
    'SellerMetricsSerializer',
    'MarketMetricsSerializer',
    'OPASMetricsSerializer',
    'PriceComplianceSerializer',
    'AlertsSerializer',
    'AdminDashboardStatsSerializer',
]


# ==================== DASHBOARD METRICS SERIALIZERS ====================

class SellerMetricsSerializer(serializers.Serializer):
    """
    Serializer for seller marketplace metrics.
    
    Metrics:
    - total_sellers: Total count of sellers
    - pending_approvals: Sellers awaiting approval
    - active_sellers: Approved sellers
    - suspended_sellers: Suspended sellers
    - new_this_month: Sellers registered this month
    - approval_rate: Percentage of approvals vs rejections
    """
    total_sellers = serializers.IntegerField(min_value=0, read_only=True)
    pending_approvals = serializers.IntegerField(min_value=0, read_only=True)
    active_sellers = serializers.IntegerField(min_value=0, read_only=True)
    suspended_sellers = serializers.IntegerField(min_value=0, read_only=True)
    new_this_month = serializers.IntegerField(min_value=0, read_only=True)
    approval_rate = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        min_value=0,
        max_value=100,
        read_only=True
    )


class MarketMetricsSerializer(serializers.Serializer):
    """
    Serializer for marketplace trading metrics.
    
    Metrics:
    - active_listings: Non-deleted, active products
    - total_sales_today: Sum of sales since midnight
    - total_sales_month: Sum of sales since month start
    - avg_price_change: Average daily price movement percentage
    - avg_transaction: Average order value
    """
    active_listings = serializers.IntegerField(min_value=0, read_only=True)
    total_sales_today = serializers.DecimalField(
        max_digits=15,
        decimal_places=2,
        min_value=0,
        read_only=True
    )
    total_sales_month = serializers.DecimalField(
        max_digits=15,
        decimal_places=2,
        min_value=0,
        read_only=True
    )
    avg_price_change = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        read_only=True
    )
    avg_transaction = serializers.DecimalField(
        max_digits=15,
        decimal_places=2,
        min_value=0,
        read_only=True
    )


class OPASMetricsSerializer(serializers.Serializer):
    """
    Serializer for OPAS bulk purchase program metrics.
    
    Metrics:
    - pending_submissions: Pending SellToOPAS requests
    - approved_this_month: Approved submissions this month
    - total_inventory: Sum of inventory quantity
    - low_stock_count: Inventory below threshold
    - expiring_count: Inventory expiring within 7 days
    - total_inventory_value: Sum of (quantity * unit_price)
    """
    pending_submissions = serializers.IntegerField(min_value=0, read_only=True)
    approved_this_month = serializers.IntegerField(min_value=0, read_only=True)
    total_inventory = serializers.IntegerField(min_value=0, read_only=True)
    low_stock_count = serializers.IntegerField(min_value=0, read_only=True)
    expiring_count = serializers.IntegerField(min_value=0, read_only=True)
    total_inventory_value = serializers.DecimalField(
        max_digits=15,
        decimal_places=2,
        min_value=0,
        read_only=True
    )


class PriceComplianceSerializer(serializers.Serializer):
    """
    Serializer for price compliance metrics.
    
    Metrics:
    - compliant_listings: Products within price ceiling
    - non_compliant: Products exceeding ceiling
    - compliance_rate: Percentage of compliant listings
    """
    compliant_listings = serializers.IntegerField(min_value=0, read_only=True)
    non_compliant = serializers.IntegerField(min_value=0, read_only=True)
    compliance_rate = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        min_value=0,
        max_value=100,
        read_only=True
    )


class AlertsSerializer(serializers.Serializer):
    """
    Serializer for marketplace alerts and system health.
    
    Metrics:
    - price_violations: Open price non-compliance alerts
    - seller_issues: Seller-related issues and alerts
    - inventory_alerts: Inventory problems (low stock, expiring)
    - total_open_alerts: All unresolved alerts
    """
    price_violations = serializers.IntegerField(min_value=0, read_only=True)
    seller_issues = serializers.IntegerField(min_value=0, read_only=True)
    inventory_alerts = serializers.IntegerField(min_value=0, read_only=True)
    total_open_alerts = serializers.IntegerField(min_value=0, read_only=True)


class AdminDashboardStatsSerializer(serializers.Serializer):
    """
    Serializer for comprehensive admin dashboard statistics.
    
    Combines all metric groups into a single dashboard response.
    
    Response includes:
    - timestamp: When the metrics were calculated
    - seller_metrics: Seller marketplace metrics
    - market_metrics: Overall marketplace trading metrics
    - opas_metrics: OPAS bulk purchase program metrics
    - price_compliance: Price ceiling compliance metrics
    - alerts: Open alerts and system health indicators
    - marketplace_health_score: Overall health score (0-100)
    """
    timestamp = serializers.DateTimeField(read_only=True)
    seller_metrics = SellerMetricsSerializer(read_only=True)
    market_metrics = MarketMetricsSerializer(read_only=True)
    opas_metrics = OPASMetricsSerializer(read_only=True)
    price_compliance = PriceComplianceSerializer(read_only=True)
    alerts = AlertsSerializer(read_only=True)
    marketplace_health_score = serializers.IntegerField(
        min_value=0,
        max_value=100,
        read_only=True
    )


