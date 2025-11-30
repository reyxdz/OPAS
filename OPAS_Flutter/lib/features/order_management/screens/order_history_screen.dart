import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../order_management/models/order_model.dart';
import '../../products/services/buyer_api_service.dart';
import 'order_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/notification_history_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'all';
  late Future<List<Order>> _ordersFuture;
  int _currentPage = 1;

  final List<String> _filters = ['all', 'pending', 'confirmed', 'completed', 'cancelled'];
  
  // User data
  String _userFirstName = 'Guest';
  String _userLastName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _debugAuthStatus();
    _loadOrders();
  }

  /// Load user first name and last name from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? 'Guest';
      final lastName = prefs.getString('last_name') ?? '';
      setState(() {
        _userFirstName = firstName;
        _userLastName = lastName;
      });
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  Future<void> _debugAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');
    final refreshToken = prefs.getString('refresh');
    debugPrint('🔐 Auth Debug: Access Token: ${token != null ? 'Present (${token.length} chars)' : 'Missing'}');
    debugPrint('🔐 Auth Debug: Refresh Token: ${refreshToken != null ? 'Present (${refreshToken.length} chars)' : 'Missing'}');
    debugPrint('🔐 Auth Debug: API Base URL: ${BuyerApiService.baseUrl}');
  }

  void _loadOrders() {
    debugPrint('📦 Loading orders...');
    setState(() {
      _ordersFuture = BuyerApiService.getBuyerOrders(page: _currentPage);
    });
  }

  void _refreshOrders() {
    _currentPage = 1;
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER ===
              _buildOrderHeader(context),
              const SizedBox(height: 16),
              Divider(
                color: Colors.grey[200],
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 24),

              // === STATS OVERVIEW ===
              FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  final allOrders = snapshot.data ?? [];
                  final pendingOrders = allOrders.where((o) => o.isPending).length;
                  final confirmedOrders = allOrders.where((o) => o.isConfirmed).length;
                  final completedOrders = allOrders.where((o) => o.isCompleted).length;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildModernStatCard(
                          context,
                          'Pending',
                          '$pendingOrders',
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernStatCard(
                          context,
                          'Confirmed',
                          '$confirmedOrders',
                          Icons.check_circle_outline,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernStatCard(
                          context,
                          'Completed',
                          '$completedOrders',
                          Icons.check_circle,
                          const Color(0xFF00B464),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // === FILTER SECTION ===
              _buildFilterSection(),
              const SizedBox(height: 20),

              // === ORDERS LIST ===
              FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF00B464)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final errorMessage = snapshot.error.toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Error Loading Orders',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage.replaceFirst('Exception: ', ''),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _refreshOrders,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B464),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var orders = snapshot.data ?? [];

                  // Filter orders
                  if (_selectedFilter != 'all') {
                    orders = orders.where((order) {
                      switch (_selectedFilter) {
                        case 'pending':
                          return order.isPending;
                        case 'confirmed':
                          return order.isConfirmed;
                        case 'completed':
                          return order.isCompleted;
                        case 'cancelled':
                          return order.isCancelled;
                        default:
                          return true;
                      }
                    }).toList();
                  }

                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No orders found',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: orders.map((order) {
                      return Column(
                        children: [
                          _buildModernOrderCard(context, order),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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

  /// Filter Section
  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Orders',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00B464) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00B464) : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      filter.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Modern Order Card
  Widget _buildModernOrderCard(BuildContext context, Order order) {
    Color statusColor;

    if (order.isPending) {
      statusColor = Colors.orange;
    } else if (order.isConfirmed) {
      statusColor = Colors.blue;
    } else if (order.isCompleted) {
      statusColor = const Color(0xFF00B464);
    } else {
      statusColor = Colors.red;
    }

    // Format status for display
    String displayStatus = order.status.toUpperCase();
    if (order.status.toLowerCase() == 'accepted') {
      displayStatus = 'CONFIRMED';
    } else if (order.status.toLowerCase() == 'delivered' || order.status.toLowerCase() == 'fulfilled') {
      displayStatus = 'COMPLETED';
    } else if (order.status.toLowerCase() == 'rejected') {
      displayStatus = 'CANCELLED';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
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
                    displayStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider
            Divider(color: Colors.grey[200], height: 12),
            const SizedBox(height: 12),

            // Product Information Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      item.productName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Shop Name (Seller Store Name)
                    Text(
                      order.sellerStoreName ?? 'Shop Name',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price per Unit with Unit
                    Text(
                      '₱${item.pricePerKilo.toStringAsFixed(2)}/${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Method of Fulfillment (Placeholder - to be delivered or for pickup)
                    Row(
                      children: [
                        Icon(
                          order.fulfillmentMethod?.toLowerCase() == 'pickup' 
                            ? Icons.store_outlined 
                            : Icons.local_shipping_outlined, 
                          size: 14, 
                          color: Colors.grey[600]
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.fulfillmentMethod != null
                            ? (order.fulfillmentMethod!.toLowerCase() == 'pickup' 
                              ? 'For pickup' 
                              : 'To be delivered')
                            : 'To be delivered',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Divider between items if multiple
                    if (order.items.indexOf(item) < order.items.length - 1)
                      Column(
                        children: [
                          Divider(color: Colors.grey[100], height: 1),
                          const SizedBox(height: 12),
                        ],
                      ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Items Count and Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.fold<int>(0, (sum, item) => sum + item.quantity)} item${order.items.fold<int>(0, (sum, item) => sum + item.quantity) > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${order.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00B464),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B464),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Build header widget for order screen
  Widget _buildOrderHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_userFirstName $_userLastName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'OPAS Orders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00B464).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_outline),
                  color: const Color(0xFF00B464),
                  iconSize: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: Colors.red,
                  iconSize: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

