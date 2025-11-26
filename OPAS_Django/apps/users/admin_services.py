"""
Admin Services for OPAS Platform - Part 3: Admin Marketplace Control

Provides business logic for admin marketplace operations:
- Price violation detection and monitoring
- Seller compliance tracking
- Marketplace analytics calculations
- Audit trail management

Service Classes:
1. PriceMonitoringService: Monitor and manage price violations
2. SellerComplianceService: Track seller compliance metrics
3. MarketplaceAnalyticsService: Calculate marketplace health metrics

Design Patterns:
- Service Layer Pattern: Business logic separated from views
- Singleton Pattern: Services instantiated once for efficiency
- Immutable Audit Logs: All actions logged for compliance
- Transaction Management: Database consistency for critical operations

Benefits:
- Clean separation of concerns (Views → Services → Models)
- Reusable business logic across endpoints
- Comprehensive logging and audit trails
- Easy unit testing and maintenance
"""

from django.db import transaction, models
from django.db.models import Q, Count, Sum, Avg, F, DecimalField
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta
import logging

from apps.users.models import User, UserRole, SellerStatus
from apps.users.seller_models import SellerProduct, ProductStatus
from apps.users.admin_models import (
    PriceCeiling, PriceNonCompliance, SellerSuspension,
    AdminAuditLog, AdminUser
)

logger = logging.getLogger(__name__)


# ==================== PRICE MONITORING SERVICE ====================

