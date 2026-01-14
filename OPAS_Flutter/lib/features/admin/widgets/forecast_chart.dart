import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opas_flutter/core/models/forecast_detail_model.dart';

/// Forecast Line Chart Widget - Phase 5.1 B
/// 
/// Displays a line chart with historical data and forecast predictions
/// with confidence interval bands using fl_chart
class ForecastChart extends StatelessWidget {
  final String title;
  final List<ForecastDataPoint> historicalData;
  final List<ForecastDataPoint> forecastData;
  final String unit;
  final Color lineColor;
  final bool showConfidenceBand;

  const ForecastChart({
    Key? key,
    required this.title,
    required this.historicalData,
    required this.forecastData,
    required this.unit,
    this.lineColor = const Color(0xFF2196F3),
    this.showConfidenceBand = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    if (historicalData.isEmpty && forecastData.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final allData = [...historicalData, ...forecastData];
    final maxValue = allData.isEmpty 
        ? 100.0
        : allData.map((p) => (p.upperBound ?? p.value).toDouble()).reduce((a, b) => a > b ? a : b);
    final minValue = allData.isEmpty 
        ? 0.0
        : allData.map((p) => (p.lowerBound ?? (p.value * 0.8)).toDouble()).reduce((a, b) => a < b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            // Unit label
            Text(
              'Unit: $unit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Chart with horizontal padding for better scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 280,
                width: (MediaQuery.of(context).size.width - 32) * 1.5 + 96,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxValue - minValue) / 5,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: ((allData.length) / 6.0).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= allData.length) {
                            return const Text('');
                          }
                          return Text(
                            allData[index].period,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxValue - minValue) / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (allData.length - 1).toDouble(),
                  minY: minValue,
                  maxY: maxValue,
                  lineBarsData: [
                    // Historical data line
                    _buildLineBarData(
                      historicalData,
                      lineColor,
                      'Historical',
                    ),
                    // Forecast data line (dashed style)
                    _buildLineBarData(
                      forecastData,
                      lineColor.withOpacity(0.6),
                      'Forecast',
                      isDashed: true,
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index < 0 || index >= allData.length) {
                            return const LineTooltipItem('', TextStyle());
                          }
                          final point = allData[index];
                          String tooltip = '${point.period}\nValue: ${point.value.toStringAsFixed(2)}';
                          if (point.lowerBound != null && point.upperBound != null) {
                            tooltip +=
                                '\n(±${(point.upperBound! - point.value).toStringAsFixed(2)})';
                          }
                          return LineTooltipItem(
                            tooltip,
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  showingTooltipIndicators: [],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              children: [
                _buildLegendItem('Historical', lineColor),
                const SizedBox(width: 24),
                _buildLegendItem('Forecast', lineColor.withOpacity(0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a line bar data for the chart
  LineChartBarData _buildLineBarData(
    List<ForecastDataPoint> data,
    Color color,
    String label, {
    bool isDashed = false,
  }) {
    // Calculate starting index for this dataset
    int startIndex = historicalData.isEmpty ? 0 : historicalData.length;
    if (!isDashed) {
      startIndex = 0;
    } else {
      startIndex = historicalData.length - 1; // Overlap last point
    }

    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        final idx = entry.key;
        final point = entry.value;
        final xValue = startIndex + idx;
        return FlSpot(xValue.toDouble(), point.value);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  /// Build legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
