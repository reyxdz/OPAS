// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/analytics_dashboard_model.dart';
import 'package:opas_flutter/core/models/sales_trend_model.dart';
import 'package:opas_flutter/features/admin/widgets/metric_card.dart';
import 'package:opas_flutter/features/admin/widgets/trend_chart.dart';
import 'package:opas_flutter/features/admin/widgets/alert_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AnalyticsDashboardModel> _dashboardFuture;
  late Future<List<SalesTrendModel>> _trendsFuture;
  AnalyticsDashboardModel? _dashboardData;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _dashboardFuture = _fetchDashboard();
    _trendsFuture = _fetchSalesTrends();
  }

  Future<AnalyticsDashboardModel> _fetchDashboard() async {
    try {
      // Simulated data - replace with actual API call
      await Future.delayed(const Duration(milliseconds: 800));
      _dashboardData = AnalyticsDashboardModel(
        totalSellers: 1250,
        pendingSellers: 45,
        activeSellers: 1180,
        marketHealthScore: 9,
        opasInventoryCount: 5420,
        alertsCount: 12,
        totalRevenue: 2500000,
        ordersToday: 342,
        priceViolations: 8,
        averageTransaction: 7315,
        lastUpdated: DateTime.now(),
      );
      return _dashboardData!;
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  Future<List<SalesTrendModel>> _fetchSalesTrends() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      return [
        SalesTrendModel(
          date: DateTime.now().subtract(const Duration(days: 6)),
          salesAmount: 145000,
          orderCount: 42,
          category: 'Electronics',
        ),
        SalesTrendModel(
          date: DateTime.now().subtract(const Duration(days: 5)),
          salesAmount: 168000,
          orderCount: 48,
          category: 'Electronics',
        ),
        SalesTrendModel(
          date: DateTime.now().subtract(const Duration(days: 4)),
          salesAmount: 142000,
          orderCount: 39,
          category: 'Electronics',
        ),
        SalesTrendModel(
          date: DateTime.now().subtract(const Duration(days: 3)),
          salesAmount: 185000,
          orderCount: 52,
          category: 'Electronics',
        ),
        SalesTrendModel(
          date: DateTime.now().subtract(const Duration(days: 2)),
          salesAmount: 172000,
          orderCount: 45,
          category: 'Electronics',
        ),
        SalesTrendModel(
          date: DateTime.now().subtract(const Duration(days: 1)),
          salesAmount: 198000,
          orderCount: 55,
          category: 'Electronics',
        ),
        SalesTrendModel(
          date: DateTime.now(),
          salesAmount: 210000,
          orderCount: 58,
          category: 'Electronics',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to load trends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_refreshData),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_refreshData),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s what\'s happening today',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Key Metrics Grid
              FutureBuilder<AnalyticsDashboardModel>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: List.generate(
                        4,
                        (i) => const MetricCard(
                          label: 'Loading...',
                          value: '--',
                          icon: Icons.trending_up,
                          backgroundColor: Colors.blue,
                          iconColor: Colors.blue,
                          isLoading: true,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const AlertWidget(
                      title: 'Error',
                      message: 'Failed to load dashboard metrics',
                      severity: 'critical',
                      icon: Icons.error,
                      isDismissible: true,
                    );
                  }

                  final data = snapshot.data!;

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      MetricCard(
                        label: 'Active Sellers',
                        value: '${data.activeSellers}',
                        subtitle: '+${data.activeSellers - data.pendingSellers} today',
                        icon: Icons.people,
                        backgroundColor: const Color(0xFF4CAF50),
                        iconColor: const Color(0xFF4CAF50),
                        trend: '+12.5%',
                      ),
                      MetricCard(
                        label: 'Total Revenue',
                        value: 'PKR ${(data.totalRevenue / 1000000).toStringAsFixed(1)}M',
                        subtitle: 'This month',
                        icon: Icons.attach_money,
                        backgroundColor: const Color(0xFF2196F3),
                        iconColor: const Color(0xFF2196F3),
                        trend: '+8.2%',
                      ),
                      MetricCard(
                        label: 'Orders Today',
                        value: '${data.ordersToday}',
                        subtitle: 'Real-time',
                        icon: Icons.shopping_bag,
                        backgroundColor: const Color(0xFFFF9800),
                        iconColor: const Color(0xFFFF9800),
                        trend: '+15.3%',
                      ),
                      MetricCard(
                        label: 'Market Health',
                        value: '${data.marketHealthScore.toStringAsFixed(1)}/10',
                        subtitle: 'Overall score',
                        icon: Icons.favorite,
                        backgroundColor: const Color(0xFFF44336),
                        iconColor: const Color(0xFFF44336),
                        trend: '+0.3',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Alerts Section
              const Text(
                'Active Alerts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<AnalyticsDashboardModel>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                  }

                  final data = snapshot.data!;
                  return Column(
                    children: [
                      if (data.alertsCount > 0)
                        AlertWidget(
                          title: 'Price Violations Detected',
                          message: '${data.priceViolations} sellers have pricing violations',
                          severity: 'warning',
                          icon: Icons.warning_amber,
                          actionLabel: 'Review',
                          onAction: () {},
                        ),
                      if (data.pendingSellers > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: AlertWidget(
                            title: 'Pending Approvals',
                            message: '${data.pendingSellers} seller applications awaiting review',
                            severity: 'info',
                            icon: Icons.schedule,
                            actionLabel: 'Approve',
                            onAction: () {},
                          ),
                        ),
                      if (data.opasInventoryCount < 2000)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: AlertWidget(
                            title: 'Low OPAS Inventory',
                            message: 'Current inventory: ${data.opasInventoryCount} units',
                            severity: 'critical',
                            icon: Icons.inventory_2,
                            actionLabel: 'Restock',
                            onAction: () {},
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Sales Trend Chart
              const Text(
                'Sales Trend (Last 7 Days)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SalesTrendModel>>(
                future: _trendsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return TrendChart(
                      data: TrendChartData(
                        values: [],
                        labels: [],
                      ),
                      isLoading: true,
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const AlertWidget(
                      title: 'Error',
                      message: 'Failed to load sales trends',
                      severity: 'critical',
                      icon: Icons.error,
                    );
                  }

                  final trends = snapshot.data!;
                  final values = trends.map((t) => t.salesAmount).toList();
                  final labels = trends.map((t) => DateFormat('MMM dd').format(t.date)).toList();

                  return TrendChart(
                    data: TrendChartData(
                      values: values,
                      labels: labels,
                      title: 'Daily Sales Revenue',
                      unit: 'PKR',
                    ),
                    lineColor: const Color(0xFF2196F3),
                    fillColor: const Color(0xFF2196F3),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _buildQuickActionButton(
                    label: 'View Analytics',
                    icon: Icons.analytics,
                    color: const Color(0xFF2196F3),
                    onTap: () {},
                  ),
                  _buildQuickActionButton(
                    label: 'Manage Sellers',
                    icon: Icons.people_alt,
                    color: const Color(0xFF4CAF50),
                    onTap: () {},
                  ),
                  _buildQuickActionButton(
                    label: 'Price Management',
                    icon: Icons.local_offer,
                    color: const Color(0xFFFF9800),
                    onTap: () {},
                  ),
                  _buildQuickActionButton(
                    label: 'Generate Report',
                    icon: Icons.description,
                    color: const Color(0xFF9C27B0),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
