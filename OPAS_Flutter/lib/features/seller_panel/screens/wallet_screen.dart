import 'package:flutter/material.dart';
import '../services/seller_service.dart';

/// Wallet Screen
/// Displays available balance and earnings summary
/// Features: Balance display, earnings metrics, withdrawal history summary, request payout button
class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _balanceFuture;
  late Future<Map<String, dynamic>> _earningsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _balanceFuture = _getBalance();
    _earningsFuture = SellerService.getEarningsSummary();
  }

  Future<Map<String, dynamic>> _getBalance() async {
    try {
      final response = await SellerService.getPayouts();
      // Calculate pending balance from completed payouts
      double totalEarned = 0;
      double totalWithdrawn = 0;

      for (final payout in response) {
        final amount = payout.amount;
        final status = payout.status.toUpperCase();

        if (status == 'COMPLETED') {
          totalWithdrawn += amount;
        }
      }

      // Get earnings summary for total earned
      try {
        final earnings = await SellerService.getEarningsSummary();
        totalEarned = (earnings['total_earnings'] as num?)?.toDouble() ?? 0;
      } catch (e) {
        totalEarned = totalWithdrawn; // Fallback
      }

      final pendingBalance = totalEarned - totalWithdrawn;

      return {
        'available_balance': pendingBalance.clamp(0, double.infinity),
        'total_earned': totalEarned,
        'total_withdrawn': totalWithdrawn,
      };
    } catch (e) {
      throw Exception('Failed to fetch balance: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Card
              FutureBuilder<Map<String, dynamic>>(
                future: _balanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      elevation: 4,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      elevation: 4,
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 32, color: Colors.red),
                            const SizedBox(height: 8),
                            const Text('Error loading balance'),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final balance = snapshot.data ?? {};
                  final availableBalance =
                      (balance['available_balance'] as num?)?.toDouble() ?? 0;
                  final totalEarned =
                      (balance['total_earned'] as num?)?.toDouble() ?? 0;
                  final totalWithdrawn =
                      (balance['total_withdrawn'] as num?)?.toDouble() ?? 0;

                  return Column(
                    children: [
                      // Main Balance Card
                      Card(
                        elevation: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[400]!, Colors.green[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '₱${availableBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Earned',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${totalEarned.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Total Withdrawn',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${totalWithdrawn.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
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
                      ),
                      const SizedBox(height: 16),

                      // Request Payout Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: availableBalance > 0
                              ? () {
                                  Navigator.of(context)
                                      .pushNamed('/seller/request-payout');
                                }
                              : null,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Request Payout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (availableBalance == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No balance available to withdraw',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Earnings Summary Section
              const Text(
                'Earnings Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _balanceFuture,
                builder: (context, balanceSnapshot) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _earningsFuture,
                    builder: (context, earningsSnapshot) {
                      if (earningsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (earningsSnapshot.hasError) {
                        return Card(
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load earnings summary',
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          ),
                        );
                      }

                      final earnings = earningsSnapshot.data ?? {};
                      final balance = balanceSnapshot.data ?? {};
                      final totalOrders =
                          (earnings['total_orders'] as num?)?.toInt() ?? 0;
                      final totalRevenue =
                          (earnings['total_revenue'] as num?)?.toDouble() ?? 0;
                      final pendingPayout =
                          (balance['available_balance'] as num?)?.toDouble() ?? 0;
                      final avgOrder = totalOrders > 0
                          ? totalRevenue / totalOrders
                          : 0.0;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _buildMetricCard(
                            title: 'Total Orders',
                            value: '$totalOrders',
                            icon: Icons.shopping_cart,
                            color: Colors.blue,
                          ),
                          _buildMetricCard(
                            title: 'Total Revenue',
                            value: '₱${totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.trending_up,
                            color: Colors.green,
                          ),
                          _buildMetricCard(
                            title: 'Avg per Order',
                            value: '₱${avgOrder.toStringAsFixed(0)}',
                            icon: Icons.calculate,
                            color: Colors.orange,
                          ),
                          _buildMetricCard(
                            title: 'Pending Payout',
                            value: '₱${pendingPayout.toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet,
                            color: Colors.purple,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Transactions Link
              Card(
                child: ListTile(
                  title: const Text('View Payout History'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.of(context).pushNamed('/seller/payouts');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
