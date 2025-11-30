import 'package:flutter/material.dart';
import '../models/seller_order_model.dart';
import '../services/seller_service.dart';

class OrdersListingScreen extends StatefulWidget {
  const OrdersListingScreen({super.key});

  @override
  State<OrdersListingScreen> createState() => _OrdersListingScreenState();
}

class _OrdersListingScreenState extends State<OrdersListingScreen> {
  late Future<List<SellerOrder>> _ordersFuture;
  List<SellerOrder> _allOrders = [];
  final Map<String, List<SellerOrder>> _groupedOrders = {};
  String _selectedStatus = 'ALL'; // ALL, PENDING, ACCEPTED, REJECTED, FULFILLED, DELIVERED
  String _sortBy = 'DATE_DESC'; // DATE_DESC, DATE_ASC, AMOUNT_DESC, AMOUNT_ASC
  bool _isLoading = false;

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
    _ordersFuture = SellerService.getOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final orders = await SellerService.getOrders();
      setState(() {
        _allOrders = orders;
        _applyFilterAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing orders: $e')),
        );
      }
    }
  }

  void _applyFilterAndSort() {
    // Filter by status
    List<SellerOrder> filtered = _allOrders;
    if (_selectedStatus != 'ALL') {
      filtered = _allOrders.where((o) => o.status == _selectedStatus).toList();
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

    // Group by status
    _groupedOrders.clear();
    for (var order in filtered) {
      if (!_groupedOrders.containsKey(order.status)) {
        _groupedOrders[order.status] = [];
      }
      _groupedOrders[order.status]!.add(order);
    }
  }

  void _onFilterChanged(String newStatus) {
    setState(() {
      _selectedStatus = newStatus;
      _applyFilterAndSort();
    });
  }

  void _onSortChanged(String newSort) {
    setState(() {
      _sortBy = newSort;
      _applyFilterAndSort();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'REJECTED':
        return Colors.red;
      case 'FULFILLED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Orders'),
        elevation: 2,
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              _allOrders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_allOrders.isEmpty && snapshot.hasData) {
            _allOrders = snapshot.data ?? [];
            _applyFilterAndSort();
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: _allOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Orders from buyers will appear here',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Filter & Sort Controls
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Status Filter
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text(
                                    'Filter:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  ...statusOptions.map((status) {
                                    final isSelected =
                                        _selectedStatus == status;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 4),
                                      child: FilterChip(
                                        label: Text(status),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            _onFilterChanged(status);
                                          }
                                        },
                                        backgroundColor: Colors.grey.withOpacity(0.2),
                                        selectedColor: const Color(0xFF00B464)
                                            .withOpacity(0.3),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF00B464)
                                              : Colors.grey,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Sort Options
                            Row(
                              children: [
                                Text(
                                  'Sort:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _sortBy,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'DATE_DESC',
                                        child: Text('Newest First'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'DATE_ASC',
                                        child: Text('Oldest First'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'AMOUNT_DESC',
                                        child: Text('Highest Amount'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'AMOUNT_ASC',
                                        child: Text('Lowest Amount'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        _onSortChanged(value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Orders List
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _groupedOrders.isEmpty
                                ? Center(
                                    child: Text(
                                      'No $_selectedStatus orders',
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    itemCount: _groupedOrders.length,
                                    itemBuilder: (context, index) {
                                      final status = _groupedOrders.keys
                                          .toList()[index];
                                      final orders = _groupedOrders[status]!;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getStatusColor(status),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '$status (${orders.length})',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            _getStatusColor(
                                                                status),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ...orders.map((order) {
                                            return _buildOrderCard(
                                              context,
                                              order,
                                              status,
                                            );
                                          }).toList(),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    SellerOrder order,
    String status,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '₱${order.totalAmount.toStringAsFixed(2)} • Qty: ${order.quantity}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Product', order.productName),
                const SizedBox(height: 8),
                _buildInfoRow('Quantity', '${order.quantity} units'),
                const SizedBox(height: 8),
                _buildInfoRow('Price per Unit', '₱${(order.totalAmount / order.quantity).toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildInfoRow('Total Amount', '₱${order.totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildInfoRow('Buyer', order.buyerName ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Date',
                  order.createdAt.toString().substring(0, 10),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                _buildActionButtons(context, order, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    SellerOrder order,
    String status,
  ) {
    final buttons = <Widget>[];

    if (status == 'PENDING') {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _acceptOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectOrder(order),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    } else if (status == 'ACCEPTED') {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _fulfillOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text(
              'Mark Fulfilled',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } else if (status == 'FULFILLED') {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _deliverOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              'Mark Delivered',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return buttons.isEmpty
        ? Center(
            child: Text(
              'No actions available for $status orders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          )
        : Row(
            children: buttons,
          );
  }

  Future<void> _acceptOrder(SellerOrder order) async {
    try {
      // Phase 3.2: Check stock availability before accepting
      // The backend will validate stock availability during acceptance
      
      final confirmed = await _showConfirmationDialog(
        'Accept Order',
        'Accept order #${order.id} for ₱${order.totalAmount.toStringAsFixed(2)}?\n\n'
        'Quantity: ${order.quantity} units',
      );

      if (!confirmed) return;

      setState(() {
        _isLoading = true;
      });

      // Attempt to accept order - backend performs stock validation
      await SellerService.acceptOrder(order.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted! Stock has been reserved.'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshOrders();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Parse backend error message for stock availability issues
      final errorMessage = e.toString();
      String displayMessage = 'Error accepting order';
      
      if (errorMessage.contains('Insufficient stock') || 
          errorMessage.contains('insufficient')) {
        displayMessage = '⚠ Insufficient Stock!\n\nNot enough inventory to accept this order.';
      } else if (errorMessage.contains('double-accept') ||
                 errorMessage.contains('already') ||
                 errorMessage.contains('already been')) {
        displayMessage = '⚠ This order has already been processed.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(SellerOrder order) async {
    final confirmed = await _showConfirmationDialog(
      'Reject Order',
      'Reject order #${order.id}? The buyer will be notified.',
    );

    if (!confirmed) return;

    try {
      await SellerService.rejectOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #${order.id} rejected')),
        );
        _refreshOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting order: $e')),
        );
      }
    }
  }

  Future<void> _fulfillOrder(SellerOrder order) async {
    final confirmed = await _showConfirmationDialog(
      'Mark as Fulfilled',
      'Mark order #${order.id} as fulfilled?\n\n'
      'Stock will be automatically updated: ${order.quantity} units deducted.',
    );

    if (!confirmed) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Phase 3.2: Stock is auto-updated by backend during fulfillment
      await SellerService.fulfillOrder(order.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order fulfilled! Stock automatically updated.'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshOrders();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      final errorMessage = e.toString();
      String displayMessage = 'Error fulfilling order';
      
      if (errorMessage.contains('insufficient')) {
        displayMessage = '⚠ Cannot fulfill - insufficient stock available.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deliverOrder(SellerOrder order) async {
    final confirmed = await _showConfirmationDialog(
      'Mark as Delivered',
      'Mark order #${order.id} as delivered? The buyer will be notified.',
    );

    if (!confirmed) return;

    try {
      await SellerService.deliverOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #${order.id} marked as delivered')),
        );
        _refreshOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error delivering order: $e')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
