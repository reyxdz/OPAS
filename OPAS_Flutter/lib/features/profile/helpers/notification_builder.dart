import 'package:flutter/material.dart';

/// Notification Type Styling Configuration
/// 
/// CLEAN ARCHITECTURE PRINCIPLE: Configuration as Data
/// Centralizes all styling configuration for different notification types
/// Makes it easy to add new types or modify existing ones
class NotificationTypeStyle {
  final IconData icon;
  final Color color;
  final String label;

  const NotificationTypeStyle({
    required this.icon,
    required this.color,
    required this.label,
  });
}

/// Notification Builder - Centralized styling logic
/// 
/// CLEAN ARCHITECTURE PRINCIPLE: Single Responsibility + Reusability
/// This class is responsible for:
/// - Determining styling for different notification types
/// - Building consistent UI components
/// - Managing read/unread visual distinctions
/// - Supporting all application statuses, not just "APPLICATION"
class NotificationBuilder {
  // Notification type styles mapping
  static final Map<String, NotificationTypeStyle> typeStyles = {
    'REGISTRATION_APPROVED': NotificationTypeStyle(
      icon: Icons.check_circle,
      color: Colors.green,
      label: 'Approved',
    ),
    'REGISTRATION_REJECTED': NotificationTypeStyle(
      icon: Icons.cancel,
      color: Colors.red,
      label: 'Rejected',
    ),
    'INFO_REQUESTED': NotificationTypeStyle(
      icon: Icons.info,
      color: Colors.orange,
      label: 'Info Needed',
    ),
    'APPLICATION': NotificationTypeStyle(
      icon: Icons.notifications,
      color: Colors.blue,
      label: 'Application',
    ),
    'PENDING_REVIEW': NotificationTypeStyle(
      icon: Icons.schedule,
      color: Colors.amber,
      label: 'Pending Review',
    ),
    'UNDER_REVIEW': NotificationTypeStyle(
      icon: Icons.search,
      color: Colors.indigo,
      label: 'Under Review',
    ),
    'RESUBMISSION_REQUIRED': NotificationTypeStyle(
      icon: Icons.refresh,
      color: Colors.purple,
      label: 'Resubmission Required',
    ),
    'APPROVED': NotificationTypeStyle(
      icon: Icons.verified,
      color: Colors.teal,
      label: 'Approved',
    ),
    'REJECTED': NotificationTypeStyle(
      icon: Icons.cancel,
      color: Colors.deepOrange,
      label: 'Rejected',
    ),
  };

  /// Get styling for a notification type
  /// Falls back to APPLICATION style if type not found
  static NotificationTypeStyle getStyle(String type) {
    return typeStyles[type] ??
        typeStyles['APPLICATION'] ??
        const NotificationTypeStyle(
          icon: Icons.notifications,
          color: Colors.blue,
          label: 'Notification',
        );
  }

  /// Build icon widget for notification
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Composition
  /// Returns a styled icon based on notification type
  static Widget buildIcon(
    String type, {
    double size = 24,
    bool isRead = false,
  }) {
    final style = getStyle(type);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        style.icon,
        color: style.color,
        size: size,
      ),
    );
  }

  /// Build color-coded badge for notification type
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Reusability
  /// Used in both list and detail views for consistency
  static Widget buildTypeBadge(
    String type, {
    bool isRead = false,
  }) {
    final style = getStyle(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withOpacity(isRead ? 0.3 : 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Get color for notification header background
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Centralized Styling
  /// Ensures consistent colors across all views
  static Color getHeaderBackgroundColor(String type) {
    return getStyle(type).color.withOpacity(0.1);
  }

  /// Get color for notification list card background based on read state
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: State-based Styling
  /// Different backgrounds for read vs unread to clearly distinguish
  static Color getCardBackgroundColor(String type, bool isRead) {
    final style = getStyle(type);
    if (isRead) {
      return Colors.white;
    }
    // Unread: light tinted background using notification color
    return style.color.withOpacity(0.08);
  }

  /// Get text style for notification title
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Consistent Styling
  /// Ensures titles are bold when unread, normal when read
  static TextStyle getTitleStyle(BuildContext context, bool isRead) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          color: isRead ? Colors.grey[700] : Colors.black87,
        ) ??
        TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          color: isRead ? Colors.grey[700] : Colors.black87,
        );
  }

  /// Get text style for notification body
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Consistent Styling
  /// Ensures body text matches title styling for consistency
  static TextStyle getBodyStyle(BuildContext context, bool isRead) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isRead ? Colors.grey[700] : Colors.black87,
        ) ??
        TextStyle(
          color: isRead ? Colors.grey[700] : Colors.black87,
        );
  }

  /// Get text style for timestamp
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Consistent Styling
  /// Timestamps always muted regardless of read state
  static TextStyle getTimestampStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[500],
          fontSize: 11,
        ) ??
        TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
        );
  }

  /// Build border for rejection/approval info boxes
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Consistent UI Patterns
  /// Used in modal and card views
  static BoxDecoration buildInfoBoxDecoration(String boxType) {
    // boxType: 'rejection', 'approval', or any other
    Color borderColor;
    switch (boxType) {
      case 'rejection':
        borderColor = Colors.red.shade300;
        break;
      case 'approval':
        borderColor = Colors.green.shade300;
        break;
      case 'info':
        borderColor = Colors.orange.shade300;
        break;
      default:
        borderColor = Colors.blue.shade300;
    }

    return BoxDecoration(
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Get background color for rejection/approval info boxes
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Consistent Colors
  /// Ensures all info boxes use consistent coloring
  static Color getInfoBoxBackgroundColor(String boxType) {
    switch (boxType) {
      case 'rejection':
        return Colors.red.shade50;
      case 'approval':
        return Colors.green.shade50;
      case 'info':
        return Colors.orange.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  /// Get text color for rejection/approval info boxes
  /// 
  /// CLEAN ARCHITECTURE PRINCIPLE: Consistent Colors
  /// Ensures readability in all info boxes
  static Color getInfoBoxTextColor(String boxType) {
    switch (boxType) {
      case 'rejection':
        return Colors.red.shade700;
      case 'approval':
        return Colors.green.shade700;
      case 'info':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}

