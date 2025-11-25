// CORE PRINCIPLE: Flutter performance monitoring dashboard
// - Real-time metrics visualization
// - Network performance tracking
// - Memory and CPU monitoring
// - User experience metrics

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opas_flutter/services/api_service.dart';

class PerformanceMonitoringScreen extends StatefulWidget {
  const PerformanceMonitoringScreen({Key? key}) : super(key: key);

  @override
  State<PerformanceMonitoringScreen> createState() =>
      _PerformanceMonitoringScreenState();
}

class _PerformanceMonitoringScreenState extends State<PerformanceMonitoringScreen> {
  final ApiService _apiService = ApiService.instance;
  
  // Metrics data
  Map<String, dynamic> _dashboardMetrics = {};
  List<Map<String, dynamic>> _apiMetrics = [];
  List<Map<String, dynamic>> _dailyTrends = [];
  
  bool _isLoading = false;
  String? _error;
  
  // Chart data
  List<FlSpot> _responseTimeSpots = [];
  List<FlSpot> _requestCountSpots = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  /// Load metrics from backend
  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load dashboard summary
      final dashboardResponse = await _apiService.get(
        '/api/v1/admin/metrics/dashboard/',
        queryParameters: {'days': 7},
      );

      // Load API metrics by endpoint
      final apiResponse = await _apiService.get(
        '/api/v1/admin/metrics/api-performance/',
        queryParameters: {'days': 7},
      );

      // Load trending data
      final trendingResponse = await _apiService.get(
        '/api/v1/admin/metrics/trending/',
      );

      setState(() {
        _dashboardMetrics = dashboardResponse;
        _apiMetrics = List<Map<String, dynamic>>.from(
          apiResponse['endpoints'] as List? ?? [],
        );
        _dailyTrends = List<Map<String, dynamic>>.from(
          trendingResponse['daily_metrics'] as List? ?? [],
        );
        
        _prepareChartData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load metrics: $e';
        _isLoading = false;
      });
    }
  }

  /// Prepare data for chart visualization
  void _prepareChartData() {
    _responseTimeSpots = [];
    _requestCountSpots = [];

    for (int i = 0; i < _dailyTrends.length; i++) {
      final trend = _dailyTrends[i];
      final x = i.toDouble();
      
      _responseTimeSpots.add(
        FlSpot(x, (trend['avg_response_time_ms'] as num?)?.toDouble() ?? 0),
      );
      
      _requestCountSpots.add(
        FlSpot(x, (trend['request_count'] as num?)?.toDouble() ?? 0),
      );
    }
  }

  /// Get health status color
  Color _getHealthStatusColor(String status) {
    switch (status) {
      case 'EXCELLENT':
        return Colors.green;
      case 'GOOD':
        return Colors.lightGreen;
      case 'FAIR':
        return Colors.amber;
      case 'POOR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Build health status card
  Widget _buildHealthStatusCard() {
    final status = _dashboardMetrics['health_status'] ?? 'UNKNOWN';
    
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getHealthStatusColor(status),
              width: 5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getHealthStatusColor(status).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    status.substring(0, 1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getHealthStatusColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getHealthStatusColor(status),
                      ),
                    ),
                    Text(
                      'Overall system status',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build metrics summary grid
  Widget _buildMetricsSummary() {
    final apiPerf = _dashboardMetrics['api_performance'] ?? {};
    final dbPerf = _dashboardMetrics['database_performance'] ?? {};
    final cachePerf = _dashboardMetrics['cache_performance'] ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildMetricCard(
          'API Response Time',
          '${apiPerf['avg_response_time_ms'] ?? 0}ms',
          'Average',
          Colors.blue,
        ),
        _buildMetricCard(
          'Error Rate',
          '${apiPerf['error_rate_percent'] ?? 0}%',
          'Last 7 days',
          Colors.red,
        ),
        _buildMetricCard(
          'Cache Hit Rate',
          '${cachePerf['cache_hit_rate_percent'] ?? 0}%',
          'Performance',
          Colors.green,
        ),
        _buildMetricCard(
          'Slow Queries',
          '${dbPerf['slow_query_percent'] ?? 0}%',
          'Database',
          Colors.orange,
        ),
      ],
    );
  }

  /// Build individual metric card
  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Build response time chart
  Widget _buildResponseTimeChart() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response Time Trend',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _responseTimeSpots.isEmpty
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('No data available'),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value >= 0 && value < _dailyTrends.length) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}ms',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _responseTimeSpots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Build API metrics table
  Widget _buildAPIMetricsTable() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endpoint Performance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _apiMetrics.isEmpty
                ? const Text('No data available')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Endpoint')),
                        DataColumn(label: Text('Avg Time')),
                        DataColumn(label: Text('Requests')),
                        DataColumn(label: Text('Errors')),
                      ],
                      rows: _apiMetrics.take(5).map((metric) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                (metric['endpoint'] as String).split('/').last,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${metric['avg_response_time_ms']}ms',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${metric['request_count']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${metric['error_count']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Build recommendations section
  Widget _buildRecommendations() {
    final recommendations = 
        (_dashboardMetrics['recommendations'] as List?) ?? [];

    if (recommendations.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text('System is performing optimally!'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optimization Recommendations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) {
          final severity = rec['severity'] ?? 'LOW';
          final severityColor = severity == 'HIGH'
              ? Colors.red
              : severity == 'MEDIUM'
                  ? Colors.orange
                  : Colors.amber;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: severityColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          severity,
                          style: TextStyle(
                            fontSize: 10,
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rec['area'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(rec['recommendation'] ?? ''),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMetrics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHealthStatusCard(),
                      const SizedBox(height: 16),
                      _buildMetricsSummary(),
                      const SizedBox(height: 16),
                      _buildResponseTimeChart(),
                      const SizedBox(height: 16),
                      _buildAPIMetricsTable(),
                      const SizedBox(height: 16),
                      _buildRecommendations(),
                    ],
                  ),
                ),
    );
  }
}
