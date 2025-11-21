import 'package:flutter/material.dart';

class AlertTile extends StatelessWidget {
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final String category;
  final DateTime timestamp;
  final bool isReviewed;
  final VoidCallback? onTap;
  final VoidCallback? onReview;
  final VoidCallback? onResolve;

  const AlertTile({
    Key? key,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.timestamp,
    required this.isReviewed,
    this.onTap,
    this.onReview,
    this.onResolve,
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

  String _getCategoryIcon() {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isReviewed ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getSeverityColor().withOpacity(0.08),
                _getSeverityColor().withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getSeverityColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryIcon(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isReviewed)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getSeverityColor(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (!isReviewed && (onReview != null || onResolve != null))
                    Row(
                      children: [
                        if (onReview != null)
                          GestureDetector(
                            onTap: onReview,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                'Mark Read',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (onResolve != null)
                          GestureDetector(
                            onTap: onResolve,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                'Resolve',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
