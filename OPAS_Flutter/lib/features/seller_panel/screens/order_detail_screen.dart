import 'package:flutter/material.dart';
import '../models/seller_order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final SellerOrder order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late SellerOrder _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_order.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.3))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${_order.orderNumber}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.6), width: 1.5),
                        ),
                        child: Text(
                          _order.status.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Placed on ${_formatDate(_order.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Buyer Information Section
                  _buildSection(
                    context,
                    'Buyer Information',
                    [
                      _buildInfoRow(context, 'Name', _order.buyerName ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Phone', _order.buyerPhone ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Product Information Section
                  _buildSection(
                    context,
                    'Product Information',
                    [
                      _buildInfoRow(context, 'Product Name', _order.productName),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Product ID', _order.product.toString()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Order Details Section
                  _buildSection(
                    context,
                    'Order Details',
                    [
                      _buildInfoRow(context, 'Quantity', '${_order.quantity} units'),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Price per Unit',
                        '₱${_order.pricePerUnit.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Total Amount',
                        '₱${_order.totalAmount.toStringAsFixed(2)}',
                        isBold: true,
                        isHighlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timeline Section
                  _buildSection(
                    context,
                    'Order Timeline',
                    [
                      _buildTimelineItem(
                        context,
                        'Created',
                        _formatDate(_order.createdAt),
                        Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      if (_order.acceptedAt != null)
                        _buildTimelineItem(
                          context,
                          'Accepted',
                          _formatDate(_order.acceptedAt!),
                          Colors.blue,
                        ),
                      if (_order.acceptedAt != null) const SizedBox(height: 16),
                      if (_order.fulfilledAt != null)
                        _buildTimelineItem(
                          context,
                          'Fulfilled',
                          _formatDate(_order.fulfilledAt!),
                          Colors.purple,
                        ),
                      if (_order.fulfilledAt != null) const SizedBox(height: 16),
                      if (_order.deliveredAt != null)
                        _buildTimelineItem(
                          context,
                          'Delivered',
                          _formatDate(_order.deliveredAt!),
                          const Color(0xFF00B464),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Additional Information Section
                  _buildSection(
                    context,
                    'Additional Information',
                    [
                      _buildInfoRow(context, 'Order ID', _order.id.toString()),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Seller ID', _order.seller.toString()),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Buyer ID', _order.buyer.toString()),
                      if (_order.deliveryLocation != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(context, 'Delivery Location', _order.deliveryLocation!),
                      ],
                      if (_order.rejectionReason != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          'Rejection Reason',
                          _order.rejectionReason!,
                          isHighlight: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons Section
                  if (_order.isPending)
                    _buildActionButtons(context)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Text(
                            'No actions available for ${_order.status.toLowerCase()} orders',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
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
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? const Color(0xFF00B464) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String dateTime,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Accept Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showConfirmationDialog(
                context,
                'Accept Order',
                'Accept order #${_order.orderNumber}?\n\nQuantity: ${_order.quantity} units\nTotal: ₱${_order.totalAmount.toStringAsFixed(2)}',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order accepted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // TODO: Call API to accept order
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Accept Order',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reject Button (Only visible if pending)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _showRejectDialog(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Reject Order',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${_order.orderNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Rejection Reason (Optional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for rejection...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order #${_order.orderNumber} rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
                // TODO: Call API to reject order with reason
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
