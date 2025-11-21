import 'package:flutter/material.dart';
import '../services/seller_service.dart';

class RevenueBreakdownScreen extends StatefulWidget {
  const RevenueBreakdownScreen({Key? key}) : super(key: key);

  @override
  State<RevenueBreakdownScreen> createState() => _RevenueBreakdownScreenState();
}

class _RevenueBreakdownScreenState extends State<RevenueBreakdownScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;
  late Future<List<Map<String, dynamic>>> _monthlyFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() {
    _dashboardFuture = SellerService.getDashboardAnalytics();
    _monthlyFuture = SellerService.getMonthlyAnalytics().then((data) {
      return data.entries
          .map((e) => {
            'month': e.key,
            'orders': e.value['count'] ?? 0,
            'revenue': e.value['total'] ?? '0',
          })
          .toList();
    });
    
    return Future.wait([_dashboardFuture, _monthlyFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Breakdown'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text('Failed to load revenue data'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final totalRevenue = data['total_revenue'] ?? '0';
          final completedOrders = data['completed_orders'] as int? ?? 0;
          final avgOrderValue = data['avg_order_value'] ?? '0';
          final totalOrders = data['total_orders'] as int? ?? 0;
          final pendingOrders = data['pending_orders'] as int? ?? 0;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Summary Card
                  _buildRevenueSummaryCard(
                    totalRevenue: totalRevenue,
                    completedOrders: completedOrders,
                    avgOrderValue: avgOrderValue,
                  ),
                  const SizedBox(height: 24),

                  // Revenue Metrics
                  const Text(
                    'Revenue Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueMetricTile(
                          title: 'Completed Orders',
                          value: '$completedOrders',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRevenueMetricTile(
                          title: 'Pending Orders',
                          value: '$pendingOrders',
                          icon: Icons.hourglass_empty,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueMetricTile(
                          title: 'Total Orders',
                          value: '$totalOrders',
                          icon: Icons.shopping_cart,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRevenueMetricTile(
                          title: 'Avg Per Order',
                          value: '₱${_formatCurrency(avgOrderValue)}',
                          icon: Icons.trending_up,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Monthly Revenue Breakdown
                  const Text(
                    'Monthly Revenue Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyRevenueBreakdown(),
                  const SizedBox(height: 24),

                  // Revenue Insights
                  _buildRevenueInsights(
                    totalRevenue: totalRevenue,
                    completedOrders: completedOrders,
                    avgOrderValue: avgOrderValue,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        tooltip: 'Refresh data',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildRevenueSummaryCard({
    required dynamic totalRevenue,
    required int completedOrders,
    required dynamic avgOrderValue,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade600,
              Colors.green.shade800,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Revenue',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '₱${_formatCurrency(totalRevenue)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Orders Completed',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedOrders',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Per Order',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_formatCurrency(avgOrderValue)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildRevenueMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueBreakdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _monthlyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No monthly revenue data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final months = snapshot.data ?? [];
        double maxRevenue = 0;

        // Calculate max revenue for scaling
        for (var month in months) {
          try {
            final revenue = double.parse(month['revenue'].toString());
            if (revenue > maxRevenue) maxRevenue = revenue;
          } catch (e) {
            // Skip invalid values
          }
        }

        if (maxRevenue == 0) maxRevenue = 1;

        return Column(
          children: [
            // Bar Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: months.length,
                      itemBuilder: (context, index) {
                        final month = months[index];
                        final monthName = month['month'] as String? ?? 'N/A';
                        final revenue =
                            double.tryParse(month['revenue'].toString()) ?? 0;
                        final normalizedHeight =
                            ((revenue / maxRevenue * 180).clamp(10, 180) as double);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: '₱${_formatCurrency(revenue)}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 50,
                                    height: normalizedHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.green.shade600,
                                          Colors.green.shade300,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                monthName.split('-')[1],
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List View with Details
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final monthName = month['month'] as String? ?? 'N/A';
                final orders = month['orders'] as int? ?? 0;
                final revenue = month['revenue'] as dynamic;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$orders orders',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱${_formatCurrency(revenue)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              orders > 0
                                  ? '₱${_formatCurrency((double.tryParse(revenue.toString()) ?? 0) / orders)}/order'
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueInsights({
    required dynamic totalRevenue,
    required int completedOrders,
    required dynamic avgOrderValue,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.trending_up,
              title: 'Strong Performance',
              description: completedOrders > 10
                  ? 'You\'ve completed $completedOrders orders'
                  : 'Keep improving your sales performance',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.info_outline,
              title: 'Average Order Value',
              description:
                  'Your average order value is ₱${_formatCurrency(avgOrderValue)}',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.star,
              title: 'Revenue Growth',
              description:
                  'Total revenue earned: ₱${_formatCurrency(totalRevenue)}',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0.00';

    String strValue = value.toString();
    try {
      final double numValue = double.parse(strValue);
      return numValue.toStringAsFixed(2);
    } catch (e) {
      return strValue;
    }
  }
}
