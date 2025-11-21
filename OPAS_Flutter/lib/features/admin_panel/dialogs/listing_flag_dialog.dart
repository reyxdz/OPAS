// Listing Flag Dialog - Dialog for flagging suspicious marketplace listings
// Used to report and manage suspicious listings with detailed information

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/marketplace_listing_model.dart';

class ListingFlagDialog extends StatefulWidget {
  final MarketplaceListingModel listing;
  final Function(String reason, String details) onSubmit;

  const ListingFlagDialog({
    Key? key,
    required this.listing,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ListingFlagDialog> createState() => _ListingFlagDialogState();
}

class _ListingFlagDialogState extends State<ListingFlagDialog> {
  late TextEditingController _reasonController;
  late TextEditingController _detailsController;
  String _selectedCategory = 'PRICE_VIOLATION';
  bool _isSubmitting = false;

  final List<String> _flagReasons = [
    'PRICE_VIOLATION',
    'MISSING_INFORMATION',
    'SUSPICIOUS_PRICING',
    'LOW_QUALITY_IMAGES',
    'POTENTIAL_FRAUD',
    'DUPLICATE_LISTING',
    'UNAUTHORIZED_SELLER',
    'COMPLIANCE_VIOLATION',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Flag Suspicious Listing'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Listing Details',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Seller', widget.listing.sellerName),
                  _buildDetailRow('Product', widget.listing.productName),
                  _buildDetailRow(
                    'Price',
                    widget.listing.formatPrice(),
                  ),
                  if (widget.listing.isAboveCeiling())
                    _buildDetailRow(
                      'Above Ceiling',
                      '${widget.listing.priceOverage!.toStringAsFixed(1)}%',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Flag category dropdown
            Text(
              'Flag Reason',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _flagReasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(_formatReason(reason)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Detailed reason
            Text(
              'Detailed Reason (Optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide additional details about why this listing is flagged...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flagged listings will be reviewed by the admin team. Sellers will be notified if violations are confirmed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitFlag,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.flag),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit Flag'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _submitFlag() {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flag reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      widget.onSubmit(
        _selectedCategory,
        _detailsController.text.trim(),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing flagged successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatReason(String reason) {
    return reason
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
