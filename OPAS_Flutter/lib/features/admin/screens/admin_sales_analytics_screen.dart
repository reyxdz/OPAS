import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/sales_trend_model.dart';
import 'package:opas_flutter/features/admin/widgets/metric_card.dart';
import 'package:opas_flutter/features/admin/widgets/trend_chart.dart';
import 'package:opas_flutter/features/admin/widgets/alert_widget.dart';

class AdminSalesAnalyticsScreen extends StatefulWidget {
  const AdminSalesAnalyticsScreen({super.key});

  @override
  AdminSalesAnalyticsScreenState createState() =>
      AdminSalesAnalyticsScreenState();
}

class AdminSalesAnalyticsScreenState extends State<AdminSalesAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = '7days';
  late Future<List<SalesTrendModel>> _trendsFuture;
  late Future<Map<String, dynamic>> _topProductsFuture;
  late Future<Map<String, dynamic>> _categoryFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    _trendsFuture = _fetchSalesTrends();
    _topProductsFuture = _fetchTopProducts();
    _categoryFuture = _fetchCategoryBreakdown();
  }

  Future<List<SalesTrendModel>> _fetchSalesTrends() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      // Generate sample data based on timeframe
      int days = _selectedTimeframe == '30days' ? 30 : 7;
      List<SalesTrendModel> trends = [];
      for (int i = days - 1; i >= 0; i--) {
        trends.add(SalesTrendModel(
          date: DateTime.now().subtract(Duration(days: i)),
          salesAmount: 150000 + (i * 5000) + (i % 3) * 20000,
          orderCount: 40 + (i * 2),
          category: 'Electronics',
        ));
      }
      return trends;
    } catch (e) {
      throw Exception('Failed to load sales trends: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchTopProducts() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      return {
        'products': [
          {'name': 'Laptop Pro', 'sales': 450000, 'units': 125, 'growth': '+18.5%'},
          {'name': 'Smartphone X', 'sales': 380000, 'units': 280, 'growth': '+12.3%'},
          {'name': 'Wireless Headphones', 'sales': 195000, 'units': 420, 'growth': '+5.2%'},
          {'name': 'Tablet Ultra', 'sales': 172000, 'units': 95, 'growth': '+8.7%'},
          {'name': 'Smart Watch', 'sales': 145000, 'units': 310, 'growth': '+22.1%'},
        ]
      };
    } catch (e) {
      throw Exception('Failed to load top products: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchCategoryBreakdown() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'categories': [
          {'name': 'Electronics', 'percentage': 35, 'sales': 875000, 'color': '0xFF2196F3'},
          {'name': 'Clothing', 'percentage': 25, 'sales': 625000, 'color': '0xFF4CAF50'},
          {'name': 'Home & Garden', 'percentage': 20, 'sales': 500000, 'color': '0xFFFF9800'},
          {'name': 'Books & Media', 'percentage': 12, 'sales': 300000, 'color': '0xFF9C27B0'},
          {'name': 'Sports & Outdoors', 'percentage': 8, 'sales': 200000, 'color': '0xFFF44336'},
        ]
      };
    } catch (e) {
      throw Exception('Failed to load category data: $e');
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
        title: const Text('Sales Analytics'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trends'),
            Tab(text: 'Top Products'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_refreshData),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTrendsTab(),
            _buildTopProductsTab(),
            _buildCategoriesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeframe Selector
          Text(
            'Select Timeframe',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimeframeButton('7 Days', '7days'),
              const SizedBox(width: 8),
              _buildTimeframeButton('30 Days', '30days'),
              const SizedBox(width: 8),
              _buildTimeframeButton('90 Days', '90days'),
            ],
          ),
          const SizedBox(height: 24),

          // Summary Cards
          FutureBuilder<List<SalesTrendModel>>(
            future: _trendsFuture,
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
                return AlertWidget(
                  title: 'Error',
                  message: snapshot.error.toString(),
                  severity: 'critical',
                  icon: Icons.error,
                );
              }

              final trends = snapshot.data!;
              final totalSales = trends.fold(0.0, (sum, t) => sum + t.salesAmount);
              final totalOrders = trends.fold(0, (sum, t) => sum + t.orderCount);
              final avgSales = totalSales / trends.length;
              final maxSales = trends.reduce((a, b) => a.salesAmount > b.salesAmount ? a : b).salesAmount;

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  MetricCard(
                    label: 'Total Sales',
                    value: 'PKR ${(totalSales / 1000).toStringAsFixed(0)}K',
                    icon: Icons.trending_up,
                    backgroundColor: const Color(0xFF4CAF50),
                    iconColor: const Color(0xFF4CAF50),
                    trend: '+15.3%',
                  ),
                  MetricCard(
                    label: 'Total Orders',
                    value: '$totalOrders',
                    subtitle: 'Orders placed',
                    icon: Icons.shopping_bag,
                    backgroundColor: const Color(0xFF2196F3),
                    iconColor: const Color(0xFF2196F3),
                    trend: '+12.5%',
                  ),
                  MetricCard(
                    label: 'Avg Sale Value',
                    value: 'PKR ${avgSales.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    backgroundColor: const Color(0xFFFF9800),
                    iconColor: const Color(0xFFFF9800),
                    trend: '+8.2%',
                  ),
                  MetricCard(
                    label: 'Peak Sales',
                    value: 'PKR ${(maxSales / 1000).toStringAsFixed(0)}K',
                    icon: Icons.show_chart,
                    backgroundColor: const Color(0xFF9C27B0),
                    iconColor: const Color(0xFF9C27B0),
                    trend: '+5.1%',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Trend Chart
          const Text(
            'Sales Over Time',
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

              if (snapshot.hasError) {
                return const AlertWidget(
                  title: 'Error',
                  message: 'Failed to load trends',
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
                lineColor: const Color(0xFF4CAF50),
                fillColor: const Color(0xFF4CAF50),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTopProductsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _topProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AlertWidget(
              title: 'Error',
              message: 'Failed to load top products',
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
                'Top Performing Products',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = products[index] as Map<String, dynamic>;
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                  fontSize: 12,
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
                                  product['name'] as String? ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PKR ${(product['sales'] as num?)?.toStringAsFixed(0) ?? '0'} • ${product['units']} units',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product['growth'] as String?}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export as CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _categoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AlertWidget(
              title: 'Error',
              message: 'Failed to load category data',
              severity: 'critical',
              icon: Icons.error,
            ),
          );
        }

        final categories = (snapshot.data?['categories'] as List?) ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales by Category',
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
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categories[index] as Map<String, dynamic>;
                  final percentage = (category['percentage'] as num?)?.toDouble() ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category['name'] as String? ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'PKR ${(category['sales'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(int.parse('0xFF${(category['color'] as String?)?.replaceAll('0xFF', '') ?? '2196F3'}')),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
