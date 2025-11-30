import 'package:flutter/material.dart';
import '../models/seller_order_model.dart';
import '../services/seller_api_service.dart';

class OrdersListingScreen extends StatefulWidget {
  const OrdersListingScreen({super.key});

  @override
  State<OrdersListingScreen> createState() => _OrdersListingScreenState();
}

class _OrdersListingScreenState extends State<OrdersListingScreen> {
  late Future<List<SellerOrder>> _ordersFuture;
  String _selectedStatus = 'ALL'; // ALL, PENDING, ACCEPTED, REJECTED, FULFILLED, DELIVERED
  String _sortBy = 'DATE_DESC'; // DATE_DESC, DATE_ASC, AMOUNT_DESC, AMOUNT_ASC

  static const List<String> statusOptions = [
    'ALL',
    'PENDING',
    'ACCEPTED',
    'REJECTED',
    'FULFILLED',
    'DELIVERED'
  ];

  @override
  void initState() {
    super.initState();
    _ordersFuture = SellerApiService.getPendingOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = SellerApiService.getPendingOrders();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'REJECTED':
        return Colors.red;
      case 'FULFILLED':
        return Colors.purple;
      case 'DELIVERED':
        return const Color(0xFF00B464);
      default:
        return Colors.grey;
    }
  }

  List<SellerOrder> _filterAndSortOrders(List<SellerOrder> orders) {
    // Filter by status
    List<SellerOrder> filtered = orders;
    if (_selectedStatus != 'ALL') {
      filtered = orders
          .where((o) => o.status.toUpperCase() == _selectedStatus.toUpperCase())
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'DATE_DESC':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'DATE_ASC':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'AMOUNT_DESC':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'AMOUNT_ASC':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<SellerOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B464)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders from buyers will appear here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final allOrders = snapshot.data!;
          final filteredOrders = _filterAndSortOrders(allOrders);

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            color: const Color(0xFF00B464),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Stats Overview
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatsOverview(context, allOrders),
                  ),
                  const SizedBox(height: 8),
                  // Filter & Sort Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Filter
                        Text(
                          'Filter by Status',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: statusOptions.map((status) {
                              final isSelected = _selectedStatus == status;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(status),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedStatus = status;
                                    });
                                  },
                                  backgroundColor: Colors.grey.withOpacity(0.1),
                                  selectedColor: const Color(0xFF00B464).withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected ? const Color(0xFF00B464) : Colors.grey[600],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF00B464) : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sort Options
                        Text(
                          'Sort by',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'DATE_DESC', child: Text('Newest First')),
                              DropdownMenuItem(value: 'DATE_ASC', child: Text('Oldest First')),
                              DropdownMenuItem(value: 'AMOUNT_DESC', child: Text('Highest Amount')),
                              DropdownMenuItem(value: 'AMOUNT_ASC', child: Text('Lowest Amount')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Orders List
                  if (filteredOrders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No $_selectedStatus orders',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: filteredOrders.asMap().entries.map((entry) {
                          final index = entry.key;
                          final order = entry.value;
                          return Column(
                            children: [
                              _buildOrderCard(context, order),
                              if (index < filteredOrders.length - 1) const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, List<SellerOrder> allOrders) {
    final pendingCount = allOrders.where((o) => o.isPending).length;
    final acceptedCount = allOrders.where((o) => o.isAccepted).length;
    final completedCount = allOrders.where((o) => o.isCompleted).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, 'Pending', '$pendingCount', Icons.pending_actions, Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(context, 'Confirmed', '$acceptedCount', Icons.receipt_long, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(context, 'Completed', '$completedCount', Icons.check_circle, const Color(0xFF00B464)),
        ),
      ],
    );
  }

  Widget _buildStatCard(
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

  Widget _buildOrderCard(BuildContext context, SellerOrder order) {
    final statusColor = _getStatusColor(order.status);
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
          const SizedBox(height: 10),
          // Order Details
          Text(
            '${order.quantity} units • ${order.buyerName ?? 'Unknown Buyer'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.productName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          // Amount and Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${order.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00B464),
                ),
              ),
              Text(
                order.createdAt.toString().substring(0, 10),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
