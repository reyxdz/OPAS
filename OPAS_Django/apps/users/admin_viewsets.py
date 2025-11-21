"""
Admin ViewSets for OPAS platform.

Provides REST API endpoints for admin panel functionality:
- Seller Management (approve, reject, suspend sellers)
- Price Management (set ceilings, manage advisories, track compliance)
- OPAS Purchasing (review submissions, manage inventory)
- Marketplace Oversight (monitor listings, manage alerts)
- Analytics & Reporting (dashboard stats, trends, reports)
- Admin Notifications (alerts, announcements, broadcasts)
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Q, Count, Sum, Avg
from django.shortcuts import get_object_or_404
from datetime import timedelta

from apps.users.models import (
    User, UserRole, SellerStatus,
    SellerProduct, SellToOPAS, SellerPayout, SellerOrder,
)
from apps.users.admin_models import (
    AdminUser, SellerRegistrationRequest, SellerDocumentVerification,
    SellerApprovalHistory, SellerSuspension,
    PriceCeiling, PriceAdvisory, PriceHistory, PriceNonCompliance,
    OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction, OPASPurchaseHistory,
    AdminAuditLog, MarketplaceAlert, SystemNotification,
)
from .admin_serializers import (
    SellerManagementSerializer, SellerDetailsSerializer,
    PriceCeilingSerializer, PriceAdvisorySerializer, PriceHistorySerializer,
    PriceNonComplianceSerializer, OPASPurchaseOrderSerializer,
    OPASInventorySerializer, AdminAuditLogSerializer, MarketplaceAlertSerializer,
    SystemNotificationSerializer,
)
from .admin_permissions import IsAdmin, CanApproveSellers, CanManagePrices


# ==================== SELLER MANAGEMENT VIEWSET ====================

class SellerManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for admin seller management operations.
    
    Handles seller approval workflow, suspensions, document verification,
    and compliance monitoring.
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = SellerManagementSerializer
    
    def get_queryset(self):
        """Get all sellers with filtering support"""
        queryset = User.objects.filter(role=UserRole.SELLER).order_by('-created_at')
        
        # Filter by status
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            queryset = queryset.filter(seller_status=status_filter)
        
        # Filter by search term
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search) |
                Q(email__icontains=search) |
                Q(store_name__icontains=search)
            )
        
        return queryset
    
    def get_serializer_class(self):
        """Use different serializer for retrieve action"""
        if self.action == 'retrieve':
            return SellerDetailsSerializer
        return SellerManagementSerializer
    
    @action(detail=False, methods=['get'], url_path='pending-approvals')
    def pending_approvals(self, request):
        """
        Get list of sellers pending approval.
        
        Returns: List of sellers with PENDING status
        """
        sellers = self.get_queryset().filter(seller_status=SellerStatus.PENDING)
        serializer = self.get_serializer(sellers, many=True)
        return Response({
            'count': sellers.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['get'], url_path='documents')
    def seller_documents(self, request, pk=None):
        """
        Get seller's submitted documents with verification status.
        
        Returns: List of documents with verification status
        """
        seller = self.get_object()
        try:
            reg_request = SellerRegistrationRequest.objects.get(seller=seller)
            documents = SellerDocumentVerification.objects.filter(
                registration_request=reg_request
            )
            from .admin_serializers import SellerDocumentVerificationSerializer
            serializer = SellerDocumentVerificationSerializer(documents, many=True)
            return Response(serializer.data)
        except SellerRegistrationRequest.DoesNotExist:
            return Response(
                {'detail': 'No registration request found for this seller'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(
        detail=True, methods=['post'],
        url_path='approve',
        permission_classes=[IsAuthenticated, IsAdmin, CanApproveSellers]
    )
    def approve_seller(self, request, pk=None):
        """
        Approve seller registration.
        
        Request body:
        {
            "admin_notes": "Application approved after verification",
            "documents_verified": true
        }
        
        Returns: Updated seller with APPROVED status
        """
        seller = self.get_object()
        admin_user = AdminUser.objects.get(user=request.user)
        
        # Update seller status
        seller.role = UserRole.SELLER
        seller.seller_status = SellerStatus.APPROVED
        seller.seller_approval_date = timezone.now()
        seller.seller_documents_verified = request.data.get('documents_verified', False)
        seller.save()
        
        # Record in approval history
        admin_notes = request.data.get('admin_notes', '')
        SellerApprovalHistory.objects.create(
            seller=seller,
            admin=admin_user,
            decision='APPROVED',
            decision_reason='Seller registration approved by admin',
            admin_notes=admin_notes,
            effective_from=timezone.now()
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Seller Approval',
            action_category='SELLER_APPROVAL',
            affected_seller=seller,
            description=f"Approved seller registration for {seller.full_name}",
            new_value=SellerStatus.APPROVED
        )
        
        serializer = self.get_serializer(seller)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(
        detail=True, methods=['post'],
        url_path='reject',
        permission_classes=[IsAuthenticated, IsAdmin, CanApproveSellers]
    )
    def reject_seller(self, request, pk=None):
        """
        Reject seller registration.
        
        Request body:
        {
            "rejection_reason": "Documentation incomplete",
            "admin_notes": "Requested more information"
        }
        
        Returns: Updated seller with REJECTED status
        """
        seller = self.get_object()
        admin_user = AdminUser.objects.get(user=request.user)
        
        rejection_reason = request.data.get('rejection_reason', 'No reason provided')
        admin_notes = request.data.get('admin_notes', '')
        
        # Update seller status
        seller.seller_status = SellerStatus.REJECTED
        seller.save()
        
        # Record in approval history
        SellerApprovalHistory.objects.create(
            seller=seller,
            admin=admin_user,
            decision='REJECTED',
            decision_reason=rejection_reason,
            admin_notes=admin_notes,
            effective_from=timezone.now()
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Seller Rejection',
            action_category='SELLER_APPROVAL',
            affected_seller=seller,
            description=f"Rejected seller registration: {rejection_reason}",
            new_value=SellerStatus.REJECTED
        )
        
        serializer = self.get_serializer(seller)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(
        detail=True, methods=['post'],
        url_path='suspend',
        permission_classes=[IsAuthenticated, IsAdmin, CanApproveSellers]
    )
    def suspend_seller(self, request, pk=None):
        """
        Suspend seller account.
        
        Request body:
        {
            "reason": "Price ceiling violations",
            "duration_days": 30,  # null for permanent
            "admin_notes": "3 consecutive violations"
        }
        
        Returns: Updated seller with SUSPENDED status
        """
        seller = self.get_object()
        admin_user = AdminUser.objects.get(user=request.user)
        
        reason = request.data.get('reason', 'Account suspended by admin')
        duration_days = request.data.get('duration_days', None)
        
        # Update seller status
        seller.seller_status = SellerStatus.SUSPENDED
        seller.suspended_at = timezone.now()
        seller.suspension_reason = reason
        seller.save()
        
        # Create suspension record
        suspended_until = None
        severity = 'PERMANENT'
        if duration_days:
            suspended_until = timezone.now() + timezone.timedelta(days=duration_days)
            severity = 'TEMPORARY'
        
        SellerSuspension.objects.create(
            seller=seller,
            admin=admin_user,
            reason=reason,
            severity=severity,
            suspended_until=suspended_until,
            is_active=True
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Seller Suspension',
            action_category='SELLER_SUSPENSION',
            affected_seller=seller,
            description=f"Suspended seller account: {reason}",
            new_value=SellerStatus.SUSPENDED
        )
        
        serializer = self.get_serializer(seller)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(
        detail=True, methods=['post'],
        url_path='reactivate',
        permission_classes=[IsAuthenticated, IsAdmin, CanApproveSellers]
    )
    def reactivate_seller(self, request, pk=None):
        """
        Reactivate suspended seller account.
        
        Request body:
        {
            "admin_notes": "Seller completed compliance training"
        }
        
        Returns: Updated seller with APPROVED status
        """
        seller = self.get_object()
        admin_user = AdminUser.objects.get(user=request.user)
        
        # Update seller status
        seller.seller_status = SellerStatus.APPROVED
        seller.suspended_at = None
        seller.suspension_reason = None
        seller.save()
        
        # Mark suspension as lifted
        suspension = SellerSuspension.objects.filter(
            seller=seller, is_active=True
        ).first()
        if suspension:
            suspension.is_active = False
            suspension.lifted_at = timezone.now()
            suspension.save()
        
        # Record in approval history
        admin_notes = request.data.get('admin_notes', '')
        SellerApprovalHistory.objects.create(
            seller=seller,
            admin=admin_user,
            decision='REACTIVATED',
            decision_reason='Seller account reactivated',
            admin_notes=admin_notes,
            effective_from=timezone.now()
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Seller Reactivation',
            action_category='SELLER_SUSPENSION',
            affected_seller=seller,
            description='Seller account reactivated',
            new_value=SellerStatus.APPROVED
        )
        
        serializer = self.get_serializer(seller)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['get'], url_path='approval-history')
    def approval_history(self, request, pk=None):
        """
        Get seller's approval history audit trail.
        
        Returns: List of all approval decisions with timestamps and notes
        """
        seller = self.get_object()
        history = SellerApprovalHistory.objects.filter(seller=seller).order_by('-created_at')
        from .admin_serializers import SellerApprovalHistorySerializer
        serializer = SellerApprovalHistorySerializer(history, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'], url_path='violations')
    def seller_violations(self, request, pk=None):
        """
        Get list of price violations for this seller.
        
        Returns: List of price violations with current status
        """
        seller = self.get_object()
        violations = PriceNonCompliance.objects.filter(seller=seller).order_by('-detected_at')
        serializer = PriceNonComplianceSerializer(violations, many=True)
        return Response({
            'count': violations.count(),
            'results': serializer.data
        })


# ==================== PRICE MANAGEMENT VIEWSET ====================

class PriceManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for admin price ceiling and advisory management.
    
    Handles price ceiling updates, compliance monitoring, price advisories,
    and violation tracking.
    """
    permission_classes = [IsAuthenticated, IsAdmin, CanManagePrices]
    
    def get_queryset(self):
        """Override to handle different models based on action"""
        return PriceCeiling.objects.all()
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if 'ceiling' in self.request.path:
            return PriceCeilingSerializer
        elif 'advisory' in self.request.path:
            return PriceAdvisorySerializer
        elif 'history' in self.request.path:
            return PriceHistorySerializer
        return PriceCeilingSerializer
    
    @action(detail=False, methods=['get'], url_path='ceilings')
    def list_ceilings(self, request):
        """
        List all price ceilings with filtering and search.
        
        Query params:
        - search: Search by product name
        - product_type: Filter by product category
        
        Returns: List of price ceilings with product details
        """
        ceilings = PriceCeiling.objects.select_related('product', 'set_by')
        
        search = request.query_params.get('search', None)
        if search:
            ceilings = ceilings.filter(product__name__icontains=search)
        
        product_type = request.query_params.get('product_type', None)
        if product_type:
            ceilings = ceilings.filter(product__product_type=product_type)
        
        serializer = PriceCeilingSerializer(ceilings, many=True)
        return Response({
            'count': ceilings.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['post'], url_path='ceilings')
    def create_ceiling(self, request):
        """
        Create new price ceiling for a product.
        
        Request body:
        {
            "product_id": 123,
            "ceiling_price": 500.00,
            "effective_from": "2025-11-19T00:00:00Z",
            "effective_until": "2025-12-19T00:00:00Z"
        }
        
        Returns: Created price ceiling
        """
        admin_user = AdminUser.objects.get(user=request.user)
        product_id = request.data.get('product_id')
        
        product = get_object_or_404(SellerProduct, pk=product_id)
        ceiling_price = request.data.get('ceiling_price')
        
        # Check if ceiling already exists
        if PriceCeiling.objects.filter(product=product).exists():
            return Response(
                {'detail': 'Price ceiling already exists for this product'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        ceiling = PriceCeiling.objects.create(
            product=product,
            ceiling_price=ceiling_price,
            set_by=admin_user,
            effective_from=request.data.get('effective_from', timezone.now()),
            effective_until=request.data.get('effective_until')
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Price Ceiling Created',
            action_category='PRICE_UPDATE',
            affected_product=product,
            description=f"Created price ceiling for {product.name}",
            new_value=str(ceiling_price)
        )
        
        serializer = PriceCeilingSerializer(ceiling)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['put'], url_path='ceilings/(?P<ceiling_id>[^/.]+)')
    def update_ceiling(self, request, ceiling_id=None):
        """
        Update existing price ceiling.
        
        Request body:
        {
            "ceiling_price": 550.00,
            "change_reason": "Market Adjustment",
            "reason_notes": "Price increase due to market demand",
            "effective_from": "2025-11-19T00:00:00Z"
        }
        
        Returns: Updated price ceiling with history
        """
        admin_user = AdminUser.objects.get(user=request.user)
        ceiling = get_object_or_404(PriceCeiling, pk=ceiling_id)
        
        old_price = ceiling.ceiling_price
        new_price = request.data.get('ceiling_price', old_price)
        
        # Record history
        PriceHistory.objects.create(
            product=ceiling.product,
            admin=admin_user,
            old_price=old_price,
            new_price=new_price,
            change_reason=request.data.get('change_reason', 'OTHER'),
            reason_notes=request.data.get('reason_notes', ''),
            affected_sellers_count=ceiling.product.seller_id and 1 or 0
        )
        
        # Update ceiling
        ceiling.previous_ceiling = old_price
        ceiling.ceiling_price = new_price
        ceiling.effective_from = request.data.get('effective_from', timezone.now())
        ceiling.save()
        
        # Flag non-compliant products
        non_compliant = SellerProduct.objects.filter(
            name=ceiling.product.name,
            price__gt=new_price
        )
        for product in non_compliant:
            PriceNonCompliance.objects.get_or_create(
                seller=product.seller,
                product=product,
                defaults={
                    'listed_price': product.price,
                    'ceiling_price': new_price,
                    'overage_percentage': ((product.price - new_price) / new_price * 100),
                    'detected_by': admin_user,
                    'status': 'NEW'
                }
            )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Price Ceiling Updated',
            action_category='PRICE_UPDATE',
            affected_product=ceiling.product,
            description=f"Updated price ceiling for {ceiling.product.name}",
            old_value=str(old_price),
            new_value=str(new_price)
        )
        
        serializer = PriceCeilingSerializer(ceiling)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['get'], url_path='ceilings/(?P<ceiling_id>[^/.]+)/history')
    def ceiling_history(self, request, ceiling_id=None):
        """Get price history for a ceiling."""
        ceiling = get_object_or_404(PriceCeiling, pk=ceiling_id)
        history = PriceHistory.objects.filter(product=ceiling.product).order_by('-changed_at')
        serializer = PriceHistorySerializer(history, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], url_path='non-compliant')
    def non_compliant_listings(self, request):
        """
        List non-compliant price listings.
        
        Returns: List of sellers with prices exceeding ceiling
        """
        violations = PriceNonCompliance.objects.filter(
            status__in=['NEW', 'WARNED']
        ).select_related('seller', 'product').order_by('-detected_at')
        
        serializer = PriceNonComplianceSerializer(violations, many=True)
        return Response({
            'count': violations.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['post'], url_path='advisories')
    def create_advisory(self, request):
        """
        Create price advisory for marketplace.
        
        Request body:
        {
            "title": "Rice Price Update",
            "content": "Price ceiling updated to 500/kg",
            "advisory_type": "PRICE_UPDATE",
            "target_audience": "ALL",
            "effective_from": "2025-11-19T00:00:00Z"
        }
        
        Returns: Created advisory
        """
        admin_user = AdminUser.objects.get(user=request.user)
        
        advisory = PriceAdvisory.objects.create(
            title=request.data.get('title'),
            content=request.data.get('content'),
            advisory_type=request.data.get('advisory_type', 'PRICE_UPDATE'),
            target_audience=request.data.get('target_audience', 'ALL'),
            effective_from=request.data.get('effective_from', timezone.now()),
            effective_until=request.data.get('effective_until'),
            is_active=True,
            created_by=admin_user
        )
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Price Advisory Created',
            action_category='ADVISORY_CREATED',
            description=f"Created price advisory: {advisory.title}"
        )
        
        serializer = PriceAdvisorySerializer(advisory)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['get'], url_path='advisories')
    def list_advisories(self, request):
        """List all active price advisories."""
        advisories = PriceAdvisory.objects.filter(is_active=True).order_by('-effective_from')
        serializer = PriceAdvisorySerializer(advisories, many=True)
        return Response({
            'count': advisories.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['delete'], url_path='advisories/(?P<advisory_id>[^/.]+)')
    def delete_advisory(self, request, advisory_id=None):
        """Delete a price advisory."""
        admin_user = AdminUser.objects.get(user=request.user)
        advisory = get_object_or_404(PriceAdvisory, pk=advisory_id)
        
        advisory.is_active = False
        advisory.save()
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Price Advisory Deleted',
            action_category='OTHER',
            description=f"Deleted price advisory: {advisory.title}"
        )
        
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=False, methods=['post'], url_path='flag-violation')
    def flag_violation(self, request):
        """
        Flag a price violation manually.
        
        Request body:
        {
            "seller_id": 123,
            "product_id": 456,
            "listed_price": 600.00,
            "ceiling_price": 500.00
        }
        """
        admin_user = AdminUser.objects.get(user=request.user)
        seller_id = request.data.get('seller_id')
        product_id = request.data.get('product_id')
        listed_price = request.data.get('listed_price')
        ceiling_price = request.data.get('ceiling_price')
        
        seller = get_object_or_404(User, pk=seller_id)
        product = get_object_or_404(SellerProduct, pk=product_id)
        
        overage_percentage = ((listed_price - ceiling_price) / ceiling_price * 100)
        
        violation, created = PriceNonCompliance.objects.get_or_create(
            seller=seller,
            product=product,
            defaults={
                'listed_price': listed_price,
                'ceiling_price': ceiling_price,
                'overage_percentage': overage_percentage,
                'detected_by': admin_user,
                'status': 'NEW'
            }
        )
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Price Violation Flagged',
            action_category='PRICE_UPDATE',
            affected_seller=seller,
            affected_product=product,
            description=f"Flagged price violation for {product.name}"
        )
        
        serializer = PriceNonComplianceSerializer(violation)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


