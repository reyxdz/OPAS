import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String type;
  final String status;
  final String targetAudience;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final int? viewCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AnnouncementCard({
    Key? key,
    required this.title,
    required this.type,
    required this.status,
    required this.targetAudience,
    required this.createdAt,
    this.scheduledFor,
    this.viewCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  Color _getTypeColor() {
    switch (type) {
      case 'price_update':
        return const Color(0xFFFF9800);
      case 'shortage_alert':
        return const Color(0xFFF44336);
      case 'policy_change':
        return const Color(0xFF2196F3);
      case 'promotion':
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String _getTypeIcon() {
    switch (type) {
      case 'price_update':
        return '💰';
      case 'shortage_alert':
        return '⚠️';
      case 'policy_change':
        return '📋';
      case 'promotion':
      default:
        return '🎉';
    }
  }

  String _getTypeLabel() {
    switch (type) {
      case 'price_update':
        return 'Price Update';
      case 'shortage_alert':
        return 'Shortage Alert';
      case 'policy_change':
        return 'Policy Change';
      case 'promotion':
      default:
        return 'Promotion';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'scheduled':
        return const Color(0xFF2196F3);
      case 'published':
        return const Color(0xFF4CAF50);
      case 'archived':
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTypeColor().withOpacity(0.08),
                _getTypeColor().withOpacity(0.02),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeIcon(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontSize: 9,
                            color: _getTypeColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target: $targetAudience',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (scheduledFor != null)
                        Text(
                          'Scheduled: ${_formatDate(scheduledFor!)}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  if (viewCount != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                        const SizedBox(height: 2),
                        Text(
                          '$viewCount views',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFFF44336),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
