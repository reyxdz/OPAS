"""
Admin permission classes for OPAS platform.

Custom permission classes for fine-grained role-based access control.
"""

from rest_framework import permissions
from apps.users.admin_models import AdminUser


# ==================== BASE PERMISSIONS ====================

class IsAdmin(permissions.BasePermission):
    """
    Permission check: User must be an admin.
    """
    message = "You do not have permission to perform this action. Admin access required."
    
    def has_permission(self, request, view):
        """Check if user is an admin."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            return admin_user.is_active
        except AdminUser.DoesNotExist:
            return False


class IsSuperAdmin(permissions.BasePermission):
    """
    Permission check: User must be a Super Admin.
    """
    message = "Super Admin access required for this operation."
    
    def has_permission(self, request, view):
        """Check if user is a super admin."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            return admin_user.admin_role == 'SUPER_ADMIN' and admin_user.is_active
        except AdminUser.DoesNotExist:
            return False


# ==================== ROLE-BASED PERMISSIONS ====================

class CanApproveSellers(permissions.BasePermission):
    """
    Permission check: User can approve/reject/suspend sellers.
    Required roles: Super Admin, Seller Manager
    """
    message = "You do not have permission to approve/reject sellers. Seller Manager role required."
    
    def has_permission(self, request, view):
        """Check if user has seller approval permissions."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            # Super Admin and Seller Manager can approve sellers
            allowed_roles = ['SUPER_ADMIN', 'SELLER_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanManagePrices(permissions.BasePermission):
    """
    Permission check: User can manage price ceilings and advisories.
    Required roles: Super Admin, Price Manager
    """
    message = "You do not have permission to manage prices. Price Manager role required."
    
    def has_permission(self, request, view):
        """Check if user has price management permissions."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            # Super Admin and Price Manager can manage prices
            allowed_roles = ['SUPER_ADMIN', 'PRICE_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanManageOPAS(permissions.BasePermission):
    """
    Permission check: User can manage OPAS submissions and inventory.
    Required roles: Super Admin, OPAS Manager
    """
    message = "You do not have permission to manage OPAS. OPAS Manager role required."
    
    def has_permission(self, request, view):
        """Check if user has OPAS management permissions."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            # Super Admin and OPAS Manager can manage OPAS
            allowed_roles = ['SUPER_ADMIN', 'OPAS_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanMonitorMarketplace(permissions.BasePermission):
    """
    Permission check: User can monitor and manage marketplace.
    Required roles: Super Admin, Marketplace Monitor
    """
    message = "You do not have permission to monitor marketplace. Marketplace Monitor role required."
    
    def has_permission(self, request, view):
        """Check if user can monitor marketplace."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            # Super Admin and Marketplace Monitor can monitor
            allowed_roles = ['SUPER_ADMIN', 'MARKETPLACE_MONITOR']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanViewAnalytics(permissions.BasePermission):
    """
    Permission check: User can view analytics and reports.
    Required roles: Super Admin, Analytics Manager
    """
    message = "You do not have permission to view analytics. Analytics Manager role required."
    
    def has_permission(self, request, view):
        """Check if user can view analytics."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            # Super Admin and Analytics Manager can view analytics
            allowed_roles = ['SUPER_ADMIN', 'ANALYTICS_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanManageNotifications(permissions.BasePermission):
    """
    Permission check: User can create and manage notifications/announcements.
    Required roles: Super Admin, Support Admin
    """
    message = "You do not have permission to manage notifications. Support Admin role required."
    
    def has_permission(self, request, view):
        """Check if user can manage notifications."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            # Super Admin and Support Admin can manage notifications
            allowed_roles = ['SUPER_ADMIN', 'SUPPORT_ADMIN']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


# ==================== READ-ONLY PERMISSIONS ====================

class CanViewAdminData(permissions.BasePermission):
    """
    Permission check: User can view admin data (read-only).
    Required roles: Any active admin role
    """
    message = "You do not have permission to view admin data. Admin access required."
    
    def has_permission(self, request, view):
        """Check if request is GET/HEAD/OPTIONS (safe methods)."""
        if request.method in permissions.SAFE_METHODS:
            if not request.user or not request.user.is_authenticated:
                return False
            try:
                admin_user = AdminUser.objects.get(user=request.user)
                return admin_user.is_active
            except AdminUser.DoesNotExist:
                return False
        return False


class CanViewAuditLog(permissions.BasePermission):
    """
    Permission check: User can view audit logs.
    Required roles: Super Admin, any admin that can review actions
    """
    message = "You do not have permission to view audit logs. Super Admin or Manager role required."
    
    def has_permission(self, request, view):
        """Check if user can view audit logs."""
        if request.method in permissions.SAFE_METHODS:
            if not request.user or not request.user.is_authenticated:
                return False
            try:
                admin_user = AdminUser.objects.get(user=request.user)
                if not admin_user.is_active:
                    return False
                # Super Admin and manager-level roles can view audit logs
                manager_roles = ['SUPER_ADMIN', 'SELLER_MANAGER', 'PRICE_MANAGER', 
                               'OPAS_MANAGER', 'ANALYTICS_MANAGER', 'MARKETPLACE_MONITOR']
                return admin_user.admin_role in manager_roles
            except AdminUser.DoesNotExist:
                return False
        return False


# ==================== COMBINED PERMISSIONS ====================

class IsAdminAndCanApproveSellers(permissions.BasePermission):
    """
    Combined permission: Must be admin AND have seller approval permission.
    """
    message = "Insufficient permissions. Super Admin or Seller Manager access required."
    
    def has_permission(self, request, view):
        """Check both IsAdmin and CanApproveSellers."""
        is_admin = IsAdmin()
        can_approve = CanApproveSellers()
        return is_admin.has_permission(request, view) and can_approve.has_permission(request, view)


class IsAdminAndCanManagePrices(permissions.BasePermission):
    """
    Combined permission: Must be admin AND have price management permission.
    """
    message = "Insufficient permissions. Super Admin or Price Manager access required."
    
    def has_permission(self, request, view):
        """Check both IsAdmin and CanManagePrices."""
        is_admin = IsAdmin()
        can_manage = CanManagePrices()
        return is_admin.has_permission(request, view) and can_manage.has_permission(request, view)


class IsAdminAndCanManageOPAS(permissions.BasePermission):
    """
    Combined permission: Must be admin AND have OPAS management permission.
    """
    message = "Insufficient permissions. Super Admin or OPAS Manager access required."
    
    def has_permission(self, request, view):
        """Check both IsAdmin and CanManageOPAS."""
        is_admin = IsAdmin()
        can_manage = CanManageOPAS()
        return is_admin.has_permission(request, view) and can_manage.has_permission(request, view)


class IsAdminAndCanMonitorMarketplace(permissions.BasePermission):
    """
    Combined permission: Must be admin AND have marketplace monitoring permission.
    """
    message = "Insufficient permissions. Super Admin or Marketplace Monitor access required."
    
    def has_permission(self, request, view):
        """Check both IsAdmin and CanMonitorMarketplace."""
        is_admin = IsAdmin()
        can_monitor = CanMonitorMarketplace()
        return is_admin.has_permission(request, view) and can_monitor.has_permission(request, view)


class IsAdminAndCanViewAnalytics(permissions.BasePermission):
    """
    Combined permission: Must be admin AND have analytics viewing permission.
    """
    message = "Insufficient permissions. Super Admin or Analytics Manager access required."
    
    def has_permission(self, request, view):
        """Check both IsAdmin and CanViewAnalytics."""
        is_admin = IsAdmin()
        can_view = CanViewAnalytics()
        return is_admin.has_permission(request, view) and can_view.has_permission(request, view)


class IsAdminAndCanManageNotifications(permissions.BasePermission):
    """
    Combined permission: Must be admin AND have notification management permission.
    """
    message = "Insufficient permissions. Super Admin or Support Admin access required."
    
    def has_permission(self, request, view):
        """Check both IsAdmin and CanManageNotifications."""
        is_admin = IsAdmin()
        can_manage = CanManageNotifications()
        return is_admin.has_permission(request, view) and can_manage.has_permission(request, view)


# ==================== ADDITIONAL PERMISSIONS ====================

class IsActiveAdmin(permissions.BasePermission):
    """
    Permission check: User must be an active admin account.
    Specifically checks that admin status is active (not disabled).
    """
    message = "This admin account is not active. Contact Super Admin."
    
    def has_permission(self, request, view):
        """Check if admin account is active."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            return admin_user.is_active
        except AdminUser.DoesNotExist:
            return False


class CanViewSellerDetails(permissions.BasePermission):
    """
    Permission check: User can view detailed seller information.
    Required roles: Super Admin, Seller Manager, Analytics Manager
    """
    message = "You do not have permission to view seller details."
    
    def has_permission(self, request, view):
        """Check if user can view seller details."""
        if request.method not in permissions.SAFE_METHODS:
            return False
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
    """
    Permission check: User can edit seller information.
    Required roles: Super Admin, Seller Manager
    """
    message = "You do not have permission to edit seller information. Seller Manager role required."
    
    def has_permission(self, request, view):
        """Check if user can edit seller info."""
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
    """
    Permission check: User can view compliance and audit reports.
    Required roles: Super Admin, Analytics Manager, Marketplace Monitor
    """
    message = "You do not have permission to view compliance reports."
    
    def has_permission(self, request, view):
        """Check if user can view compliance reports."""
        if request.method not in permissions.SAFE_METHODS:
            return False
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'ANALYTICS_MANAGER', 'MARKETPLACE_MONITOR']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanExportData(permissions.BasePermission):
    """
    Permission check: User can export data (CSV, JSON, etc.).
    Required roles: Super Admin, Analytics Manager
    """
    message = "You do not have permission to export data. Analytics Manager role required."
    
    def has_permission(self, request, view):
        """Check if user can export data."""
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


class CanAccessAuditLogs(permissions.BasePermission):
    """
    Permission check: User can access and search audit logs.
    Required roles: Super Admin, Compliance Manager
    """
    message = "You do not have permission to access audit logs."
    
    def has_permission(self, request, view):
        """Check if user can access audit logs."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'COMPLIANCE_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


class CanBroadcastAnnouncements(permissions.BasePermission):
    """
    Permission check: User can create and broadcast announcements.
    Required roles: Super Admin, Support Admin
    """
    message = "You do not have permission to broadcast announcements. Support Admin role required."
    
    def has_permission(self, request, view):
        """Check if user can broadcast announcements."""
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
    """
    Permission check: User can moderate and resolve marketplace alerts.
    Required roles: Super Admin, Marketplace Monitor, Compliance Manager
    """
    message = "You do not have permission to moderate alerts. Marketplace Monitor role required."
    
    def has_permission(self, request, view):
        """Check if user can moderate alerts."""
        if not request.user or not request.user.is_authenticated:
            return False
        try:
            admin_user = AdminUser.objects.get(user=request.user)
            if not admin_user.is_active:
                return False
            allowed_roles = ['SUPER_ADMIN', 'MARKETPLACE_MONITOR', 'COMPLIANCE_MANAGER']
            return admin_user.admin_role in allowed_roles
        except AdminUser.DoesNotExist:
            return False


__all__ = [
    'IsAdmin',
    'IsSuperAdmin',
    'IsActiveAdmin',
    'CanApproveSellers',
    'CanManagePrices',
    'CanManageOPAS',
    'CanMonitorMarketplace',
    'CanViewAnalytics',
    'CanManageNotifications',
    'CanViewAdminData',
    'CanViewAuditLog',
    'CanViewSellerDetails',
    'CanEditSellerInfo',
    'CanViewComplianceReports',
    'CanExportData',
    'CanAccessAuditLogs',
    'CanBroadcastAnnouncements',
    'CanModerateAlerts',
    'IsAdminAndCanApproveSellers',
    'IsAdminAndCanManagePrices',
    'IsAdminAndCanManageOPAS',
    'IsAdminAndCanMonitorMarketplace',
    'IsAdminAndCanViewAnalytics',
    'IsAdminAndCanManageNotifications',
]
