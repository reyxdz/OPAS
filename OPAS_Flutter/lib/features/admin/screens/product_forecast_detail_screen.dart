import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/forecast_detail_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin/widgets/forecast_chart.dart';

/// Product Forecast Detail Screen - Phase 5.1 B
/// 
/// Displays detailed forecast information for a single product:
/// - Model information and parameters
/// - Historical and forecast line charts
/// - Detailed forecast data table
/// - Forecast alerts
/// - Export and email options
/// 
/// Data sourced from backend API:
/// - GET /api/admin/forecasts/{product_id}/ - Detailed forecast
class ProductForecastDetailScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductForecastDetailScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProductForecastDetailScreenState createState() =>
      _ProductForecastDetailScreenState();
}

class _ProductForecastDetailScreenState extends State<ProductForecastDetailScreen> {
  late Future<ForecastDetailModel> _forecastDetailFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadForecastDetail();
  }

  void _loadForecastDetail() {
    _forecastDetailFuture = _fetchForecastDetail();
  }

  Future<ForecastDetailModel> _fetchForecastDetail() async {
    try {
      final data = await AdminService.getForecastDetail(widget.productId);
      return ForecastDetailModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching forecast detail: $e');
      rethrow;
    }
  }

  Future<void> _exportReport(ForecastDetailModel forecast) async {
    setState(() => _isExporting = true);
    
    try {
      // Generate report content
      final buffer = StringBuffer();
      
      buffer.writeln('FORECAST REPORT');
      buffer.writeln('===============');
      buffer.writeln('Product: ${forecast.productName}');
      buffer.writeln('Category: ${forecast.categoryName ?? "N/A"}');
      buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(forecast.forecastDate)}');
      buffer.writeln('');
      
      buffer.writeln('MODEL INFORMATION');
      buffer.writeln('=================');
      buffer.writeln('Model Type: ${forecast.modelType}');
      buffer.writeln('Parameters: ${forecast.modelParameters}');
      buffer.writeln('Data Points: ${forecast.dataPointsCount}');
      buffer.writeln('Last Training: ${DateFormat('yyyy-MM-dd HH:mm').format(forecast.lastTrainingDate)}');
      buffer.writeln('Confidence: ${forecast.confidenceLevel}');
      buffer.writeln('Reliable: ${forecast.isReliable ? "Yes" : "No"}');
      buffer.writeln('RMSE: ${forecast.rmseValue.toStringAsFixed(4)}');
      buffer.writeln('MAPE: ${forecast.mapeValue.toStringAsFixed(2)}%');
      buffer.writeln('');
      
      buffer.writeln('DEMAND FORECAST');
      buffer.writeln('===============');
      for (final point in forecast.demandForecast) {
        buffer.writeln('${point.period}: ${point.value.toStringAsFixed(2)} kg '
            '(${point.lowerBound?.toStringAsFixed(2) ?? "N/A"} - ${point.upperBound?.toStringAsFixed(2) ?? "N/A"})');
      }
      buffer.writeln('');
      
      buffer.writeln('PRICE FORECAST');
      buffer.writeln('==============');
      for (final point in forecast.priceForecast) {
        buffer.writeln('${point.period}: ₱${point.value.toStringAsFixed(2)}/kg '
            '(₱${point.lowerBound?.toStringAsFixed(2) ?? "N/A"} - ₱${point.upperBound?.toStringAsFixed(2) ?? "N/A"})');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported (check console)'),
            duration: Duration(seconds: 2),
          ),
        );
        debugPrint('Report:\n${buffer.toString()}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName),
            const Text(
              'Forecast Detail',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<ForecastDetailModel>(
        future: _forecastDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadForecastDetail()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final forecast = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model Information Card
                  _buildModelInfoCard(forecast),
                  const SizedBox(height: 20),

                  // Demand Chart
                  ForecastChart(
                    title: '📊 Demand Forecast (Next 4 Weeks)',
                    historicalData: forecast.demandHistory,
                    forecastData: forecast.demandForecast,
                    unit: 'kg',
                    lineColor: Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  // Demand Table
                  _buildForecastTable(
                    'Demand Forecast Details',
                    forecast.demandForecast,
                    'kg',
                  ),
                  const SizedBox(height: 20),

                  // Price Chart
                  ForecastChart(
                    title: '💰 Price Forecast (Next 4 Weeks)',
                    historicalData: forecast.priceHistory,
                    forecastData: forecast.priceForecast,
                    unit: '₱/kg',
                    lineColor: Colors.green,
                  ),
                  const SizedBox(height: 12),

                  // Price Table
                  _buildForecastTable(
                    'Price Forecast Details',
                    forecast.priceForecast,
                    '₱/kg',
                  ),
                  const SizedBox(height: 20),

                  // Alerts Section
                  _buildAlertsSection(forecast),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportReport(forecast),
                          icon: const Icon(Icons.download),
                          label: const Text('Export Report'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email functionality coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.email),
                          label: const Text('Email'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build model information card
  Widget _buildModelInfoCard(ForecastDetailModel forecast) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleColor = isDarkMode ? Colors.grey[400] ?? Colors.grey : Colors.grey[700] ?? Colors.grey;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            // Model parameters
            _buildInfoRow(
              'Model',
              forecast.modelParameters,
              textColor,
              subtleColor,
            ),
            const SizedBox(height: 8),
            // Data points
            _buildInfoRow(
              'Data Points',
              '${forecast.dataPointsCount} weeks',
              textColor,
              subtleColor,
            ),
            const SizedBox(height: 8),
            // Last Updated
            _buildInfoRow(
              'Last Updated',
              forecast.getLastUpdatedFormatted(),
              textColor,
              subtleColor,
            ),
            const SizedBox(height: 12),
            // Confidence stars
            Row(
              children: [
                Text(
                  'Confidence Level',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${forecast.getConfidenceStars()} (${forecast.confidenceLevel})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value, Color textColor, Color subtleColor) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: subtleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// Build forecast data table
  Widget _buildForecastTable(
    String title,
    List<ForecastDataPoint> data,
    String unit,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleColor = isDarkMode ? Colors.grey[400] ?? Colors.grey : Colors.grey[700] ?? Colors.grey;
    final bgColor = isDarkMode ? Colors.grey[850] ?? Colors.grey : Colors.grey[100] ?? Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(3),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: bgColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Period',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: subtleColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Forecast',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: subtleColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Confidence Interval',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: subtleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...data.map(
                  (point) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          point.period,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${point.value.toStringAsFixed(0)} $unit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '±${(point.errorMargin).toStringAsFixed(0)} $unit',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build alerts section
  Widget _buildAlertsSection(ForecastDetailModel forecast) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    if (forecast.alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '✅',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'No alerts',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Alerts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...forecast.alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alert.getAlertColor().withOpacity(0.1),
                    border: Border(
                      left: BorderSide(
                        color: alert.getAlertColor(),
                        width: 4,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            alert.getAlertIcon(),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.message,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(alert.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
