import 'package:intl/intl.dart';

/// Notification History Model
/// Represents a single notification event (approval, rejection, info request, etc.)
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Complete history with timestamps
/// - Resource Management: Efficient local storage
/// - Data Persistence: JSON serializable for storage
class NotificationHistory {
  final String id; // Unique identifier
  final String type; // REGISTRATION_APPROVED, REGISTRATION_REJECTED, INFO_REQUESTED, etc.
  final String title;
  final String body;
  final String? rejectionReason; // Only for rejections
  final String? approvalNotes; // Only for approvals
  final DateTime receivedAt;
  final DateTime? actionTakenAt; // When user interacted with it
  final bool isRead;
  final Map<String, dynamic> data; // Full notification data

  NotificationHistory({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.rejectionReason,
    this.approvalNotes,
    required this.receivedAt,
    this.actionTakenAt,
    this.isRead = false,
    required this.data,
  });

  /// Create from push notification data
  factory NotificationHistory.fromNotification({
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    return NotificationHistory(
      id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      rejectionReason: data['rejection_reason'] as String?,
      approvalNotes: data['approval_notes'] as String?,
      receivedAt: DateTime.now(),
      isRead: false,
      data: data,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'rejection_reason': rejectionReason,
        'approval_notes': approvalNotes,
        'received_at': receivedAt.toIso8601String(),
        'action_taken_at': actionTakenAt?.toIso8601String(),
        'is_read': isRead,
        'data': data,
      };

  /// Create from JSON
  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      approvalNotes: json['approval_notes'] as String?,
      receivedAt: DateTime.tryParse(json['received_at'] as String? ?? '') ??
          DateTime.now(),
      actionTakenAt: json['action_taken_at'] != null
          ? DateTime.tryParse(json['action_taken_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Get display text based on notification type
  String getDisplayText() {
    switch (type) {
      case 'REGISTRATION_APPROVED':
        return 'Your application was approved! ✅';
      case 'REGISTRATION_REJECTED':
        return 'Your application was rejected ❌';
      case 'INFO_REQUESTED':
        return 'More information needed ℹ️';
      default:
        return body;
    }
  }

  /// Get color code for notification type
  int getColorValue() {
    switch (type) {
      case 'REGISTRATION_APPROVED':
        return 0xFF00B464; // Green
      case 'REGISTRATION_REJECTED':
        return 0xFFE74C3C; // Red
      case 'INFO_REQUESTED':
        return 0xFFFFA500; // Orange
      default:
        return 0xFF666666; // Gray
    }
  }

  /// Get icon for notification type
  String getIcon() {
    switch (type) {
      case 'REGISTRATION_APPROVED':
        return 'check_circle';
      case 'REGISTRATION_REJECTED':
        return 'cancel';
      case 'INFO_REQUESTED':
        return 'help';
      default:
        return 'notifications';
    }
  }

  /// Get formatted time string
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(receivedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(receivedAt);
    }
  }

  /// Get detailed date and time
  String getDetailedDateTime() {
    return DateFormat('MMM d, yyyy • hh:mm a').format(receivedAt);
  }

  /// Mark as read
  NotificationHistory copyWithRead() => NotificationHistory(
        id: id,
        type: type,
        title: title,
        body: body,
        rejectionReason: rejectionReason,
        approvalNotes: approvalNotes,
        receivedAt: receivedAt,
        actionTakenAt: actionTakenAt ?? DateTime.now(),
        isRead: true,
        data: data,
      );
}
