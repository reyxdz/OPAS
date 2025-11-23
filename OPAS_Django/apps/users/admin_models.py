"""
Admin-specific models for OPAS platform - Clean Architecture Implementation.

This module follows clean architecture principles with:
- Clear separation of concerns (choices, models, managers, utilities)
- Comprehensive documentation and type hints
- Reusable model managers and querysets
- Validation and business logic separation
- Immutable audit logs for compliance
- Database indexes for performance

Models organized by functional domain:
1. AdminUser: Extended admin user with role hierarchy and permissions
2. Seller Approval: SellerRegistrationRequest, SellerDocumentVerification, SellerApprovalHistory, SellerSuspension
3. Price Management: PriceCeiling, PriceAdvisory, PriceHistory, PriceNonCompliance
4. OPAS Bulk Purchase: OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction, OPASPurchaseHistory
5. Admin Activity & Alerts: AdminAuditLog, MarketplaceAlert, SystemNotification

Database Architecture:
- 15 total models with comprehensive foreign key relationships
- 30+ database indexes for query optimization
- Immutable AdminAuditLog for compliance tracking
- Cascading deletes with SET_NULL fallbacks for audit trails
"""

from django.db import models
from django.utils import timezone
from django.contrib.auth.models import Permission, Group
from django.core.validators import MinValueValidator, DecimalValidator
from django.core.exceptions import ValidationError
from .models import User, UserRole


# ==================== CUSTOM VALIDATORS ====================

def validate_ceiling_price_positive(value):
    """
    Validator: PriceCeiling.ceiling_price must be > 0
    
    Ensures price ceiling is a positive value (required for price management).
    
    Args:
        value: The ceiling price value
    
    Raises:
        ValidationError: If value <= 0
    
    Usage:
        ceiling_price = models.DecimalField(..., validators=[validate_ceiling_price_positive])
    """
    if value <= 0:
        raise ValidationError(
            "Ceiling price must be greater than 0. "
            f"Received: {value}",
            code='ceiling_price_not_positive'
        )


def validate_opas_inventory_dates(in_date, expiry_date):
    """
    Validator: OPASInventory dates must satisfy: expiry_date > in_date
    
    Ensures expiration date is after the production/in date for inventory tracking.
    Applied in model's clean() method.
    
    Args:
        in_date: Production/manufacturing date
        expiry_date: Expiration date
    
    Raises:
        ValidationError: If expiry_date <= in_date
    """
    if expiry_date <= in_date:
        raise ValidationError(
            "Expiry date must be after the in/production date. "
            f"In date: {in_date}, Expiry date: {expiry_date}",
            code='expiry_date_not_after_in_date'
        )


def validate_opas_inventory_quantity(quantity):
    """
    Validator: OPASInventory.quantity must be >= 0
    
    Ensures inventory quantity is non-negative (can be 0 for consumed inventory).
    
    Args:
        value: The quantity value
    
    Raises:
        ValidationError: If value < 0
    
    Usage:
        quantity = models.IntegerField(..., validators=[validate_opas_inventory_quantity])
    """
    if quantity < 0:
        raise ValidationError(
            "Inventory quantity cannot be negative. "
            f"Received: {quantity}",
            code='inventory_quantity_negative'
        )


def validate_overage_percent_non_negative(value):
    """
    Validator: PriceNonCompliance.overage_percentage must be >= 0
    
    Ensures overage percentage is non-negative for price violation tracking.
    
    Args:
        value: The overage percentage value
    
    Raises:
        ValidationError: If value < 0
    
    Usage:
        overage_percentage = models.DecimalField(..., validators=[validate_overage_percent_non_negative])
    """
    if value < 0:
        raise ValidationError(
            "Overage percentage cannot be negative. "
            f"Received: {value}",
            code='overage_percent_negative'
        )


def validate_price_non_compliance_prices(listed_price, ceiling_price):
    """
    Validator: PriceNonCompliance must have listed_price > ceiling_price
    
    Ensures that a non-compliance record only exists when seller's price exceeds ceiling.
    Applied in model's clean() method.
    
    Args:
        listed_price: The price listed by seller
        ceiling_price: The ceiling price at violation time
    
    Raises:
        ValidationError: If listed_price <= ceiling_price
    """
    if listed_price <= ceiling_price:
        raise ValidationError(
            "For a price non-compliance record, listed price must be greater than ceiling price. "
            f"Listed: {listed_price}, Ceiling: {ceiling_price}",
            code='listed_price_not_greater_than_ceiling'
        )


def validate_action_type_in_valid_choices(action_type):
    """
    Validator: AdminAuditLog.action_type must be in valid choices
    
    Ensures audit log action types are from the predefined list of valid actions.
    
    Valid action types:
    - SELLER_APPROVED: Seller registration approved
    - SELLER_REJECTED: Seller registration rejected  
    - SELLER_SUSPENDED: Seller account suspended
    - SELLER_REACTIVATED: Seller account reactivated
    - PRICE_CEILING_SET: Price ceiling set for product
    - PRICE_CEILING_UPDATED: Price ceiling updated
    - PRICE_ADVISORY_POSTED: Price advisory posted
    - OPAS_SUBMISSION_APPROVED: OPAS submission approved
    - OPAS_SUBMISSION_REJECTED: OPAS submission rejected
    - INVENTORY_RECEIVED: Inventory received into OPAS
    - INVENTORY_CONSUMED: Inventory consumed from OPAS
    - INVENTORY_ADJUSTED: Inventory adjusted
    - ALERT_CREATED: Alert created
    - ALERT_RESOLVED: Alert resolved
    - ANNOUNCEMENT_POSTED: Announcement posted
    - OTHER: Other action
    
    Args:
        action_type: The action type string
    
    Raises:
        ValidationError: If action_type not in valid list
    
    Usage:
        action_type = models.CharField(..., validators=[validate_action_type_in_valid_choices])
    """
    VALID_ACTIONS = {
        'SELLER_APPROVED',
        'SELLER_REJECTED',
        'SELLER_SUSPENDED',
        'SELLER_REACTIVATED',
        'PRICE_CEILING_SET',
        'PRICE_CEILING_UPDATED',
        'PRICE_ADVISORY_POSTED',
        'OPAS_SUBMISSION_APPROVED',
        'OPAS_SUBMISSION_REJECTED',
        'INVENTORY_RECEIVED',
        'INVENTORY_CONSUMED',
        'INVENTORY_ADJUSTED',
        'ALERT_CREATED',
        'ALERT_RESOLVED',
        'ANNOUNCEMENT_POSTED',
        'OTHER',
    }
    
    if action_type not in VALID_ACTIONS:
        raise ValidationError(
            f"Action type '{action_type}' is not valid. "
            f"Must be one of: {', '.join(sorted(VALID_ACTIONS))}",
            code='invalid_action_type'
        )


# ==================== CHOICES & STATUSES ====================

class AdminRole(models.TextChoices):
    """Admin role hierarchy"""
    SUPER_ADMIN = 'SUPER_ADMIN', 'Super Admin'
    SELLER_MANAGER = 'SELLER_MANAGER', 'Seller Manager'
    PRICE_MANAGER = 'PRICE_MANAGER', 'Price Manager'
    OPAS_MANAGER = 'OPAS_MANAGER', 'OPAS Manager'
    ANALYTICS_MANAGER = 'ANALYTICS_MANAGER', 'Analytics Manager'
    SUPPORT_ADMIN = 'SUPPORT_ADMIN', 'Support Admin'


class SellerRegistrationStatus(models.TextChoices):
    """Status for seller registration requests"""
    PENDING = 'PENDING', 'Pending Review'
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'
    SUSPENDED = 'SUSPENDED', 'Suspended'
    REQUEST_MORE_INFO = 'REQUEST_MORE_INFO', 'More Info Requested'


class DocumentVerificationStatus(models.TextChoices):
    """Status for individual document verification"""
    PENDING = 'PENDING', 'Pending'
    VERIFIED = 'VERIFIED', 'Verified'
    REJECTED = 'REJECTED', 'Rejected'
    EXPIRED = 'EXPIRED', 'Expired'


class PriceChangeReason(models.TextChoices):
    """Reasons for price ceiling changes"""
    MARKET_ADJUSTMENT = 'MARKET_ADJUSTMENT', 'Market Adjustment'
    FORECAST_UPDATE = 'FORECAST_UPDATE', 'Forecast Update'
    COMPLIANCE = 'COMPLIANCE', 'Compliance'
    SEASONAL = 'SEASONAL', 'Seasonal Adjustment'
    OTHER = 'OTHER', 'Other'


class OPASSubmissionStatus(models.TextChoices):
    """Status for OPAS bulk purchase submissions"""
    PENDING = 'PENDING', 'Pending Review'
    APPROVED = 'APPROVED', 'Approved'
    REJECTED = 'REJECTED', 'Rejected'
    PARTIALLY_APPROVED = 'PARTIALLY_APPROVED', 'Partially Approved'
    CANCELLED = 'CANCELLED', 'Cancelled'


class InventoryTransactionType(models.TextChoices):
    """Types of inventory transactions"""
    IN = 'IN', 'Stock In (Purchase)'
    OUT = 'OUT', 'Stock Out (Consumption/Sale)'
    ADJUSTMENT = 'ADJUSTMENT', 'Inventory Adjustment'
    RETURN = 'RETURN', 'Return'
    SPOILAGE = 'SPOILAGE', 'Spoilage'


