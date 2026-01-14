import 'package:flutter/material.dart';

/// Widget to display model type and confidence level as a compact tag
/// 
/// Shows:
/// - Model type (SARIMA, ARIMA, SIMPLE, INSUFFICIENT_DATA)
/// - Confidence level (HIGH, MEDIUM, LOW)
/// - Visual indicators (icons, colors)
class ModelMetadataTag extends StatelessWidget {
  final String modelType;
  final String confidenceLevel;
  final double? fontSize;
  final EdgeInsets? padding;

  const ModelMetadataTag({
    Key? key,
    required this.modelType,
    required this.confidenceLevel,
    this.fontSize,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fSize = fontSize ?? 12.0;
    final paddings = padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return Container(
      padding: paddings,
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(isDarkMode),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Model Type Icon & Label
          Icon(
            _getModelIcon(),
            size: fSize + 2,
            color: _getModelColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getModelLabel(),
            style: TextStyle(
              fontSize: fSize,
              fontWeight: FontWeight.w600,
              color: _getModelColor(),
            ),
          ),
          const SizedBox(width: 8),

          // Separator
          Container(
            width: 1,
            height: fSize + 4,
            color: _getBorderColor(isDarkMode),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),

          // Confidence Level Stars
          Text(
            _getConfidenceStars(),
            style: TextStyle(
              fontSize: fSize + 2,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getConfidenceLabel(),
            style: TextStyle(
              fontSize: fSize,
              fontWeight: FontWeight.w500,
              color: _getConfidenceColor(),
            ),
          ),
        ],
      ),
    );
  }

  String _getModelLabel() {
    switch (modelType) {
      case 'SARIMA':
        return 'SARIMA';
      case 'ARIMA':
        return 'ARIMA';
      case 'SIMPLE':
        return 'Simple';
      case 'INSUFFICIENT_DATA':
        return 'Insufficient';
      default:
        return 'Unknown';
    }
  }

  IconData _getModelIcon() {
    switch (modelType) {
      case 'SARIMA':
        return Icons.auto_graph; // Advanced model
      case 'ARIMA':
        return Icons.trending_up; // Trend model
      case 'SIMPLE':
        return Icons.show_chart; // Simple model
      case 'INSUFFICIENT_DATA':
        return Icons.info_outline; // Info
      default:
        return Icons.help_outline;
    }
  }

  Color _getModelColor() {
    switch (modelType) {
      case 'SARIMA':
        return const Color(0xFF4CAF50); // Green - Best model
      case 'ARIMA':
        return const Color(0xFF2196F3); // Blue - Good model
      case 'SIMPLE':
        return const Color(0xFFFFC107); // Amber - Fallback model
      case 'INSUFFICIENT_DATA':
        return const Color(0xFF9E9E9E); // Gray - Unable to model
      default:
        return Colors.grey;
    }
  }

  String _getConfidenceStars() {
    switch (confidenceLevel) {
      case 'HIGH':
        return '⭐⭐⭐⭐⭐';
      case 'MEDIUM':
        return '⭐⭐⭐⭐';
      case 'LOW':
        return '⭐⭐⭐';
      default:
        return '⭐⭐';
    }
  }

  String _getConfidenceLabel() {
    switch (confidenceLevel) {
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      case 'LOW':
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  Color _getConfidenceColor() {
    switch (confidenceLevel) {
      case 'HIGH':
        return const Color(0xFF4CAF50); // Green
      case 'MEDIUM':
        return const Color(0xFFFFC107); // Amber
      case 'LOW':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  Color _getBackgroundColor(bool isDarkMode) {
    if (isDarkMode) {
      return Colors.grey[900]!;
    }
    return Colors.grey[100]!;
  }

  Color _getBorderColor(bool isDarkMode) {
    if (isDarkMode) {
      return Colors.grey[700]!;
    }
    return Colors.grey[300]!;
  }
}
