/// Admin Role Model for Phase 4.4: Admin Collaboration
/// Implements role-based access control with granular permissions
/// 
/// Architecture: Enum-based roles with permission bitmasks for scalability
/// Supports 5+ role types with 25+ permission types

// ignore_for_file: constant_identifier_names

/// Represents admin permission types with granular access control
enum AdminPermission {
  // Seller Management Permissions
  APPROVE_SELLER,
  REJECT_SELLER,
  SUSPEND_SELLER,
  REACTIVATE_SELLER,
  VIEW_SELLER_DETAILS,
  EDIT_SELLER_INFO,

  // Price Management Permissions
  VIEW_PRICE_CEILINGS,
  UPDATE_PRICE_CEILING,
  CREATE_PRICE_ADVISORY,
  DELETE_PRICE_ADVISORY,
  FLAG_PRICE_VIOLATION,

  // OPAS Management Permissions
  VIEW_OPAS_SUBMISSIONS,
  APPROVE_OPAS_SUBMISSION,
  REJECT_OPAS_SUBMISSION,
  MANAGE_OPAS_INVENTORY,
  ADJUST_OPAS_STOCK,

  // Marketplace Permissions
  VIEW_MARKETPLACE_LISTINGS,
  FLAG_LISTING,
  REMOVE_LISTING,
  VIEW_MARKETPLACE_ALERTS,

  // Analytics & Reporting Permissions
  VIEW_ANALYTICS,
  VIEW_REPORTS,
  EXPORT_DATA,
  GENERATE_CUSTOM_REPORT,

  // Notification & Announcement Permissions
  SEND_ANNOUNCEMENT,
  SEND_NOTIFICATION,
  MANAGE_ALERTS,

  // Collaboration Permissions
  ADD_ADMIN_NOTES,
  EDIT_OWN_NOTES,
  DELETE_OWN_NOTES,
  CREATE_DISCUSSION_THREAD,
  ADD_DISCUSSION_COMMENT,

  // Escalation Permissions
  CREATE_ESCALATION,
  HANDLE_ESCALATION,
  ASSIGN_ESCALATION,

  // Admin Management Permissions (Super Admin only)
  MANAGE_ADMINS,
  ASSIGN_ROLES,
  VIEW_AUDIT_LOG,
  MANAGE_SYSTEM_SETTINGS,
  APPROVE_HIGH_RISK_ACTIONS,
}

/// Represents admin role types with predefined permission sets
enum AdminRole {
  SUPER_ADMIN,
  SELLER_MANAGER,
  PRICE_MANAGER,
  OPAS_MANAGER,
  MARKETPLACE_MANAGER,
  ANALYTICS_MANAGER,
  SUPPORT_ADMIN,
}

