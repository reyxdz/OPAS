/// AdminRole Integration Helper for Phase 4.4: Admin Collaboration
/// Permission validation utilities and decorators for AdminService
/// 
/// Architecture: Reusable permission checking helpers
/// Features: Permission validation, error handling, audit logging

import 'package:opas_flutter/core/services/logger_service.dart';
import 'package:opas_flutter/features/admin_panel/models/admin_role_model.dart';

/// Exception thrown when permission is denied
class PermissionDeniedException implements Exception {
  final String message;
  final AdminPermission requiredPermission;

  PermissionDeniedException({
    required this.message,
    required this.requiredPermission,
  });

  @override
  String toString() => 'PermissionDenied: $message';
}

/// Helper class for permission-aware actions
class PermissionAwareAction {
  final AdminUserProfile admin;
  final AdminPermission requiredPermission;
  final String actionDescription;
  final String entityType;
  final String entityId;

  PermissionAwareAction({
    required this.admin,
    required this.requiredPermission,
    required this.actionDescription,
    required this.entityType,
    required this.entityId,
  });

  /// Validate permission and execute action
  Future<T> executeIfAllowed<T>(
    Future<T> Function() action,
  ) async {
    try {
      // Check permission
      if (!admin.hasPermission(requiredPermission)) {
        final missingPerm = PermissionValidator.getPermissionName(
          requiredPermission,
        );
        LoggerService.warning(
          'Permission denied for ${admin.name}: $missingPerm on $entityType:$entityId',
        );
        throw PermissionDeniedException(
          message:
              '${admin.name} lacks permission: $missingPerm for $actionDescription',
          requiredPermission: requiredPermission,
        );
      }

      // Log attempt
      LoggerService.info(
        '${admin.name} (${admin.role.displayName}) executing: $actionDescription on $entityType:$entityId',
      );

      // Execute action
      final result = await action();

      // Log success
      LoggerService.info(
        'Action successful: $actionDescription by ${admin.name}',
      );

      return result;
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      LoggerService.error('Action failed: $actionDescription - $e');
      rethrow;
    }
  }

  /// Synchronous permission check without execution
  void validatePermission() {
    if (!admin.hasPermission(requiredPermission)) {
      final missingPerm =
          PermissionValidator.getPermissionName(requiredPermission);
      throw PermissionDeniedException(
        message:
            '${admin.name} lacks permission: $missingPerm for $actionDescription',
        requiredPermission: requiredPermission,
      );
    }
  }
}

/// Reusable permission validators for common admin operations
class AdminOperationValidator {
  /// Validate seller management operations
  static void validateSellerManagement({
    required AdminUserProfile admin,
    required SellerManagementOperation operation,
  }) {
    final permission = _getSellerManagementPermission(operation);
    if (!admin.hasPermission(permission)) {
      throw PermissionDeniedException(
        message:
            'Insufficient permissions for seller operation: ${operation.name}',
        requiredPermission: permission,
      );
    }
  }

  /// Validate price management operations
  static void validatePriceManagement({
    required AdminUserProfile admin,
    required PriceManagementOperation operation,
  }) {
    final permission = _getPriceManagementPermission(operation);
    if (!admin.hasPermission(permission)) {
      throw PermissionDeniedException(
        message:
            'Insufficient permissions for price operation: ${operation.name}',
        requiredPermission: permission,
      );
    }
  }

  /// Validate OPAS operations
  static void validateOPASManagement({
    required AdminUserProfile admin,
    required OPASManagementOperation operation,
  }) {
    final permission = _getOPASManagementPermission(operation);
    if (!admin.hasPermission(permission)) {
      throw PermissionDeniedException(
        message:
            'Insufficient permissions for OPAS operation: ${operation.name}',
        requiredPermission: permission,
      );
    }
  }

  /// Validate escalation operations
  static void validateEscalationManagement({
    required AdminUserProfile admin,
    required EscalationManagementOperation operation,
  }) {
    final permission = _getEscalationManagementPermission(operation);
    if (!admin.hasPermission(permission)) {
      throw PermissionDeniedException(
        message:
            'Insufficient permissions for escalation operation: ${operation.name}',
        requiredPermission: permission,
      );
    }
  }