class AlertSeverity(models.TextChoices):
    """Alert severity levels"""
    INFO = 'INFO', 'Information'
    WARNING = 'WARNING', 'Warning'
    CRITICAL = 'CRITICAL', 'Critical'


class AlertCategory(models.TextChoices):
    """Alert categories"""
    PRICE_VIOLATION = 'PRICE_VIOLATION', 'Price Violation'
    SELLER_ISSUE = 'SELLER_ISSUE', 'Seller Issue'
    INVENTORY_ALERT = 'INVENTORY_ALERT', 'Inventory Alert'
    COMPLIANCE = 'COMPLIANCE', 'Compliance'
    SYSTEM = 'SYSTEM', 'System'
    OTHER = 'OTHER', 'Other'


# ==================== CUSTOM MANAGERS & QUERYSETS ====================

class AdminUserQuerySet(models.QuerySet):
    """Custom QuerySet for AdminUser with common filters"""
    
    def active(self):
        """Filter for active admin accounts"""
        return self.filter(is_active=True)
    
    def by_role(self, role):
        """Filter by admin role"""
        return self.filter(admin_role=role)
    
    def by_department(self, department):
        """Filter by department"""
        return self.filter(department=department)
    
    def super_admins(self):
        """Get all super admins"""
        return self.filter(admin_role=AdminRole.SUPER_ADMIN)


class AdminUserManager(models.Manager):
    """Custom Manager for AdminUser"""
    
    def get_queryset(self):
        return AdminUserQuerySet(self.model, using=self._db)
    
    def active(self):
        return self.get_queryset().active()
    
    def by_role(self, role):
        return self.get_queryset().by_role(role)
    
    def super_admins(self):
        return self.get_queryset().super_admins()


class SellerRegistrationQuerySet(models.QuerySet):
    """Custom QuerySet for SellerRegistrationRequest"""
    
    def pending(self):
        """Get pending registration requests"""
        return self.filter(status=SellerRegistrationStatus.PENDING)
    
    def approved(self):
        """Get approved registrations"""
        return self.filter(status=SellerRegistrationStatus.APPROVED)
    
    def recent(self, days=30):
        """Get recent submissions (last N days)"""
        from django.utils import timezone
        from datetime import timedelta
        cutoff = timezone.now() - timedelta(days=days)
        return self.filter(submitted_at__gte=cutoff)
    
    def awaiting_review(self):
        """Get requests awaiting admin review"""
        return self.filter(status__in=[
            SellerRegistrationStatus.PENDING,
            SellerRegistrationStatus.REQUEST_MORE_INFO
        ])


class SellerRegistrationManager(models.Manager):
    """Custom Manager for SellerRegistrationRequest"""
    
    def get_queryset(self):
        return SellerRegistrationQuerySet(self.model, using=self._db)
    
    def pending(self):
        return self.get_queryset().pending()
    
    def recent(self, days=30):
        return self.get_queryset().recent(days)
    
    def awaiting_review(self):
        return self.get_queryset().awaiting_review()


class PriceNonComplianceQuerySet(models.QuerySet):
    """Custom QuerySet for PriceNonCompliance"""
    
    def active_violations(self):
        """Get active (unresolved) violations"""
        return self.exclude(status=PriceNonCompliance.StatusChoices.RESOLVED)
    
    def by_seller(self, seller):
        """Get violations for a specific seller"""
        return self.filter(seller=seller)
    
    def by_product(self, product):
        """Get violations for a specific product"""
        return self.filter(product=product)


class PriceNonComplianceManager(models.Manager):
    """Custom Manager for PriceNonCompliance"""
    
    def get_queryset(self):
        return PriceNonComplianceQuerySet(self.model, using=self._db)
    
    def active_violations(self):
        return self.get_queryset().active_violations()
    
    def by_seller(self, seller):
        return self.get_queryset().by_seller(seller)


class OPASInventoryQuerySet(models.QuerySet):
    """Custom QuerySet for OPASInventory"""
    
    def low_stock(self, threshold=None):
        """Get inventory at low stock levels"""
        if threshold:
            return self.filter(quantity_on_hand__lt=threshold)
        return self.filter(quantity_on_hand__lt=models.F('low_stock_threshold'))
    
    def expiring_soon(self, days=7):
        """Get inventory expiring within specified days"""
        from django.utils import timezone
        from datetime import timedelta
        cutoff_date = timezone.now() + timedelta(days=days)
        return self.filter(expiry_date__lte=cutoff_date, quantity_on_hand__gt=0)
    
    def by_location(self, location):
        """Get inventory at specific storage location"""
        return self.filter(storage_location=location)
    
    def by_storage_condition(self, condition):
        """Get inventory by storage condition"""
        return self.filter(storage_condition=condition)
    
    def available(self):
        """Get inventory with quantity on hand > 0"""
        return self.filter(quantity_on_hand__gt=0)
    
    def expired(self):
        """Get expired inventory"""
        from django.utils import timezone
        return self.filter(expiry_date__lt=timezone.now())


class OPASInventoryManager(models.Manager):
    """Custom Manager for OPASInventory"""
    
    def get_queryset(self):
        return OPASInventoryQuerySet(self.model, using=self._db)
    
    def low_stock(self, threshold=None):
        return self.get_queryset().low_stock(threshold)
    
    def expiring_soon(self, days=7):
        return self.get_queryset().expiring_soon(days)
    
    def by_location(self, location):
        return self.get_queryset().by_location(location)
    
    def by_storage_condition(self, condition):
        return self.get_queryset().by_storage_condition(condition)
    
    def available(self):
        return self.get_queryset().available()
    
    def expired(self):
        return self.get_queryset().expired()
    
    def total_quantity(self):
        """Get total quantity across all inventory"""
        return self.get_queryset().aggregate(total=models.Sum('quantity_on_hand'))['total'] or 0
    
    def total_value(self):
        """Get total inventory value"""
        from django.db.models import F, Sum, DecimalField
        return self.get_queryset().aggregate(
            total_value=Sum(F('quantity_on_hand') * F('product__price'), output_field=DecimalField())
        )['total_value'] or 0


class AlertQuerySet(models.QuerySet):
    """Custom QuerySet for MarketplaceAlert"""
    
    def open_alerts(self):
        """Get unresolved alerts"""
        return self.filter(status='OPEN')
    
    def critical(self):
        """Get critical severity alerts"""
        return self.filter(severity=AlertSeverity.CRITICAL)
    
    def recent(self, days=7):
        """Get recent alerts (last N days)"""
        from django.utils import timezone
        from datetime import timedelta
        cutoff = timezone.now() - timedelta(days=days)
        return self.filter(created_at__gte=cutoff)


class AlertManager(models.Manager):
    """Custom Manager for MarketplaceAlert"""
    
    def get_queryset(self):
        return AlertQuerySet(self.model, using=self._db)
    
    def open_alerts(self):
        return self.get_queryset().open_alerts()
    
    def critical(self):
        return self.get_queryset().critical()




