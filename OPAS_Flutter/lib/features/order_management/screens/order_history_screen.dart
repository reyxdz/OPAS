import 'package:flutter/material.dart';
import '../../order_management/models/order_model.dart';
import '../../products/services/buyer_api_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'all';
  late Future<List<Order>> _ordersFuture;

  final List<String> _filters = ['all', 'pending', 'confirmed', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      // _ordersFuture = BuyerApiService.getBuyerOrders();
      // Use mock data for presentation
      _ordersFuture = Future.delayed(
        const Duration(milliseconds: 500),
        () => _generateMockOrders(),
      );
    });
  }

  List<Order> _generateMockOrders() {
    return [
      Order(
        id: 1,
        orderNumber: 'ORD-2023-001',
        items: [
          OrderItem(
            id: 1, productId: 101, productName: 'Fresh Tomatoes',
            pricePerKilo: 45.0, quantity: 2, unit: 'kg', subtotal: 90.0,
            imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=300&q=80',
          ),
          OrderItem(
            id: 2, productId: 102, productName: 'Organic Lettuce',
            pricePerKilo: 60.0, quantity: 1, unit: 'kg', subtotal: 60.0,
            imageUrl: 'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?auto=format&fit=crop&w=300&q=80',
          ),
          OrderItem(
            id: 6, productId: 106, productName: 'Chicken Breast',
            pricePerKilo: 180.0, quantity: 2, unit: 'kg', subtotal: 360.0,
            imageUrl: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        totalAmount: 510.0,
        status: 'completed',
        paymentMethod: 'cash_on_delivery',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        deliveryAddress: '123 Main St, Baguio City',
        buyerName: 'Juan Dela Cruz',
        buyerPhone: '09123456789',
      ),
      Order(
        id: 2,
        orderNumber: 'ORD-2023-002',
        items: [
          OrderItem(
            id: 5, productId: 105, productName: 'Yellow Mangoes',
            pricePerKilo: 120.0, quantity: 3, unit: 'kg', subtotal: 360.0,
            imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        totalAmount: 360.0,
        status: 'pending',
        paymentMethod: 'gcash',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        deliveryAddress: '123 Main St, Baguio City',
        buyerName: 'Juan Dela Cruz',
        buyerPhone: '09123456789',
      ),
      Order(
        id: 3,
        orderNumber: 'ORD-2023-003',
        items: [
          OrderItem(
            id: 3, productId: 103, productName: 'Red Onions',
            pricePerKilo: 80.0, quantity: 1, unit: 'kg', subtotal: 80.0,
            imageUrl: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=300&q=80',
          ),
          OrderItem(
            id: 4, productId: 104, productName: 'Green Apples',
            pricePerKilo: 50.0, quantity: 2, unit: 'kg', subtotal: 100.0,
            imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        totalAmount: 180.0,
        status: 'cancelled',
        paymentMethod: 'cash_on_delivery',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        deliveryAddress: '123 Main St, Baguio City',
        buyerName: 'Juan Dela Cruz',
        buyerPhone: '09123456789',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER ===
              Text(
                'My Orders',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // === STATS OVERVIEW ===
              FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  final allOrders = snapshot.data ?? [];
                  final totalOrders = allOrders.length;
                  final pendingOrders = allOrders.where((o) => o.isPending).length;
                  final completedOrders = allOrders.where((o) => o.isCompleted).length;
                  final totalSpent = allOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);

                  return Row(
                    children: [
                      Expanded(
                        child: _buildModernStatCard(
                          context,
                          'Total Orders',
                          '$totalOrders',
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Error loading orders',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
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
                    orders = orders.where((order) => order.status == _selectedFilter).toList();
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
                    order.status.toUpperCase(),
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

            // Items Count and Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
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
}