  // Helper methods to get required permissions
  static AdminPermission _getSellerManagementPermission(
    SellerManagementOperation operation,
  ) {
    switch (operation) {
      case SellerManagementOperation.approve:
        return AdminPermission.APPROVE_SELLER;
      case SellerManagementOperation.reject:
        return AdminPermission.REJECT_SELLER;
      case SellerManagementOperation.suspend:
        return AdminPermission.SUSPEND_SELLER;
      case SellerManagementOperation.reactivate:
        return AdminPermission.REACTIVATE_SELLER;
      case SellerManagementOperation.view:
        return AdminPermission.VIEW_SELLER_DETAILS;
      case SellerManagementOperation.edit:
        return AdminPermission.EDIT_SELLER_INFO;
    }
  }

  static AdminPermission _getPriceManagementPermission(
    PriceManagementOperation operation,
  ) {
    switch (operation) {
      case PriceManagementOperation.view:
        return AdminPermission.VIEW_PRICE_CEILINGS;
      case PriceManagementOperation.update:
        return AdminPermission.UPDATE_PRICE_CEILING;
      case PriceManagementOperation.flagViolation:
        return AdminPermission.FLAG_PRICE_VIOLATION;
    }
  }

  static AdminPermission _getOPASManagementPermission(
    OPASManagementOperation operation,
  ) {
    switch (operation) {
      case OPASManagementOperation.view:
        return AdminPermission.VIEW_OPAS_SUBMISSIONS;
      case OPASManagementOperation.approve:
        return AdminPermission.APPROVE_OPAS_SUBMISSION;
      case OPASManagementOperation.reject:
        return AdminPermission.REJECT_OPAS_SUBMISSION;
      case OPASManagementOperation.manageInventory:
        return AdminPermission.MANAGE_OPAS_INVENTORY;
    }
  }

  static AdminPermission _getEscalationManagementPermission(
    EscalationManagementOperation operation,
  ) {
    switch (operation) {
      case EscalationManagementOperation.create:
        return AdminPermission.CREATE_ESCALATION;
      case EscalationManagementOperation.handle:
        return AdminPermission.HANDLE_ESCALATION;
      case EscalationManagementOperation.assign:
        return AdminPermission.ASSIGN_ESCALATION;
    }
  }
}

/// Enum for seller management operations requiring permissions
enum SellerManagementOperation {
  approve,
  reject,
  suspend,
  reactivate,
  view,
  edit,
}

/// Enum for price management operations requiring permissions
enum PriceManagementOperation {
  view,
  update,
  flagViolation,
}

/// Enum for OPAS management operations requiring permissions
enum OPASManagementOperation {
  view,
  approve,
  reject,
  manageInventory,
}

/// Enum for escalation management operations requiring permissions
enum EscalationManagementOperation {
  create,
  handle,
  assign,
}

/// Audit logger for admin actions
class AdminActionAuditLogger {
  /// Log a permission-checked admin action
  static void logAction({
    required AdminUserProfile admin,
    required String action,
    required String entityType,
    required String entityId,
    required bool success,
    String? details,
  }) {
    final logMessage = [
      'Admin: ${admin.name}',
      'Role: ${admin.role.displayName}',
      'Action: $action',
      'Entity: $entityType:$entityId',
      'Success: $success',
      if (details != null) 'Details: $details',
    ].join(' | ');

    if (success) {
      LoggerService.info('[ADMIN_ACTION] $logMessage');
    } else {
      LoggerService.warning('[ADMIN_ACTION_FAILED] $logMessage');
    }
  }

  /// Log a denied permission attempt
  static void logPermissionDenied({
    required AdminUserProfile admin,
    required AdminPermission deniedPermission,
    required String attemptedAction,
  }) {
    final logMessage = [
      'Admin: ${admin.name}',
      'Role: ${admin.role.displayName}',
      'DeniedPermission: ${PermissionValidator.getPermissionName(deniedPermission)}',
      'AttemptedAction: $attemptedAction',
    ].join(' | ');

    LoggerService.warning('[PERMISSION_DENIED] $logMessage');
  }
}
