import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/forecast_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:fl_chart/fl_chart.dart';

/// Forecast History Screen - Phase 5.1 C
/// 
/// Displays historical forecasts for a product, showing:
/// - All past forecast versions (not just current)
/// - Forecast generation dates and predictions
/// - How predictions changed over time
/// - Confidence levels and model types used
class ForecastHistoryScreen extends StatefulWidget {
  final String productName;
  final String? categoryName;

  const ForecastHistoryScreen({
    Key? key,
    required this.productName,
    this.categoryName,
  }) : super(key: key);

  @override
  State<ForecastHistoryScreen> createState() => _ForecastHistoryScreenState();
}

class _ForecastHistoryScreenState extends State<ForecastHistoryScreen> {
  late Future<List<ForecastModel>> _historicalForecastsFuture;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistoricalForecasts();
  }

  void _loadHistoricalForecasts() {
    _historicalForecastsFuture = _fetchHistoricalForecasts();
  }

  Future<List<ForecastModel>> _fetchHistoricalForecasts() async {
    try {
      // Fetch all forecasts (including historical) for this product
      final data = await AdminService.getHistoricalForecasts(widget.productName);
      
      final forecasts = (data)
          .map((item) => ForecastModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort by forecast date descending (newest first)
      forecasts.sort((a, b) => b.forecastDate.compareTo(a.forecastDate));

      return forecasts;
    } catch (e) {
      debugPrint('Error fetching forecast history: $e');
      return [];
    }
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName),
            const Text(
              'Forecast History',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () {
              setState(() => _loadHistoricalForecasts());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ForecastModel>>(
        future: _historicalForecastsFuture,
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
                    onPressed: () => setState(() => _loadHistoricalForecasts()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final forecasts = snapshot.data ?? [];

          if (forecasts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No forecast history available'),
                  const SizedBox(height: 8),
                  Text(
                    'Forecast history will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Chart section showing progression
              _buildProgressionChart(forecasts, cardColor, textColor),
              const SizedBox(height: 24),
              
              // Detailed forecast cards
              ...List.generate(
                forecasts.length,
                (index) => Column(
                  children: [
                    _buildForecastHistoryCard(
                      context,
                      forecasts[index],
                      index + 1,
                      cardColor,
                      textColor,
                      subtleColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressionChart(
    List<ForecastModel> forecasts,
    Color? cardColor,
    Color? textColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    
    // Sort by date ascending (oldest first) for chart
    final sortedForecasts = List<ForecastModel>.from(forecasts)
      ..sort((a, b) => a.forecastDate.compareTo(b.forecastDate));

    // Create chart data points
    final demandSpots = <FlSpot>[];
    final priceSpots = <FlSpot>[];

    for (int i = 0; i < sortedForecasts.length; i++) {
      demandSpots.add(
        FlSpot(i.toDouble(), sortedForecasts[i].demandForecastKg),
      );
      priceSpots.add(
        FlSpot(i.toDouble(), sortedForecasts[i].priceForecast),
      );
    }

    return Card(
      color: cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Progression',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Demand chart
            _buildChart(
              title: 'Demand Forecast Progression (kg)',
              spots: demandSpots,
              gridColor: gridColor,
              lineColor: Colors.blue,
              forecasts: sortedForecasts,
            ),
            const SizedBox(height: 32),
            
            // Price chart
            _buildChart(
              title: 'Price Forecast Progression (₱/kg)',
              spots: priceSpots,
              gridColor: gridColor,
              lineColor: Colors.orange,
              forecasts: sortedForecasts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart({
    required String title,
    required List<FlSpot> spots,
    Color? gridColor,
    required Color lineColor,
    required List<ForecastModel> forecasts,
  }) {
    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate min/max for Y axis
    final yValues = spots.map((spot) => spot.y).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        // Chart with fixed left axis and scrollable content
        SizedBox(
          height: 270,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Y-axis labels on the left
              SizedBox(
                width: 45,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final yValue = (minY - padding) + 
                          ((maxY + padding) - (minY - padding)) * (1 - index / 4);
                      return Text(
                        yValue.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 9),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Scrollable chart area
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: (spots.length * 60).toDouble().clamp(300, double.infinity),
                    height: 270,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: (maxY - minY) / 4,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: gridColor ?? Colors.grey[300],
                              strokeWidth: 0.5,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: gridColor ?? Colors.grey[300],
                              strokeWidth: 0.5,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.round();
                                if (index >= 0 && index < forecasts.length) {
                                  final date = forecasts[index].forecastDate;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('MMM d').format(date),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              interval: 1,
                              reservedSize: 40,
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: lineColor,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: lineColor,
                                  strokeWidth: 0,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: lineColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: (minY - padding).clamp(0, double.infinity),
                        maxY: maxY + padding,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastHistoryCard(
    BuildContext context,
    ForecastModel forecast,
    int index,
    Color? cardColor,
    Color? textColor,
    Color? subtleColor,
  ) {
    final isCurrent = forecast.isCurrent;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: isCurrent ? 3 : 1,
      child: InkWell(
        onTap: () {
          // Could add drill-down to detail view
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and current badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forecast #$index',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(forecast.forecastDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Forecast period
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Period: ${forecast.forecastPeriod}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forecast data in two columns
              Row(
                children: [
                  // Demand
                  Expanded(
                    child: _buildForecastDataColumn(
                      label: 'Demand Forecast',
                      value: '${forecast.demandForecastKg.toStringAsFixed(2)} kg',
                      bounds: '±${(forecast.demandUpperBound - forecast.demandForecastKg).abs().toStringAsFixed(2)} kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Price
                  Expanded(
                    child: _buildForecastDataColumn(
                      label: 'Price Forecast',
                      value: '₱${forecast.priceForecast.toStringAsFixed(2)}/kg',
                      bounds: '±₱${(forecast.priceUpperBound - forecast.priceForecast).abs().toStringAsFixed(2)}/kg',
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Model and confidence info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        forecast.getModelLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceBgColor(forecast.confidenceLevel),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          forecast.confidenceLevel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    forecast.getConfidenceEmoji(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastDataColumn({
    required String label,
    required String value,
    required String bounds,
    Color? textColor,
    Color? subtleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: subtleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bounds,
          style: TextStyle(
            fontSize: 11,
            color: subtleColor,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceBgColor(String confidence) {
    switch (confidence) {
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
