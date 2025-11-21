import 'package:flutter/material.dart';
import 'product_listing_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  late int _selectedIndex;

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
                onPressed: () {
                  if (_selectedIndex == 2) {
                    Navigator.of(context).pushNamed('/seller/products/add');
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
        return const _ProductPostingTab();
      case 3:
        return const _SellToOPASTab();
      case 4:
        return const _DemandForecastingTab();
      default:
        return const _SellerHomeTab();
    }
  }

  Widget _buildSellerBottomNavBar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: 25,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width - 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  _buildSellerNavItem(0, Icons.home_outlined, Icons.home),
                  const SizedBox(width: 30),
                  _buildSellerNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2),
                  const SizedBox(width: 30),
                  _buildSellerNavItem(2, Icons.add_box_outlined, Icons.add_box),
                  const SizedBox(width: 30),
                  _buildSellerNavItem(3, Icons.local_shipping_outlined, Icons.local_shipping),
                  const SizedBox(width: 30),
                  _buildSellerNavItem(4, Icons.trending_up_outlined, Icons.trending_up),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
        
      ],
    );
  }

  Widget _buildSellerNavItem(int index, IconData outlinedIcon, IconData filledIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedIndex = index;
      }),
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? const Color(0xFF00B464) : const Color(0xFFFAFAFA),
          size: 25,
        ),
      ),
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

// ======================== TAB 1: ACCOUNT & PROFILE ========================
class _AccountProfileTab extends StatelessWidget {
  const _AccountProfileTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales & Inventory',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildSalesStats(context),
          const SizedBox(height: 20),
          Text(
            'Incoming Orders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildOrderCard(context, 'Order #001', 'Fresh Tomatoes - 10 kg', '₱450', 'PENDING'),
          const SizedBox(height: 10),
          _buildOrderCard(context, 'Order #002', 'Green Peppers - 5 kg', '₱175', 'PENDING'),
          const SizedBox(height: 20),
          Text(
            'Inventory Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildInventoryCard(context, 'Total Stock', '245 kg', Colors.blue),
          const SizedBox(height: 10),
          _buildInventoryCard(context, 'Low Stock Items', '3', Colors.orange),
          const SizedBox(height: 10),
          _buildInventoryCard(context, 'Out of Stock', '2', Colors.red),
        ],
      ),
    );
  }

  Widget _buildSalesStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(context, 'Pending', '4', Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(context, 'Completed', '28', Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(context, 'Cancelled', '2', Colors.red),
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

  Widget _buildOrderCard(BuildContext context, String orderId, String details, String amount, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderId, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(details, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(amount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF00B464))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, String label, String value, Color color) {
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== TAB 2: PRODUCT POSTING ========================
// ======================== TAB 2: PRODUCT POSTING (REAL IMPLEMENTATION) ========================
class _ProductPostingTab extends StatelessWidget {
  const _ProductPostingTab();

  @override
  Widget build(BuildContext context) {
    return const ProductListingScreen();
  }
}

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