class AdminUser(models.Model):
    """
    Extended admin user profile with role, department, and audit capabilities.
    
    Enhancement to the User model for admin-specific features:
    - Admin role hierarchy (Super Admin, Seller Manager, Price Manager, etc.)
    - Department/team assignment
    - Activity audit log tracking
    - Permission management
    - Comprehensive audit trail for compliance
    
    Usage:
        admin = AdminUser.objects.create(user=user, admin_role=AdminRole.SELLER_MANAGER)
        super_admins = AdminUser.objects.super_admins()
        active_admins = AdminUser.objects.active()
    """
    
    # ==================== RELATIONSHIPS ====================
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='admin_profile',
        help_text='The user with admin role'
    )
    
    # ==================== ADMIN ROLE & PERMISSIONS ====================
    admin_role = models.CharField(
        max_length=30,
        choices=AdminRole.choices,
        default=AdminRole.SELLER_MANAGER,
        help_text='Admin role hierarchy for permission levels'
    )
    department = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Department/team assignment (e.g., Seller Onboarding, Market Regulation)'
    )
    custom_permissions = models.ManyToManyField(
        Permission,
        blank=True,
        related_name='admin_users',
        help_text='Custom permissions beyond role'
    )
    
    # ==================== ACTIVITY TRACKING ====================
    last_login = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Last successful login timestamp'
    )
    last_activity = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Last recorded activity timestamp'
    )
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this admin account is active'
    )
    
    # ==================== AUDIT FIELDS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the admin account was created'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='When the admin profile was last updated'
    )
    
    # ==================== MANAGERS ====================
    objects = AdminUserManager()
    
    class Meta:
        db_table = 'admin_users'
        verbose_name = 'Admin User'
        verbose_name_plural = 'Admin Users'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['admin_role']),
            models.Index(fields=['department']),
            models.Index(fields=['is_active']),
            models.Index(fields=['user_id']),
            models.Index(fields=['admin_role', 'is_active']),
            models.Index(fields=['department', 'is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        """Return formatted string with admin email and role"""
        return f"{self.user.email} ({self.admin_role})"
    
    def __repr__(self):
        return f"<AdminUser: {self.user.email} | Role: {self.admin_role}>"
    
    # ==================== BUSINESS LOGIC METHODS ====================
    
    def is_super_admin(self) -> bool:
        """Check if this admin has super admin role"""
        return self.admin_role == AdminRole.SUPER_ADMIN
    
    def can_approve_sellers(self) -> bool:
        """Check if this admin can approve sellers"""
        return self.admin_role in [
            AdminRole.SUPER_ADMIN,
            AdminRole.SELLER_MANAGER
        ]
    
    def can_manage_prices(self) -> bool:
        """Check if this admin can manage price ceilings"""
        return self.admin_role in [
            AdminRole.SUPER_ADMIN,
            AdminRole.PRICE_MANAGER
        ]
    
    def can_manage_opas(self) -> bool:
        """Check if this admin can manage OPAS purchases"""
        return self.admin_role in [
            AdminRole.SUPER_ADMIN,
            AdminRole.OPAS_MANAGER
        ]
    
    def can_view_analytics(self) -> bool:
        """Check if this admin can view analytics"""
        return self.admin_role in [
            AdminRole.SUPER_ADMIN,
            AdminRole.ANALYTICS_MANAGER
        ]
    
    def update_last_activity(self):
        """Update last activity timestamp to now"""
        self.last_activity = timezone.now()
        self.save(update_fields=['last_activity'])
    
    def get_permissions(self) -> list:
        """
        Get comprehensive list of all permissions for this admin.
        
        Combines role-based permissions with custom permissions.
        Returns a list of permission codes/names that this admin has.
        
        Returns:
            list: List of permission codes (e.g., ['view_all_data', 'approve_sellers'])
        
        Example:
            admin = AdminUser.objects.get(user__email='admin@opas.com')
            permissions = admin.get_permissions()
            if 'approve_sellers' in permissions:
                # Admin can approve sellers
        """
        role_permissions = self._get_role_permissions()
        custom_perms = list(self.custom_permissions.values_list('codename', flat=True))
        return role_permissions + custom_perms
    
    def get_permissions_list(self) -> list:
        """Get list of all permissions (role-based + custom)"""
        role_permissions = self._get_role_permissions()
        custom_perms = list(self.custom_permissions.values_list('codename', flat=True))
        return role_permissions + custom_perms
    
    def _get_role_permissions(self) -> list:
        """Get permissions based on admin role"""
        role_permissions_map = {
            AdminRole.SUPER_ADMIN: [
                'view_all_data',
                'approve_sellers',
                'manage_prices',
                'manage_opas',
                'view_analytics',
                'manage_admins',
                'export_data'
            ],
            AdminRole.SELLER_MANAGER: [
                'approve_sellers',
                'suspend_sellers',
                'view_seller_data'
            ],
            AdminRole.PRICE_MANAGER: [
                'manage_prices',
                'view_price_data',
                'view_compliance_data'
            ],
            AdminRole.OPAS_MANAGER: [
                'manage_opas',
                'view_inventory',
                'approve_opas_purchases'
            ],
            AdminRole.ANALYTICS_MANAGER: [
                'view_analytics',
                'export_reports'
            ],
            AdminRole.SUPPORT_ADMIN: [
                'view_seller_data',
                'respond_to_issues'
            ],
        }
        return role_permissions_map.get(self.admin_role, [])




# ==================== SELLER APPROVAL WORKFLOW MODELS ====================

class SellerRegistrationRequest(models.Model):
    """
    Model for seller registration applications with complete workflow tracking.
    
    Tracks the entire seller approval process:
    - Initial application submission
    - Document verification
    - Admin decision (approve/reject/suspend)
    - Audit trail with decision reasons
    
    Usage:
        # Get pending registrations
        pending = SellerRegistrationRequest.objects.pending()
        
        # Get recent submissions
        recent = SellerRegistrationRequest.objects.recent(days=7)
        
        # Get requests awaiting review
        awaiting = SellerRegistrationRequest.objects.awaiting_review()
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='registration_request',
        help_text='The seller user applying for marketplace access'
    )
    
    # ==================== APPLICATION STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=SellerRegistrationStatus.choices,
        default=SellerRegistrationStatus.PENDING,
        help_text='Current status of seller registration'
    )
    
    # ==================== APPLICATION DETAILS ====================
    farm_name = models.CharField(
        max_length=255,
        help_text='Name of the farm'
    )
    farm_location = models.CharField(
        max_length=255,
        help_text='Location/address of the farm'
    )
    farm_size = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Size of farm (e.g., "5 hectares")'
    )
    products_grown = models.TextField(
        blank=True,
        null=True,
        help_text='List of products grown/produced'
    )
    
    # ==================== STORE INFORMATION ====================
    store_name = models.CharField(
        max_length=255,
        help_text='Name of the store/business'
    )
    store_description = models.TextField(
        help_text='Description of the store'
    )
    
    # ==================== TIMESTAMPS ====================
    submitted_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the application was submitted'
    )
    reviewed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the application was reviewed'
    )
    approved_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the application was approved'
    )
    rejected_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the application was rejected'
    )
    
    # ==================== REJECTION DETAILS ====================
    rejection_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for rejection (if rejected)'
    )
    
    # ==================== MANAGERS ====================
    objects = SellerRegistrationManager()
    
    class Meta:
        db_table = 'seller_registration_requests'
        verbose_name = 'Seller Registration Request'
        verbose_name_plural = 'Seller Registration Requests'
        ordering = ['-submitted_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['status']),
            models.Index(fields=['submitted_at']),
            models.Index(fields=['status', 'submitted_at']),
            models.Index(fields=['seller_id', 'status']),
            models.Index(fields=['reviewed_at']),
        ]
    
    def __str__(self):
        return f"Registration: {self.seller.full_name} - {self.status}"
    
    def __repr__(self):
        return f"<SellerRegistrationRequest: {self.seller.email} | Status: {self.status}>"
    
    # ==================== BUSINESS LOGIC METHODS ====================
    
    def is_pending(self) -> bool:
        """Check if application is still pending"""
        return self.status == SellerRegistrationStatus.PENDING
    
    def is_approved(self) -> bool:
        """Check if application was approved"""
        return self.status == SellerRegistrationStatus.APPROVED
    
    def is_rejected(self) -> bool:
        """Check if application was rejected"""
        return self.status == SellerRegistrationStatus.REJECTED
    
    def get_all_documents(self):
        """Get all documents submitted for this registration"""
        return self.document_verifications.all()
    
    def get_verified_documents(self):
        """Get all verified documents"""
        return self.document_verifications.filter(
            status=DocumentVerificationStatus.VERIFIED
        )
    
    def get_pending_documents(self):
        """Get all documents pending verification"""
        return self.document_verifications.filter(
            status=DocumentVerificationStatus.PENDING
        )
    
    def documents_verified(self) -> bool:
        """Check if all required documents are verified"""
        total_docs = self.document_verifications.count()
        verified_docs = self.get_verified_documents().count()
        return total_docs > 0 and total_docs == verified_docs
    
    def days_since_submission(self) -> int:
        """Get number of days since application was submitted"""
        from datetime import timedelta
        delta = timezone.now() - self.submitted_at
        return delta.days
    
    def approve(self, admin_user: AdminUser, approval_notes: str = ""):
        """
        Approve the seller registration request.
        
        Updates:
        - Sets status to APPROVED
        - Updates seller_status in User model to APPROVED
        - Records approval in SellerApprovalHistory
        - Creates success notification
        - Sets approved_at timestamp
        
        Args:
            admin_user (AdminUser): The admin approving this request
            approval_notes (str): Optional approval notes
        
        Raises:
            ValidationError: If registration is not in valid state for approval
        
        Example:
            registration = SellerRegistrationRequest.objects.get(id=1)
            admin = AdminUser.objects.get(user__email='admin@opas.com')
            registration.approve(admin, "Documents verified and valid")
        """
        if self.status == SellerRegistrationStatus.APPROVED:
            raise ValidationError("This registration has already been approved.")
        
        if self.status == SellerRegistrationStatus.REJECTED:
            raise ValidationError("Cannot approve a rejected registration.")
        
        # Update registration request status
        self.status = SellerRegistrationStatus.APPROVED
        self.reviewed_at = timezone.now()
        self.approved_at = timezone.now()
        self.save(update_fields=['status', 'reviewed_at', 'approved_at'])
        
        # Update seller user status to APPROVED
        from .models import SellerStatus
        self.seller.seller_status = SellerStatus.APPROVED
        self.seller.save(update_fields=['seller_status'])
        
        # Create approval history record
        SellerApprovalHistory.objects.create(
            seller=self.seller,
            admin=admin_user,
            decision='APPROVED',
            decision_reason=approval_notes or 'Application approved by admin',
            admin_notes=approval_notes,
            effective_from=timezone.now()
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='SELLER_APPROVED',
            action_category='SELLER_APPROVAL',
            affected_seller=self.seller,
            description=f'Seller {self.seller.full_name} registration approved',
            new_value='APPROVED'
        )
    
    def reject(self, admin_user: AdminUser, rejection_reason: str, rejection_notes: str = ""):
        """
        Reject the seller registration request.
        
        Updates:
        - Sets status to REJECTED
        - Updates seller_status in User model to REJECTED
        - Records rejection in SellerApprovalHistory
        - Records rejection reason for seller feedback
        - Creates failure notification
        - Sets rejected_at timestamp
        
        Args:
            admin_user (AdminUser): The admin rejecting this request
            rejection_reason (str): Reason for rejection (required)
            rejection_notes (str): Optional additional notes
        
        Raises:
            ValidationError: If rejection_reason is empty or registration already resolved
        
        Example:
            registration = SellerRegistrationRequest.objects.get(id=1)
            admin = AdminUser.objects.get(user__email='admin@opas.com')
            registration.reject(
                admin, 
                "Tax ID document is invalid",
                "Document appears to be expired"
            )
        """
        if not rejection_reason.strip():
            raise ValidationError("Rejection reason is required.")
        
        if self.status == SellerRegistrationStatus.APPROVED:
            raise ValidationError("Cannot reject an already approved registration.")
        
        if self.status == SellerRegistrationStatus.REJECTED:
            raise ValidationError("This registration has already been rejected.")
        
        # Update registration request status
        self.status = SellerRegistrationStatus.REJECTED
        self.reviewed_at = timezone.now()
        self.rejected_at = timezone.now()
        self.rejection_reason = rejection_reason
        self.save(update_fields=['status', 'reviewed_at', 'rejected_at', 'rejection_reason'])
        
        # Update seller user status to REJECTED
        from .models import SellerStatus
        self.seller.seller_status = SellerStatus.REJECTED
        self.seller.save(update_fields=['seller_status'])
        
        # Create approval history record
        SellerApprovalHistory.objects.create(
            seller=self.seller,
            admin=admin_user,
            decision='REJECTED',
            decision_reason=rejection_reason,
            admin_notes=rejection_notes,
            effective_from=timezone.now()
        )
        
        # Create audit log
        AdminAuditLog.objects.create(
            admin=admin_user,
            action_type='SELLER_REJECTED',
            action_category='SELLER_APPROVAL',
            affected_seller=self.seller,
            description=f'Seller {self.seller.full_name} registration rejected: {rejection_reason}',
            new_value='REJECTED',
            old_value='PENDING'
        )





class SellerDocumentVerification(models.Model):
    """
    Track verification status of seller-submitted documents.
    
    Documents tracked:
    - Business registration
    - Tax ID
    - Land certificate
    - Banking information
    - Insurance certificate
    """
    
    # ==================== RELATIONSHIPS ====================
    registration_request = models.ForeignKey(
        SellerRegistrationRequest,
        on_delete=models.CASCADE,
        related_name='document_verifications',
        help_text='The seller registration request'
    )
    
    # ==================== DOCUMENT INFORMATION ====================
    document_type = models.CharField(
        max_length=100,
        help_text='Type of document (e.g., Business Registration, Tax ID, etc.)'
    )
    document_url = models.URLField(
        help_text='URL to the document file stored in cloud storage'
    )
    status = models.CharField(
        max_length=20,
        choices=DocumentVerificationStatus.choices,
        default=DocumentVerificationStatus.PENDING,
        help_text='Verification status of the document'
    )
    
    # ==================== VERIFICATION DETAILS ====================
    verified_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='verified_documents',
        help_text='The admin who verified this document'
    )
    verification_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Notes from admin verification'
    )
    
    # ==================== TIMESTAMPS ====================
    uploaded_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the document was uploaded'
    )
    verified_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the document was verified'
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the document expires (if applicable)'
    )
    
    class Meta:
        db_table = 'seller_document_verifications'
        verbose_name = 'Seller Document Verification'
        verbose_name_plural = 'Seller Document Verifications'
        ordering = ['-uploaded_at']
        unique_together = [['registration_request', 'document_type']]
        indexes = [
            models.Index(fields=['registration_request_id']),
            models.Index(fields=['status']),
            models.Index(fields=['document_type']),
            models.Index(fields=['registration_request_id', 'status']),
            models.Index(fields=['verified_by_id']),
            models.Index(fields=['uploaded_at']),
            models.Index(fields=['verified_at']),
        ]
    
    def __str__(self):
        return f"Document: {self.document_type} - {self.status}"


class SellerApprovalHistory(models.Model):
    """
    Audit trail for seller approval decisions.
    
    Records all admin decisions with:
    - Admin who made the decision
    - Decision (approve/reject/suspend)
    - Decision reason and notes
    - Timestamp for compliance tracking
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='approval_history',
        help_text='The seller user'
    )
    admin = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='seller_approvals',
        help_text='The admin who made the decision'
    )
    
    # ==================== DECISION DETAILS ====================
    decision = models.CharField(
        max_length=20,
        choices=[
            ('APPROVED', 'Approved'),
            ('REJECTED', 'Rejected'),
            ('SUSPENDED', 'Suspended'),
            ('REACTIVATED', 'Reactivated'),
        ],
        help_text='The approval decision'
    )
    decision_reason = models.TextField(
        help_text='Reason for the decision'
    )
    admin_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Additional admin notes'
    )
    
    # ==================== EFFECTIVE DATE ====================
    effective_from = models.DateTimeField(
        default=timezone.now,
        help_text='Date when the decision becomes effective'
    )
    effective_until = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Date when the decision expires (e.g., suspension end date)'
    )
    
    # ==================== AUDIT FIELDS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the decision was recorded'
    )
    
    class Meta:
        db_table = 'seller_approval_history'
        verbose_name = 'Seller Approval History'
        verbose_name_plural = 'Seller Approval History'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['decision']),
            models.Index(fields=['created_at']),
            models.Index(fields=['seller_id', 'decision']),
            models.Index(fields=['admin_id']),
            models.Index(fields=['effective_from']),
            models.Index(fields=['decision', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.seller.full_name} - {self.decision} on {self.created_at.date()}"


class SellerSuspension(models.Model):
    """
    Track seller suspensions with reason and duration.
    
    Supports:
    - Temporary suspensions (with end date)
    - Permanent suspensions
    - Automatic lifting of expired suspensions
    """
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='suspensions',
        help_text='The suspended seller'
    )
    admin = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='seller_suspensions',
        help_text='The admin who issued the suspension'
    )
    
    # ==================== SUSPENSION DETAILS ====================
    reason = models.TextField(
        help_text='Reason for suspension'
    )
    severity = models.CharField(
        max_length=20,
        choices=[
            ('TEMPORARY', 'Temporary'),
            ('PERMANENT', 'Permanent'),
        ],
        default='TEMPORARY',
        help_text='Whether suspension is temporary or permanent'
    )
    
    # ==================== DATES ====================
    suspended_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the suspension was issued'
    )
    suspended_until = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When temporary suspension expires'
    )
    lifted_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When suspension was lifted/overturned'
    )
    
    # ==================== STATUS ====================
    is_active = models.BooleanField(
        default=True,
        help_text='Whether suspension is currently in effect'
    )
    
    class Meta:
        db_table = 'seller_suspensions'
        verbose_name = 'Seller Suspension'
        verbose_name_plural = 'Seller Suspensions'
        ordering = ['-suspended_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['is_active']),
            models.Index(fields=['suspended_at']),
            models.Index(fields=['seller_id', 'is_active']),
            models.Index(fields=['admin_id']),
            models.Index(fields=['suspended_until']),
            models.Index(fields=['is_active', 'suspended_until']),
        ]
    
    def __str__(self):
        status = "Active" if self.is_active else "Lifted"
        return f"Suspension: {self.seller.full_name} - {status}"


