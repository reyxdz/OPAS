from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

class UserRole(models.TextChoices):
    """User role choices for the OPAS platform"""
    BUYER = 'BUYER', 'Buyer'
    SELLER = 'SELLER', 'Seller'
    ADMIN = 'ADMIN', 'Admin'


class SellerStatus(models.TextChoices):
    """Seller approval status choices"""
    PENDING = 'PENDING', 'Pending Approval'
    APPROVED = 'APPROVED', 'Approved'
    SUSPENDED = 'SUSPENDED', 'Suspended'
    REJECTED = 'REJECTED', 'Rejected'


class AdminRole(models.TextChoices):
    """Admin permission levels"""
    SUPER_ADMIN = 'SUPER_ADMIN', 'Super Admin (Full Access)'
    SELLER_MANAGER = 'SELLER_MANAGER', 'Seller Manager (Approve/Reject Sellers & Handle Support)'
    PRICE_MANAGER = 'PRICE_MANAGER', 'Price Manager (Manage Prices)'
    ANALYTICS_ADMIN = 'ANALYTICS_ADMIN', 'Analytics Admin (View Reports)'


class User(AbstractUser):
    """
    Custom User model extending Django's AbstractUser.
    
    Features:
    - Role-based access (BUYER, SELLER, ADMIN)
    - Seller management with approval workflow
    - Account suspension tracking
    - Document verification
    - Timestamps for audit trail
    """
    
    # ==================== IDENTITY FIELDS ====================
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=15, unique=True, help_text='Phone number used for authentication')
    address = models.TextField(blank=True, null=True)
    
    # ==================== LOCATION FIELDS (RESIDENCE) ====================
    municipality = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text='Municipality of residence (Biliran)'
    )
    barangay = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Barangay of residence within the selected municipality'
    )
    
    # ==================== FARM LOCATION FIELDS (SELLERS ONLY) ====================
    farm_municipality = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text='Municipality where the farm is located (Biliran)'
    )
    farm_barangay = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Barangay where the farm is located within the selected municipality'
    )
    
    # ==================== ROLE & PERMISSIONS ====================
    role = models.CharField(
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.BUYER,
        help_text='User role: Buyer, Seller, Admin, or System Admin'
    )
    admin_role = models.CharField(
        max_length=20,
        choices=AdminRole.choices,
        default=AdminRole.SUPER_ADMIN,
        blank=True,
        null=True,
        help_text='Permission level for admin users'
    )
    
    # ==================== SELLER INFORMATION ====================
    store_name = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text='Name of the seller\'s store/business'
    )
    store_description = models.TextField(
        blank=True,
        null=True,
        help_text='Description of the seller\'s store/business'
    )
    is_seller_approved = models.BooleanField(
        default=False,
        help_text='Legacy field - use seller_status instead'
    )
    
    # ==================== SELLER APPROVAL WORKFLOW ====================
    seller_status = models.CharField(
        max_length=20,
        choices=SellerStatus.choices,
        default=SellerStatus.PENDING,
        blank=True,
        null=True,
        help_text='Current approval status for seller applications'
    )
    seller_approval_date = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Date when seller was approved'
    )
    seller_documents_verified = models.BooleanField(
        default=False,
        help_text='Whether seller documents have been verified by admin'
    )
    
    # ==================== ACCOUNT MANAGEMENT ====================
    suspension_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for account suspension (if applicable)'
    )
    suspended_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Timestamp when account was suspended'
    )
    
    # ==================== AUDIT FIELDS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='Account creation timestamp'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='Last update timestamp'
    )
    
    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['phone_number']),
            models.Index(fields=['role']),
            models.Index(fields=['seller_status']),
            models.Index(fields=['municipality']),
            models.Index(fields=['barangay']),
            models.Index(fields=['municipality', 'barangay']),
            models.Index(fields=['farm_municipality']),
            models.Index(fields=['farm_barangay']),
            models.Index(fields=['farm_municipality', 'farm_barangay']),
        ]

    # ==================== PROPERTIES ====================
    
    @property
    def full_name(self) -> str:
        """Get user's full name"""
        return f"{self.first_name} {self.last_name}".strip()

    @property
    def is_admin(self) -> bool:
        """Check if user is admin"""
        return self.role == UserRole.ADMIN

    def has_admin_permission(self, permission: str) -> bool:
        """
        Check if admin has specific permission.
        
        Permissions:
        - 'approve_sellers': Approve/reject seller applications
        - 'manage_prices': Set prices and price regulations
        - 'view_analytics': View reports and analytics
        - 'handle_suspensions': Suspend/reactivate accounts
        - 'full_access': All permissions
        """
        if not self.is_admin:
            return False
        
        # Super admin has all permissions
        if self.admin_role == AdminRole.SUPER_ADMIN:
            return True
        
        permission_map = {
            'approve_sellers': ['SUPER_ADMIN', 'SELLER_MANAGER'],
            'manage_prices': ['SUPER_ADMIN', 'PRICE_MANAGER'],
            'view_analytics': ['SUPER_ADMIN', 'ANALYTICS_ADMIN'],
            'handle_suspensions': ['SUPER_ADMIN', 'SELLER_MANAGER'],
            'full_access': ['SUPER_ADMIN'],
        }
        
        allowed_roles = permission_map.get(permission, [])
        return self.admin_role in allowed_roles

    @property
    def is_seller(self) -> bool:
        """Check if user is a seller"""
        return self.role == UserRole.SELLER

    @property
    def is_buyer(self) -> bool:
        """Check if user is a buyer"""
        return self.role == UserRole.BUYER

    @property
    def is_opas_admin(self) -> bool:
        """Deprecated: Use is_admin instead"""
        return self.role == UserRole.ADMIN

    @property
    def is_system_admin(self) -> bool:
        """Deprecated: Use is_admin instead"""
        return self.role == UserRole.ADMIN

    @property
    def is_suspended(self) -> bool:
        """Check if user is suspended"""
        return self.suspended_at is not None and self.seller_status == SellerStatus.SUSPENDED

    @property
    def is_seller_approved(self) -> bool:
        """Check if seller is approved"""
        return self.seller_status == SellerStatus.APPROVED

    @property
    def is_seller_pending(self) -> bool:
        """Check if seller approval is pending"""
        return self.seller_status == SellerStatus.PENDING

    # ==================== METHODS ====================

    def approve_seller(self):
        """Approve seller account"""
        self.seller_status = SellerStatus.APPROVED
        self.seller_approval_date = timezone.now()
        self.is_seller_approved = True
        self.save()

    def reject_seller(self):
        """Reject seller account"""
        self.seller_status = SellerStatus.REJECTED
        self.is_seller_approved = False
        self.save()

    def suspend_account(self, reason: str):
        """Suspend user account with reason"""
        self.seller_status = SellerStatus.SUSPENDED
        self.suspension_reason = reason
        self.suspended_at = timezone.now()
        self.save()

    def unsuspend_account(self):
        """Unsuspend user account"""
        self.suspension_reason = None
        self.suspended_at = None
        if self.seller_status == SellerStatus.SUSPENDED:
            self.seller_status = SellerStatus.APPROVED
        self.save()

    def verify_documents(self):
        """Mark seller documents as verified"""
        self.seller_documents_verified = True
        self.save()

    def unverify_documents(self):
        """Mark seller documents as unverified"""
        self.seller_documents_verified = False
        self.save()

    def __str__(self):
        return f"{self.full_name} ({self.email})"

    def __repr__(self):
        return f"<User: {self.email} | Role: {self.role} | ID: {self.id}>"


