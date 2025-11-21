import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/forecast_model.dart';
import 'package:opas_flutter/features/admin/widgets/forecast_card.dart';
import 'package:opas_flutter/features/admin/widgets/alert_widget.dart';

class DemandForecastAdminScreen extends StatefulWidget {
  const DemandForecastAdminScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DemandForecastAdminScreenState createState() =>
      _DemandForecastAdminScreenState();
}

class _DemandForecastAdminScreenState extends State<DemandForecastAdminScreen> {
  String _selectedTimeframe = 'monthly';
  late Future<List<ForecastModel>> _forecastFuture;
  late Future<Map<String, dynamic>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _forecastFuture = _fetchForecasts();
    _recommendationsFuture = _fetchRecommendations();
  }

  Future<List<ForecastModel>> _fetchForecasts() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return [
        ForecastModel(
          productName: 'Laptop Pro',
          forecastDate: DateTime.now().add(const Duration(days: 30)),
          predictedDemand: 450,
          confidence: 0.92,
          seasonality: 'high',
          trend: 'increasing',
          recommendation: 'Increase inventory by 20%',
        ),
        ForecastModel(
          productName: 'Smartphone X',
          forecastDate: DateTime.now().add(const Duration(days: 30)),
          predictedDemand: 850,
          confidence: 0.88,
          seasonality: 'medium',
          trend: 'increasing',
          recommendation: 'Maintain current stock levels',
        ),
        ForecastModel(
          productName: 'Tablet Ultra',
          forecastDate: DateTime.now().add(const Duration(days: 30)),
          predictedDemand: 320,
          confidence: 0.85,
          seasonality: 'low',
          trend: 'stable',
          recommendation: 'Monitor closely for changes',
        ),
        ForecastModel(
          productName: 'Wireless Headphones',
          forecastDate: DateTime.now().add(const Duration(days: 30)),
          predictedDemand: 1200,
          confidence: 0.79,
          seasonality: 'high',
          trend: 'decreasing',
          recommendation: 'Reduce stock by 15%',
        ),
        ForecastModel(
          productName: 'Smart Watch',
          forecastDate: DateTime.now().add(const Duration(days: 30)),
          predictedDemand: 580,
          confidence: 0.91,
          seasonality: 'medium',
          trend: 'increasing',
          recommendation: 'Increase inventory by 25%',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to load forecasts: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchRecommendations() async {
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      return {
        'alerts': [
          {
            'type': 'high_confidence',
            'message': '5 forecasts have high confidence (>0.85)',
            'icon': Icons.trending_up,
            'severity': 'info',
          },
          {
            'type': 'seasonal_peak',
            'message': 'Peak season approaching - prepare inventory',
            'icon': Icons.calendar_today,
            'severity': 'warning',
          },
        ],
        'insights': [
          {
            'title': 'Highest Demand Growth',
            'product': 'Smart Watch',
            'growth': '+28%',
            'period': 'Next 30 days',
          },
          {
            'title': 'Lowest Demand',
            'product': 'Tablet Ultra',
            'growth': '-5%',
            'period': 'Next 30 days',
          },
        ],
      };
    } catch (e) {
      throw Exception('Failed to load recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Demand Forecast'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_refreshData),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe Selector
              Text(
                'Forecast Period',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimeframeButton('Weekly', 'weekly'),
                  const SizedBox(width: 8),
                  _buildTimeframeButton('Monthly', 'monthly'),
                  const SizedBox(width: 8),
                  _buildTimeframeButton('Quarterly', 'quarterly'),
                ],
              ),
              const SizedBox(height: 24),

              // Alerts Section
              FutureBuilder<Map<String, dynamic>>(
                future: _recommendationsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final alerts = (snapshot.data?['alerts'] as List?) ?? [];
                  return Column(
                    children: List.generate(
                      alerts.length,
                      (index) {
                        final alert = alerts[index] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AlertWidget(
                            title: alert['type'] == 'high_confidence'
                                ? 'Strong Predictions'
                                : 'Seasonal Alert',
                            message: alert['message'] as String,
                            severity: alert['severity'] as String,
                            icon: alert['icon'] as IconData? ?? Icons.info,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: _recommendationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && ((snapshot.data?['alerts'] as List?)?.isNotEmpty ?? false)) {
                    return const SizedBox(height: 24);
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Forecasts Section
              const Text(
                'Product Demand Forecasts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<ForecastModel>>(
                future: _forecastFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => const ForecastCard(
                        productName: 'Loading...',
                        predictedValue: 0,
                        unit: 'units',
                        confidence: 0.0,
                        trend: 'stable',
                        recommendation: '',
                        isLoading: true,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const AlertWidget(
                      title: 'Error',
                      message: 'Failed to load forecasts',
                      severity: 'critical',
                      icon: Icons.error,
                    );
                  }

                  final forecasts = snapshot.data ?? [];
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: forecasts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final forecast = forecasts[index];
                      return ForecastCard(
                        productName: forecast.productName,
                        predictedValue: forecast.predictedDemand,
                        unit: 'units',
                        confidence: forecast.confidence,
                        trend: forecast.trend,
                        recommendation: forecast.recommendation,
                        trendColor: forecast.trend == 'increasing'
                            ? const Color(0xFF4CAF50)
                            : forecast.trend == 'decreasing'
                                ? const Color(0xFFF44336)
                                : Colors.grey,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Insights Section
              const Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _recommendationsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final insights = (snapshot.data?['insights'] as List?) ?? [];
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: insights.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final insight = insights[index] as Map<String, dynamic>;
                      final isPositive = (insight['growth'] as String?)?.startsWith('+') ?? false;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                                    .withOpacity(0.08),
                                (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                                    .withOpacity(0.02),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isPositive
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFF44336))
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isPositive
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: isPositive
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFF44336),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      insight['title'] as String? ?? 'Insight',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${insight['product']} - ${insight['period']}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                insight['growth'] as String? ?? '+0%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFF44336),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export Forecast Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.settings),
                  label: const Text('Adjust Forecast Settings'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2196F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String label, String value) {
    final isSelected = _selectedTimeframe == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTimeframe = value;
            _refreshData();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
