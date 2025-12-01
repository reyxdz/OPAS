import 'package:flutter/material.dart';

/// Stock Status Widget
/// 
/// Displays product stock status with:
/// - Color-coded status label (Low/Moderate/High)
/// - Visual progress bar showing stock percentage
/// - Current stock amount and percentage
/// 
/// Status thresholds:
/// - LOW: < 40% (Red)
/// - MODERATE: 40-69% (Orange)
/// - HIGH: >= 70% (Green)

class StockStatusWidget extends StatelessWidget {
  final String status; // 'LOW', 'MODERATE', 'HIGH'
  final double percentage;
  final int currentStock;
  final String unit;

  const StockStatusWidget({
    super.key,
    required this.status,
    required this.percentage,
    required this.currentStock,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Label with Color
        Text(
          '${status[0]}${status.substring(1).toLowerCase()} Stock',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getStatusColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
        ),
        const SizedBox(height: 4),
        // Percentage Text
        Text(
          '$currentStock ${unit}s (${percentage.toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Get status color based on stock status
  Color _getStatusColor() {
    switch (status) {
      case 'LOW':
        return Colors.red;
      case 'MODERATE':
        return Colors.orange;
      case 'HIGH':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
