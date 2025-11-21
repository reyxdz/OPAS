import 'package:flutter/material.dart';
import '../services/seller_service.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;
  late Future<List<Map<String, dynamic>>> _topProductsFuture;
  late Future<List<Map<String, dynamic>>> _monthlyFuture;
  
  String _selectedTimeframe = 'MONTHLY'; // DAILY, WEEKLY, MONTHLY

  @override
  void initState() {
    super.initState();
    _refreshAnalytics();
  }

  Future<void> _refreshAnalytics() {
    _dashboardFuture = SellerService.getDashboardAnalytics();
    _topProductsFuture = SellerService.getAnalyticsTopProducts();
    _monthlyFuture = SellerService.getMonthlyAnalytics().then((data) {
      return data.entries
          .map((e) => {
            'month': e.key,
            'orders': e.value['count'] ?? 0,
            'revenue': e.value['total'] ?? '0',
          })
          .toList();
    });
    
    return Future.wait([_dashboardFuture, _topProductsFuture, _monthlyFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales & Analytics'),
          centerTitle: true,
          elevation: 2,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Top Products'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Dashboard Tab
            _buildDashboardTab(),
            // Top Products Tab
            _buildTopProductsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refreshAnalytics,
          tooltip: 'Refresh analytics',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<Map<String, dynamic>>(
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
                const Text('Failed to load analytics'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalOrders = data['total_orders'] as int? ?? 0;
        final completedOrders = data['completed_orders'] as int? ?? 0;
        final pendingOrders = data['pending_orders'] as int? ?? 0;
        final totalRevenue = data['total_revenue'] ?? '0';
        final totalProducts = data['total_products'] as int? ?? 0;
        final activeProducts = data['active_products'] as int? ?? 0;
        final avgOrderValue = data['avg_order_value'] ?? '0';

        return RefreshIndicator(
          onRefresh: _refreshAnalytics,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key Metrics Grid
                const Text(
                  'Key Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // First Row - Orders and Revenue
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Orders',
                        value: '$totalOrders',
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                        subtitle: '$completedOrders completed',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Revenue',
                        value: '₱${_formatCurrency(totalRevenue)}',
                        icon: Icons.money,
                        color: Colors.green,
                        subtitle: 'Avg: ₱${_formatCurrency(avgOrderValue)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Second Row - Products and Pending
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Products',
                        value: '$totalProducts',
                        icon: Icons.inventory_2,
                        color: Colors.orange,
                        subtitle: '$activeProducts active',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Pending Orders',
                        value: '$pendingOrders',
                        icon: Icons.pending_actions,
                        color: Colors.amber,
                        subtitle: 'Awaiting action',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sales Trend Section
                const Text(
                  'Sales Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Timeframe Selector
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'DAILY',
                            label: Text('Daily'),
                          ),
                          ButtonSegment<String>(
                            value: 'WEEKLY',
                            label: Text('Weekly'),
                          ),
                          ButtonSegment<String>(
                            value: 'MONTHLY',
                            label: Text('Monthly'),
                          ),
                        ],
                        selected: <String>{_selectedTimeframe},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedTimeframe = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sales Chart
                _buildSalesTrendChart(),
                const SizedBox(height: 24),

                // Monthly Breakdown
                const Text(
                  'Monthly Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMonthlyBreakdown(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    if (_selectedTimeframe == 'DAILY') {
      return FutureBuilder<Map<String, dynamic>>(
        future: SellerService.getDailyAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildChartCard(
            title: 'Daily Sales',
            data: snapshot.data ?? {},
          );
        },
      );
    } else if (_selectedTimeframe == 'WEEKLY') {
      return FutureBuilder<Map<String, dynamic>>(
        future: SellerService.getWeeklyAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildChartCard(
            title: 'Weekly Sales',
            data: snapshot.data ?? {},
          );
        },
      );
    } else {
      return FutureBuilder<Map<String, dynamic>>(
        future: SellerService.getMonthlyAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildChartCard(
            title: 'Monthly Sales',
            data: snapshot.data ?? {},
          );
        },
      );
    }
  }

  Widget _buildChartCard({
    required String title,
    required Map<String, dynamic> data,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.length.clamp(0, 12),
                itemBuilder: (context, index) {
                  final entries = data.entries.toList();
                  if (index >= entries.length) return const SizedBox.shrink();
                  
                  final entry = entries[index];
                  final key = entry.key;
                  final value = entry.value;
                  
                  final orders = (value is Map ? value['count'] : 0) as int;
                  final revenue = value is Map ? value['total'] : '0';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: 'Orders: $orders\nRevenue: ₱$revenue',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 40,
                              height: (orders * 5).toDouble().clamp(10, 150),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade200,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          key.toString().split('-').last.substring(0, 3),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chart shows order volume over time',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _monthlyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No monthly data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final data = snapshot.data ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final month = item['month'] as String? ?? 'N/A';
            final orders = item['orders'] as int? ?? 0;
            final revenue = item['revenue'] as String? ?? '0';

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
                          month,
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
                    Text(
                      '₱${_formatCurrency(revenue)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopProductsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _topProductsFuture,
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
                const Text('Failed to load top products'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No top products data available'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshAnalytics,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final rank = index + 1;
              final name = product['name'] as String? ?? 'Unknown';
              final orders = product['orders'] as int? ?? 0;
              final revenue = product['revenue'] as String? ?? '0';
              final stock = product['stock'] as int? ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank and Product Name
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getRankColor(rank),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#$rank',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stock: $stock units',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Orders', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('$orders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Revenue', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('₱${_formatCurrency(revenue)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
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
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade600;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.orange.shade600;
    return Colors.blue.shade600;
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
