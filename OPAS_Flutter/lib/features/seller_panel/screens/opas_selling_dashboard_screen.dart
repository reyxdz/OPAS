import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/seller_service.dart';
import 'opas_submission_edit_screen.dart';

class OPASSellingDashboardScreen extends StatefulWidget {
  const OPASSellingDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OPASSellingDashboardScreen> createState() =>
      _OPASSellingDashboardScreenState();
}

class _OPASSellingDashboardScreenState extends State<OPASSellingDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _submissionsFuture;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadSubmissions() {
    _submissionsFuture = SellerService.getSellToOPASRequests()
        .then((data) {
          final submissions = (data is List)
              ? data
                  .cast<Map<String, dynamic>>()
                  .map((item) => {
                'id': item['id'] ?? 0,
                'submission_number': item['submission_number'] ?? '',
                'product_name': item['product_name'] ?? 'Unknown Product',
                'quantity_offered': item['quantity_offered'] ?? 0,
                'unit': item['unit'] ?? 'kg',
                'offered_price': item['offered_price'] ?? '0.00',
                'quality_grade': item['quality_grade'] ?? 'STANDARD',
                'status': item['status'] ?? 'PENDING',
                'created_at': item['created_at'] ?? '',
                'status_display': item['status_display'] ?? 'Pending',
                'product': item['product'] ?? 0,
              })
                  .toList()
              : <Map<String, dynamic>>[];
          return submissions;
        })
        .catchError((error) {
          _showErrorSnackbar('Failed to load submissions: $error');
          return <Map<String, dynamic>>[];
        });
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _editSubmission(Map<String, dynamic> submission) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OPASSubmissionEditScreen(
          submission: submission,
        ),
      ),
    );

    if (result == true && mounted) {
      // Reload submissions after edit
      setState(() => _loadSubmissions());
      _showSuccessSnackbar('Submission updated successfully');
    }
  }

  Future<void> _withdrawSubmission(Map<String, dynamic> submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Submission'),
        content: Text(
          'Are you sure you want to withdraw "${submission['product_name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _performWithdrawal(submission);
    }
  }

  Future<void> _performWithdrawal(Map<String, dynamic> submission) async {
    try {
      final submissionId = submission['id'] as int;
      
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Call the cancel API endpoint to delete the submission
      await SellerService.cancelOPASOffer(submissionId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Reload submissions
      setState(() => _loadSubmissions());
      _showSuccessSnackbar('Submission withdrawn successfully');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackbar('Failed to withdraw submission: $e');
    }
  }

  Future<void> _viewReceipt(Map<String, dynamic> submission) async {
    final submissionId = submission['id'] as int;
    
    try {
      // Fetch receipt/PO details
      final details = await SellerService.getOPASRequestDetails(submissionId);
      
      if (!mounted) return;
      
      // Show receipt dialog
      showDialog(
        context: context,
        builder: (context) => _buildReceiptDialog(details),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to load receipt: $e');
    }
  }

  Widget _buildReceiptDialog(Map<String, dynamic> submission) {
    return AlertDialog(
      title: const Text('Purchase Order Receipt'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReceiptRow('Submission ID', submission['submission_number'] ?? 'N/A'),
            _buildReceiptRow('Status', submission['status'] ?? 'N/A'),
            _buildReceiptRow('Product', submission['product_name'] ?? 'N/A'),
            _buildReceiptRow('Quantity Offered', '${submission['quantity_offered'] ?? 0} ${submission['unit'] ?? 'kg'}'),
            _buildReceiptRow('Offered Price', '₱${submission['offered_price'] ?? '0.00'} per ${submission['unit'] ?? 'kg'}'),
            if (submission['final_price'] != null)
              _buildReceiptRow('Final Price', '₱${submission['final_price']} per ${submission['unit'] ?? 'kg'}'),
            if (submission['quantity_accepted'] != null)
              _buildReceiptRow('Quantity Accepted', '${submission['quantity_accepted']} ${submission['unit'] ?? 'kg'}'),
            _buildReceiptRow('Created', _formatDate(submission['created_at'] ?? '')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _filterSubmissions(
      List<Map<String, dynamic>> submissions) {
    if (_selectedFilter == 'ALL') return submissions;
    return submissions
        .where((s) => s['status'].toString().toUpperCase() == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Stats Section
          _buildStatsSection(),
          const SizedBox(height: 16),
          // Filter Buttons
          _buildFilterButtons(),
          const SizedBox(height: 16),
          // All Submissions List
          Expanded(
            child: _buildAllSubmissionsList(),
          ),
          // Bottom padding to prevent content from being hidden by bottom nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _submissionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        final submissions = snapshot.data ?? [];
        final pending =
            submissions.where((s) => s['status'] == 'PENDING').length;
        final approved = submissions
            .where((s) =>
                s['status'] == 'APPROVED' || s['status'] == 'ACCEPTED')
            .length;
        final total = submissions.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Pending',
                  value: pending.toString(),
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Approved',
                  value: approved.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Total',
                  value: total.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = [
      {'label': 'All', 'value': 'ALL', 'icon': Icons.apps},
      {'label': 'Pending', 'value': 'PENDING', 'icon': Icons.schedule},
      {'label': 'Approved', 'value': 'APPROVED', 'icon': Icons.check_circle},
      {'label': 'Completed', 'value': 'COMPLETED', 'icon': Icons.task_alt},
      {'label': 'Rejected', 'value': 'REJECTED', 'icon': Icons.cancel},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['value'] as String;
                });
              },
              selected: isSelected,
              label: Text(filter['label'] as String),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.withOpacity(0.2),
              side: BorderSide(
                color: isSelected ? Colors.green : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.green : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllSubmissionsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _submissionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Error loading submissions: ${snapshot.error}'),
              ],
            ),
          );
        }

        final allSubmissions = snapshot.data ?? [];
        final filteredSubmissions = _selectedFilter == 'ALL'
            ? allSubmissions
            : allSubmissions
                .where((s) {
                  final status = s['status'].toString().toUpperCase();
                  // Map 'ACCEPTED' (from backend) to 'APPROVED' filter
                  if (_selectedFilter == 'APPROVED') {
                    return status == 'APPROVED' || status == 'ACCEPTED';
                  }
                  return status == _selectedFilter;
                })
                .toList();

        if (filteredSubmissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'ALL'
                      ? 'No submissions yet'
                      : 'No $_selectedFilter submissions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadSubmissions());
            await _submissionsFuture;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: filteredSubmissions.length,
            itemBuilder: (context, index) {
              return _buildSubmissionCard(filteredSubmissions[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final status = submission['status'].toString().toUpperCase();
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () {
        // Navigate to submission details
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission['product_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${submission['submission_number'] ?? 'N/A'}',
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.scale,
                      label: 'Quantity',
                      value:
                          '${submission['quantity_offered']} ${submission['unit']}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.local_offer,
                      label: 'Price',
                      value: '₱${submission['offered_price']}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.check_box,
                      label: 'Quality',
                      value: submission['quality_grade'] ?? 'Standard',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDate(submission['created_at'] ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Buttons
              if (status == 'PENDING')
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _editSubmission(submission),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _withdrawSubmission(submission),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Withdraw'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (status == 'APPROVED' || status == 'ACCEPTED')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewReceipt(submission),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('View Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}