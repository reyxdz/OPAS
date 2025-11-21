import 'package:flutter/material.dart';
import '../services/seller_service.dart';

/// Enhanced Forecast Insights Screen with Trend Analysis (Phase 3.3)
/// Displays detailed forecast insights, trends, and actionable recommendations
class EnhancedForecastInsightsScreen extends StatefulWidget {
  const EnhancedForecastInsightsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedForecastInsightsScreen> createState() => _EnhancedForecastInsightsScreenState();
}

class _EnhancedForecastInsightsScreenState extends State<EnhancedForecastInsightsScreen> {
  late Future<Map<String, dynamic>> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = SellerService.getForecastInsights();
  }

  void _refresh() {
    setState(() {
      _insightsFuture = SellerService.getForecastInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forecast Insights & Trends'),
        elevation: 0,
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _insightsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No insights available'));
          }

          final insights = snapshot.data!;
          final totalDemand = insights['total_forecasted_demand'] ?? 0;
          final avgConfidence = (insights['average_confidence'] ?? 0.0).toDouble();
          final highRiskCount = insights['high_risk_count'] ?? 0;
          final mediumRiskCount = insights['medium_risk_count'] ?? 0;
          final lowRiskCount = insights['low_risk_count'] ?? 0;
          final trendSummary = insights['trend_summary'] ?? {};
          final highRiskProducts = List<Map<String, dynamic>>.from(insights['high_risk_products'] ?? []);
          final recommendations = List<String>.from(insights['recommendations'] ?? []);

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _insightsFuture;
            },
            color: Colors.deepOrange,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Summary Cards
                _buildSummaryCard(
                  icon: '📊',
                  title: 'Total Forecasted Demand',
                  value: '$totalDemand units',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  icon: '🎯',
                  title: 'Average Confidence',
                  value: '${avgConfidence.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                // Risk Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade50, Colors.orange.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Risk Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRiskBadge(
                              label: 'High Risk',
                              count: highRiskCount,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRiskBadge(
                              label: 'Medium Risk',
                              count: mediumRiskCount,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRiskBadge(
                              label: 'Low Risk',
                              count: lowRiskCount,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Trend Analysis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.cyan.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📈 Trend Analysis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTrendBadge(
                              label: 'Uptrend',
                              count: trendSummary['uptrend'] ?? 0,
                              emoji: '📈',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTrendBadge(
                              label: 'Stable',
                              count: trendSummary['stable'] ?? 0,
                              emoji: '➡️',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTrendBadge(
                              label: 'Downtrend',
                              count: trendSummary['downtrend'] ?? 0,
                              emoji: '📉',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // High Risk Products
                if (highRiskProducts.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🚨 High-Risk Products',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ...highRiskProducts.map((product) => _buildHighRiskProductTile(product)).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Recommendations
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Recommendations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ...recommendations.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 13),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge({
    required String label,
    required int count,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHighRiskProductTile(Map<String, dynamic> product) {
    final productName = product['product_name'] ?? 'Unknown';
    final forecastedDemand = product['forecasted_demand'] ?? 0;
    final currentStock = product['current_stock'] ?? 0;
    final surplusRisk = (product['surplus_risk'] as num?)?.toDouble() ?? 0.0;
    final stockoutRisk = (product['stockout_risk'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Forecasted: $forecastedDemand units',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                'Stock: $currentStock',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildRiskProgressBar(
                  label: 'Surplus',
                  value: surplusRisk,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRiskProgressBar(
                  label: 'Stockout',
                  value: stockoutRisk,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskProgressBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