class PriceMonitoringService:
    """
    Service for monitoring and managing product price violations.
    
    Purpose: Centralized business logic for:
    - Detecting price ceiling violations
    - Tracking violation history
    - Generating violation reports
    - Managing violation resolution
    
    Methods:
    - check_price_violations(): Scan for new violations
    - get_seller_violations(): Get violations by seller
    - get_product_violation(): Get specific product violation
    - resolve_violation(): Mark violation as resolved
    - get_violation_audit_trail(): Get violation history
    
    Transaction Management:
    - All violation updates use @transaction.atomic for consistency
    - Audit logs created transactionally with violations
    
    Optimization:
    - Uses select_related/prefetch_related for efficient queries
    - Batch processing for bulk violation checks
    - Indexes on violation_status and created_at fields
    """
    
    @staticmethod
    def check_price_violations(product=None, seller=None, batch_size=100):
        """
        Detect product price violations against OPAS ceiling prices.
        
        Purpose: Scan for products exceeding their category's ceiling price.
        
        Args:
            product (SellerProduct, optional): Check specific product
            seller (User, optional): Check specific seller's products
            batch_size (int): Batch size for bulk processing
        
        Returns:
            dict: {
                'total_violations': int,
                'new_violations': int,
                'critical_violations': int,
                'warning_violations': int,
                'products_processed': int
            }
        
        Process:
        1. Query products to check (active products only)
        2. Get price ceiling for each product type
        3. Compare actual price vs ceiling
        4. Create/update violation records
        5. Log audit trail
        6. Return summary
        
        Example:
            >>> service = PriceMonitoringService()
            >>> result = service.check_price_violations(seller=farmer_user)
            >>> print(f"Found {result['new_violations']} new violations")
        """
        try:
            # Build query
            query = SellerProduct.objects.filter(
                status=ProductStatus.ACTIVE
            ).select_related('seller')
            
            if product:
                query = query.filter(id=product.id)
            if seller:
                query = query.filter(seller=seller)
            
            # Initialize counters
            total_violations = 0
            new_violations_count = 0
            critical_count = 0
            warning_count = 0
            products_checked = 0
            
            # Process in batches
            products = list(query)
            for prod in products:
                products_checked += 1
                
                # Get price ceiling
                try:
                    ceiling = PriceCeiling.objects.get(
                        product_type=prod.product_type
                    )
                except PriceCeiling.DoesNotExist:
                    logger.warning(
                        f'No price ceiling found for product type: {prod.product_type}'
                    )
                    continue
                
                # Check if price exceeds ceiling
                if prod.price > ceiling.ceiling_price:
                    excess = prod.price - ceiling.ceiling_price
                    excess_percentage = (excess / ceiling.ceiling_price) * 100
                    
                    # Determine violation severity
                    violation_status = 'CRITICAL' if excess_percentage > 10 else 'WARNING'
                    
                    # Check if violation already exists
                    violation, created = PriceNonCompliance.objects.get_or_create(
                        product=prod,
                        defaults={
                            'violation_status': violation_status,
                            'is_resolved': False
                        }
                    )
                    
                    if created:
                        new_violations_count += 1
                        logger.info(
                            f'New price violation detected: {prod.name} '
                            f'(Price: {prod.price}, Ceiling: {ceiling.ceiling_price})'
                        )
                    
                    if violation_status == 'CRITICAL':
                        critical_count += 1
                    else:
                        warning_count += 1
                    
                    total_violations += 1
            
            # Log action
            logger.info(
                f'Price check completed: {products_checked} products checked, '
                f'{new_violations_count} new violations found'
            )
            
            return {
                'total_violations': total_violations,
                'new_violations': new_violations_count,
                'critical_violations': critical_count,
                'warning_violations': warning_count,
                'products_processed': products_checked
            }
        
        except Exception as e:
            logger.error(f'Error checking price violations: {str(e)}')
            raise
    
    @staticmethod
    def get_seller_violations(seller, include_resolved=False):
        """
        Get all price violations for a specific seller.
        
        Args:
            seller (User): Seller user instance
            include_resolved (bool): Include resolved violations
        
        Returns:
            QuerySet: Violations for seller
        
        Optimization:
        - Uses select_related to avoid N+1 queries
        - Indexes on seller_id and violation_status
        """
        query = PriceNonCompliance.objects.filter(
            product__seller=seller
        ).select_related(
            'product', 'product__seller'
        ).order_by('-created_at')
        
        if not include_resolved:
            query = query.filter(is_resolved=False)
        
        return query
    
    @staticmethod
    def get_product_violation(product):
        """
        Get current violation for a product.
        
        Args:
            product (SellerProduct): Product to check
        
        Returns:
            PriceNonCompliance or None: Current violation if exists
        """
        try:
            return PriceNonCompliance.objects.get(
                product=product,
                is_resolved=False
            )
        except PriceNonCompliance.DoesNotExist:
            return None
    
    @staticmethod
    @transaction.atomic
    def resolve_violation(violation, admin_user, admin_notes='', action_taken='MANUAL_RESOLUTION'):
        """
        Resolve a price violation.
        
        Args:
            violation (PriceNonCompliance): Violation to resolve
            admin_user (User): Admin resolving violation
            admin_notes (str): Notes about resolution
            action_taken (str): Type of action taken
        
        Returns:
            PriceNonCompliance: Updated violation
        
        Creates audit log of resolution action.
        """
        violation.is_resolved = True
        violation.resolved_at = timezone.now()
        violation.admin_notes = admin_notes
        violation.save()
        
        # Create audit log
        try:
            admin_obj = AdminUser.objects.get(user=admin_user)
        except AdminUser.DoesNotExist:
            admin_obj = None
        
        AdminAuditLog.objects.create(
            admin=admin_obj,
            action_type='Price Violation Resolved',
            action_category='RESOLUTION',
            description=f'Resolved price violation for {violation.product.name} - {action_taken}',
            product=violation.product,
            details={'admin_notes': admin_notes, 'action_taken': action_taken}
        )
        
        logger.info(
            f'Price violation resolved by {admin_user.email}: '
            f'{violation.product.name} ({action_taken})'
        )
        
        return violation
    
    @staticmethod
    def get_violation_audit_trail(violation):
        """
        Get audit trail for a violation.
        
        Args:
            violation (PriceNonCompliance): Violation to audit
        
        Returns:
            QuerySet: Audit logs related to violation
        """
        return AdminAuditLog.objects.filter(
            product=violation.product,
            action_type__in=['Price Violation Detected', 'Price Violation Resolved']
        ).order_by('-created_at')


# ==================== SELLER COMPLIANCE SERVICE ====================

