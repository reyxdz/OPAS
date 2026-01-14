import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/forecast_model.dart';

/// Forecast Detail Screen - Phase 5.1 B
/// 
/// Displays detailed forecast information for any forecast (farmer or market data):
/// - Product and forecast metadata
/// - Demand and price forecast values
/// - Confidence intervals
/// - Model information
class ForecastDetailScreen extends StatefulWidget {
  final ForecastModel forecast;

  const ForecastDetailScreen({
    Key? key,
    required this.forecast,
  }) : super(key: key);

  @override
  State<ForecastDetailScreen> createState() => _ForecastDetailScreenState();
}

class _ForecastDetailScreenState extends State<ForecastDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.forecast.productName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: cardColor,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.forecast.productName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.forecast.categoryName ?? 'Market Data',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtleColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.forecast.getConfidenceEmoji(),
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                widget.forecast.confidenceLevel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(widget.forecast.forecastDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Demand Forecast Section
            Text(
              'Demand Forecast',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: cardColor,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildForecastField(
                      label: 'Forecast',
                      value: '${widget.forecast.demandForecastKg.toStringAsFixed(2)} kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Lower Bound',
                      value: '${widget.forecast.demandLowerBound.toStringAsFixed(2)} kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Upper Bound',
                      value: '${widget.forecast.demandUpperBound.toStringAsFixed(2)} kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Confidence Interval',
                      value: '±${(widget.forecast.demandUpperBound - widget.forecast.demandForecastKg).abs().toStringAsFixed(2)} kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price Forecast Section
            Text(
              'Price Forecast',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: cardColor,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildForecastField(
                      label: 'Forecast',
                      value: '₱${widget.forecast.priceForecast.toStringAsFixed(2)}/kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Lower Bound',
                      value: '₱${widget.forecast.priceLowerBound.toStringAsFixed(2)}/kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Upper Bound',
                      value: '₱${widget.forecast.priceUpperBound.toStringAsFixed(2)}/kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Confidence Interval',
                      value: '±₱${(widget.forecast.priceUpperBound - widget.forecast.priceForecast).abs().toStringAsFixed(2)}/kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Model Information Section
            Text(
              'Model Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: cardColor,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildForecastField(
                      label: 'Model Type',
                      value: widget.forecast.getModelLabel(),
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Forecast Period',
                      value: widget.forecast.forecastPeriod,
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Confidence Level',
                      value: widget.forecast.confidenceLevel,
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const SizedBox(height: 8),
                    _buildForecastField(
                      label: 'Current Forecast',
                      value: widget.forecast.isCurrent ? 'Yes' : 'No',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastField({
    required String label,
    required String value,
    required Color textColor,
    required Color? subtleColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: subtleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor() {
    switch (widget.forecast.confidenceLevel) {
      case 'HIGH':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