class SellerApplication(models.Model):
    """
    Model to track seller applications from buyers.
    
    Workflow:
    1. Buyer submits application with farm details
    2. Application status set to PENDING
    3. Admin reviews application
    4. Admin approves/rejects application
    5. User.seller_status updated accordingly
    """
    
    # ==================== RELATIONSHIPS ====================
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='seller_application',
        help_text='The user applying to become a seller'
    )
    
    # ==================== FARM INFORMATION ====================
    farm_name = models.CharField(
        max_length=255,
        help_text='Name of the farm'
    )
    farm_location = models.CharField(
        max_length=255,
        help_text='Location/address of the farm'
    )
    
    # ==================== STORE INFORMATION ====================
    store_name = models.CharField(
        max_length=255,
        help_text='Name of the seller\'s store/business'
    )
    store_description = models.TextField(
        help_text='Description of the seller\'s store/business'
    )
    
    # ==================== APPLICATION STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=[
            ('PENDING', 'Pending Review'),
            ('APPROVED', 'Approved'),
            ('REJECTED', 'Rejected'),
        ],
        default='PENDING',
        help_text='Current application status'
    )
    rejection_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for rejection (if rejected)'
    )
    
    # ==================== TIMESTAMPS ====================
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the application was submitted'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='When the application was last updated'
    )
    reviewed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When the application was reviewed'
    )
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_applications',
        help_text='The admin who reviewed this application'
    )
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Seller Application'
        verbose_name_plural = 'Seller Applications'
    
    def approve(self, admin_user):
        """Approve the seller application"""
        self.status = 'APPROVED'
        self.reviewed_at = timezone.now()
        self.reviewed_by = admin_user
        self.save()
        
        # Update user role and seller status
        self.user.role = UserRole.SELLER
        self.user.seller_status = SellerStatus.APPROVED
        self.user.seller_approval_date = timezone.now()
        self.user.store_name = self.store_name
        self.user.store_description = self.store_description
        self.user.save()
        self.user.save()
    
    def reject(self, admin_user, reason=''):
        """Reject the seller application"""
        self.status = 'REJECTED'
        self.rejection_reason = reason
        self.reviewed_at = timezone.now()
        self.reviewed_by = admin_user
        self.save()
        
        # Update user seller status (keep role as BUYER)
        self.user.seller_status = SellerStatus.REJECTED
        self.user.save()
    
    def __str__(self):
        return f"Application from {self.user.email} - {self.farm_name}"
    
    def __repr__(self):
        return f"<SellerApplication: {self.user.email} | Status: {self.status}>"


