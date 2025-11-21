import 'package:flutter/material.dart';

class ForecastCard extends StatelessWidget {
  final String productName;
  final int predictedValue;
  final String unit;
  final double confidence;
  final String trend;
  final String recommendation;
  final Color trendColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const ForecastCard({
    Key? key,
    required this.productName,
    required this.predictedValue,
    required this.unit,
    required this.confidence,
    required this.trend,
    required this.recommendation,
    this.trendColor = const Color(0xFF2196F3),
    this.isLoading = false,
    this.onTap,
  }) : super(key: key);

  Color _getConfidenceColor() {
    if (confidence >= 0.8) return const Color(0xFF4CAF50);
    if (confidence >= 0.6) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  IconData _getTrendIcon() {
    if (trend == 'increasing') return Icons.trending_up;
    if (trend == 'decreasing') return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getTrendColor() {
    if (trend == 'increasing') return const Color(0xFF4CAF50);
    if (trend == 'decreasing') return const Color(0xFFF44336);
    return Colors.grey;
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
                trendColor.withOpacity(0.05),
                trendColor.withOpacity(0.02),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
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
                                'Predicted Demand',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _getTrendIcon(),
                          color: _getTrendColor(),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$predictedValue $unit',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confidence',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: confidence,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getConfidenceColor(),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getConfidenceColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue[200]!,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '💡 $recommendation',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
