// Seller list tile widget for admin sellers list
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/seller_model.dart';

class SellerListTile extends StatelessWidget {
  final SellerModel seller;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;

  const SellerListTile({
    Key? key,
    required this.seller,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (seller.status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'SUSPENDED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay() {
    switch (seller.status.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'SUSPENDED':
        return 'Suspended';
      case 'PENDING':
        return 'Pending';
      default:
        return seller.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withOpacity(0.3),
          child: Icon(
            seller.status == 'APPROVED' 
              ? Icons.check_circle 
              : seller.status == 'SUSPENDED'
              ? Icons.block
              : Icons.hourglass_empty,
            color: _getStatusColor(),
          ),
        ),
        title: Text(seller.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              seller.storeName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${seller.email} • ${dateFormat.format(seller.createdAt)}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusDisplay(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