# ==================== PRICE MANAGEMENT MODELS ====================

class PriceCeiling(models.Model):
    """
    Product-specific price ceiling set by admin.
    
    Features:
    - Per-product ceiling prices
    - Effective date tracking
    - Automatic non-compliance detection
    - Price change history
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.OneToOneField(
        'SellerProduct',
        on_delete=models.CASCADE,
        related_name='price_ceiling',
        help_text='The product this ceiling applies to'
    )
    
    # ==================== CEILING PRICE ====================
    ceiling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[validate_ceiling_price_positive],
        help_text='Maximum allowed price per unit'
    )
    previous_ceiling = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Previous ceiling price for history tracking'
    )
    
    # ==================== EFFECTIVE DATES ====================
    effective_from = models.DateTimeField(
        default=timezone.now,
        help_text='When this ceiling price becomes effective'
    )
    effective_until = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When this ceiling price expires (if temporary)'
    )
    
    # ==================== AUDIT FIELDS ====================
    set_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='set_price_ceilings',
        help_text='The admin who set this ceiling'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the ceiling was created'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='When the ceiling was last updated'
    )
    
    class Meta:
        db_table = 'price_ceilings'
        verbose_name = 'Price Ceiling'
        verbose_name_plural = 'Price Ceilings'
        ordering = ['product__name']
        indexes = [
            models.Index(fields=['product_id']),
            models.Index(fields=['effective_from']),
            models.Index(fields=['product_id', 'effective_from']),
            models.Index(fields=['set_by_id']),
            models.Index(fields=['effective_until']),
            models.Index(fields=['updated_at']),
        ]
    
    def __str__(self):
        return f"Ceiling: {self.product.name} - {self.ceiling_price}"
    
    def clean(self):
        """
        Validate PriceCeiling constraints before save.
        
        Checks:
        - ceiling_price > 0 (via field validator)
        - effective_until is after effective_from (if provided)
        
        Raises:
            ValidationError: If any validation fails
        """
        if self.effective_until and self.effective_from:
            if self.effective_until <= self.effective_from:
                raise ValidationError({
                    'effective_until': 'Effective until date must be after effective from date.'
                })
    
    # ==================== BUSINESS LOGIC METHODS ====================
    
    def check_compliance(self, seller_price: float) -> dict:
        """
        Check if a seller's listed price complies with this ceiling.
        
        Compares a seller's price against this ceiling and returns
        compliance status with detailed metrics.
        
        Args:
            seller_price (float): The price listed by the seller
        
        Returns:
            dict: Compliance status with keys:
                - 'is_compliant' (bool): True if price <= ceiling
                - 'listed_price' (float): The seller's price
                - 'ceiling_price' (float): The ceiling price
                - 'overage_amount' (float): Amount over ceiling (0 if compliant)
                - 'overage_percentage' (float): Percentage over ceiling (0 if compliant)
                - 'status' (str): 'COMPLIANT' or 'NON_COMPLIANT'
        
        Example:
            ceiling = PriceCeiling.objects.get(product__id=1)
            result = ceiling.check_compliance(125.50)
            
            if result['is_compliant']:
                print("Price is within ceiling")
            else:
                print(f"Price exceeds ceiling by {result['overage_percentage']}%")
        """
        seller_price = float(seller_price)
        ceiling_price = float(self.ceiling_price)
        
        is_compliant = seller_price <= ceiling_price
        
        if is_compliant:
            overage_amount = 0.0
            overage_percentage = 0.0
        else:
            overage_amount = seller_price - ceiling_price
            overage_percentage = (overage_amount / ceiling_price) * 100
        
        return {
            'is_compliant': is_compliant,
            'listed_price': seller_price,
            'ceiling_price': ceiling_price,
            'overage_amount': round(overage_amount, 2),
            'overage_percentage': round(overage_percentage, 2),
            'status': 'COMPLIANT' if is_compliant else 'NON_COMPLIANT'
        }


class PriceAdvisory(models.Model):
    """
    Official OPAS price recommendations visible to marketplace.
    
    Types:
    - Price updates/alerts
    - Shortage alerts
    - Promotion notices
    - Market trend information
    """
    
    # ==================== ADVISORY INFORMATION ====================
    title = models.CharField(
        max_length=255,
        help_text='Advisory title'
    )
    content = models.TextField(
        help_text='Advisory content/message'
    )
    advisory_type = models.CharField(
        max_length=50,
        choices=[
            ('PRICE_UPDATE', 'Price Update'),
            ('SHORTAGE_ALERT', 'Shortage Alert'),
            ('PROMOTION', 'Promotion'),
            ('MARKET_TREND', 'Market Trend'),
        ],
        help_text='Type of advisory'
    )
    
    # ==================== TARGET AUDIENCE ====================
    target_audience = models.CharField(
        max_length=50,
        choices=[
            ('ALL', 'All Users'),
            ('BUYERS', 'Buyers Only'),
            ('SELLERS', 'Sellers Only'),
            ('SPECIFIC', 'Specific Users'),
        ],
        default='ALL',
        help_text='Who this advisory is targeted to'
    )
    
    # ==================== DATES ====================
    effective_from = models.DateTimeField(
        default=timezone.now,
        help_text='When advisory becomes visible'
    )
    effective_until = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When advisory expires'
    )
    
    # ==================== STATUS ====================
    is_active = models.BooleanField(
        default=True,
        help_text='Whether advisory is currently active'
    )
    
    # ==================== AUDIT FIELDS ====================
    created_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_advisories',
        help_text='The admin who created this advisory'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the advisory was created'
    )
    
    class Meta:
        db_table = 'price_advisories'
        verbose_name = 'Price Advisory'
        verbose_name_plural = 'Price Advisories'
        ordering = ['-effective_from']
        indexes = [
            models.Index(fields=['is_active']),
            models.Index(fields=['effective_from']),
            models.Index(fields=['advisory_type']),
            models.Index(fields=['is_active', 'effective_from']),
            models.Index(fields=['created_by_id']),
            models.Index(fields=['target_audience']),
            models.Index(fields=['effective_until']),
        ]
    
    def __str__(self):
        return f"Advisory: {self.title}"


class PriceHistory(models.Model):
    """
    Track all price ceiling changes with full audit trail.
    
    Records:
    - Previous and new price
    - Admin who made change
    - Reason for change
    - Timestamp for compliance
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.CASCADE,
        related_name='price_history',
        help_text='The product this price change applies to'
    )
    admin = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='price_changes',
        help_text='The admin who made the price change'
    )
    
    # ==================== PRICE DETAILS ====================
    old_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Previous ceiling price'
    )
    new_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='New ceiling price'
    )
    change_reason = models.CharField(
        max_length=30,
        choices=PriceChangeReason.choices,
        help_text='Reason for the price change'
    )
    reason_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Additional notes about the price change'
    )
    
    # ==================== IMPACT ====================
    affected_sellers_count = models.IntegerField(
        default=0,
        help_text='Number of sellers affected by this change'
    )
    non_compliant_count = models.IntegerField(
        default=0,
        help_text='Number of sellers now non-compliant with new ceiling'
    )
    
    # ==================== TIMESTAMPS ====================
    changed_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the price was changed'
    )
    
    class Meta:
        db_table = 'price_history'
        verbose_name = 'Price History'
        verbose_name_plural = 'Price History'
        ordering = ['-changed_at']
        indexes = [
            models.Index(fields=['product_id']),
            models.Index(fields=['changed_at']),
            models.Index(fields=['change_reason']),
            models.Index(fields=['product_id', 'changed_at']),
            models.Index(fields=['admin_id']),
            models.Index(fields=['change_reason', 'changed_at']),
        ]
    
    def __str__(self):
        return f"Price Change: {self.product.name} ({self.old_price} → {self.new_price})"