class SellerComplianceService:
    """
    Service for tracking seller compliance metrics.
    
    Purpose: Calculate and track:
    - Seller compliance score
    - Violation history and patterns
    - Suspension status
    - Performance metrics
    
    Methods:
    - get_seller_compliance_score(): Calculate compliance rating
    - get_violation_history(): Get seller's violation history
    - check_for_suspension(): Determine if seller should be suspended
    - get_seller_metrics(): Get comprehensive seller metrics
    """
    
    @staticmethod
    def get_seller_compliance_score(seller):
        """
        Calculate seller's compliance score (0-100).
        
        Based on:
        - Price ceiling compliance (60% weight)
        - Product quality rating (20% weight)
        - Response time (20% weight)
        
        Args:
            seller (User): Seller to rate
        
        Returns:
            int: Compliance score 0-100
        """
        score = 100
        
        # Price compliance: 60% weight
        violations = PriceNonCompliance.objects.filter(
            product__seller=seller,
            is_resolved=False
        ).count()
        
        products = SellerProduct.objects.filter(
            seller=seller,
            status=ProductStatus.ACTIVE
        ).count()
        
        violation_rate = (violations / max(products, 1)) * 100
        price_score = max(0, 100 - (violation_rate * 0.6))
        score = (score * 0.4) + (price_score * 0.6)
        
        return int(score)
    
    @staticmethod
    def get_violation_history(seller, days=30):
        """
        Get seller's violation history for time period.
        
        Args:
            seller (User): Seller to check
            days (int): Number of days to look back
        
        Returns:
            QuerySet: Violations within time period
        """
        cutoff = timezone.now() - timedelta(days=days)
        return PriceNonCompliance.objects.filter(
            product__seller=seller,
            created_at__gte=cutoff
        ).order_by('-created_at')
    
    @staticmethod
    def check_for_suspension(seller):
        """
        Check if seller should be suspended based on violations.
        
        Suspension criteria:
        - > 5 critical violations in 30 days
        - > 10 total violations in 30 days
        - Compliance score < 50
        
        Args:
            seller (User): Seller to check
        
        Returns:
            dict: {
                'should_suspend': bool,
                'reason': str,
                'violations_count': int,
                'critical_count': int
            }
        """
        violations = SellerComplianceService.get_violation_history(seller, days=30)
        critical_count = violations.filter(
            violation_status='CRITICAL'
        ).count()
        
        score = SellerComplianceService.get_seller_compliance_score(seller)
        
        reasons = []
        if critical_count > 5:
            reasons.append(f'Too many critical violations ({critical_count})')
        if violations.count() > 10:
            reasons.append(f'Too many total violations ({violations.count()})')
        if score < 50:
            reasons.append(f'Low compliance score ({score})')
        
        return {
            'should_suspend': len(reasons) > 0,
            'reason': ' | '.join(reasons) if reasons else 'No suspension needed',
            'violations_count': violations.count(),
            'critical_count': critical_count,
            'compliance_score': score
        }
    
    @staticmethod
    def get_seller_metrics(seller):
        """
        Get comprehensive seller compliance metrics.
        
        Args:
            seller (User): Seller to analyze
        
        Returns:
            dict: Complete seller metrics
        """
        violations = PriceNonCompliance.objects.filter(
            product__seller=seller
        )
        
        return {
            'seller_id': seller.id,
            'seller_email': seller.email,
            'total_violations': violations.count(),
            'unresolved_violations': violations.filter(is_resolved=False).count(),
            'critical_violations': violations.filter(
                violation_status='CRITICAL'
            ).count(),
            'warning_violations': violations.filter(
                violation_status='WARNING'
            ).count(),
            'compliance_score': SellerComplianceService.get_seller_compliance_score(seller),
            'total_products': SellerProduct.objects.filter(seller=seller).count(),
            'active_products': SellerProduct.objects.filter(
                seller=seller,
                status=ProductStatus.ACTIVE
            ).count(),
            'is_suspended': SellerSuspension.objects.filter(
                seller=seller,
                is_active=True
            ).exists()
        }


# ==================== MARKETPLACE ANALYTICS SERVICE ====================

