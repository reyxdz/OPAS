// OPAS Submission Review Dialog - Admin approval/rejection workflow
// Allows admin to accept submissions, set final prices, generate purchase orders

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/opas_submission_model.dart';
import '../../../core/services/admin_service.dart';

class OPASSubmissionReviewDialog extends StatefulWidget {
  final OPASSubmissionModel submission;
  final Function(bool approved, double? quantityAccepted, double? finalPrice,
      String? deliveryTerms, String? notes) onDecision;

  const OPASSubmissionReviewDialog({
    Key? key,
    required this.submission,
    required this.onDecision,
  }) : super(key: key);

  @override
  State<OPASSubmissionReviewDialog> createState() =>
      _OPASSubmissionReviewDialogState();
}

class _OPASSubmissionReviewDialogState
    extends State<OPASSubmissionReviewDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _finalPriceController;
  late TextEditingController _deliveryTermsController;
  late TextEditingController _adminNotesController;

  bool _isLoading = false;
  bool _isApproving = true; // true = approve, false = reject
  String? _selectedDeliveryOption;

  static const List<String> _deliveryOptions = [
    'To be picked up by OPAS',
    'To be delivered to OPAS',
  ];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.submission.quantity.toStringAsFixed(2),
    );
    _finalPriceController = TextEditingController(
      text: widget.submission.offeredPrice.toStringAsFixed(2),
    );
    _deliveryTermsController = TextEditingController();
    _adminNotesController = TextEditingController();
    _selectedDeliveryOption = _deliveryOptions.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _finalPriceController.dispose();
    _deliveryTermsController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  void _handleDecision() async {
    if (_isApproving) {
      // Validate approval fields
      if (_quantityController.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter accepted quantity')),
          );
        }
        return;
      }

      if (_finalPriceController.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter final price')),
          );
        }
        return;
      }

      if (_selectedDeliveryOption == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select delivery option')),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isApproving) {
        // Call approve API - static method
        await AdminService.approveOPASSubmission(
          widget.submission.id.toString(),
          quantityAccepted: double.parse(_quantityController.text).toInt(),
          finalPrice: double.parse(_finalPriceController.text),
          terms: _selectedDeliveryOption ?? 'To be arranged',
          adminNotes: _adminNotesController.text,
        );

        if (mounted) {
          widget.onDecision(
            true,
            double.parse(_quantityController.text),
            double.parse(_finalPriceController.text),
            _selectedDeliveryOption,
            _adminNotesController.text,
          );
          Navigator.pop(context);
        }
      } else {
        // Call reject API - static method
        await AdminService.rejectOPASSubmission(
          widget.submission.id.toString(),
          reason: _adminNotesController.text.isEmpty 
              ? 'No reason provided' 
              : _adminNotesController.text,
        );

        if (mounted) {
          widget.onDecision(
            false,
            null,
            null,
            null,
            _adminNotesController.text,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.submission.status.toUpperCase() == 'APPROVED';
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                isApproved ? 'Purchase Order' : 'Review OPAS Submission',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Submission Details (Read-only)
              _buildDetailSection(
                'Submission Details',
                [
                  ('Seller', widget.submission.sellerName),
                  ('Product', widget.submission.productName),
                  ('Description', widget.submission.description),
                  ('Submitted', DateFormat('MMM dd, yyyy').format(widget.submission.submittedAt)),
                ],
              ),

              const SizedBox(height: 20),

              // Original Offer
              _buildDetailSection(
                'Original Offer',
                [
                  ('Quantity', '${widget.submission.quantity.toStringAsFixed(2)} ${widget.submission.unit}'),
                  ('Offered Price', 'PHP ${widget.submission.offeredPrice.toStringAsFixed(2)}/${widget.submission.unit}'),
                  ('Total Value', 'PHP ${widget.submission.getTotalOfferedValue().toStringAsFixed(0)}'),
                ],
              ),

              const SizedBox(height: 20),

              // Product Photos (if available)
              if (widget.submission.getImageUrls().isNotEmpty)
                _buildPhotoGallerySection(widget.submission.getImageUrls()),

              if (widget.submission.getImageUrls().isNotEmpty)
                const SizedBox(height: 20),

              // Show different UI based on status
              if (isApproved)
                _buildApprovedView()
              else
                _buildReviewView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Approval Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Approved',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildApprovedRow('Status', 'APPROVED'),
              _buildApprovedRow('Quantity Accepted', '${widget.submission.quantity.toStringAsFixed(2)} ${widget.submission.unit}'),
              _buildApprovedRow('Final Price', 'PHP ${widget.submission.offeredPrice.toStringAsFixed(2)}/${widget.submission.unit}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildApprovedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewView() {
    return Column(
      children: [
        // Decision Toggle
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _isApproving = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isApproving
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade300,
                  foregroundColor:
                      _isApproving ? Colors.white : Colors.black,
                ),
                child: const Text('Approve'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _isApproving = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_isApproving
                      ? Colors.red
                      : Colors.grey.shade300,
                  foregroundColor:
                      !_isApproving ? Colors.white : Colors.black,
                ),
                child: const Text('Reject'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Conditional Fields Based on Decision
        if (_isApproving) ...[
          Text(
            'Approval Details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          // Quantity Accepted
          Text(
            'Quantity Accepted',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter quantity to accept',
              suffixText: widget.submission.unit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 16),

          // Final Price
          Text(
            'Final Price per ${widget.submission.unit}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _finalPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter final negotiated price',
              prefixText: 'PHP ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 16),

          // Price Comparison
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'PHP ${widget.submission.offeredPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_right, color: Colors.grey.shade400),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Final',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _finalPriceController.text.isNotEmpty
                          ? 'PHP ${double.parse(_finalPriceController.text).toStringAsFixed(2)}'
                          : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Delivery Terms
          Text(
            'Delivery Terms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: _selectedDeliveryOption,
              items: _deliveryOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedDeliveryOption = value),
            ),
          ),

          const SizedBox(height: 16),

          // Additional notes
          TextField(
            controller: _deliveryTermsController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Additional delivery notes (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ] else ...[
          // Rejection Notes
          Text(
            'Rejection Reason',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _adminNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Explain reason for rejection',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _handleDecision,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isApproving
                    ? const Color(0xFF4CAF50)
                    : Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_isApproving
                      ? 'Approve & Generate PO'
                      : 'Reject Submission'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 2),
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper to build photo gallery section
  Widget _buildPhotoGallerySection(List<String> imageUrls) {
    // Debug: Log the image URLs
    if (imageUrls.isNotEmpty) {
      debugPrint('🖼️ [OPAS Photos] Loaded ${imageUrls.length} images:');
      for (int i = 0; i < imageUrls.length; i++) {
        debugPrint('  [$i] ${{imageUrls[i]}}');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Photos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(12),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return _buildPhotoTile(imageUrls[index]);
            },
          ),
        ),
      ],
    );
  }

  /// Helper to build individual photo tile
  Widget _buildPhotoTile(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImagePreview(imageUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Failed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
              // Zoom icon overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show full-screen image preview
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: const Text(
                  'Tap to close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build detail section
  Widget _buildDetailSection(String title, List<(String, String)> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: details
                .asMap()
                .entries
                .map(
                  (entry) {
                    final isLast = entry.key == details.length - 1;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.value.$1,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              entry.value.$2,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (!isLast)
                          Divider(color: Colors.grey.shade300, height: 16),
                      ],
                    );
                  },
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