class PriceNonCompliance(models.Model):
    """
    Track sellers exceeding price ceiling with compliance status.
    
    Workflow:
    1. Detection: Seller's price > ceiling
    2. Alert: Flag in admin dashboard
    3. Resolution: Warning, force adjustment, or suspension
    
    Usage:
        # Get active violations
        violations = PriceNonCompliance.objects.active_violations()
        
        # Get violations by seller
        seller_violations = PriceNonCompliance.objects.by_seller(seller)
        
        # Get violations by product
        product_violations = PriceNonCompliance.objects.by_product(product)
    """
    
    # Status choices
    class StatusChoices(models.TextChoices):
        NEW = 'NEW', 'New Violation'
        WARNED = 'WARNED', 'Warning Issued'
        ADJUSTED = 'ADJUSTED', 'Price Adjusted'
        SUSPENDED = 'SUSPENDED', 'Seller Suspended'
        RESOLVED = 'RESOLVED', 'Resolved'
    
    # ==================== RELATIONSHIPS ====================
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='price_violations',
        help_text='The seller with non-compliant price'
    )
    product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.CASCADE,
        related_name='compliance_violations',
        help_text='The product with non-compliant price'
    )
    detected_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='detected_violations',
        help_text='The admin who detected or flagged this violation'
    )
    
    # ==================== VIOLATION DETAILS ====================
    listed_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text='The price listed by seller'
    )
    ceiling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text='The ceiling price at time of violation'
    )
    overage_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[validate_overage_percent_non_negative],
        help_text='Percentage over ceiling'
    )
    
    # ==================== STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.NEW,
        help_text='Current status of violation'
    )
    
    # ==================== RESOLUTION ====================
    warning_issued_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When warning was issued'
    )
    warning_expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When seller must comply by'
    )
    resolved_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When violation was resolved'
    )
    resolution_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Notes on how violation was resolved'
    )
    
    # ==================== AUDIT FIELDS ====================
    detected_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When violation was first detected'
    )
    
    # ==================== MANAGERS ====================
    objects = PriceNonComplianceManager()
    
    class Meta:
        db_table = 'price_non_compliances'
        verbose_name = 'Price Non-Compliance'
        verbose_name_plural = 'Price Non-Compliances'
        ordering = ['-detected_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['product_id']),
            models.Index(fields=['status']),
            models.Index(fields=['detected_at']),
            models.Index(fields=['seller_id', 'status']),
            models.Index(fields=['product_id', 'status']),
            models.Index(fields=['seller_id', 'product_id']),
            models.Index(fields=['status', 'detected_at']),
            models.Index(fields=['detected_by_id']),
            models.Index(fields=['warning_expires_at']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(listed_price__gt=models.F('ceiling_price')),
                name='listed_price_exceeds_ceiling'
            ),
        ]
    
    def __str__(self):
        return f"Violation: {self.seller.full_name} - {self.product.name}"
    
    def clean(self):
        """
        Validate PriceNonCompliance constraints before save.
        
        Checks:
        - overage_percentage >= 0 (via field validator)
        - listed_price > ceiling_price (non-compliance must have violation)
        
        Raises:
            ValidationError: If any validation fails
        """
        if self.listed_price and self.ceiling_price:
            validate_price_non_compliance_prices(self.listed_price, self.ceiling_price)
    
    # ==================== BUSINESS LOGIC METHODS ====================
    
    def is_active(self) -> bool:
        """Check if violation is still active (unresolved)"""
        return self.status != self.StatusChoices.RESOLVED
    
    def is_warning_expired(self) -> bool:
        """Check if warning period has expired"""
        if not self.warning_expires_at:
            return False
        return timezone.now() > self.warning_expires_at
    
    def calculate_overage_percentage(self) -> float:
        """Calculate overage percentage"""
        if self.ceiling_price == 0:
            return 0
        overage = ((self.listed_price - self.ceiling_price) / self.ceiling_price) * 100
        return round(overage, 2)
    
    def issue_warning(self, warning_days: int = 7):
        """Issue warning to seller"""
        self.status = self.StatusChoices.WARNED
        self.warning_issued_at = timezone.now()
        self.warning_expires_at = timezone.now() + timezone.timedelta(days=warning_days)
        self.save(update_fields=['status', 'warning_issued_at', 'warning_expires_at'])
    
    def mark_resolved(self, resolution_note: str = ""):
        """Mark violation as resolved"""
        self.status = self.StatusChoices.RESOLVED
        self.resolved_at = timezone.now()
        if resolution_note:
            self.resolution_notes = resolution_note
        self.save(update_fields=['status', 'resolved_at', 'resolution_notes'])





