import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pending_seller_approvals_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _selectedIndex;
  int _pendingApprovalCount = 0;
  bool _loadingPendingCount = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _fetchPendingApprovalCount();
  }

  Future<void> _fetchPendingApprovalCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access') ?? '';

      if (accessToken.isEmpty) {
        setState(() => _loadingPendingCount = false);
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.113.93.34:8000/api/users/admin/sellers/pending_approvals/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = (data is List) ? data.length : 0;
        setState(() {
          _pendingApprovalCount = count;
          _loadingPendingCount = false;
        });
      } else {
        setState(() => _loadingPendingCount = false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching pending approval count: $e');
      }
      setState(() => _loadingPendingCount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildAdminBottomNavBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardTab();
      case 1:
        return _UserManagementTab(
          pendingApprovalCount: _pendingApprovalCount,
          loadingPendingCount: _loadingPendingCount,
        );
      case 2:
        return const _PriceRegulationTab();
      case 3:
        return const _InventoryTab();
      case 4:
        return const _AnnouncementsTab();
      default:
        return const _DashboardTab();
    }
  }

  Widget _buildAdminBottomNavBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(bottom: 25, top: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 55),
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
              _buildAdminNavItem(0, Icons.analytics_outlined, Icons.analytics),
              const SizedBox(width: 35),
              _buildAdminNavItem(1, Icons.person_add_outlined, Icons.person_add),
              const SizedBox(width: 35),
              _buildAdminNavItem(2, Icons.price_check_outlined, Icons.price_check),
              const SizedBox(width: 35),
              _buildAdminNavItem(3, Icons.store_outlined, Icons.store),
              const SizedBox(width: 35),
              _buildAdminNavItem(4, Icons.campaign_outlined, Icons.campaign),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminNavItem(int index, IconData outlinedIcon, IconData filledIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? const Color(0xFF00B464) : const Color(0xFFFAFAFA),
          size: 28,
        ),
      ),
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard & Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            context,
            'Total Users',
            '1,234',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            'Active Sellers',
            '567',
            Icons.store,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            'Pending Approvals',
            '12',
            Icons.pending_actions,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            'Total Listings',
            '2,345',
            Icons.list_alt,
            Colors.purple,
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Reports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildReportCard(context, 'Price Trend Report', 'Updated 2 hours ago'),
          const SizedBox(height: 8),
          _buildReportCard(context, 'Market Activity', 'Updated 1 hour ago'),
          const SizedBox(height: 8),
          _buildReportCard(context, 'Compliance Report', 'Updated 30 minutes ago'),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String subtitle) {
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
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          const Icon(Icons.arrow_forward, color: Colors.grey),
        ],
      ),
    );
  }
}

// User Management Tab
class _UserManagementTab extends StatelessWidget {
  final int pendingApprovalCount;
  final bool loadingPendingCount;

  const _UserManagementTab({
    required this.pendingApprovalCount,
    required this.loadingPendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User & Seller Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingSellerApprovalsScreen(),
                ),
              );
            },
            child: _buildManagementSection(
              context,
              'Pending Seller Approvals',
              Icons.pending_actions,
              Colors.orange,
              loadingPendingCount ? 'Loading...' : '$pendingApprovalCount pending',
            ),
          ),
          const SizedBox(height: 12),
          _buildManagementSection(
            context,
            'Verify Seller Documents',
            Icons.badge,
            Colors.blue,
            'Review documents',
          ),
          const SizedBox(height: 12),
          _buildManagementSection(
            context,
            'Manage Suspensions',
            Icons.block,
            Colors.red,
            '3 suspended',
          ),
          const SizedBox(height: 12),
          _buildManagementSection(
            context,
            'User Statistics',
            Icons.analytics,
            Colors.green,
            'View breakdown',
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildActionItem(context, 'Approved seller: Fresh Produce Co.', '2 hours ago'),
          const SizedBox(height: 8),
          _buildActionItem(context, 'Suspended user: Invalid documents', '5 hours ago'),
          const SizedBox(height: 8),
          _buildActionItem(context, 'Verified documents: Green Valley Farm', '1 day ago'),
        ],
      ),
    );
  }

  Widget _buildManagementSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Icon(icon, color: color, size: 32),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String action, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}

