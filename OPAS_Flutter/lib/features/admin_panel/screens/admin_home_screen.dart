import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pending_seller_approvals_screen.dart';
import 'pending_product_approvals_screen.dart';
import 'opas_submissions_screen.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/api_service.dart';
import '../../../features/admin/screens/forecasting_dashboard_screen.dart';
import '../../../features/products/widgets/stock_status_widget.dart';
import 'users_list_screen.dart';
import 'sellers_list_screen.dart';
import 'product_listings_screen.dart';
import 'product_upload_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _selectedIndex;
  int _totalBuyers = 0;
  int _totalSellers = 0;
  int _totalProducts = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Load all stats in parallel
      final [buyers, sellers, products, approvals] = await Future.wait([
        AdminService.getAllBuyers().then((b) => b.length),
        AdminService.getAllSellers().then((s) => s.length),
        AdminService.getAllProducts().then((p) => p.length),
        AdminService.getPendingSellerApprovals().then((a) => a.length),
      ]);
      
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          _totalBuyers = buyers;
          _totalSellers = sellers;
          _totalProducts = products;
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dashboard stats: $e');
      }
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 1 ? _buildUploadFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildAdminBottomNavBar(),
    );
  }

  Widget _buildUploadFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 65),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B464), Color(0xFF009850)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B464).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductUploadScreen(),
                ),
              ).then((result) {
                // If upload was successful, switch to products tab to refresh
                if (result == true) {
                  setState(() => _selectedIndex = 1);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return const _PriceRegulationTab();
      case 2:
        return const _AnnouncementsTab();
      default:
        return _buildDashboardTab();
    }
  }

  /// Modern Dashboard Tab matching Buyer Home Screen design
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0, bottom: 100, left: 16, right: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with gradient background
            _buildHeaderSectionWithGradient(context),
            const SizedBox(height: 24),

            // Key Stats Cards - Improved layout
            _buildStatsSection(context),
            const SizedBox(height: 28),

            // Quick Actions Section - Improved layout
            _buildQuickActionsSection(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Header Section with gradient background
  Widget _buildHeaderSectionWithGradient(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B464),
            Color(0xFF009850),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B464).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Admin Dashboard & Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Platform Overview • ${DateTime.now().toString().split(' ')[0]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Header Section with Title and Icon
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin Dashboard & Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Key Statistics Cards Section - Improved layout
  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadingStats)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00B464),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row - 2 cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Buyers',
                      _totalBuyers.toString(),
                      Icons.shopping_cart_outlined,
                      const Color(0xFF2196F3),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UsersListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active Sellers',
                      _totalSellers.toString(),
                      Icons.store_outlined,
                      const Color(0xFF4CAF50),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SellersListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row - 2 cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Listings',
                      _totalProducts.toString(),
                      Icons.inventory_2_outlined,
                      const Color(0xFF9C27B0),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductListingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Demand & Price',
                      'Forecasting',
                      Icons.trending_up_outlined,
                      const Color(0xFFFFA726),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForecastingDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  /// Individual Stat Card - Improved design
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[100]!),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[300],
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Actions Section - Improved layout
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          context,
          'Seller Approvals',
          'Review and manage seller applications',
          Icons.verified_user_outlined,
          const Color(0xFFFFA726),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PendingSellerApprovalsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          context,
          'Product Approvals',
          'Review and approve product listings',
          Icons.assignment_outlined,
          const Color(0xFF29B6F6),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PendingProductApprovalsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          context,
          'Manage Sellers',
          'View and manage all active sellers',
          Icons.people_outline,
          const Color(0xFF4CAF50),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SellersListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          context,
          'AI Forecasting',
          'View demand predictions and insights',
          Icons.trending_up_outlined,
          const Color(0xFF9C27B0),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForecastingDashboardScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          context,
          'OPAS Submissions',
          'Review seller product offers to OPAS',
          Icons.shopping_bag_outlined,
          const Color(0xFF66BB6A),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OPASSubmissionsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Individual Action Card - Improved design
  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[100]!),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey[300], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[100]!),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey[300], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBottomNavBar() {
    List<Widget> navItems = [];
    
    navItems.add(_buildAdminNavItem(0, Icons.analytics_outlined, Icons.analytics));
    navItems.add(_buildAdminNavItem(1, Icons.store_outlined, Icons.store));
    navItems.add(_buildAdminNavItem(2, Icons.campaign_outlined, Icons.campaign));
    
    final containerWidth = (navItems.length * 75.0) + 30;

    return Container(
      height: 80,
      padding: const EdgeInsets.only(bottom: 25, top: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Center(
        child: Container(
          height: 60,
          width: containerWidth,
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navItems,
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
class _PriceRegulationTab extends StatefulWidget {
  const _PriceRegulationTab();

  @override
  State<_PriceRegulationTab> createState() => _PriceRegulationTabState();
}

class _PriceRegulationTabState extends State<_PriceRegulationTab> {
  List<dynamic> _adminProducts = [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadAdminProducts();
  }

  Future<void> _loadAdminProducts() async {
    try {
      // First try to use the dedicated OPAS endpoint
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final opasUrl = '${ApiService.baseUrl}/admin/opas-products/';
      print('DEBUG: Loading OPAS products from: $opasUrl');
      print('DEBUG: Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(opasUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('DEBUG: OPAS endpoint status: ${response.statusCode}');
      print('DEBUG: OPAS response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('DEBUG: Decoded OPAS response type: ${decoded.runtimeType}');
        
        List<dynamic> products;
        if (decoded is List) {
          products = decoded;
        } else if (decoded is Map && decoded.containsKey('results')) {
          products = decoded['results'] as List;
        } else {
          products = [];
        }
        
        print('DEBUG: Got ${products.length} OPAS products');
        
        if (mounted) {
          setState(() {
            _adminProducts = List<Map<String, dynamic>>.from(
              products.map((p) => Map<String, dynamic>.from(p as Map))
            );
            _loadingProducts = false;
          });
        }
        return;
      }
      
      print('DEBUG: OPAS endpoint returned ${response.statusCode}, falling back to general products');
      
      // Fallback to general products endpoint if OPAS endpoint fails
      final allProducts = await AdminService.getAllProducts();
      print('DEBUG: Got ${allProducts.length} total products, filtering for OPAS');
      
      final opasProducts = allProducts.where((product) {
        print('DEBUG: Checking product: seller_id=${product['seller_id']}, phone=${product['seller']?['phone_number']}');
        return product['seller_id'] == 'opas' || 
               product['store_name'] == 'OPAS' ||
               product['seller']?['id'] == 'opas' ||
               product['seller']?['store_name'] == 'OPAS' ||
               product['seller']?['phone_number'] == '0000000000';
      }).toList();
      
      print('DEBUG: Filtered to ${opasProducts.length} OPAS products');
      
      if (mounted) {
        setState(() {
          _adminProducts = opasProducts;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      print('Error loading OPAS products: $e');
      if (mounted) {
        setState(() => _loadingProducts = false);
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String productName, int productId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Delete Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  'Are you sure you want to delete "$productName"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 28),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteProduct(productId, productName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int inventoryId, String productName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';
      final headers = {
        'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('${ApiService.baseUrl}/admin/opas-products/$inventoryId/');
      
      final response = await http.delete(url, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 204 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$productName" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh product list
        _loadAdminProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAdminProducts,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPAS Marketplace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'View active products and upload new listings',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            // Active Products Section
            Text(
              'Active Products (${_adminProducts.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingProducts)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_adminProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'No products uploaded yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by uploading your first product',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: _adminProducts.length,
                itemBuilder: (context, index) {
                  final product = _adminProducts[index];
                  // For OPAS products, the key is 'image'. For general products, it's 'primary_image'
                  var imageUrl = product['image'] ?? product['primary_image'];
                  print('DEBUG: Product ${product['product_name']} - raw image: ${product['image']}, primary_image: ${product['primary_image']}');
                  // If imageUrl is a relative path, prepend the server base URL (without /api)
                  if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    // Extract server URL from baseUrl (remove /api suffix)
                    final serverUrl = ApiService.baseUrl.replaceAll('/api', '');
                    imageUrl = '$serverUrl$imageUrl';
                  }
                  print('DEBUG: Final imageUrl for ${product['product_name']}: $imageUrl');
                  
                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                color: Colors.grey[200],
                              ),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                            ),
                            // Active Badge
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B464),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Active',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Product Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              // Product Name
                              Text(
                                (product['product_name'] ?? product['name'] ?? 'Unknown Product').length > 20
                                    ? (product['product_name'] ?? product['name'] ?? 'Unknown Product').substring(0, 20)
                                    : (product['product_name'] ?? product['name'] ?? 'Unknown Product'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Category
                              Row(
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 11,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      product['category'] ?? 'Uncategorized',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // Stock Status Widget
                              StockStatusWidget(
                                status: product['stock_status'] ?? 'HIGH',
                                percentage: (product['stock_percentage'] ?? 100.0).toDouble(),
                                currentStock: product['stock_level'] ?? 0,
                                unit: 'kg',
                              ),
                              const SizedBox(height: 4),
                              // Price and Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱${product['price'] ?? 0}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF00B464),
                                          fontSize: 11,
                                        ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 13,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              // TODO: Edit product
                                            },
                                            tooltip: 'Edit',
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 13,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _showDeleteConfirmation(
                                                context,
                                                product['product_name'],
                                                product['id'],
                                              );
                                            },
                                            tooltip: 'Delete',
                                            padding: EdgeInsets.zero,
                                          ),
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
                      ],
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}

// Inventory Tab
// Announcements Tab
class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  late List<Announcement> announcements;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  void _loadAnnouncements() {
    // TODO: Load from API
    announcements = [
      Announcement(
        id: '1',
        title: 'New Seasonal Products Available',
        description: 'Fresh seasonal products are now available in the OPAS marketplace.',
        type: 'info',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        recipientCount: 1250,
      ),
      Announcement(
        id: '2',
        title: 'System Maintenance Alert',
        description: 'Scheduled maintenance on Saturday 10 PM - 2 AM. Please plan accordingly.',
        type: 'warning',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        recipientCount: 3420,
      ),
      Announcement(
        id: '3',
        title: 'Welcome to OPAS Platform',
        description: 'Thank you for joining OPAS. Explore new opportunities with our marketplace.',
        type: 'success',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        recipientCount: 890,
      ),
    ];
  }

  void _showCreateAnnouncementDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAnnouncementDialog(
        onCreate: (title, description, type, recipientType) {
          setState(() {
            announcements.insert(
              0,
              Announcement(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                description: description,
                type: type,
                createdAt: DateTime.now(),
                recipientCount: 0,
              ),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement created successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'Announcements & Updates',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage and send announcements to users',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsRow(),
              const SizedBox(height: 24),

              // Announcements List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Announcements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${announcements.length} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Announcements List
              if (announcements.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) => _buildAnnouncementCard(
                    context,
                    announcements[index],
                  ),
                ),
            ],
          ),
        ),

        // FAB
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              onPressed: _showCreateAnnouncementDialog,
              backgroundColor: const Color(0xFF00B464),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Sent',
            value: '${announcements.length}',
            icon: Icons.send_rounded,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Reach',
            value: announcements.fold<int>(0, (sum, a) => sum + a.recipientCount).toString(),
            icon: Icons.people_rounded,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Active',
            value: announcements.where((a) => a.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length.toString(),
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Announcement announcement) {
    final typeColor = _getTypeColor(announcement.type);
    final timeAgo = _formatTimeAgo(announcement.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAnnouncementDetails(context, announcement),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          setState(() {
                            announcements.removeWhere((a) => a.id == announcement.id);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.recipientCount} reached',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No announcements yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first announcement to get started',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF4CAF50);
      case 'warning':
        return const Color(0xFFFFC107);
      case 'error':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF2196F3);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _showAnnouncementDetails(BuildContext context, Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(announcement.description),
              const SizedBox(height: 16),
              Text(
                'Recipients Reached: ${announcement.recipientCount}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${announcement.createdAt.toString()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime createdAt;
  final int recipientCount;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.recipientCount,
  });
}

class _CreateAnnouncementDialog extends StatefulWidget {
  final Function(String title, String description, String type, String recipientType) onCreate;

  const _CreateAnnouncementDialog({required this.onCreate});

  @override
  State<_CreateAnnouncementDialog> createState() => _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<_CreateAnnouncementDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  String selectedType = 'info';
  String selectedRecipients = 'all';

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Announcement',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter announcement title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter announcement description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['info', 'success', 'warning', 'error'].map((type) {
                    final isSelected = selectedType == type;
                    return FilterChip(
                      label: Text(type.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedType = type;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Send To',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRecipients,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'buyers', child: Text('Buyers Only')),
                    DropdownMenuItem(value: 'sellers', child: Text('Sellers Only')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRecipients = value ?? 'all';
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: titleController.text.isEmpty || descriptionController.text.isEmpty
                          ? null
                          : () {
                        widget.onCreate(
                          titleController.text,
                          descriptionController.text,
                          selectedType,
                          selectedRecipients,
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Create Announcement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
