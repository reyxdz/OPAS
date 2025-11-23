import 'package:flutter/material.dart';
import '../../../features/profile/models/registration_status_enum.dart';

/// Registration Status Badge Widget
/// Displays colorized status indicator for use in lists and detail views
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Color-coded visual feedback for status at a glance
/// - Resource Management: Minimal widget overhead, efficient rendering
class RegistrationStatusBadge extends StatelessWidget {
  final String status;
  final bool showLabel;
  final double fontSize;
  final EdgeInsets padding;

  const RegistrationStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  /// Get status enum from string
  RegistrationStatus _getStatus() {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return RegistrationStatus.approved;
      case 'REJECTED':
        return RegistrationStatus.rejected;
      case 'REQUEST_MORE_INFO':
        return RegistrationStatus.requestMoreInfo;
      default:
        return RegistrationStatus.pending;
    }
  }

  /// Get color based on status
  Color _getStatusColor() {
    final regStatus = _getStatus();
    if (regStatus.isPending) {
      return Colors.orange.shade600;
    } else if (regStatus.isApproved) {
      return Colors.green.shade600;
    } else if (regStatus.isRejected) {
      return Colors.red.shade600;
    } else {
      return Colors.blue.shade600;
    }
  }

  /// Get background color (lighter shade)
  Color _getBackgroundColor() {
    return _getStatusColor().withOpacity(0.15);
  }

  /// Get display text
  String _getDisplayText() {
    final regStatus = _getStatus();
    if (regStatus.isPending) {
      return 'Pending';
    } else if (regStatus.isApproved) {
      return 'Approved';
    } else if (regStatus.isRejected) {
      return 'Rejected';
    } else {
      return 'More Info Needed';
    }
  }

  /// Get icon for status
  IconData _getStatusIcon() {
    final regStatus = _getStatus();
    if (regStatus.isPending) {
      return Icons.schedule;
    } else if (regStatus.isApproved) {
      return Icons.check_circle;
    } else if (regStatus.isRejected) {
      return Icons.cancel;
    } else {
      return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(),
          width: 1.5,
        ),
      ),
      child: showLabel
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  _getDisplayText(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            )
          : Icon(
              _getStatusIcon(),
              size: 18,
              color: _getStatusColor(),
            ),
    );
  }
}