# ==================== OPAS BULK PURCHASE MODELS ====================

class OPASPurchaseOrder(models.Model):
    """
    Admin review and approval of seller OPAS submissions.
    
    Workflow:
    1. Seller submits "Sell to OPAS" offer (SellToOPAS)
    2. Creates OPASPurchaseOrder for admin review
    3. Admin approves with quantity and final price
    4. Creates OPASInventory entry on approval
    """
    
    # ==================== RELATIONSHIPS ====================
    sell_to_opas = models.OneToOneField(
        'SellToOPAS',
        on_delete=models.CASCADE,
        related_name='purchase_order',
        help_text='The original OPAS submission'
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='opas_purchase_orders',
        help_text='The seller submitting the offer'
    )
    product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.CASCADE,
        related_name='opas_purchase_orders',
        help_text='The product offered'
    )
    reviewed_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_opas_orders',
        help_text='The admin who reviewed this submission'
    )
    
    # ==================== SUBMISSION DETAILS ====================
    status = models.CharField(
        max_length=25,
        choices=OPASSubmissionStatus.choices,
        default=OPASSubmissionStatus.PENDING,
        help_text='Review status of OPAS submission'
    )
    
    # Original offer from seller
    offered_quantity = models.IntegerField(
        help_text='Quantity offered by seller'
    )
    offered_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Price per unit offered by seller'
    )
    
    # Admin approval details
    approved_quantity = models.IntegerField(
        blank=True,
        null=True,
        help_text='Quantity approved by admin'
    )
    final_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Final price per unit set by admin'
    )
    
    # ==================== APPROVAL DETAILS ====================
    quality_grade = models.CharField(
        max_length=20,
        choices=[
            ('PREMIUM', 'Premium'),
            ('GRADE_A', 'Grade A'),
            ('GRADE_B', 'Grade B'),
            ('STANDARD', 'Standard'),
        ],
        blank=True,
        null=True,
        help_text='Quality assessment'
    )
    delivery_terms = models.TextField(
        blank=True,
        null=True,
        help_text='Delivery terms and schedule'
    )
    admin_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Admin review notes'
    )
    rejection_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for rejection (if rejected)'
    )
    
    # ==================== DATES ====================
    submitted_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When offer was submitted'
    )
    reviewed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When admin reviewed offer'
    )
    approved_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When offer was approved'
    )
    
    class Meta:
        db_table = 'opas_purchase_orders'
        verbose_name = 'OPAS Purchase Order'
        verbose_name_plural = 'OPAS Purchase Orders'
        ordering = ['-submitted_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['product_id']),
            models.Index(fields=['status']),
            models.Index(fields=['submitted_at']),
            models.Index(fields=['seller_id', 'status']),
            models.Index(fields=['status', 'submitted_at']),
            models.Index(fields=['reviewed_by_id']),
            models.Index(fields=['reviewed_at']),
            models.Index(fields=['approved_at']),
        ]
    
    def __str__(self):
        return f"PO: {self.seller.full_name} - {self.product.name} ({self.status})"


class OPASInventory(models.Model):
    """
    Centralized OPAS stock management with automatic alerts.
    
    Tracks:
    - Current inventory quantities
    - Storage locations
    - Expiration dates
    - Automatic low stock and expiry alerts
    - FIFO compliance for perishables
    
    Usage:
        # Get low stock inventory
        low_stock = OPASInventory.objects.low_stock()
        
        # Get expiring inventory
        expiring = OPASInventory.objects.expiring_soon()
        
        # Get inventory by location
        warehouse_stock = OPASInventory.objects.by_location("Main Warehouse")
    """
    
    # ==================== RELATIONSHIPS ====================
    product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.CASCADE,
        related_name='opas_inventory',
        help_text='The product in OPAS inventory'
    )
    purchase_order = models.OneToOneField(
        OPASPurchaseOrder,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='inventory_entry',
        help_text='The OPAS purchase order that created this inventory'
    )
    
    # ==================== INVENTORY LEVELS ====================
    quantity_received = models.IntegerField(
        validators=[MinValueValidator(0)],
        help_text='Total quantity received into OPAS inventory'
    )
    quantity_on_hand = models.IntegerField(
        validators=[MinValueValidator(0)],
        help_text='Current quantity available'
    )
    quantity_consumed = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text='Quantity consumed/sold out'
    )
    quantity_spoiled = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text='Quantity spoiled/damaged'
    )
    
    # ==================== STORAGE ====================
    storage_location = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text='Storage location/warehouse'
    )
    storage_condition = models.CharField(
        max_length=50,
        choices=[
            ('AMBIENT', 'Ambient'),
            ('COLD_CHAIN', 'Cold Chain'),
            ('REFRIGERATED', 'Refrigerated'),
        ],
        default='AMBIENT',
        help_text='Storage condition required'
    )
    
    # ==================== DATES ====================
    received_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When inventory was received'
    )
    in_date = models.DateTimeField(
        help_text='Manufactured/production date'
    )
    expiry_date = models.DateTimeField(
        help_text='Expiration date of the produce'
    )
    
    # ==================== ALERTS ====================
    low_stock_threshold = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text='Quantity threshold for low stock alert'
    )
    is_low_stock = models.BooleanField(
        default=False,
        help_text='Whether current stock is below threshold'
    )
    is_expiring = models.BooleanField(
        default=False,
        help_text='Whether produce is expiring within 7 days'
    )
    
    # ==================== MANAGERS ====================
    objects = OPASInventoryManager()
    
    class Meta:
        db_table = 'opas_inventory'
        verbose_name = 'OPAS Inventory'
        verbose_name_plural = 'OPAS Inventory'
        ordering = ['expiry_date']
        indexes = [
            models.Index(fields=['product_id']),
            models.Index(fields=['quantity_on_hand']),
            models.Index(fields=['is_low_stock']),
            models.Index(fields=['is_expiring']),
            models.Index(fields=['expiry_date']),
            models.Index(fields=['storage_location']),
            models.Index(fields=['product_id', 'expiry_date']),
            models.Index(fields=['is_low_stock', 'quantity_on_hand']),
            models.Index(fields=['is_expiring', 'expiry_date']),
            models.Index(fields=['storage_location', 'is_low_stock']),
            models.Index(fields=['received_at']),
            models.Index(fields=['purchase_order_id']),
        ]
    
    def __str__(self):
        return f"Inventory: {self.product.name} - {self.quantity_on_hand} units"
    
    def clean(self):
        """
        Validate OPASInventory constraints before save.
        
        Checks:
        - quantity_received >= 0 (via field validator)
        - quantity_on_hand >= 0 (via field validator)
        - quantity_consumed >= 0 (via field validator)
        - quantity_spoiled >= 0 (via field validator)
        - expiry_date > in_date
        
        Raises:
            ValidationError: If any validation fails
        """
        if self.in_date and self.expiry_date:
            validate_opas_inventory_dates(self.in_date, self.expiry_date)
    
    # ==================== BUSINESS LOGIC METHODS ====================
    
    def check_is_low_stock(self) -> bool:
        """
        Check if inventory is at or below low stock threshold.
        
        Compares current quantity_on_hand against the low_stock_threshold.
        Default threshold is 10 units or custom value set during configuration.
        
        Returns:
            bool: True if quantity is at or below threshold, False otherwise
        
        Example:
            inventory = OPASInventory.objects.get(product__id=1)
            if inventory.check_is_low_stock():
                print("Low stock alert: Order more units immediately")
        """
        return self.quantity_on_hand <= self.low_stock_threshold
    
    def check_is_expiring(self) -> bool:
        """
        Check if inventory will expire within 7 days.
        
        Useful for FIFO compliance and spoilage prevention.
        Checks if expiry_date is within next 7 days from now.
        
        Returns:
            bool: True if expiring within 7 days, False otherwise
        
        Example:
            inventory = OPASInventory.objects.get(product__id=1)
            if inventory.check_is_expiring():
                print("Product expires soon - prioritize consumption")
        """
        from datetime import timedelta
        expiry_threshold = timezone.now() + timedelta(days=7)
        return self.expiry_date <= expiry_threshold
    
    def update_stock_status(self):
        """Update low stock and expiring status flags"""
        # Check low stock
        self.is_low_stock = self.quantity_on_hand <= self.low_stock_threshold
        
        # Check if expiring (within 7 days)
        from datetime import timedelta
        expiry_threshold = timezone.now() + timedelta(days=7)
        self.is_expiring = self.expiry_date <= expiry_threshold
        
        self.save(update_fields=['is_low_stock', 'is_expiring'])
    
    def days_until_expiry(self) -> int:
        """Get number of days until expiry"""
        delta = self.expiry_date - timezone.now()
        return max(0, delta.days)
    
    def is_expired(self) -> bool:
        """Check if inventory has expired"""
        return timezone.now() > self.expiry_date
    
    def get_available_quantity(self) -> int:
        """Get quantity still available (not consumed or spoiled)"""
        return self.quantity_on_hand
    
    def consume_stock(self, quantity: int, reason: str = ""):
        """Consume stock from inventory"""
        if quantity > self.quantity_on_hand:
            raise ValidationError(
                f"Cannot consume {quantity} units. Only {self.quantity_on_hand} available."
            )
        self.quantity_on_hand -= quantity
        self.quantity_consumed += quantity
        self.save(update_fields=['quantity_on_hand', 'quantity_consumed'])
    
    def record_spoilage(self, quantity: int, reason: str = ""):
        """Record spoilage in inventory"""
        if quantity > self.quantity_on_hand:
            raise ValidationError(
                f"Cannot spoil {quantity} units. Only {self.quantity_on_hand} available."
            )
        self.quantity_on_hand -= quantity
        self.quantity_spoiled += quantity
        self.save(update_fields=['quantity_on_hand', 'quantity_spoiled'])





