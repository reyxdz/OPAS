// OPAS Submissions Screen - Admin review of seller "Sell to OPAS" offers
// List submissions with filtering, sorting, and approval workflow

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/models/opas_submission_model.dart';
import '../../../core/services/admin_service.dart';
import '../dialogs/opas_submission_review_dialog.dart';

class OPASSubmissionsScreen extends StatefulWidget {
  const OPASSubmissionsScreen({Key? key}) : super(key: key);

  @override
  State<OPASSubmissionsScreen> createState() => _OPASSubmissionsScreenState();
}

class _OPASSubmissionsScreenState extends State<OPASSubmissionsScreen> {
  late TextEditingController _searchController;

  // Filter & Sort State
  String _selectedStatus = 'ALL'; // ALL, PENDING, ACCEPTED, DELIVERED, REJECTED
  String _sortBy = 'date'; // date, seller, quantity
  bool _sortAscending = false; // Newest first
  DateTimeRange? _dateRange;

  // Data State
  List<OPASSubmissionModel> _submissions = [];
  List<OPASSubmissionModel> _filteredSubmissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all OPAS submissions from API
  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AdminService.getOPASSubmissions();
      setState(() {
        // Handle paginated response with 'results' key
        final List<dynamic> results = response['results'] is List
            ? response['results'] as List<dynamic>
            : [];
        
        _submissions = results
            .map((item) =>
                OPASSubmissionModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load submissions: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    _filteredSubmissions = _submissions.where((submission) {
      // Status filter
      if (_selectedStatus != 'ALL') {
        if (submission.status.toUpperCase() != _selectedStatus) {
          return false;
        }
      }

      // Date range filter
      if (_dateRange != null) {
        if (submission.submittedAt.isBefore(_dateRange!.start) ||
            submission.submittedAt.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return submission.sellerName.toLowerCase().contains(query) ||
            submission.productName.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredSubmissions.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.submittedAt.compareTo(b.submittedAt);
          break;
        case 'seller':
          comparison = a.sellerName.compareTo(b.sellerName);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  /// Show submission review dialog
  void _showReviewDialog(OPASSubmissionModel submission) {
    showDialog(
      context: context,
      builder: (dialogContext) => OPASSubmissionReviewDialog(
        submission: submission,
        onDecision: (approved, quantityAccepted, finalPrice, deliveryTerms,
            notes) {
          _loadSubmissions();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approved
                  ? 'Submission approved & PO generated'
                  : 'Submission rejected'),
              backgroundColor: approved ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }

  /// Show approved order details dialog
  void _showApprovedDetailsDialog(OPASSubmissionModel submission) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with green accent
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00B464),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      submission.purchaseOrderId ?? 'OPAS-2025',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller Section
                    _buildSectionTitle('Seller Information'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Name', submission.sellerName),
                    _buildDetailRow('Farm Address', submission.sellerAddress ?? 'Not provided'),
                    const SizedBox(height: 20),
                    // Product Section
                    _buildSectionTitle('Product Details'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Product', submission.productName),
                    const SizedBox(height: 20),
                    // Quantity & Pricing Section
                    _buildSectionTitle('Pricing & Quantities'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailRow('Offered Qty', '${submission.quantity.toStringAsFixed(1)} ${submission.unit}'),
                        ),
                        Expanded(
                          child: _buildDetailRow('Offered Price', '₱${submission.offeredPrice.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                    if (submission.finalPrice != null)
                      _buildDetailRow('Final Price', '₱${submission.finalPrice!.toStringAsFixed(2)}/${submission.unit}'),
                    if (submission.quantityAccepted != null)
                      _buildDetailRow('Accepted Qty', '${submission.quantityAccepted!.toStringAsFixed(1)} ${submission.unit}'),
                    const SizedBox(height: 20),
                    // Terms & Dates
                    _buildSectionTitle('Terms & Timeline'),
                    const SizedBox(height: 12),
                    if (submission.deliveryTerms != null && submission.deliveryTerms!.isNotEmpty)
                      _buildDetailRow('Delivery Terms', submission.deliveryTerms!),
                    _buildDetailRow('Submitted', DateFormat('MMM dd, yyyy').format(submission.submittedAt)),
                    if (submission.approvedAt != null)
                      _buildDetailRow('Approved', DateFormat('MMM dd, yyyy').format(submission.approvedAt!)),
                  ],
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Delivered Button - Only show for APPROVED submissions
                    if (submission.status.toUpperCase() == 'APPROVED' || submission.status.toUpperCase() == 'DELIVERED')
                      ElevatedButton.icon(
                        onPressed: submission.status.toUpperCase() == 'DELIVERED'
                            ? null
                            : () => _showDeliveryProofDialog(submission, dialogContext),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: submission.status.toUpperCase() == 'DELIVERED' ? Colors.grey : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: Text(
                          submission.status.toUpperCase() == 'DELIVERED' ? 'Delivery Confirmed' : 'Mark as Delivered',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (submission.status.toUpperCase() == 'APPROVED' || submission.status.toUpperCase() == 'DELIVERED')
                      const SizedBox(height: 12),
                    if (submission.status.toUpperCase() != 'APPROVED' && submission.status.toUpperCase() != 'DELIVERED')
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'This submission must be approved before marking as delivered',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    if (submission.status.toUpperCase() != 'APPROVED' && submission.status.toUpperCase() != 'DELIVERED')
                      const SizedBox(height: 12),
                    // Close Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B464),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Helper to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Show delivery proof dialog - allows uploading up to 3 images
  void _showDeliveryProofDialog(OPASSubmissionModel submission, BuildContext parentContext) {
    List<File> deliveryImages = [];
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Delivery Proof',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload up to 3 images as proof of delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image count indicator
                      Text(
                        'Images: ${deliveryImages.length}/3',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (deliveryImages.length < 3)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _pickDeliveryImage(deliveryImages, setState),
                            icon: const Icon(Icons.add_photo_alternate, size: 18),
                            label: const Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Image preview grid
                      if (deliveryImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: deliveryImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? Image.memory(
                                          deliveryImages[index].readAsBytesSync(),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          deliveryImages[index],
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        deliveryImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      if (deliveryImages.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No images selected',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Confirm button
                      ElevatedButton(
                        onPressed: deliveryImages.isEmpty
                            ? null
                            : () => _confirmDelivery(submission, deliveryImages, dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cancel button
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pick image for delivery proof
  Future<void> _pickDeliveryImage(List<File> images, Function setState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          images.add(File(image.path));
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  /// Confirm delivery and upload proof images
  Future<void> _confirmDelivery(
    OPASSubmissionModel submission,
    List<File> images,
    BuildContext dialogContext,
  ) async {
    // Show loading dialog
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Uploading delivery proof...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Call API to mark as delivered with images
      // Backend will resolve submission ID to purchase order ID
      await AdminService.markOPASDelivered(
        submission.id.toString(),
        images,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(dialogContext).pop();
      // Close proof dialog
      Navigator.of(dialogContext).pop();
      // Close order details dialog
      Navigator.of(dialogContext).pop();

      // Refresh submissions
      _loadSubmissions();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery confirmed with proof images'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(dialogContext).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count submissions by status
    final pendingCount =
        _submissions.where((s) => s.status.toUpperCase() == 'PENDING').length;
    final approvedCount =
        _submissions.where((s) => s.status.toUpperCase() == 'ACCEPTED').length;
    final deliveredCount =
        _submissions.where((s) => s.status.toUpperCase() == 'DELIVERED').length;
    final rejectedCount =
        _submissions.where((s) => s.status.toUpperCase() == 'REJECTED').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'OPAS Submissions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadSubmissions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubmissions,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ===== STATS SECTION =====
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1,
                              children: [
                                _buildStatCard(
                                  label: 'Pending',
                                  count: pendingCount,
                                  color: Colors.orange,
                                  icon: Icons.schedule,
                                ),
                                _buildStatCard(
                                  label: 'Approved',
                                  count: approvedCount,
                                  color: Colors.green,
                                  icon: Icons.check_circle,
                                ),
                                _buildStatCard(
                                  label: 'Successful',
                                  count: deliveredCount,
                                  color: Colors.blue,
                                  icon: Icons.done_all,
                                ),
                                _buildStatCard(
                                  label: 'Rejected',
                                  count: rejectedCount,
                                  color: Colors.red,
                                  icon: Icons.cancel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, thickness: 1),

                      // ===== SEARCH & FILTERS =====
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Submissions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Search bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search seller or product...',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00B464),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) {
                                setState(() => _applyFiltersAndSort());
                              },
                            ),
                            const SizedBox(height: 12),

                            // Status filter chips
                            Wrap(
                              spacing: 8,
                              children: ['ALL', 'PENDING', 'ACCEPTED', 'DELIVERED', 'REJECTED']
                                  .map((status) {
                                final isSelected = _selectedStatus == status;
                                return FilterChip(
                                  label: Text(
                                    status == 'PENDING'
                                        ? 'Pending ($pendingCount)'
                                        : status == 'ACCEPTED'
                                            ? 'Approved ($approvedCount)'
                                            : status == 'DELIVERED'
                                                ? 'Successful ($deliveredCount)'
                                                : status == 'REJECTED'
                                                    ? 'Rejected ($rejectedCount)'
                                                    : 'All',
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() => _selectedStatus = status);
                                    _applyFiltersAndSort();
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: const Color(0xFF00B464).withOpacity(0.2),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF00B464)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF00B464)
                                        : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),

                            // Sort dropdown
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _sortBy,
                                underline: Container(),
                                items: [
                                  ('date', 'Sort by: Newest First'),
                                  ('seller', 'Sort by: Seller A-Z'),
                                  ('quantity', 'Sort by: Highest Quantity'),
                                ]
                                    .map((item) => DropdownMenuItem(
                                          value: item.$1,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(item.$2),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _sortBy = value);
                                    _applyFiltersAndSort();
                                  }
                                },
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF00B464),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== SUBMISSIONS LIST =====
                      if (_filteredSubmissions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No submissions found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or check back later',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: List.generate(
                              _filteredSubmissions.length,
                              (index) {
                                final submission = _filteredSubmissions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildSubmissionCard(submission),
                                );
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(OPASSubmissionModel submission) {
    final statusColor = submission.status.toUpperCase() == 'PENDING'
        ? Colors.orange
        : submission.status.toUpperCase() == 'ACCEPTED'
            ? Colors.green
            : submission.status.toUpperCase() == 'DELIVERED'
                ? Colors.blue
                : Colors.red;

    final statusLabel = submission.status.toUpperCase() == 'PENDING'
        ? 'Pending Review'
        : submission.status.toUpperCase() == 'ACCEPTED'
            ? 'Approved'
            : submission.status.toUpperCase() == 'DELIVERED'
                ? 'Successful'
                : 'Rejected';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'From: ${submission.sellerName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${submission.quantity} kg',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offered Price',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${submission.offeredPrice}/unit',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submitted',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(submission.submittedAt),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quality',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            submission.qualityGrade,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          if (submission.status.toUpperCase() == 'PENDING')
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showReviewDialog(submission),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text(
                        'Review',
                        style: TextStyle(
                          color: Color(0xFF00B464),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // Quick reject
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Submission rejected'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        _loadSubmissions();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: submission.status.toUpperCase() == 'ACCEPTED'
                  ? TextButton.icon(
                      onPressed: () => _showApprovedDetailsDialog(submission),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('View Order Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF00B464),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                        shape: const RoundedRectangleBorder(),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        '✗ Rejected',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
