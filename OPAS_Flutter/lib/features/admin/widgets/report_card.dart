import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String reportName;
  final String reportType;
  final String dateRange;
  final String status;
  final int metricsCount;
  final DateTime? generatedAt;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final bool isLoading;

  const ReportCard({
    Key? key,
    required this.reportName,
    required this.reportType,
    required this.dateRange,
    required this.status,
    required this.metricsCount,
    this.generatedAt,
    this.onTap,
    this.onDownload,
    this.onShare,
    this.isLoading = false,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'failed':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getReportIcon() {
    switch (reportType) {
      case 'sales_summary':
        return Icons.trending_up;
      case 'opas_purchases':
        return Icons.shopping_cart;
      case 'seller_participation':
        return Icons.people;
      case 'market_impact':
        return Icons.analytics;
      default:
        return Icons.description;
    }
  }

  String _getReportTypeLabel() {
    switch (reportType) {
      case 'sales_summary':
        return 'Sales Summary';
      case 'opas_purchases':
        return 'OPAS Purchases';
      case 'seller_participation':
        return 'Seller Participation';
      case 'market_impact':
        return 'Market Impact';
      default:
        return 'Custom Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStatusColor().withOpacity(0.08),
                _getStatusColor().withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getReportIcon(),
                            color: _getStatusColor(),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reportName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getReportTypeLabel(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(Icons.data_thresholding,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '$metricsCount metrics',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (generatedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Generated: ${generatedAt!.toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    if (status == 'completed')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onDownload != null)
                              GestureDetector(
                                onTap: onDownload,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.download,
                                          size: 12, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Download',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (onDownload != null && onShare != null)
                              const SizedBox(width: 8),
                            if (onShare != null)
                              GestureDetector(
                                onTap: onShare,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.share,
                                          size: 12, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