# ==================== SELLER MODELS ====================
# Import seller models to make them available to Django migrations
from .seller_models import (
    SellerProduct,
    SellerOrder,
    SellToOPAS,
    SellerPayout,
    SellerForecast,
)

# ==================== ADMIN MODELS ====================
# Import admin models for admin panel functionality
from .admin_models import (
    AdminUser,
    AdminRole,
    SellerRegistrationStatus,
    DocumentVerificationStatus,
    PriceChangeReason,
    OPASSubmissionStatus,
    InventoryTransactionType,
    AlertSeverity,
    AlertCategory,
    SellerRegistrationRequest,
    SellerDocumentVerification,
    SellerApprovalHistory,
    SellerSuspension,
    PriceCeiling,
    PriceAdvisory,
    PriceHistory,
    PriceNonCompliance,
    OPASPurchaseOrder,
    OPASInventory,
    OPASInventoryTransaction,
    OPASPurchaseHistory,
    AdminAuditLog,
    MarketplaceAlert,
    SystemNotification,
)

__all__ = [
    'User',
    'UserRole',
    'SellerStatus',
    'SellerApplication',
    'SellerProduct',
    'SellerOrder',
    'SellToOPAS',
    'SellerPayout',
    'SellerForecast',
    # Admin models
    'AdminUser',
    'AdminRole',
    'SellerRegistrationStatus',
    'DocumentVerificationStatus',
    'PriceChangeReason',
    'OPASSubmissionStatus',
    'InventoryTransactionType',
    'AlertSeverity',
    'AlertCategory',
    'SellerRegistrationRequest',
    'SellerDocumentVerification',
    'SellerApprovalHistory',
    'SellerSuspension',
    'PriceCeiling',
    'PriceAdvisory',
    'PriceHistory',
    'PriceNonCompliance',
    'OPASPurchaseOrder',
    'OPASInventory',
    'OPASInventoryTransaction',
    'OPASPurchaseHistory',
    'AdminAuditLog',
    'MarketplaceAlert',
    'SystemNotification',
]
