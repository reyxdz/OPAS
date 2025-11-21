import 'package:flutter/material.dart';

class AlertWidget extends StatelessWidget {
  final String title;
  final String message;
  final String severity; // 'info', 'warning', 'critical'
  final IconData icon;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool isDismissible;

  const AlertWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.isDismissible = true,
  }) : super(key: key);

  Color _getSeverityColor() {
    switch (severity) {
      case 'critical':
        return const Color(0xFFF44336);
      case 'warning':
        return const Color(0xFFFF9800);
      case 'info':
      default:
        return const Color(0xFF2196F3);
    }
  }

  Color _getBackgroundColor() {
    final baseColor = _getSeverityColor();
    return baseColor.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _getBackgroundColor(),
          border: Border.all(
            color: _getSeverityColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSeverityColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: _getSeverityColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getSeverityColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: onAction,
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getSeverityColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isDismissible)
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