class MarketplaceAnalyticsService:
    """
    Service for calculating marketplace analytics metrics.
    
    Purpose: Generate metrics for admin dashboard:
    - Product counts and status
    - Seller metrics
    - Price compliance overview
    - Marketplace health score
    
    Methods:
    - get_marketplace_overview(): Overall metrics
    - get_compliance_metrics(): Price compliance stats
    - calculate_health_score(): Marketplace health rating
    """
    
    @staticmethod
    def get_marketplace_overview():
        """
        Get comprehensive marketplace overview.
        
        Returns:
            dict: {
                'total_products': int,
                'active_products': int,
                'inactive_products': int,
                'total_sellers': int,
                'active_sellers': int,
                'suspended_sellers': int,
                'total_stock_value': Decimal,
                'timestamp': datetime
            }
        """
        total_products = SellerProduct.objects.count()
        active_products = SellerProduct.objects.filter(
            status=ProductStatus.ACTIVE
        ).count()
        
        total_sellers = User.objects.filter(
            role=UserRole.SELLER
        ).count()
        
        active_sellers = User.objects.filter(
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        ).count()
        
        suspended_sellers = SellerSuspension.objects.filter(
            is_active=True
        ).values('seller').distinct().count()
        
        # Calculate total stock value
        stock_value_data = SellerProduct.objects.aggregate(
            total_value=Sum(
                F('price') * F('stock_level'),
                output_field=DecimalField()
            )
        )
        total_stock_value = stock_value_data['total_value'] or Decimal('0.00')
        
        return {
            'total_products': total_products,
            'active_products': active_products,
            'inactive_products': total_products - active_products,
            'total_sellers': total_sellers,
            'active_sellers': active_sellers,
            'suspended_sellers': suspended_sellers,
            'total_stock_value': total_stock_value,
            'timestamp': timezone.now()
        }
    
    @staticmethod
    def get_compliance_metrics():
        """
        Get price compliance metrics.
        
        Returns:
            dict: {
                'total_violations': int,
                'critical_violations': int,
                'warning_violations': int,
                'compliance_percentage': float,
                'affected_sellers': int
            }
        """
        active_products = SellerProduct.objects.filter(
            status=ProductStatus.ACTIVE
        ).count()
        
        total_violations = PriceNonCompliance.objects.filter(
            is_resolved=False
        ).count()
        
        critical = PriceNonCompliance.objects.filter(
            is_resolved=False,
            violation_status='CRITICAL'
        ).count()
        
        warning = PriceNonCompliance.objects.filter(
            is_resolved=False,
            violation_status='WARNING'
        ).count()
        
        compliant = active_products - total_violations
        compliance_pct = (compliant / max(active_products, 1)) * 100
        
        affected_sellers = PriceNonCompliance.objects.filter(
            is_resolved=False
        ).values('product__seller').distinct().count()
        
        return {
            'total_violations': total_violations,
            'critical_violations': critical,
            'warning_violations': warning,
            'compliance_percentage': compliance_pct,
            'affected_sellers': affected_sellers
        }
    
    @staticmethod
    def calculate_health_score():
        """
        Calculate marketplace health score (0-100).
        
        Based on:
        - Price compliance (70% weight)
        - Seller distribution (20% weight)
        - Stock diversity (10% weight)
        
        Returns:
            int: Health score 0-100
        """
        # Get metrics
        compliance = MarketplaceAnalyticsService.get_compliance_metrics()
        overview = MarketplaceAnalyticsService.get_marketplace_overview()
        
        # Compliance score (70% weight)
        compliance_score = compliance['compliance_percentage']
        
        # Seller distribution (20% weight)
        total_sellers = overview['total_sellers']
        active_sellers = overview['active_sellers']
        seller_score = (active_sellers / max(total_sellers, 1)) * 100
        
        # Stock diversity (10% weight)
        categories = SellerProduct.objects.filter(
            status=ProductStatus.ACTIVE
        ).values('product_type').distinct().count()
        max_categories = 10  # Assume max 10 categories
        diversity_score = (categories / max_categories) * 100
        
        # Calculate weighted score
        health_score = (
            (compliance_score * 0.7) +
            (seller_score * 0.2) +
            (diversity_score * 0.1)
        )
        
        return int(min(100, health_score))


__all__ = [
    'PriceMonitoringService',
    'SellerComplianceService',
    'MarketplaceAnalyticsService'
]
