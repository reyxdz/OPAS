// Alert Card Widget - Displays marketplace alerts with status and actions
// Reusable widget for showing alert details and management actions

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/marketplace_alert_model.dart';

class AlertCard extends StatelessWidget {
  final MarketplaceAlertModel alert;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onEscalate;
  final VoidCallback? onViewDetails;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onTap,
    this.onAcknowledge,
    this.onResolve,
    this.onEscalate,
    this.onViewDetails,
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
              // Header with severity badge and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.getSeverityIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: alert.getSeverityColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alert.severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: alert.getSeverityColor(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alert.getCategoryLabel(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      alert.getStatusLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description and details
              Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Alert metadata
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alert.affectedListingName != null)
                      _buildDetailRow(
                        'Listing',
                        alert.affectedListingName!,
                      ),
                    if (alert.sellerName != null)
                      _buildDetailRow('Seller', alert.sellerName!),
                    _buildDetailRow('Created', alert.formatCreatedAt()),
                    if (alert.reason != null)
                      _buildDetailRow('Reason', alert.reason!),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Recommended action
              if (alert.recommendedAction != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue, width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recommended: ${alert.recommendedAction}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!alert.isResolved()) ...[
                    if (onAcknowledge != null)
                      TextButton.icon(
                        onPressed: onAcknowledge,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Acknowledge'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                  if (onResolve != null)
                    TextButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Resolve'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  if (alert.requiresEscalation && onEscalate != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onEscalate,
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Escalate'),
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

  Color _getStatusColor() {
    switch (alert.status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.red;
      case 'ACKNOWLEDGED':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'ESCALATED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor() {
    switch (alert.status.toUpperCase()) {
      case 'ACTIVE':
        return const Color.fromARGB(255, 244, 67, 54).withOpacity(0.1);
      case 'ACKNOWLEDGED':
        return Colors.orange.withOpacity(0.1);
      case 'RESOLVED':
        return const Color.fromARGB(255, 76, 175, 80).withOpacity(0.1);
      case 'ESCALATED':
        return Colors.purple.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
