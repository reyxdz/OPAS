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
    'Seller Pickup',
    'OPAS Delivery',
    'Third Party Logistics',
    'To be arranged'
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
          quantityAccepted: int.parse(_quantityController.text),
          finalPrice: double.parse(_finalPriceController.text),
          terms: _selectedDeliveryOption ?? 'To be arranged',
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
                'Review OPAS Submission',
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
                  ('Category', widget.submission.productCategory),
                  ('Quality Grade', widget.submission.qualityGrade),
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
                  ('Offered Price', 'PKR ${widget.submission.offeredPrice.toStringAsFixed(2)}/${widget.submission.unit}'),
                  ('Total Value', 'PKR ${widget.submission.getTotalOfferedValue().toStringAsFixed(0)}'),
                ],
              ),

              const SizedBox(height: 24),

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
                    prefixText: 'PKR ',
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
                            'PKR ${widget.submission.offeredPrice.toStringAsFixed(2)}',
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
                                ? 'PKR ${double.parse(_finalPriceController.text).toStringAsFixed(2)}'
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // Admin Notes (always visible)
              Text(
                'Admin Notes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _adminNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isApproving
                      ? 'Internal notes (e.g., quality concerns, special handling)'
                      : 'Explain reason for rejection',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleDecision,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApproving
                          ? const Color(0xFF4CAF50)
                          : Colors.red,
                      foregroundColor: Colors.white,
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
                ],
              ),
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
