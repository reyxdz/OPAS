import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/forecast_model.dart';

/// Forecast Summary Card Widget - Phase 5.1 A
/// 
/// Displays a single product forecast in a card format with:
/// - Product name and category (fixed header)
/// - Horizontally scrollable table with demand/price forecasts
/// - Model type and confidence level
/// - Action buttons for details and history
class ForecastCard extends StatelessWidget {
  final ForecastModel forecast;
  final VoidCallback? onViewDetails;
  final VoidCallback? onViewHistory;

  const ForecastCard({
    Key? key,
    required this.forecast,
    this.onViewDetails,
    this.onViewHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final borderColor =
        isDarkMode ? Colors.grey[700] : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Product info + Confidence badge
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (forecast.categoryName != null)
                        Text(
                          forecast.categoryName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConfidenceBgColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    forecast.confidenceLevel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getConfidenceBgColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: borderColor,
          ),

          // Data Grid: Model, Period, Demand, Price
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // First row: Model & Period
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        context,
                        label: 'Model',
                        value: forecast.getModelLabel(),
                        icon: Icons.show_chart_rounded,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildDataItem(
                        context,
                        label: 'Forecast Period',
                        value: forecast.forecastPeriod,
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Second row: Demand & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        context,
                        label: 'Demand',
                        value:
                            '${forecast.demandForecastKg.toStringAsFixed(1)} kg',
                        subtitle:
                            '±${(forecast.demandUpperBound - forecast.demandForecastKg).abs().toStringAsFixed(1)} kg',
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildDataItem(
                        context,
                        label: 'Price',
                        value:
                            '₱${forecast.priceForecast.toStringAsFixed(2)}/kg',
                        subtitle:
                            '±₱${(forecast.priceUpperBound - forecast.priceForecast).abs().toStringAsFixed(2)}',
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: borderColor,
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewHistory,
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B464),
                      side: const BorderSide(color: Color(0xFF00B464), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual data item with icon
  Widget _buildDataItem(
    BuildContext context, {
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00B464).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF00B464),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: subtleColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00B464),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Get background color based on confidence level
  Color _getConfidenceBgColor() {
    switch (forecast.confidenceLevel) {
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
