import 'package:flutter/material.dart';
import '../../order_management/models/order_model.dart';
import '../../order_management/screens/order_detail_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00B464),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Success Message
              Text(
                'Order Placed Successfully!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been received and is being processed.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Order Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      'Order Number',
                      order.orderNumber,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Total Amount',
                      '₱${order.totalAmount.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 12),
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
                      'Delivery Address',
                      order.deliveryAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Order Status',
                      order.status.replaceAll('_', ' ').toUpperCase(),
                      isStatus: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Items Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items Ordered (${order.items.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}× ${item.productName}',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₱${item.subtotal.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt),
                  label: const Text('Track Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B464),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (route) => route.settings.name == '/' || route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
    bool isStatus = false,
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
          child: isHighlight
              ? Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: const Color(0xFF00B464),
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.right,
                )
              : isStatus
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B464).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: const Color(0xFF00B464),
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    )
                  : Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
        ),
      ],
    );
  }
}
