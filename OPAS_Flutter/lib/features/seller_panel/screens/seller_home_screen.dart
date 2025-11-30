import 'package:flutter/material.dart';
import 'package:opas_flutter/features/seller_panel/widgets/seller_bottom_nav_bar.dart';
import '../services/seller_api_service.dart';
import '../../order_management/models/order_model.dart';
import 'product_listing_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  late int _selectedIndex;
  // Version key for product listing screen — incrementing forces a remount and fetch
  int _productListVersion = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: _buildBody(),
          ),
          _buildSellerBottomNavBar(),
          if (_selectedIndex == 2 || _selectedIndex == 3)
            Positioned(
              bottom: 105,
              right: 30,
              child: FloatingActionButton(
                onPressed: () async {
                  if (_selectedIndex == 2) {
                    // Navigate to add product and wait for result
                    final result = await Navigator.of(context).pushNamed('/seller/products/add');
                    // If a product was created successfully, trigger an in-app refresh
                    if (result == true && mounted) {
                      // Increment version to force ProductListingScreen remount and refresh
                      setState(() {
                        _productListVersion++;
                      });
                    }
                  } else if (_selectedIndex == 3) {
                    Navigator.of(context).pushNamed('/seller/opas/submit');
                  }
                },
                backgroundColor: const Color(0xFF00B464),
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const _SellerHomeTab();
      case 1:
        return const _AccountProfileTab();
      case 2:
        // Pass in a ValueKey that changes when a new product is created.
        return ProductListingScreen(key: ValueKey(_productListVersion));
      case 3:
        return const _SellToOPASTab();
      case 4:
        return const _DemandForecastingTab();
      default:
        return const _SellerHomeTab();
    }
  }

  Widget _buildSellerBottomNavBar() {
    return SellerBottomNavBar(
      selectedIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
    );
  }
}

// ======================== TAB 0: SELLER HOME ========================
class _SellerHomeTab extends StatefulWidget {
  const _SellerHomeTab();

  @override
  State<_SellerHomeTab> createState() => _SellerHomeTabState();
}

class _SellerHomeTabState extends State<_SellerHomeTab> {
  late Map<String, dynamic> _dailySales;
  late Map<String, dynamic> _weeklySales;
  late Map<String, dynamic> _monthlySales;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  void _loadSalesData() {
    // Initialize with sample data - in production, fetch from API
    _dailySales = {
      'amount': 2450.0,
      'orders': 12,
      'trend': 'up',
      'percentage': 12.5,
    };
    _weeklySales = {
      'amount': 15200.0,
      'orders': 85,
      'trend': 'up',
      'percentage': 8.3,
    };
    _monthlySales = {
      'amount': 62500.0,
      'orders': 380,
      'trend': 'up',
      'percentage': 5.2,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          // ===== SALES PERFORMANCE SECTION =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPerformanceCard(context, 'Daily Sales', '₱${_dailySales['amount'].toStringAsFixed(2)}', '${_dailySales['orders']} orders', Colors.blue),
                const SizedBox(height: 10),
                _buildPerformanceCard(context, 'Weekly Sales', '₱${_weeklySales['amount'].toStringAsFixed(2)}', '${_weeklySales['orders']} orders', Colors.green),
                const SizedBox(height: 10),
                _buildPerformanceCard(context, 'Monthly Sales', '₱${_monthlySales['amount'].toStringAsFixed(2)}', '${_monthlySales['orders']} orders', Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ===== TOP PERFORMING PRODUCTS SECTION =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Performing Products',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildProductRankCard(context, '1', 'Fresh Tomatoes', '125 units', '₱5,625'),
                const SizedBox(height: 8),
                _buildProductRankCard(context, '2', 'Green Peppers', '98 units', '₱3,430'),
                const SizedBox(height: 8),
                _buildProductRankCard(context, '3', 'Onions', '87 units', '₱1,740'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ===== WALLET & PAYOUT SECTION =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.05),
              border: Border.all(color: Colors.purple.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet & Payout',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildWalletCard(context),
                const SizedBox(height: 20),
                _buildFinancialStats(context),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ===== RECENT TRANSACTIONS SECTION =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTransactionCard(context, 'Sale Payment', '+₱450', 'Order #001', true, '2 hours ago'),
                const SizedBox(height: 8),
                _buildTransactionCard(context, 'Sale Payment', '+₱875', 'Order #002', true, '1 day ago'),
                const SizedBox(height: 8),
                _buildTransactionCard(context, 'Payout Completed', '-₱5,000', 'Bank Transfer', false, '3 days ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, String label, String amount, String details, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(amount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(details, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          Icon(Icons.bar_chart, color: color, size: 32),
        ],
      ),
    );
  }

  Widget _buildProductRankCard(BuildContext context, String rank, String product, String units, String revenue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF00B464),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(units, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Text(revenue, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF00B464))),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B464), Color(0xFF00854d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B464).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '₱8,750.50',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Card Holder', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('John Farmer', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                ],
              ),
              Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(context, 'Pending', '₱2,350', Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(context, 'Completed', '₱24,500', Colors.green),
        ),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(amount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, String title, String amount, String details, bool isIncome, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(details, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400])),
            ],
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== TAB 1: SALES & INVENTORY ========================
class _AccountProfileTab extends StatefulWidget {
  const _AccountProfileTab();

  @override
  State<_AccountProfileTab> createState() => _AccountProfileTabState();
}