/// Extension providing permission checks for each admin role
extension AdminRoleExtension on AdminRole {
  String get displayName {
    return name.split('_').map((part) {
      return '${part[0]}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String get description {
    switch (this) {
      case AdminRole.SUPER_ADMIN:
        return 'Full access to all features and user management';
      case AdminRole.SELLER_MANAGER:
        return 'Manage seller approvals, suspensions, and profiles';
      case AdminRole.PRICE_MANAGER:
        return 'Set price ceilings and manage price compliance';
      case AdminRole.OPAS_MANAGER:
        return 'Manage OPAS submissions and inventory';
      case AdminRole.MARKETPLACE_MANAGER:
        return 'Monitor marketplace listings and alerts';
      case AdminRole.ANALYTICS_MANAGER:
        return 'View analytics, reports, and market insights';
      case AdminRole.SUPPORT_ADMIN:
        return 'Send announcements and manage support tickets';
    }
  }

  /// Get set of permissions for this role
  Set<AdminPermission> get permissions {
    switch (this) {
      case AdminRole.SUPER_ADMIN:
        return Set.from(AdminPermission.values);

      case AdminRole.SELLER_MANAGER:
        return {
          AdminPermission.APPROVE_SELLER,
          AdminPermission.REJECT_SELLER,
          AdminPermission.SUSPEND_SELLER,
          AdminPermission.REACTIVATE_SELLER,
          AdminPermission.VIEW_SELLER_DETAILS,
          AdminPermission.EDIT_SELLER_INFO,
          AdminPermission.VIEW_ANALYTICS,
          AdminPermission.ADD_ADMIN_NOTES,
          AdminPermission.EDIT_OWN_NOTES,
          AdminPermission.DELETE_OWN_NOTES,
          AdminPermission.CREATE_DISCUSSION_THREAD,
          AdminPermission.ADD_DISCUSSION_COMMENT,
          AdminPermission.CREATE_ESCALATION,
          AdminPermission.HANDLE_ESCALATION,
          AdminPermission.SEND_NOTIFICATION,
        };

      case AdminRole.PRICE_MANAGER:
        return {
          AdminPermission.VIEW_PRICE_CEILINGS,
          AdminPermission.UPDATE_PRICE_CEILING,
          AdminPermission.CREATE_PRICE_ADVISORY,
          AdminPermission.DELETE_PRICE_ADVISORY,
          AdminPermission.FLAG_PRICE_VIOLATION,
          AdminPermission.VIEW_SELLER_DETAILS,
          AdminPermission.VIEW_ANALYTICS,
          AdminPermission.ADD_ADMIN_NOTES,
          AdminPermission.EDIT_OWN_NOTES,
          AdminPermission.DELETE_OWN_NOTES,
          AdminPermission.CREATE_DISCUSSION_THREAD,
          AdminPermission.ADD_DISCUSSION_COMMENT,
          AdminPermission.CREATE_ESCALATION,
          AdminPermission.SEND_ANNOUNCEMENT,
        };

      case AdminRole.OPAS_MANAGER:
        return {
          AdminPermission.VIEW_OPAS_SUBMISSIONS,
          AdminPermission.APPROVE_OPAS_SUBMISSION,
          AdminPermission.REJECT_OPAS_SUBMISSION,
          AdminPermission.MANAGE_OPAS_INVENTORY,
          AdminPermission.ADJUST_OPAS_STOCK,
          AdminPermission.VIEW_SELLER_DETAILS,
          AdminPermission.VIEW_ANALYTICS,
          AdminPermission.ADD_ADMIN_NOTES,
          AdminPermission.EDIT_OWN_NOTES,
          AdminPermission.DELETE_OWN_NOTES,
          AdminPermission.CREATE_DISCUSSION_THREAD,
          AdminPermission.ADD_DISCUSSION_COMMENT,
          AdminPermission.CREATE_ESCALATION,
          AdminPermission.HANDLE_ESCALATION,
          AdminPermission.SEND_NOTIFICATION,
        };

      case AdminRole.MARKETPLACE_MANAGER:
        return {
          AdminPermission.VIEW_MARKETPLACE_LISTINGS,
          AdminPermission.FLAG_LISTING,
          AdminPermission.REMOVE_LISTING,
          AdminPermission.VIEW_MARKETPLACE_ALERTS,
          AdminPermission.VIEW_SELLER_DETAILS,
          AdminPermission.VIEW_ANALYTICS,
          AdminPermission.ADD_ADMIN_NOTES,
          AdminPermission.EDIT_OWN_NOTES,
          AdminPermission.DELETE_OWN_NOTES,
          AdminPermission.CREATE_DISCUSSION_THREAD,
          AdminPermission.ADD_DISCUSSION_COMMENT,
          AdminPermission.CREATE_ESCALATION,
          AdminPermission.SEND_NOTIFICATION,
        };

      case AdminRole.ANALYTICS_MANAGER:
        return {
          AdminPermission.VIEW_ANALYTICS,
          AdminPermission.VIEW_REPORTS,
          AdminPermission.EXPORT_DATA,
          AdminPermission.GENERATE_CUSTOM_REPORT,
          AdminPermission.VIEW_SELLER_DETAILS,
          AdminPermission.ADD_ADMIN_NOTES,
          AdminPermission.EDIT_OWN_NOTES,
          AdminPermission.ADD_DISCUSSION_COMMENT,
        };

      case AdminRole.SUPPORT_ADMIN:
        return {
          AdminPermission.SEND_ANNOUNCEMENT,
          AdminPermission.SEND_NOTIFICATION,
          AdminPermission.MANAGE_ALERTS,
          AdminPermission.VIEW_SELLER_DETAILS,
          AdminPermission.ADD_ADMIN_NOTES,
          AdminPermission.EDIT_OWN_NOTES,
          AdminPermission.ADD_DISCUSSION_COMMENT,
        };
    }
  }

  /// Check if this role has a specific permission
  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission);
  }