// Price & Market Regulation Tab
class _PriceRegulationTab extends StatelessWidget {
  const _PriceRegulationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price & Market Regulation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildPriceSection(
            context,
            'Set Ceiling Prices',
            Icons.trending_down,
            Colors.red,
            'Configure maximum prices',
          ),
          const SizedBox(height: 12),
          _buildPriceSection(
            context,
            'Monitor Listings',
            Icons.visibility,
            Colors.blue,
            '5 violations detected',
          ),
          const SizedBox(height: 12),
          _buildPriceSection(
            context,
            'Price Advisories',
            Icons.notifications_active,
            Colors.orange,
            'Post official announcements',
          ),
          const SizedBox(height: 12),
          _buildPriceSection(
            context,
            'Non-Compliant Listings',
            Icons.warning,
            Colors.red,
            '3 pending action',
          ),
          const SizedBox(height: 24),
          Text(
            'Price Updates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildPriceUpdateItem(context, 'Tomato', '₱40/kg', 'Updated 2 hours ago'),
          const SizedBox(height: 8),
          _buildPriceUpdateItem(context, 'Onion', '₱25/kg', 'Updated 4 hours ago'),
          const SizedBox(height: 8),
          _buildPriceUpdateItem(context, 'Cabbage', '₱15/kg', 'Updated 1 day ago'),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Icon(icon, color: color, size: 32),
        ],
      ),
    );
  }

  Widget _buildPriceUpdateItem(BuildContext context, String product, String price, String time) {
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
              Text(product, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
            ],
          ),
          Text(price, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF00B464),
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

// Inventory Tab
class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPAS Purchasing & Inventory',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildInventorySection(
            context,
            'Sell to OPAS Requests',
            Icons.add_shopping_cart,
            Colors.blue,
            '8 pending',
          ),
          const SizedBox(height: 12),
          _buildInventorySection(
            context,
            'Current Stock',
            Icons.inventory_2,
            Colors.green,
            '245 items',
          ),
          const SizedBox(height: 12),
          _buildInventorySection(
            context,
            'Restocking Needs',
            Icons.warning,
            Colors.orange,
            '5 items low',
          ),
          const SizedBox(height: 12),
          _buildInventorySection(
            context,
            'FIFO Management',
            Icons.timeline,
            Colors.purple,
            'Track expiration',
          ),
          const SizedBox(height: 24),
          Text(
            'Current Inventory',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildInventoryItem(context, 'Fresh Tomato', '120 kg', '₱4,800', true),
          const SizedBox(height: 8),
          _buildInventoryItem(context, 'Green Onion', '45 kg', '₱1,125', false),
          const SizedBox(height: 8),
          _buildInventoryItem(context, 'Cabbage', '200 kg', '₱3,000', true),
        ],
      ),
    );
  }

  Widget _buildInventorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Icon(icon, color: color, size: 32),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(BuildContext context, String name, String quantity, String value, bool inStock) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: inStock ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(quantity, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                inStock ? 'In Stock' : 'Low Stock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inStock ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Announcements Tab
class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications & Announcements',
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
                  'Create Announcement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Announcement title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Announcement message',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.message),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                    label: const Text('Send Announcement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Announcements',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildAnnouncementItem(
            context,
            'Price Advisory: Tomato Prices Updated',
            'New ceiling price set at ₱40/kg effective tomorrow.',
            '2 hours ago',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildAnnouncementItem(
            context,
            'System Maintenance Notice',
            'Platform will undergo maintenance tonight 10 PM - 12 AM.',
            '5 hours ago',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildAnnouncementItem(
            context,
            'New Seller Registration Batch Approved',
            '5 new sellers have been approved and are now active.',
            '1 day ago',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(
    BuildContext context,
    String title,
    String message,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notification_important, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
