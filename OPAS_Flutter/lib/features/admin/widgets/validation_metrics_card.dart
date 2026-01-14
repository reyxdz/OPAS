import 'package:flutter/material.dart';

/// Model metric information
class ModelMetric {
  final String model;
  final double mape;
  final double? rmse;
  final double? mae;

  ModelMetric({
    required this.model,
    required this.mape,
    this.rmse,
    this.mae,
  });

  String getAccuracyEmoji() {
    if (mape <= 5) return '⭐';
    if (mape <= 10) return '✅';
    if (mape <= 20) return '👍';
    return '⚠️';
  }

  String getConfidenceFromMape() {
    if (mape <= 10) return 'HIGH';
    if (mape <= 20) return 'MEDIUM';
    return 'LOW';
  }
}

/// Model accuracy info containing demand and price forecasts
class ModelAccuracyGroup {
  final String bestModel;
  final List<ModelMetric> models;

  ModelAccuracyGroup({
    required this.bestModel,
    required this.models,
  });
}

/// Complete model accuracy info
class ModelAccuracyInfo {
  final ModelAccuracyGroup? demand;
  final ModelAccuracyGroup? price;

  ModelAccuracyInfo({
    this.demand,
    this.price,
  });
}

/// Widget to display validation metrics from enhanced forecasting
class ValidationMetricsCard extends StatelessWidget {
  final double? validationMape;
  final String? validationConfidence;
  final DateTime? validationDate;
  final ModelAccuracyInfo? modelAccuracyInfo;

  const ValidationMetricsCard({
    Key? key,
    this.validationMape,
    this.validationConfidence,
    this.validationDate,
    this.modelAccuracyInfo,
  }) : super(key: key);

  /// Get color based on confidence level
  Color _getConfidenceColor(String? confidence) {
    switch (confidence?.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFF4CAF50); // Green
      case 'MEDIUM':
        return const Color(0xFFFFC107); // Amber
      case 'LOW':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get emoji for confidence level
  String _getConfidenceEmoji(String? confidence) {
    switch (confidence?.toUpperCase()) {
      case 'HIGH':
        return '✅';
      case 'MEDIUM':
        return '👍';
      case 'LOW':
        return '⚠️';
      default:
        return 'ℹ️';
    }
  }

  /// Get last updated text
  String _getLastUpdatedText(DateTime? date) {
    if (date == null) return 'Not validated yet';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays ~/ 7)}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no validation metrics, show placeholder
    if (validationMape == null) {
      return const Card(
        margin: EdgeInsets.all(16.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF9E9E9E)),
              SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  'Validation metrics not yet available',
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and validation date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Model Validation Results',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Validated ${_getLastUpdatedText(validationDate)}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Main metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // MAPE accuracy
                _buildMetricBox(
                  icon: '📊',
                  label: 'Accuracy',
                  value: '${validationMape!.toStringAsFixed(2)}%',
                  description: 'MAPE Error',
                  color: _getConfidenceColor(validationConfidence),
                ),
                // Confidence level
                _buildMetricBox(
                  icon: _getConfidenceEmoji(validationConfidence),
                  label: 'Confidence',
                  value: validationConfidence ?? 'UNKNOWN',
                  description: 'Based on MAPE',
                  color: _getConfidenceColor(validationConfidence),
                ),
                // Expected error range
                _buildMetricBox(
                  icon: '±',
                  label: 'Error Range',
                  value: '±${validationMape!.toStringAsFixed(1)}%',
                  description: 'Expected variation',
                  color: _getConfidenceColor(validationConfidence),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Model comparison section
            if (modelAccuracyInfo != null)
              _buildModelComparison(context)
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Model comparison data not available',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build individual metric box
  Widget _buildMetricBox({
    required String icon,
    required String label,
    required String value,
    required String description,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8.0),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: const TextStyle(fontSize: 11.0, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              description,
              style: const TextStyle(fontSize: 10.0, color: Color(0xFFBDBDBD)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build model comparison table
  Widget _buildModelComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Model Comparison',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8.0),

        // Demand models
        if (modelAccuracyInfo?.demand != null)
          _buildModelComparisonTable(
            title: 'Demand Forecast',
            bestModel: modelAccuracyInfo!.demand!.bestModel,
            models: modelAccuracyInfo!.demand!.models,
          ),

        const SizedBox(height: 12.0),

        // Price models
        if (modelAccuracyInfo?.price != null)
          _buildModelComparisonTable(
            title: 'Price Forecast',
            bestModel: modelAccuracyInfo!.price!.bestModel,
            models: modelAccuracyInfo!.price!.models,
          ),
      ],
    );
  }

  /// Build comparison table for one metric (demand or price)
  Widget _buildModelComparisonTable({
    required String title,
    required String bestModel,
    required List<ModelMetric> models,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with best model
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'Best: $bestModel',
                style: const TextStyle(
                  fontSize: 10.0,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Model rows
        ...models.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final metric = entry.value;
          final isBest = metric.model == bestModel;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isBest
                      ? const Color(0xFF4CAF50).withOpacity(0.5)
                      : const Color(0xFFE0E0E0),
                ),
                borderRadius: BorderRadius.circular(4.0),
                color: isBest
                    ? const Color(0xFF4CAF50).withOpacity(0.05)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rank and model name
                  Row(
                    children: [
                      Text(
                        '#$index',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        metric.model,
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                          color: isBest ? const Color(0xFF4CAF50) : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        metric.getAccuracyEmoji(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),

                  // MAPE value with confidence indicator
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'MAPE: ${metric.mape.toStringAsFixed(2)}%',
                            style: const TextStyle(fontSize: 11.0),
                          ),
                          Text(
                            '(${metric.getConfidenceFromMape()})',
                            style: const TextStyle(
                              fontSize: 9.0,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12.0),
                      if (isBest)
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFC107),
                          size: 16.0,
                        )
                      else
                        const SizedBox(width: 16.0),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