class OPASInventoryTransaction(models.Model):
    """
    FIFO tracking of OPAS inventory in/out movements.
    
    Tracks:
    - Stock received (IN)
    - Stock consumed (OUT)
    - Spoilage events
    - Manual adjustments
    - FIFO validation
    """
    
    # ==================== RELATIONSHIPS ====================
    inventory = models.ForeignKey(
        OPASInventory,
        on_delete=models.CASCADE,
        related_name='transactions',
        help_text='The inventory being transacted'
    )
    processed_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='inventory_transactions',
        help_text='The admin who processed this transaction'
    )
    
    # ==================== TRANSACTION DETAILS ====================
    transaction_type = models.CharField(
        max_length=20,
        choices=InventoryTransactionType.choices,
        help_text='Type of transaction'
    )
    quantity = models.IntegerField(
        help_text='Quantity in this transaction'
    )
    reference_number = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Reference number (PO, invoice, etc.)'
    )
    reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for transaction (especially for adjustments/spoilage)'
    )
    
    # ==================== FIFO TRACKING ====================
    is_fifo_compliant = models.BooleanField(
        default=True,
        help_text='Whether this transaction follows FIFO'
    )
    batch_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Batch ID for FIFO tracking'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When transaction was recorded'
    )
    
    class Meta:
        db_table = 'opas_inventory_transactions'
        verbose_name = 'OPAS Inventory Transaction'
        verbose_name_plural = 'OPAS Inventory Transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['inventory_id']),
            models.Index(fields=['transaction_type']),
            models.Index(fields=['created_at']),
            models.Index(fields=['batch_id']),
            models.Index(fields=['inventory_id', 'transaction_type']),
            models.Index(fields=['inventory_id', 'created_at']),
            models.Index(fields=['transaction_type', 'created_at']),
            models.Index(fields=['processed_by_id']),
            models.Index(fields=['is_fifo_compliant']),
        ]
    
    def __str__(self):
        return f"Transaction: {self.transaction_type} - {self.quantity} units"


class OPASPurchaseHistory(models.Model):
    """
    Complete transaction audit for OPAS purchases.
    
    Records:
    - What was purchased (product, quantity)
    - From whom (seller)
    - For how much (price)
    - When (date/time)
    - Audit trail for compliance
    """
    
    # ==================== RELATIONSHIPS ====================
    purchase_order = models.ForeignKey(
        OPASPurchaseOrder,
        on_delete=models.CASCADE,
        related_name='purchase_history',
        help_text='The purchase order'
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='opas_sales_history',
        help_text='The seller'
    )
    product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.CASCADE,
        related_name='opas_sales_history',
        help_text='The product purchased'
    )
    
    # ==================== PURCHASE DETAILS ====================
    quantity = models.IntegerField(
        help_text='Quantity purchased'
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Price per unit'
    )
    total_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='Total purchase price'
    )
    quality_grade = models.CharField(
        max_length=20,
        help_text='Quality grade of product'
    )
    
    # ==================== PAYMENT ====================
    payment_status = models.CharField(
        max_length=20,
        choices=[
            ('PENDING', 'Pending'),
            ('PAID', 'Paid'),
            ('PARTIAL', 'Partial'),
        ],
        default='PENDING',
        help_text='Payment status'
    )
    paid_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When payment was made'
    )
    
    # ==================== TIMESTAMPS ====================
    purchased_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When purchase was completed'
    )
    
    class Meta:
        db_table = 'opas_purchase_history'
        verbose_name = 'OPAS Purchase History'
        verbose_name_plural = 'OPAS Purchase History'
        ordering = ['-purchased_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['product_id']),
            models.Index(fields=['purchased_at']),
            models.Index(fields=['seller_id', 'purchased_at']),
            models.Index(fields=['product_id', 'purchased_at']),
            models.Index(fields=['payment_status']),
            models.Index(fields=['purchase_order_id']),
        ]
    
    def __str__(self):
        return f"Purchase: {self.seller.full_name} - {self.product.name}"


# ==================== ADMIN ACTIVITY & ALERTS MODELS ====================

class AdminAuditLog(models.Model):
    """
    Immutable audit log of all admin actions for compliance.
    
    Tracks:
    - What action was taken
    - Who did it (admin)
    - When it was done
    - What changed
    - For complete compliance record
    """
    
    # ==================== RELATIONSHIPS ====================
    admin = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs',
        help_text='The admin who performed the action'
    )
    
    # ==================== ACTION DETAILS ====================
    action_type = models.CharField(
        max_length=100,
        validators=[validate_action_type_in_valid_choices],
        help_text='Type of action performed'
    )
    action_category = models.CharField(
        max_length=50,
        choices=[
            ('SELLER_APPROVAL', 'Seller Approval'),
            ('SELLER_SUSPENSION', 'Seller Suspension'),
            ('PRICE_UPDATE', 'Price Update'),
            ('OPAS_REVIEW', 'OPAS Submission Review'),
            ('INVENTORY_ADJUSTMENT', 'Inventory Adjustment'),
            ('ADVISORY_CREATED', 'Advisory Created'),
            ('ALERT_ISSUED', 'Alert Issued'),
            ('ANNOUNCEMENT', 'Announcement'),
            ('OTHER', 'Other'),
        ],
        help_text='Category of action'
    )
    
    # ==================== AFFECTED RESOURCES ====================
    affected_seller = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs_as_subject',
        help_text='Seller affected by this action (if applicable)'
    )
    affected_product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs',
        help_text='Product affected by this action (if applicable)'
    )
    target_id = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text='Generic target ID for the affected resource (flexible for any model)'
    )
    
    # ==================== CHANGE DETAILS ====================
    description = models.TextField(
        help_text='Description of the action'
    )
    old_value = models.TextField(
        blank=True,
        null=True,
        help_text='Previous value (before change)'
    )
    new_value = models.TextField(
        blank=True,
        null=True,
        help_text='New value (after change)'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the action was performed'
    )
    
    class Meta:
        db_table = 'admin_audit_logs'
        verbose_name = 'Admin Audit Log'
        verbose_name_plural = 'Admin Audit Logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['admin_id']),
            models.Index(fields=['action_category']),
            models.Index(fields=['affected_seller_id']),
            models.Index(fields=['created_at']),
            models.Index(fields=['admin_id', 'action_category']),
            models.Index(fields=['admin_id', 'created_at']),
            models.Index(fields=['action_category', 'created_at']),
            models.Index(fields=['action_type']),
            models.Index(fields=['affected_product_id']),
            models.Index(fields=['affected_seller_id', 'created_at']),
        ]
    
    def clean(self):
        """
        Validate AdminAuditLog constraints before save.
        
        Checks:
        - action_type is in valid choices (via field validator)
        
        Raises:
            ValidationError: If any validation fails
        """
        # Validators are called automatically on field-level
        # This method provides a clean() integration point
        pass
    
    def save(self, *args, **kwargs):
        """
        Immutable audit log - prevent updates after creation.
        Only allow initial creation.
        
        Raises:
            ValidationError: If attempting to update an existing audit log
        """
        if self.pk is not None:
            # This is an update attempt - prevent it
            raise ValidationError(
                "AdminAuditLog is immutable. Audit logs cannot be modified after creation."
            )
        super().save(*args, **kwargs)
    
    def delete(self, *args, **kwargs):
        """
        Immutable audit log - prevent deletion.
        Audit logs must be preserved forever for compliance.
        
        Raises:
            ValidationError: Always raises - deletions not permitted
        """
        raise ValidationError(
            "AdminAuditLog is immutable. Audit logs cannot be deleted."
        )
    
    def __str__(self):
        """
        Return formatted audit log string with action, admin, and timestamp.
        
        Format: "Audit: [ACTION_TYPE] by [ADMIN_EMAIL] @ [TIMESTAMP]"
        Example: "Audit: SELLER_APPROVED by admin@opas.com @ 2025-11-22 14:35:42"
        """
        admin_str = f"{self.admin.user.email}" if self.admin else "System"
        timestamp_str = self.created_at.strftime("%Y-%m-%d %H:%M:%S")
        return f"Audit: {self.action_type} by {admin_str} @ {timestamp_str}"


