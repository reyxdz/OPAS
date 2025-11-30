import 'package:flutter/material.dart';
import '../../order_management/models/order_model.dart';
import '../../products/services/buyer_api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order? order;
  final int? orderId;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _orderFuture;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _orderFuture = Future.value(widget.order!);
    } else if (widget.orderId != null) {
      _orderFuture = BuyerApiService.getOrderDetail(widget.orderId!);
    } else {
      _orderFuture = Future.error('No order data provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<Order>(
        future: _orderFuture,
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading order',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === ORDER HEADER CARD ===
                _buildOrderHeaderCard(context, order),
                const SizedBox(height: 24),

                // === ORDER STATUS TIMELINE ===
                _buildStatusTimeline(context, order),
                const SizedBox(height: 24),

                // === ITEMS SECTION ===
                _buildItemsSection(context, order),
                const SizedBox(height: 24),

                // === DELIVERY INFORMATION ===
                _buildDeliverySection(context, order),
                const SizedBox(height: 24),

                // === SELLER INFORMATION ===
                _buildSellerSection(context, order),
                const SizedBox(height: 24),

                // === PAYMENT INFORMATION ===
                _buildPaymentSection(context, order),
                const SizedBox(height: 24),

                // === ACTION BUTTONS ===
                if (order.isPending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showCancelConfirmation(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (order.isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Leave a Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B464),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Order Header Card with Order Number and Status
  Widget _buildOrderHeaderCard(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Placed on ${_formatDate(order.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B464).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00B464).withOpacity(0.2),
              ),
            ),
            child: Row(
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
                    const SizedBox(height: 4),
                    Text(
                      '₱${order.totalAmount.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00B464),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.receipt_long,
                  color: const Color(0xFF00B464),
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status Timeline
  Widget _buildStatusTimeline(BuildContext context, Order order) {
    final statuses = [
      {'status': 'pending', 'label': 'Pending', 'icon': Icons.shopping_cart},
      {'status': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle},
      {'status': 'completed', 'label': 'Delivered', 'icon': Icons.local_shipping},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Order Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(statuses.length * 2 - 1, (index) {
                  if (index.isEven) {
                    final statusIndex = index ~/ 2;
                    final statusInfo = statuses[statusIndex];
                    final status = statusInfo['status'] as String;
                    final label = statusInfo['label'] as String;
                    final icon = statusInfo['icon'] as IconData;
                    final isCompleted = _getStatusIndex(order.status) >= statusIndex;
                    final isCurrent = order.status == status;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? const Color(0xFF00B464)
                                : Colors.grey[200],
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF00B464)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isCompleted ? Colors.white : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? const Color(0xFF00B464) : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  } else {
                    final isActive = _getStatusIndex(order.status) > index ~/ 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 20,
                        height: 2,
                        child: Container(
                          color: isActive ? const Color(0xFF00B464) : Colors.grey[200],
                        ),
                      ),
                    );
                  }
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Items Section
  Widget _buildItemsSection(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            order.items.length,
            (index) {
              final item = order.items[index];
              return Column(
                children: [
                  _buildItemRow(context, item),
                  if (index < order.items.length - 1) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Individual Item Row
  Widget _buildItemRow(BuildContext context, dynamic item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} ${item.unit} × ₱${item.pricePerKilo.toStringAsFixed(2)}/unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${item.subtotal.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00B464),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Buyer Information Section
  Widget _buildDeliverySection(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Buyer\'s Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Name', order.buyerName),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'Phone', order.buyerPhone),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Delivery Address',
            order.deliveryAddress,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// Seller Information Section
  Widget _buildSellerSection(BuildContext context, Order order) {
    final hasSellerInfo = order.sellerStoreName != null ||
        order.sellerFarmName != null ||
        order.sellerFarmAddress != null ||
        order.sellerPhone != null;

    if (!hasSellerInfo) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Color(0xFF00B464), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Seller\'s Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (order.sellerStoreName != null && order.sellerStoreName!.isNotEmpty) ...[
            _buildInfoRow(context, 'Store Name', order.sellerStoreName!),
            const SizedBox(height: 12),
          ],
          if (order.sellerFarmName != null && order.sellerFarmName!.isNotEmpty) ...[
            _buildInfoRow(context, 'Farm Name', order.sellerFarmName!),
            const SizedBox(height: 12),
          ],
          if (order.sellerPhone != null && order.sellerPhone!.isNotEmpty) ...[
            _buildInfoRow(context, 'Phone', order.sellerPhone!),
            const SizedBox(height: 12),
          ],
          if (order.sellerFarmAddress != null && order.sellerFarmAddress!.isNotEmpty)
            _buildInfoRow(context, 'Farm Address', order.sellerFarmAddress!, maxLines: 3),
        ],
      ),
    );
  }

  /// Payment Information Section
  Widget _buildPaymentSection(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Delivery Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Delivery Method',
            order.paymentMethod == 'cash_on_delivery'
                ? 'Cash on Delivery'
                : order.paymentMethod == 'delivery'
                    ? 'Home Delivery'
                    : order.paymentMethod.replaceAll('_', ' ').toUpperCase(),
          ),
        ],
      ),
    );
  }

  /// Info Row Widget
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Show modern cancel confirmation dialog
  void _showCancelConfirmation(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Cancel Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Are you sure you want to cancel order #${order.orderNumber}?\n\nThis action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    // Keep Order Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Keep Order',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Cancel Order Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _cancelOrder(context, order);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel Order',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cancel the order
  Future<void> _cancelOrder(BuildContext context, Order order) async {
    // Show loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00B464)),
                const SizedBox(height: 16),
                Text(
                  'Cancelling order...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Call API to cancel order
      debugPrint('🔄 Attempting to cancel order ${order.id}...');
      await BuyerApiService.cancelOrder(order.id);
      debugPrint('✅ Order ${order.id} cancelled successfully');

      if (!context.mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh and navigate back after delay
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      
      if (!context.mounted) return;
      
      // Close loading dialog first
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Helper Functions
  int _getStatusIndex(String status) {
    const statusMap = {
      'pending': 0,
      'confirmed': 1,
      'completed': 2,
    };
    return statusMap[status] ?? 0;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