class _AccountProfileTabState extends State<_AccountProfileTab> {
  late Future<List<Order>> _pendingOrdersFuture;
  late Future<List<Order>> _inventoryStatsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _pendingOrdersFuture = SellerApiService.getPendingOrders();
    _inventoryStatsFuture = SellerApiService.getIncomingOrders(); // For stats
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales & Inventory',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // === STATS OVERVIEW ===
          FutureBuilder<List<Order>>(
            future: _inventoryStatsFuture,
            builder: (context, snapshot) {
              final totalOrders = snapshot.data?.length ?? 0;
              final pendingOrders = snapshot.data?.where((o) => o.isPending).length ?? 0;
              final completedOrders = snapshot.data?.where((o) => o.isCompleted).length ?? 0;

              return _buildStatsOverview(context, totalOrders, pendingOrders, completedOrders);
            },
          ),
          const SizedBox(height: 28),
          
          // === INCOMING ORDERS SECTION ===
          _buildOrdersSection(context),
          const SizedBox(height: 28),
          
          // === INVENTORY OVERVIEW ===
          _buildInventoryOverviewSection(context),
        ],
      ),
    );
  }

  /// Stats Overview with modern cards
  Widget _buildStatsOverview(BuildContext context, int total, int pending, int completed) {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(context, 'Total Orders', '$total', Icons.receipt_long, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(context, 'Pending', '$pending', Icons.pending_actions, Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(context, 'Completed', '$completed', Icons.check_circle, const Color(0xFF00B464)),
        ),
      ],
    );
  }

  /// Modern Stat Card
  Widget _buildModernStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Orders Section
  Widget _buildOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Incoming Orders (Pending)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF00B464)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Order>>(
          future: _pendingOrdersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF00B464)),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading orders: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No pending orders',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Get the 3 most recent pending orders, sorted by creation date (newest first)
            final orders = snapshot.data!
                .where((o) => o.isPending)
                .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            final displayOrders = orders.take(3).toList();

            return Column(
              children: displayOrders.asMap().entries.map((entry) {
                final index = entry.key;
                final order = entry.value;

                return Column(
                  children: [
                    _buildModernOrderCard(
                      context,
                      'Order #${order.orderNumber}',
                      '${order.items.length} items • ${order.buyerName}',
                      '₱${order.totalAmount.toStringAsFixed(2)}',
                      'PENDING',
                      Colors.blue,
                    ),
                    if (index < displayOrders.length - 1)
                      const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Modern Order Card
  Widget _buildModernOrderCard(
    BuildContext context,
    String orderId,
    String details,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderId,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00B464),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  /// Inventory Overview Section
  Widget _buildInventoryOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inventory Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Details',
                style: TextStyle(color: Color(0xFF00B464)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModernInventoryCard(context, 'Total Stock', '245 kg', Icons.inventory_2, const Color(0xFF00B464)),
        const SizedBox(height: 10),
        _buildModernInventoryCard(context, 'Low Stock Items', '3', Icons.warning_amber, Colors.orange),
        const SizedBox(height: 10),
        _buildModernInventoryCard(context, 'Out of Stock', '2', Icons.block, Colors.red),
      ],
    );
  }

  /// Modern Inventory Card
  Widget _buildModernInventoryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}

// ======================== TAB 2: PRODUCT POSTING ========================
// Product posting is implemented by `ProductListingScreen` (used directly in
// the switch above). The `_ProductPostingTab` helper widget was unused and has
// been removed to avoid dead code.

// ======================== TAB 3: SELL TO OPAS ========================
class _SellToOPASTab extends StatelessWidget {
  const _SellToOPASTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sell to OPAS',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOPASStats(context),
          const SizedBox(height: 20),
          Text(
            'Pending Submissions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildSubmissionCard(context, 'Tomatoes', '50 kg', '₱2,500', 'PENDING'),
          const SizedBox(height: 10),
          _buildSubmissionCard(context, 'Onions', '30 kg', '₱1,500', 'PENDING'),
          const SizedBox(height: 20),
          Text(
            'Approved Transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildSubmissionCard(context, 'Cabbage', '40 kg', '₱1,200', 'APPROVED'),
        ],
      ),
    );
  }

  Widget _buildOPASStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(context, 'Pending', '2', Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(context, 'Approved', '8', Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(context, 'Total', '₱12,500', Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context, String product, String quantity, String amount, String status) {
    final isApproved = status == 'APPROVED';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: isApproved ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$quantity • $amount', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== TAB 5: DEMAND FORECASTING ========================
class _DemandForecastingTab extends StatelessWidget {
  const _DemandForecastingTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demand Forecasting',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00B464).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00B464).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Month Forecast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildForecastItem(context, 'Tomatoes', '120 kg', 'Medium Risk'),
                const SizedBox(height: 8),
                _buildForecastItem(context, 'Peppers', '80 kg', 'Low Risk'),
                const SizedBox(height: 8),
                _buildForecastItem(context, 'Onions', '150 kg', 'High Risk'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Historical Comparison',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildComparisonCard(context, 'Tomatoes', 'Forecasted: 120 kg', 'Actual: 115 kg', Colors.green),
          const SizedBox(height: 10),
          _buildComparisonCard(context, 'Peppers', 'Forecasted: 80 kg', 'Actual: 85 kg', Colors.orange),
          const SizedBox(height: 20),
          Text(
            'Insights & Recommendations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(context, 'Production increased by 5% last month', Icons.trending_up),
          const SizedBox(height: 8),
          _buildInsightCard(context, 'Surplus risk high for onions - consider storage', Icons.warning),
          const SizedBox(height: 8),
          _buildInsightCard(context, 'Peppers demand stable - maintain production', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildForecastItem(BuildContext context, String product, String forecast, String risk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(forecast, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: risk.contains('Low') ? Colors.green : risk.contains('Medium') ? Colors.orange : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            risk,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, String product, String forecast, String actual, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(forecast, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          Text(actual, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, String insight, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B464), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(insight, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
