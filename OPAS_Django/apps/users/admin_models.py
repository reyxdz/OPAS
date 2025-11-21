"""
Admin-specific models for OPAS platform.

Models for admin panel functionality:
- AdminUser: Enhanced admin user with department/team assignment and audit capabilities
- Seller Approval Workflow: SellerRegistrationRequest, SellerDocumentVerification, SellerApprovalHistory, SellerSuspension
- Price Management: PriceCeiling, PriceAdvisory, PriceHistory, PriceNonCompliance
- OPAS Bulk Purchase: OPASPurchaseOrder, OPASInventory, OPASInventoryTransaction, OPASPurchaseHistory
- Admin Activity & Alerts: AdminAuditLog, MarketplaceAlert, SystemNotification
"""

from django.db import models
from django.utils import timezone
from django.contrib.auth.models import Permission, Group
from .models import User, UserRole


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


# ==================== ADMIN USER ENHANCEMENT ====================

class AdminUser(models.Model):
    """
    Extended admin user profile with role, department, and audit capabilities.
    
    Enhancement to the User model for admin-specific features:
    - Admin role hierarchy (Super Admin, Seller Manager, Price Manager, etc.)
    - Department/team assignment
    - Activity audit log tracking
    - Permission management
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
    
    class Meta:
        db_table = 'admin_users'
        verbose_name = 'Admin User'
        verbose_name_plural = 'Admin Users'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['admin_role']),
            models.Index(fields=['department']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.user.full_name} ({self.admin_role})"
    
    def __repr__(self):
        return f"<AdminUser: {self.user.email} | Role: {self.admin_role}>"


# ==================== SELLER APPROVAL WORKFLOW MODELS ====================

class SellerRegistrationRequest(models.Model):
    """
    Model for seller registration applications with complete workflow tracking.
    
    Tracks the entire seller approval process:
    - Initial application submission
    - Document verification
    - Admin decision (approve/reject/suspend)
    - Audit trail with decision reasons
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
    
    class Meta:
        db_table = 'seller_registration_requests'
        verbose_name = 'Seller Registration Request'
        verbose_name_plural = 'Seller Registration Requests'
        ordering = ['-submitted_at']
        indexes = [
            models.Index(fields=['seller_id']),
            models.Index(fields=['status']),
            models.Index(fields=['submitted_at']),
        ]
    
    def __str__(self):
        return f"Registration: {self.seller.full_name} - {self.status}"
    
    def __repr__(self):
        return f"<SellerRegistrationRequest: {self.seller.email} | Status: {self.status}>"


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
        ]
    
    def __str__(self):
        return f"Ceiling: {self.product.name} - {self.ceiling_price}"


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
    """
    
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
        help_text='The price listed by seller'
    )
    ceiling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='The ceiling price at time of violation'
    )
    overage_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        help_text='Percentage over ceiling'
    )
    
    # ==================== STATUS ====================
    status = models.CharField(
        max_length=20,
        choices=[
            ('NEW', 'New Violation'),
            ('WARNED', 'Warning Issued'),
            ('ADJUSTED', 'Price Adjusted'),
            ('SUSPENDED', 'Seller Suspended'),
            ('RESOLVED', 'Resolved'),
        ],
        default='NEW',
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
        ]
    
    def __str__(self):
        return f"Violation: {self.seller.full_name} - {self.product.name}"


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
        ]
    
    def __str__(self):
        return f"PO: {self.seller.full_name} - {self.product.name} ({self.status})"


class OPASInventory(models.Model):
    """
    Centralized OPAS stock management.
    
    Tracks:
    - Current inventory quantities
    - Storage locations
    - Expiration dates
    - Automatic low stock and expiry alerts
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
        help_text='Total quantity received into OPAS inventory'
    )
    quantity_on_hand = models.IntegerField(
        help_text='Current quantity available'
    )
    quantity_consumed = models.IntegerField(
        default=0,
        help_text='Quantity consumed/sold out'
    )
    quantity_spoiled = models.IntegerField(
        default=0,
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
    
    class Meta:
        db_table = 'opas_inventory'
        verbose_name = 'OPAS Inventory'
        verbose_name_plural = 'OPAS Inventory'
        ordering = ['expiry_date']
        indexes = [
            models.Index(fields=['product_id']),
            models.Index(fields=['quantity_on_hand']),
            models.Index(fields=['is_low_stock']),
            models.Index(fields=['expiry_date']),
        ]
    
    def __str__(self):
        return f"Inventory: {self.product.name} - {self.quantity_on_hand} units"


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
        ]
    
    def __str__(self):
        return f"Audit: {self.action_type} by {self.admin}"


class MarketplaceAlert(models.Model):
    """
    Flags and alerts for marketplace issues.
    
    Alert types:
    - Price violations
    - Seller issues
    - Unusual activity
    - Inventory problems
    """
    
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
        choices=[
            ('PRICE_VIOLATION', 'Price Violation'),
            ('SELLER_ISSUE', 'Seller Issue'),
            ('INVENTORY_ALERT', 'Inventory Alert'),
            ('UNUSUAL_ACTIVITY', 'Unusual Activity'),
            ('COMPLIANCE', 'Compliance Issue'),
        ],
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
        choices=[
            ('OPEN', 'Open'),
            ('ACKNOWLEDGED', 'Acknowledged'),
            ('RESOLVED', 'Resolved'),
        ],
        default='OPEN',
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
        ]
    
    def __str__(self):
        return f"Alert: {self.title} ({self.severity})"


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
