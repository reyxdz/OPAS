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

  final List<String> _filters = ['all', 'pending', 'confirmed', 'completed'];

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
      backgroundColor: const Color(0xFFFAFAFA),
      // appBar: AppBar(
      //   title: const Text('Order History'),
      //   centerTitle: true,
      // ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
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
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                var orders = snapshot.data ?? [];

                // Filter orders
                if (_selectedFilter != 'all') {
                  orders = orders
                      .where((order) => order.status == _selectedFilter)
                      .toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    Color statusColor;
    IconData statusIcon;

    if (order.isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else if (order.isConfirmed) {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
    } else if (order.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.done_all;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order # and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              
              // Product Images Preview
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        image: item.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(item.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.imageUrl.isEmpty
                          ? Icon(Icons.image, color: Colors.grey[400], size: 20)
                          : null,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Footer: Total and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₱${order.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF00B464),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B464),
                      side: const BorderSide(color: Color(0xFF00B464)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
