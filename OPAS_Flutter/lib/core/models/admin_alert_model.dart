// Admin Alert Model - System notifications and alerts
class AdminAlertModel {
  final String alertId;
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final String category; // 'price_violation', 'low_inventory', 'seller_issue', 'system'
  final DateTime createdAt;
  late final bool isReviewed;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final Map<String, dynamic>? metadata;

  AdminAlertModel({
    required this.alertId,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    required this.isReviewed,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    this.metadata,
  });

  factory AdminAlertModel.fromJson(Map<String, dynamic> json) {
    return AdminAlertModel(
      alertId: json['alert_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Alert',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      category: json['category'] as String? ?? 'system',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isReviewed: json['is_reviewed'] as bool? ?? false,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionNotes: json['resolution_notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String getSeverityColor() {
    switch (severity) {
      case 'critical':
        return '#F44336';
      case 'warning':
        return '#FF9800';
      case 'info':
      default:
        return '#2196F3';
    }
  }

  String getCategoryIcon() {
    switch (category) {
      case 'price_violation':
        return '💰';
      case 'low_inventory':
        return '📦';
      case 'seller_issue':
        return '⚠️';
      case 'system':
      default:
        return '⚙️';
    }
  }

  String getCategoryLabel() {
    switch (category) {
      case 'price_violation':
        return 'Price Violation';
      case 'low_inventory':
        return 'Low Inventory';
      case 'seller_issue':
        return 'Seller Issue';
      case 'system':
      default:
        return 'System';
    }
  }

  bool isPending() => !isReviewed;
  bool isResolved() => isReviewed && resolvedAt != null;
}