# ==================== OPAS PURCHASING VIEWSET ====================

class OPASPurchasingViewSet(viewsets.ModelViewSet):
    """
    ViewSet for admin OPAS bulk purchase management.
    
    Handles approval/rejection of seller OPAS submissions, inventory tracking,
    and FIFO validation.
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = OPASPurchaseOrderSerializer
    
    def get_queryset(self):
        """Get OPAS purchase orders with filtering"""
        queryset = OPASPurchaseOrder.objects.select_related(
            'sell_to_opas', 'seller', 'product', 'reviewed_by'
        ).order_by('-submitted_at')
        
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset
    
    @action(detail=False, methods=['get'], url_path='submissions')
    def list_submissions(self, request):
        """List seller OPAS submissions pending review."""
        submissions = self.get_queryset()
        serializer = self.get_serializer(submissions, many=True)
        return Response({
            'count': submissions.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['get'], url_path='submission')
    def get_submission(self, request, pk=None):
        """Get submission details."""
        submission = self.get_object()
        serializer = self.get_serializer(submission)
        return Response(serializer.data)
    
    @action(
        detail=True, methods=['post'],
        url_path='submission/approve'
    )
    def approve_submission(self, request, pk=None):
        """
        Approve OPAS submission and create purchase order.
        
        Request body:
        {
            "approved_quantity": 1000,
            "final_price": 450.00,
            "quality_grade": "GRADE_A",
            "delivery_terms": "Delivery in 3 days",
            "admin_notes": "Good quality produce"
        }
        """
        admin_user = AdminUser.objects.get(user=request.user)
        purchase_order = self.get_object()
        
        purchase_order.status = 'APPROVED'
        purchase_order.approved_quantity = request.data.get('approved_quantity')
        purchase_order.final_price = request.data.get('final_price')
        purchase_order.quality_grade = request.data.get('quality_grade')
        purchase_order.delivery_terms = request.data.get('delivery_terms')
        purchase_order.admin_notes = request.data.get('admin_notes')
        purchase_order.reviewed_by = admin_user
        purchase_order.reviewed_at = timezone.now()
        purchase_order.approved_at = timezone.now()
        purchase_order.save()
        
        # Create OPAS inventory entry
        OPASInventory.objects.create(
            product=purchase_order.product,
            purchase_order=purchase_order,
            quantity_received=purchase_order.approved_quantity,
            quantity_on_hand=purchase_order.approved_quantity,
            in_date=timezone.now(),
            expiry_date=request.data.get('expiry_date', timezone.now() + timezone.timedelta(days=30))
        )
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='OPAS Submission Approved',
            action_category='OPAS_REVIEW',
            affected_seller=purchase_order.seller,
            affected_product=purchase_order.product,
            description=f"Approved OPAS submission from {purchase_order.seller.full_name}",
            new_value=str(purchase_order.approved_quantity)
        )
        
        serializer = self.get_serializer(purchase_order)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(
        detail=True, methods=['post'],
        url_path='submission/reject'
    )
    def reject_submission(self, request, pk=None):
        """
        Reject OPAS submission.
        
        Request body:
        {
            "rejection_reason": "Quality not meeting standards"
        }
        """
        admin_user = AdminUser.objects.get(user=request.user)
        purchase_order = self.get_object()
        
        purchase_order.status = 'REJECTED'
        purchase_order.rejection_reason = request.data.get('rejection_reason')
        purchase_order.reviewed_by = admin_user
        purchase_order.reviewed_at = timezone.now()
        purchase_order.save()
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='OPAS Submission Rejected',
            action_category='OPAS_REVIEW',
            affected_seller=purchase_order.seller,
            affected_product=purchase_order.product,
            description=f"Rejected OPAS submission: {purchase_order.rejection_reason}"
        )
        
        serializer = self.get_serializer(purchase_order)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'], url_path='purchase-orders')
    def list_purchase_orders(self, request):
        """List all OPAS purchase orders."""
        orders = OPASPurchaseOrder.objects.filter(
            status='APPROVED'
        ).select_related('seller', 'product').order_by('-approved_at')
        serializer = self.get_serializer(orders, many=True)
        return Response({
            'count': orders.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'], url_path='purchase-history')
    def purchase_history(self, request):
        """Get OPAS purchase history."""
        history = OPASPurchaseHistory.objects.select_related(
            'seller', 'product'
        ).order_by('-purchased_at')
        from .admin_serializers import OPASPurchaseHistorySerializer
        serializer = OPASPurchaseHistorySerializer(history, many=True)
        return Response({
            'count': history.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'], url_path='inventory')
    def list_inventory(self, request):
        """List current OPAS inventory."""
        inventory = OPASInventory.objects.select_related(
            'product'
        ).order_by('expiry_date')
        from .admin_serializers import OPASInventorySerializer
        serializer = OPASInventorySerializer(inventory, many=True)
        return Response({
            'count': inventory.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'], url_path='inventory/low-stock')
    def low_stock_inventory(self, request):
        """Get low stock alerts."""
        low_stock = OPASInventory.objects.filter(
            is_low_stock=True
        ).select_related('product').order_by('quantity_on_hand')
        from .admin_serializers import OPASInventorySerializer
        serializer = OPASInventorySerializer(low_stock, many=True)
        return Response({
            'count': low_stock.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'], url_path='inventory/expiring')
    def expiring_inventory(self, request):
        """Get expiring inventory alerts."""
        from datetime import timedelta
        alert_date = timezone.now() + timedelta(days=7)
        expiring = OPASInventory.objects.filter(
            expiry_date__lte=alert_date,
            is_expiring=True
        ).select_related('product').order_by('expiry_date')
        from .admin_serializers import OPASInventorySerializer
        serializer = OPASInventorySerializer(expiring, many=True)
        return Response({
            'count': expiring.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['post'], url_path='inventory/adjust')
    def adjust_inventory(self, request):
        """
        Manually adjust OPAS inventory (FIFO).
        
        Request body:
        {
            "inventory_id": 123,
            "quantity_change": -50,
            "transaction_type": "OUT",
            "reason": "Spoilage"
        }
        """
        admin_user = AdminUser.objects.get(user=request.user)
        inventory_id = request.data.get('inventory_id')
        quantity_change = request.data.get('quantity_change')
        
        inventory = get_object_or_404(OPASInventory, pk=inventory_id)
        
        # Record transaction
        transaction = OPASInventoryTransaction.objects.create(
            inventory=inventory,
            processed_by=admin_user,
            transaction_type=request.data.get('transaction_type', 'ADJUSTMENT'),
            quantity=abs(quantity_change),
            reason=request.data.get('reason'),
            is_fifo_compliant=True
        )
        
        # Update inventory
        inventory.quantity_on_hand += quantity_change
        if quantity_change < 0:
            inventory.quantity_consumed += abs(quantity_change)
        inventory.save()
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Inventory Adjustment',
            action_category='INVENTORY_ADJUSTMENT',
            affected_product=inventory.product,
            description=f"Adjusted OPAS inventory: {quantity_change} units",
            new_value=str(inventory.quantity_on_hand)
        )
        
        from .admin_serializers import OPASInventoryTransactionSerializer
        serializer = OPASInventoryTransactionSerializer(transaction)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


# ==================== MARKETPLACE OVERSIGHT VIEWSET ====================

class MarketplaceOversightViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for marketplace monitoring and oversight.
    
    Handles listing monitoring, alert management, and compliance tracking.
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    queryset = SellerProduct.objects.all()
    
    @action(detail=False, methods=['get'], url_path='listings')
    def list_listings(self, request):
        """List all active marketplace listings."""
        listings = SellerProduct.objects.filter(
            status='ACTIVE'
        ).select_related('seller').order_by('-created_at')
        from .admin_serializers import ProductListingSerializer
        serializer = ProductListingSerializer(listings, many=True)
        return Response({
            'count': listings.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'], url_path='alerts')
    def marketplace_alerts(self, request):
        """Get marketplace alerts and flags."""
        alerts = MarketplaceAlert.objects.filter(
            status__in=['OPEN', 'ACKNOWLEDGED']
        ).select_related('affected_seller', 'affected_product').order_by('-created_at')
        serializer = MarketplaceAlertSerializer(alerts, many=True)
        return Response({
            'count': alerts.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'], url_path='listings/(?P<product_id>[^/.]+)/flag')
    def flag_listing(self, request, product_id=None):
        """
        Flag a marketplace listing.
        
        Request body:
        {
            "reason": "Price too low",
            "severity": "WARNING"
        }
        """
        admin_user = AdminUser.objects.get(user=request.user)
        product = get_object_or_404(SellerProduct, pk=product_id)
        
        alert = MarketplaceAlert.objects.create(
            title=f"Flagged Listing: {product.name}",
            description=request.data.get('reason'),
            alert_type='PRICE_VIOLATION',
            severity=request.data.get('severity', 'WARNING'),
            affected_seller=product.seller,
            affected_product=product,
            status='OPEN'
        )
        
        serializer = MarketplaceAlertSerializer(alert)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'], url_path='listings/(?P<product_id>[^/.]+)/remove')
    def remove_listing(self, request, product_id=None):
        """Remove a marketplace listing."""
        admin_user = AdminUser.objects.get(user=request.user)
        product = get_object_or_404(SellerProduct, pk=product_id)
        
        product.status = 'INACTIVE'
        product.save()
        
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='Listing Removed',
            action_category='OTHER',
            affected_seller=product.seller,
            affected_product=product,
            description=f"Removed listing: {product.name}"
        )
        
        return Response({'detail': 'Listing removed'}, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'], url_path='activity')
    def marketplace_activity(self, request):
        """Get marketplace activity statistics."""
        from django.db.models import Count, Q
        from datetime import timedelta
        
        today = timezone.now().date()
        month_ago = today - timedelta(days=30)
        
        stats = {
            'active_listings': SellerProduct.objects.filter(status='ACTIVE').count(),
            'sales_today': SellerOrder.objects.filter(
                created_at__date=today,
                status='DELIVERED'
            ).count(),
            'total_sales_month': SellerOrder.objects.filter(
                created_at__date__gte=month_ago,
                status='DELIVERED'
            ).aggregate(total=Sum('total_amount'))['total'] or 0,
            'new_sellers_month': User.objects.filter(
                role=UserRole.SELLER,
                created_at__date__gte=month_ago
            ).count(),
            'active_alerts': MarketplaceAlert.objects.filter(status='OPEN').count(),
        }
        
        return Response(stats)


# ==================== ANALYTICS & REPORTING VIEWSET ====================

class AnalyticsReportingViewSet(viewsets.ViewSet):
    """
    ViewSet for admin analytics and reporting.
    
    Provides dashboard statistics, trends, forecasts, and report generation.
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    
    @action(detail=False, methods=['get'], url_path='dashboard')
    def dashboard_stats(self, request):
        """
        Get comprehensive admin dashboard statistics.
        
        Returns aggregated metrics across all admin domains:
        - Seller metrics: total, pending, active, suspended, new
        - Market metrics: active listings, sales today/month
        - OPAS metrics: submissions, approvals, inventory, alerts
        - Price compliance: compliant/non-compliant listings
        - System alerts: price violations, seller issues, inventory alerts
        
        Query params:
        - include_details: Include detailed breakdowns (default: false)
        """
        from django.db.models import Sum, Count, Q, Avg, DecimalField
        from django.db.models.functions import Cast
        from datetime import timedelta
        
        today = timezone.now().date()
        month_ago = today - timedelta(days=30)
        
        # ==================== SELLER METRICS ====================
        total_sellers = User.objects.filter(role=UserRole.SELLER).count()
        pending_approvals = User.objects.filter(
            seller_status=SellerStatus.PENDING
        ).count()
        active_sellers = User.objects.filter(
            seller_status=SellerStatus.APPROVED
        ).count()
        suspended_sellers = User.objects.filter(
            seller_status=SellerStatus.SUSPENDED
        ).count()
        new_this_month = User.objects.filter(
            role=UserRole.SELLER,
            created_at__date__gte=month_ago
        ).count()
        
        seller_metrics = {
            'total_sellers': total_sellers,
            'pending_approvals': pending_approvals,
            'active_sellers': active_sellers,
            'suspended_sellers': suspended_sellers,
            'new_this_month': new_this_month,
            'approval_rate': round((active_sellers / total_sellers * 100), 2) if total_sellers > 0 else 0,
        }
        
        # ==================== MARKET METRICS ====================
        active_listings = SellerProduct.objects.filter(status='ACTIVE').count()
        total_sales_today = SellerOrder.objects.filter(
            created_at__date=today,
            status='DELIVERED'
        ).aggregate(total=Sum('total_amount'))['total'] or 0
        total_sales_month = SellerOrder.objects.filter(
            created_at__date__gte=month_ago,
            status='DELIVERED'
        ).aggregate(total=Sum('total_amount'))['total'] or 0
        
        # Calculate average price change
        avg_price_change = PriceHistory.objects.filter(
            changed_at__date__gte=month_ago
        ).aggregate(
            avg_change=Avg(
                Cast('new_price', DecimalField()) - Cast('old_price', DecimalField())
            )
        )['avg_change'] or 0
        
        market_metrics = {
            'active_listings': active_listings,
            'total_sales_today': float(total_sales_today),
            'total_sales_month': float(total_sales_month),
            'avg_price_change': float(round(avg_price_change, 2)) if avg_price_change else 0,
            'avg_transaction': float(total_sales_month / 30) if total_sales_month > 0 else 0,
        }
        
        # ==================== OPAS METRICS ====================
        pending_submissions = OPASPurchaseOrder.objects.filter(
            status='PENDING'
        ).count()
        approved_this_month = OPASPurchaseOrder.objects.filter(
            status='APPROVED',
            approved_at__date__gte=month_ago
        ).count()
        total_inventory = OPASInventory.objects.aggregate(
            total=Sum('quantity_on_hand')
        )['total'] or 0
        low_stock_count = OPASInventory.objects.filter(
            is_low_stock=True
        ).count()
        expiring_count = OPASInventory.objects.filter(
            is_expiring=True
        ).count()
        
        opas_metrics = {
            'pending_submissions': pending_submissions,
            'approved_this_month': approved_this_month,
            'total_inventory': float(total_inventory),
            'low_stock_count': low_stock_count,
            'expiring_count': expiring_count,
            'total_inventory_value': 0,  # Calculated from inventory prices
        }
        
        # ==================== PRICE COMPLIANCE ====================
        # Count compliant listings (price <= ceiling)
        non_compliant_count = PriceNonCompliance.objects.filter(
            status__in=['NEW', 'WARNED']
        ).count()
        compliant_listings = active_listings - non_compliant_count
        compliance_rate = round(
            (compliant_listings / active_listings * 100), 2
        ) if active_listings > 0 else 100
        
        price_compliance = {
            'compliant_listings': compliant_listings,
            'non_compliant': non_compliant_count,
            'compliance_rate': compliance_rate,
        }
        
        # ==================== SYSTEM ALERTS ====================
        price_violations = MarketplaceAlert.objects.filter(
            alert_type='PRICE_VIOLATION',
            status='OPEN'
        ).count()
        seller_issues = MarketplaceAlert.objects.filter(
            alert_type='SELLER_ISSUE',
            status='OPEN'
        ).count()
        inventory_alerts = MarketplaceAlert.objects.filter(
            alert_type='INVENTORY_ALERT',
            status='OPEN'
        ).count()
        
        alerts = {
            'price_violations': price_violations,
            'seller_issues': seller_issues,
            'inventory_alerts': inventory_alerts,
            'total_open_alerts': price_violations + seller_issues + inventory_alerts,
        }
        
        # ==================== HEALTH SCORE ====================
        # Calculate overall marketplace health (0-100)
        health_score = 100
        if non_compliant_count > 0:
            health_score -= min(10, non_compliant_count * 2)  # Max -10
        if pending_approvals > 0:
            health_score -= min(10, pending_approvals)  # Max -10
        if suspended_sellers > 0:
            health_score -= min(5, suspended_sellers * 2)  # Max -5
        if low_stock_count > 0:
            health_score -= min(5, low_stock_count)  # Max -5
        
        # Aggregate response
        stats = {
            'timestamp': timezone.now().isoformat(),
            'seller_metrics': seller_metrics,
            'market_metrics': market_metrics,
            'opas_metrics': opas_metrics,
            'price_compliance': price_compliance,
            'alerts': alerts,
            'marketplace_health_score': max(0, health_score),
        }
        
        return Response(stats)
    
    @action(detail=False, methods=['get'], url_path='price-trends')
    def price_trends(self, request):
        """Get price trend data."""
        from datetime import timedelta
        
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)
        
        history = PriceHistory.objects.filter(
            changed_at__date__gte=start_date
        ).values('changed_at__date').annotate(
            avg_price=Avg('new_price'),
            change_count=Count('id')
        ).order_by('changed_at__date')
        
        return Response(list(history))
    
    @action(detail=False, methods=['get'], url_path='demand-forecast')
    def demand_forecast(self, request):
        """Get demand forecast data."""
        from apps.users.models import SellerForecast
        
        forecasts = SellerForecast.objects.filter(
            forecast_date__gte=timezone.now()
        ).values('product__name').annotate(
            avg_forecast=Avg('predicted_quantity')
        ).order_by('-avg_forecast')[:10]
        
        return Response(list(forecasts))
    
    @action(detail=False, methods=['get'], url_path='sales-summary')
    def sales_summary_report(self, request):
        """Get sales summary report."""
        date_range = request.query_params.get('date_range', '30')
        days = int(date_range)
        start_date = timezone.now().date() - timedelta(days=days)
        
        summary = {
            'total_sales': SellerOrder.objects.filter(
                created_at__date__gte=start_date,
                status='DELIVERED'
            ).aggregate(total=Sum('total_amount'))['total'] or 0,
            'total_orders': SellerOrder.objects.filter(
                created_at__date__gte=start_date,
                status='DELIVERED'
            ).count(),
            'avg_order_value': SellerOrder.objects.filter(
                created_at__date__gte=start_date,
                status='DELIVERED'
            ).aggregate(avg=Avg('total_amount'))['avg'] or 0,
        }
        
        return Response(summary)
    
    @action(detail=False, methods=['get'], url_path='opas-purchases')
    def opas_purchases_report(self, request):
        """Get OPAS purchases report."""
        date_range = request.query_params.get('date_range', '30')
        days = int(date_range)
        start_date = timezone.now().date() - timedelta(days=days)
        
        summary = {
            'total_purchases': OPASPurchaseOrder.objects.filter(
                approved_at__date__gte=start_date,
                status='APPROVED'
            ).count(),
            'total_spent': OPASPurchaseHistory.objects.filter(
                purchased_at__date__gte=start_date
            ).aggregate(total=Sum('total_price'))['total'] or 0,
            'total_quantity': OPASPurchaseHistory.objects.filter(
                purchased_at__date__gte=start_date
            ).aggregate(total=Sum('quantity'))['total'] or 0,
        }
        
        return Response(summary)
    
    @action(detail=False, methods=['get'], url_path='seller-participation')
    def seller_participation_report(self, request):
        """Get seller participation report."""
        return Response({
            'total_sellers': User.objects.filter(role=UserRole.SELLER).count(),
            'active_sellers': User.objects.filter(
                seller_status=SellerStatus.APPROVED
            ).count(),
            'sellers_with_sales': SellerOrder.objects.values('seller').distinct().count(),
            'sellers_in_opas': OPASPurchaseOrder.objects.values('seller').distinct().count(),
        })
    
    @action(detail=False, methods=['get'], url_path='generate-pdf')
    def generate_report_pdf(self, request):
        """Generate downloadable PDF report."""
        report_type = request.query_params.get('type', 'dashboard')
        return Response({
            'message': f'PDF generation for {report_type} report initiated',
            'status': 'pending'
        })