class MarketplaceAlert(models.Model):
    """
    Flags and alerts for marketplace issues with priority handling.
    
    Alert types:
    - Price violations
    - Seller issues
    - Unusual activity
    - Inventory problems
    - Compliance issues
    
    Usage:
        # Get open alerts
        open_alerts = MarketplaceAlert.objects.open_alerts()
        
        # Get critical alerts
        critical = MarketplaceAlert.objects.critical()
        
        # Get recent alerts (last 7 days)
        recent = MarketplaceAlert.objects.recent(days=7)
    """
    
    # Status choices
    class StatusChoices(models.TextChoices):
        OPEN = 'OPEN', 'Open'
        ACKNOWLEDGED = 'ACKNOWLEDGED', 'Acknowledged'
        RESOLVED = 'RESOLVED', 'Resolved'
    
    # Alert type choices
    class AlertTypeChoices(models.TextChoices):
        PRICE_VIOLATION = 'PRICE_VIOLATION', 'Price Violation'
        SELLER_ISSUE = 'SELLER_ISSUE', 'Seller Issue'
        INVENTORY_ALERT = 'INVENTORY_ALERT', 'Inventory Alert'
        UNUSUAL_ACTIVITY = 'UNUSUAL_ACTIVITY', 'Unusual Activity'
        COMPLIANCE = 'COMPLIANCE', 'Compliance Issue'
    
    # ==================== ALERT DETAILS ====================
    title = models.CharField(
        max_length=255,
        help_text='Alert title'
    )
    description = models.TextField(
        help_text='Detailed description of the alert'
    )
    alert_type = models.CharField(
        max_length=50,
        choices=AlertTypeChoices.choices,
        help_text='Type of alert'
    )
    severity = models.CharField(
        max_length=20,
        choices=AlertSeverity.choices,
        default=AlertSeverity.WARNING,
        help_text='Alert severity level'
    )
    
    # ==================== AFFECTED RESOURCES ====================
    affected_seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='marketplace_alerts',
        help_text='Seller this alert is about'
    )
    affected_product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='marketplace_alerts',
        help_text='Product this alert is about'
    )
    
    # ==================== STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.OPEN,
        help_text='Alert status'
    )
    acknowledged_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='acknowledged_alerts',
        help_text='Admin who acknowledged this alert'
    )
    resolution_notes = models.TextField(
        blank=True,
        null=True,
        help_text='How the alert was resolved'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When alert was created'
    )
    acknowledged_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When alert was acknowledged'
    )
    resolved_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When alert was resolved'
    )
    
    # ==================== MANAGERS ====================
    objects = AlertManager()
    
    class Meta:
        db_table = 'marketplace_alerts'
        verbose_name = 'Marketplace Alert'
        verbose_name_plural = 'Marketplace Alerts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['alert_type']),
            models.Index(fields=['severity']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
            models.Index(fields=['affected_seller_id']),
            models.Index(fields=['severity', 'status']),
            models.Index(fields=['alert_type', 'severity']),
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['acknowledged_by_id']),
            models.Index(fields=['affected_product_id']),
            models.Index(fields=['severity', 'status', 'created_at']),
        ]
    
    def __str__(self):
        return f"Alert: {self.title} ({self.severity})"
    
    # ==================== BUSINESS LOGIC METHODS ====================
    
    def is_open(self) -> bool:
        """Check if alert is still open"""
        return self.status == self.StatusChoices.OPEN
    
    def is_critical(self) -> bool:
        """Check if this is a critical alert"""
        return self.severity == AlertSeverity.CRITICAL
    
    def acknowledge(self, admin: AdminUser, notes: str = ""):
        """Acknowledge the alert"""
        self.status = self.StatusChoices.ACKNOWLEDGED
        self.acknowledged_by = admin
        self.acknowledged_at = timezone.now()
        self.save(update_fields=['status', 'acknowledged_by', 'acknowledged_at'])
    
    def resolve(self, resolution_note: str = ""):
        """Resolve the alert"""
        self.status = self.StatusChoices.RESOLVED
        self.resolved_at = timezone.now()
        if resolution_note:
            self.resolution_notes = resolution_note
        self.save(update_fields=['status', 'resolved_at', 'resolution_notes'])
    
    def get_priority_score(self) -> int:
        """Calculate alert priority score (0-100)"""
        severity_scores = {
            AlertSeverity.INFO: 10,
            AlertSeverity.WARNING: 50,
            AlertSeverity.CRITICAL: 100,
        }
        base_score = severity_scores.get(self.severity, 50)
        
        # Adjust for age - older unresolved alerts are more important
        if self.is_open():
            from datetime import timedelta
            age_days = (timezone.now() - self.created_at).days
            age_multiplier = min(1.5, 1 + (age_days / 10))
            base_score = int(base_score * age_multiplier)
        
        return min(100, base_score)





class SystemNotification(models.Model):
    """
    System notifications sent to admin dashboard.
    
    Types:
    - Price violations detected
    - Seller suspensions
    - OPAS submissions pending review
    - Inventory alerts
    - System health alerts
    """
    
    # ==================== RELATIONSHIPS ====================
    recipient = models.ForeignKey(
        AdminUser,
        on_delete=models.CASCADE,
        related_name='system_notifications',
        help_text='Admin recipient of notification'
    )
    
    # ==================== NOTIFICATION DETAILS ====================
    title = models.CharField(
        max_length=255,
        help_text='Notification title'
    )
    message = models.TextField(
        help_text='Notification message'
    )
    notification_type = models.CharField(
        max_length=50,
        choices=[
            ('PRICE_VIOLATION', 'Price Violation'),
            ('SELLER_SUSPENSION', 'Seller Suspension'),
            ('OPAS_PENDING', 'OPAS Pending Review'),
            ('INVENTORY_ALERT', 'Inventory Alert'),
            ('SYSTEM_ALERT', 'System Alert'),
            ('COMPLIANCE', 'Compliance Alert'),
        ],
        help_text='Type of notification'
    )
    
    # ==================== RELATED RESOURCES ====================
    related_seller = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications_about',
        help_text='Seller this notification is about'
    )
    related_product = models.ForeignKey(
        'SellerProduct',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications',
        help_text='Product this notification is about'
    )
    
    # ==================== STATUS ====================
    is_read = models.BooleanField(
        default=False,
        help_text='Whether notification has been read'
    )
    read_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When notification was read'
    )
    
    # ==================== PRIORITY ====================
    priority = models.CharField(
        max_length=20,
        choices=[
            ('LOW', 'Low'),
            ('MEDIUM', 'Medium'),
            ('HIGH', 'High'),
            ('CRITICAL', 'Critical'),
        ],
        default='MEDIUM',
        help_text='Notification priority'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When notification was created'
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When notification expires'
    )
    
    class Meta:
        db_table = 'system_notifications'
        verbose_name = 'System Notification'
        verbose_name_plural = 'System Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient_id']),
            models.Index(fields=['is_read']),
            models.Index(fields=['priority']),
            models.Index(fields=['created_at']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['recipient_id', 'is_read']),
            models.Index(fields=['recipient_id', 'created_at']),
            models.Index(fields=['is_read', 'created_at']),
            models.Index(fields=['priority', 'is_read']),
            models.Index(fields=['related_seller_id']),
            models.Index(fields=['related_product_id']),
            models.Index(fields=['notification_type', 'priority']),
        ]
    
    def __str__(self):
        read_status = "Read" if self.is_read else "Unread"
        return f"Notification: {self.title} - {read_status}"


# ==================== EXPORTS ====================

__all__ = [
    # Enums and choices
    'AdminRole',
    'SellerRegistrationStatus',
    'DocumentVerificationStatus',
    'PriceChangeReason',
    'OPASSubmissionStatus',
    'InventoryTransactionType',
    'AlertSeverity',
    'AlertCategory',
    # Admin user
    'AdminUser',
    # Seller approval workflow
    'SellerRegistrationRequest',
    'SellerDocumentVerification',
    'SellerApprovalHistory',
    'SellerSuspension',
    # Price management
    'PriceCeiling',
    'PriceAdvisory',
    'PriceHistory',
    'PriceNonCompliance',
    # OPAS bulk purchase
    'OPASPurchaseOrder',
    'OPASInventory',
    'OPASInventoryTransaction',
    'OPASPurchaseHistory',
    # Admin activity & alerts
    'AdminAuditLog',
    'MarketplaceAlert',
    'SystemNotification',
]