  /// Check if this role has all of the specified permissions
  bool hasAllPermissions(Set<AdminPermission> requiredPermissions) {
    return requiredPermissions.every((perm) => hasPermission(perm));
  }

  /// Check if this role has any of the specified permissions
  bool hasAnyPermission(Set<AdminPermission> requiredPermissions) {
    return requiredPermissions.any((perm) => hasPermission(perm));
  }
}

/// Admin user profile with role and permissions
class AdminUserProfile {
  final String adminId;
  final String name;
  final String email;
  final AdminRole role;
  final DateTime assignedAt;
  final String? department;
  final String? phoneNumber;
  final bool isActive;
  final DateTime? lastActiveAt;

  AdminUserProfile({
    required this.adminId,
    required this.name,
    required this.email,
    required this.role,
    required this.assignedAt,
    this.department,
    this.phoneNumber,
    this.isActive = true,
    this.lastActiveAt,
  });

  /// Check if admin has a specific permission
  bool hasPermission(AdminPermission permission) {
    if (!isActive) return false;
    return role.hasPermission(permission);
  }

  /// Get all permissions for this admin
  Set<AdminPermission> get permissions => role.permissions;

  /// Create a copy with updated fields
  AdminUserProfile copyWith({
    String? adminId,
    String? name,
    String? email,
    AdminRole? role,
    DateTime? assignedAt,
    String? department,
    String? phoneNumber,
    bool? isActive,
    DateTime? lastActiveAt,
  }) {
    return AdminUserProfile(
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'adminId': adminId,
    'name': name,
    'email': email,
    'role': role.name,
    'assignedAt': assignedAt.toIso8601String(),
    'department': department,
    'phoneNumber': phoneNumber,
    'isActive': isActive,
    'lastActiveAt': lastActiveAt?.toIso8601String(),
  };

  /// Create from JSON response
  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      adminId: json['adminId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: AdminRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => AdminRole.SUPPORT_ADMIN,
      ),
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      department: json['department'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }
}

/// Helper class for permission validation
class PermissionValidator {
  /// Validate if admin can perform an action
  static bool canPerformAction({
    required AdminUserProfile admin,
    required AdminPermission requiredPermission,
  }) {
    return admin.hasPermission(requiredPermission);
  }

  /// Validate if admin can perform multiple actions
  static bool canPerformActions({
    required AdminUserProfile admin,
    required Set<AdminPermission> requiredPermissions,
    bool requireAll = true,
  }) {
    if (requireAll) {
      return requiredPermissions.every((perm) => admin.hasPermission(perm));
    } else {
      return requiredPermissions.any((perm) => admin.hasPermission(perm));
    }
  }

  /// Get permissions missing from admin's role
  static Set<AdminPermission> getMissingPermissions({
    required AdminUserProfile admin,
    required Set<AdminPermission> requiredPermissions,
  }) {
    return requiredPermissions
        .where((perm) => !admin.hasPermission(perm))
        .toSet();
  }

  /// Get human-readable permission name
  static String getPermissionName(AdminPermission permission) {
    return permission.name.split('_').map((part) {
      return '${part[0]}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
