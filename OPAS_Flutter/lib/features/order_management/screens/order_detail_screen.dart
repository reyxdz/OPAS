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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<Order>(
        future: _orderFuture,
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

          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Timeline
                _buildStatusTimeline(context, order),
                const SizedBox(height: 24),

                // Order Information
                _buildSection(
                  context,
                  'Order Information',
                  [
                    _buildDetailRow(context, 'Order Number', order.orderNumber),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Order Date',
                      '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Status',
                      order.status.toUpperCase(),
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Delivery Information
                _buildSection(
                  context,
                  'Delivery Information',
                  [
                    _buildDetailRow(context, 'Recipient', order.buyerName),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Phone', order.buyerPhone),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Address',
                      order.deliveryAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Information
                _buildSection(
                  context,
                  'Payment Information',
                  [
                    _buildDetailRow(
                      context,
                      'Payment Method',
                      order.paymentMethod == 'cash_on_delivery'
                          ? 'Cash on Delivery'
                          : order.paymentMethod.replaceAll('_', ' '),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Total Amount',
                      '₱${order.totalAmount.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Items
                _buildSection(
                  context,
                  'Items (${order.items.length})',
                  [
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  Text(
                                    '${item.quantity} ${item.unit} × ₱${item.pricePerKilo.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₱${item.subtotal.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00B464),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                if (order.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to review screen
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
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context, Order order) {
    final statuses = [
      {'status': 'pending', 'label': 'Order Placed'},
      {'status': 'confirmed', 'label': 'Confirmed'},
      {'status': 'completed', 'label': 'Delivered'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (context, index) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Divider(thickness: 2),
                ),
              ),
              itemBuilder: (context, index) {
                final statusInfo = statuses[index];
                final status = statusInfo['status'] as String;
                final label = statusInfo['label'] as String;
                final isCompleted =
                    _getStatusIndex(order.status) >= index;
                final isCurrent = order.status == status;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF00B464)
                            : Colors.grey[300],
                      ),
                      child: Icon(
                        isCurrent
                            ? Icons.check_circle
                            : isCompleted
                                ? Icons.check
                                : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getStatusIndex(String status) {
    const statusMap = {
      'pending': 0,
      'confirmed': 1,
      'completed': 2,
    };
    return statusMap[status] ?? 0;
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? const Color(0xFF00B464) : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