# ==================== ADMIN NOTIFICATIONS VIEWSET ====================

class AdminNotificationsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for admin notifications and announcements.
    
    Handles system notifications, alerts, and marketplace announcements.
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = SystemNotificationSerializer
    
    def get_queryset(self):
        """Get notifications for current admin user"""
        try:
            admin_user = AdminUser.objects.get(user=self.request.user)
            return SystemNotification.objects.filter(
                recipient=admin_user
            ).order_by('-created_at')
        except AdminUser.DoesNotExist:
            return SystemNotification.objects.none()
    
    @action(detail=False, methods=['get'], url_path='notifications')
    def list_notifications(self, request):
        """List admin notifications."""
        notifications = self.get_queryset()
        serializer = self.get_serializer(notifications, many=True)
        return Response({
            'count': notifications.count(),
            'unread_count': notifications.filter(is_read=False).count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'], url_path='acknowledge')
    def acknowledge_notification(self, request, pk=None):
        """Mark notification as read."""
        notification = self.get_object()
        notification.is_read = True
        notification.read_at = timezone.now()
        notification.save()
        
        serializer = self.get_serializer(notification)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'], url_path='announcements')
    def create_announcement(self, request):
        """
        Create marketplace announcement.
        
        Request body:
        {
            "title": "Maintenance Alert",
            "message": "System maintenance on Nov 20",
            "announcement_type": "ALERT",
            "target_audience": "ALL"
        }
        """
        from apps.users.models import Announcement
        
        announcement = Announcement.objects.create(
            title=request.data.get('title'),
            message=request.data.get('message'),
            announcement_type=request.data.get('announcement_type', 'ALERT'),
            target_audience=request.data.get('target_audience', 'ALL'),
            is_active=True,
            created_by=request.user
        )
        
        return Response({
            'id': announcement.id,
            'title': announcement.title,
            'message': announcement.message,
            'created_at': announcement.created_at
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['get'], url_path='announcements')
    def list_announcements(self, request):
        """List marketplace announcements."""
        from apps.users.models import Announcement
        
        announcements = Announcement.objects.filter(
            is_active=True
        ).order_by('-created_at')
        
        return Response({
            'count': announcements.count(),
            'results': [
                {
                    'id': a.id,
                    'title': a.title,
                    'message': a.message,
                    'announcement_type': a.announcement_type,
                    'created_at': a.created_at
                }
                for a in announcements
            ]
        })
    
    @action(detail=True, methods=['put'], url_path='announcements/(?P<announcement_id>[^/.]+)')
    def update_announcement(self, request, announcement_id=None):
        """Update announcement."""
        from apps.users.models import Announcement
        
        announcement = get_object_or_404(Announcement, pk=announcement_id)
        announcement.title = request.data.get('title', announcement.title)
        announcement.message = request.data.get('message', announcement.message)
        announcement.save()
        
        return Response({
            'id': announcement.id,
            'title': announcement.title,
            'message': announcement.message,
            'updated_at': announcement.updated_at
        })
    
    @action(detail=True, methods=['delete'], url_path='announcements/(?P<announcement_id>[^/.]+)')
    def delete_announcement(self, request, announcement_id=None):
        """Delete announcement."""
        from apps.users.models import Announcement
        
        announcement = get_object_or_404(Announcement, pk=announcement_id)
        announcement.is_active = False
        announcement.save()
        
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=False, methods=['get'], url_path='announcements/broadcast-history')
    def broadcast_history(self, request):
        """Get announcement broadcast history."""
        from apps.users.models import Announcement
        
        history = Announcement.objects.filter(
            is_active=False
        ).order_by('-created_at')
        
        return Response({
            'count': history.count(),
            'results': [
                {
                    'id': a.id,
                    'title': a.title,
                    'created_at': a.created_at,
                    'updated_at': a.updated_at
                }
                for a in history
            ]
        })


__all__ = [
    'SellerManagementViewSet',
    'PriceManagementViewSet',
    'OPASPurchasingViewSet',
    'MarketplaceOversightViewSet',
    'AnalyticsReportingViewSet',
    'AdminNotificationsViewSet',
]
