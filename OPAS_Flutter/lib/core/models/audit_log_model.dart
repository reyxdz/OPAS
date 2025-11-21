/// Audit Log Model
/// Records all admin actions for compliance and tracking
class AuditLogModel {
  final String logId;
  final String adminId;
  final String adminName;
  final String actionType; // 'seller_approval', 'price_change', 'opas_decision', 'announcement', 'user_management', 'system_config'
  final String actionDescription;
  final Map<String, dynamic>? metadata; // Additional context about the action
  final String status; // 'success', 'failed', 'partial'
  final String? errorMessage;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final int? affectedItemsCount;

  AuditLogModel({
    required this.logId,
    required this.adminId,
    required this.adminName,
    required this.actionType,
    required this.actionDescription,
    this.metadata,
    required this.status,
    this.errorMessage,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.affectedItemsCount,
  });

  /// Convert JSON to AuditLogModel
  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      logId: json['log_id'] ?? '',
      adminId: json['admin_id'] ?? '',
      adminName: json['admin_name'] ?? 'Unknown',
      actionType: json['action_type'] ?? 'unknown',
      actionDescription: json['action_description'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: json['status'] ?? 'success',
      errorMessage: json['error_message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      affectedItemsCount: json['affected_items_count'] as int?,
    );
  }

  /// Convert AuditLogModel to JSON
  Map<String, dynamic> toJson() => {
    'log_id': logId,
    'admin_id': adminId,
    'admin_name': adminName,
    'action_type': actionType,
    'action_description': actionDescription,
    'metadata': metadata,
    'status': status,
    'error_message': errorMessage,
    'timestamp': timestamp.toIso8601String(),
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'affected_items_count': affectedItemsCount,
  };

  /// Get color based on action type
  String getActionColor() {
    switch (actionType) {
      case 'seller_approval':
        return '0xFF4CAF50'; // Green
      case 'price_change':
        return '0xFF2196F3'; // Blue
      case 'opas_decision':
        return '0xFFFFC107'; // Amber
      case 'announcement':
        return '0xFF9C27B0'; // Purple
      case 'user_management':
        return '0xFFF44336'; // Red
      case 'system_config':
        return '0xFF673AB7'; // Deep Purple
      default:
        return '0xFF757575'; // Gray
    }
  }

  /// Get icon based on action type
  String getActionIcon() {
    switch (actionType) {
      case 'seller_approval':
        return '✓'; // Checkmark
      case 'price_change':
        return '₦'; // Currency
      case 'opas_decision':
        return '⚖'; // Scale
      case 'announcement':
        return '📢'; // Megaphone
      case 'user_management':
        return '👤'; // User
      case 'system_config':
        return '⚙'; // Gear
      default:
        return '•'; // Bullet
    }
  }

  /// Get label for action type
  String getActionLabel() {
    switch (actionType) {
      case 'seller_approval':
        return 'Seller Approval';
      case 'price_change':
        return 'Price Change';
      case 'opas_decision':
        return 'OPAS Decision';
      case 'announcement':
        return 'Announcement';
      case 'user_management':
        return 'User Management';
      case 'system_config':
        return 'System Config';
      default:
        return 'Unknown';
    }
  }

  /// Get status color
  String getStatusColor() {
    switch (status) {
      case 'success':
        return '0xFF4CAF50'; // Green
      case 'failed':
        return '0xFFF44336'; // Red
      case 'partial':
        return '0xFFFFC107'; // Amber
      default:
        return '0xFF757575'; // Gray
    }
  }

  /// Check if action was successful
  bool isSuccess() => status == 'success';
  
  /// Check if action failed
  bool isFailed() => status == 'failed';
}
