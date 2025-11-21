// Activity Feed Item Widget - Displays marketplace activity in feed format
// Reusable widget for showing activity entries with details and actions

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/marketplace_activity_model.dart';

class ActivityFeedItem extends StatelessWidget {
  final MarketplaceActivityModel activity;
  final VoidCallback? onTap;
  final VoidCallback? onFlag;
  final VoidCallback? onDismiss;

  const ActivityFeedItem({
    Key? key,
    required this.activity,
    this.onTap,
    this.onFlag,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, title, and priority badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.getActivityIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.getActivityLabel(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          activity.formatTime(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity.priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: activity.getPriorityColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity.priority!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activity.getPriorityColor(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Activity details
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activity.sellerName != null)
                      _buildDetailRow('Seller', activity.sellerName!),
                    if (activity.productName != null)
                      _buildDetailRow('Product', activity.productName!),
                    if (activity.amount != null)
                      _buildDetailRow('Amount', activity.formatAmount()),
                    if (activity.description != null && activity.description!.isNotEmpty)
                      _buildDetailRow('Details', activity.description!),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDismiss != null)
                    TextButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Dismiss'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  if (onFlag != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onFlag,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Flag'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
