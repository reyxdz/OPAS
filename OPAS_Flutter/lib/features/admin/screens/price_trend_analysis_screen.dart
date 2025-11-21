import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/price_trend_model.dart';
import 'package:opas_flutter/features/admin/widgets/trend_chart.dart';
import 'package:opas_flutter/features/admin/widgets/alert_widget.dart';

class PriceTrendAnalysisScreen extends StatefulWidget {
  const PriceTrendAnalysisScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PriceTrendAnalysisScreenState createState() =>
      _PriceTrendAnalysisScreenState();
}

class _PriceTrendAnalysisScreenState extends State<PriceTrendAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PriceTrendModel>> _trendsFuture;
  late Future<Map<String, dynamic>> _comparisonFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    _trendsFuture = _fetchPriceTrends();
    _comparisonFuture = _fetchComparison();
  }

  Future<List<PriceTrendModel>> _fetchPriceTrends() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      return [
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now().subtract(const Duration(days: 6)),
          currentPrice: 145000,
          priceTarget: 140000,
          overagePercentage: 3.6,
          complianceStatus: 'warning',
        ),
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now().subtract(const Duration(days: 5)),
          currentPrice: 143500,
          priceTarget: 140000,
          overagePercentage: 2.5,
          complianceStatus: 'warning',
        ),
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now().subtract(const Duration(days: 4)),
          currentPrice: 142000,
          priceTarget: 140000,
          overagePercentage: 1.4,
          complianceStatus: 'compliant',
        ),
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now().subtract(const Duration(days: 3)),
          currentPrice: 141500,
          priceTarget: 140000,
          overagePercentage: 1.1,
          complianceStatus: 'compliant',
        ),
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now().subtract(const Duration(days: 2)),
          currentPrice: 140500,
          priceTarget: 140000,
          overagePercentage: 0.4,
          complianceStatus: 'compliant',
        ),
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now().subtract(const Duration(days: 1)),
          currentPrice: 140200,
          priceTarget: 140000,
          overagePercentage: 0.1,
          complianceStatus: 'compliant',
        ),
        PriceTrendModel(
          productName: 'Laptop Pro',
          date: DateTime.now(),
          currentPrice: 140000,
          priceTarget: 140000,
          overagePercentage: 0.0,
          complianceStatus: 'compliant',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to load price trends: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchComparison() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'products': [
          {
            'name': 'Laptop Pro',
            'ceiling': 140000,
            'current': 140000,
            'status': 'compliant',
            'sellers': 45,
            'violations': 0,
          },
          {
            'name': 'Smartphone X',
            'ceiling': 85000,
            'current': 87500,
            'status': 'violation',
            'sellers': 128,
            'violations': 12,
          },
          {
            'name': 'Tablet Ultra',
            'ceiling': 52000,
            'current': 51800,
            'status': 'compliant',
            'sellers': 82,
            'violations': 0,
          },
          {
            'name': 'Wireless Headphones',
            'ceiling': 8500,
            'current': 8900,
            'status': 'violation',
            'sellers': 156,
            'violations': 8,
          },
          {
            'name': 'Smart Watch',
            'ceiling': 12000,
            'current': 11950,
            'status': 'compliant',
            'sellers': 93,
            'violations': 0,
          },
        ]
      };
    } catch (e) {
      throw Exception('Failed to load comparison data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Price Trend Analysis'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trends'),
            Tab(text: 'Compliance'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_refreshData),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTrendsTab(),
            _buildComplianceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return FutureBuilder<List<PriceTrendModel>>(
      future: _trendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AlertWidget(
              title: 'Error',
              message: 'Failed to load price trends',
              severity: 'critical',
              icon: Icons.error,
            ),
          );
        }

        final trends = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Movement Tracking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TrendChart(
                data: TrendChartData(
                  values: trends.map((t) => t.currentPrice).toList(),
                  labels: trends.map((t) => DateFormat('MMM dd').format(t.date)).toList(),
                  title: 'Laptop Pro - Price Trend',
                  unit: 'PKR',
                ),
                lineColor: const Color(0xFF2196F3),
                fillColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 24),

              // Key Metrics
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: [
                  _buildSummaryCard(
                    label: 'Current Price',
                    value: 'PKR ${trends.last.currentPrice.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: const Color(0xFF2196F3),
                  ),
                  _buildSummaryCard(
                    label: 'Price Target',
                    value: 'PKR ${trends.last.priceTarget.toStringAsFixed(0)}',
                    icon: Icons.tablet,
                    color: const Color(0xFF4CAF50),
                  ),
                  _buildSummaryCard(
                    label: 'Overage %',
                    value: '${trends.last.overagePercentage.toStringAsFixed(2)}%',
                    icon: Icons.warning,
                    color: const Color(0xFFFF9800),
                  ),
                  _buildSummaryCard(
                    label: 'Compliance',
                    value: trends.last.isCompliant() ? 'Compliant' : 'Violation',
                    icon: Icons.verified,
                    color: trends.last.isCompliant() ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Price History
              Text(
                'Price History',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final trend = trends[trends.length - 1 - index]; // Reverse order (latest first)
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: trend.isCompliant() ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              trend.isCompliant() ? Icons.check_circle : Icons.warning_amber,
                              color: trend.isCompliant() ? Colors.green : Colors.orange,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(trend.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PKR ${trend.currentPrice.toStringAsFixed(0)} (Target: PKR ${trend.priceTarget.toStringAsFixed(0)})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${trend.overagePercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: trend.isCompliant() ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplianceTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _comparisonFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AlertWidget(
              title: 'Error',
              message: 'Failed to load compliance data',
              severity: 'critical',
              icon: Icons.error,
            ),
          );
        }

        final products = (snapshot.data?['products'] as List?) ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Ceiling Compliance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index] as Map<String, dynamic>;
                  final status = product['status'] as String?;
                  final isViolation = status == 'violation';

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (isViolation ? const Color(0xFFF44336) : const Color(0xFF4CAF50)).withOpacity(0.05),
                            (isViolation ? const Color(0xFFF44336) : const Color(0xFF4CAF50)).withOpacity(0.02),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] as String? ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${product['sellers']} active sellers',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isViolation ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isViolation ? 'VIOLATION' : 'COMPLIANT',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price Ceiling',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  Text(
                                    'PKR ${(product['ceiling'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Price',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  Text(
                                    'PKR ${(product['current'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isViolation ? const Color(0xFFF44336) : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              if (((product['violations'] as num?)?.toInt() ?? 0) > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Violations',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    Text(
                                      '${product['violations']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF44336),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
