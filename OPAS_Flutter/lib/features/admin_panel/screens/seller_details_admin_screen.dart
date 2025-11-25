// Seller details admin screen
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';

class SellerDetailsAdminScreen extends StatefulWidget {
  final Map<String, dynamic> seller;

  const SellerDetailsAdminScreen({
    Key? key,
    required this.seller,
  }) : super(key: key);

  @override
  State<SellerDetailsAdminScreen> createState() =>
      _SellerDetailsAdminScreenState();
}

class _SellerDetailsAdminScreenState extends State<SellerDetailsAdminScreen> {
  late Map<String, dynamic> _seller;
  List<dynamic> _approvalHistory = [];
  List<dynamic> _violations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _seller = widget.seller;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sellerId = _seller['id']?.toString() ?? '';
      
      // Load approval history and violations in parallel
      final results = await Future.wait([
        AdminService.getSellerApprovalHistory(sellerId),
        AdminService.getSellerViolations(sellerId),
      ]);

      if (!mounted) return;

      setState(() {
        _approvalHistory = (results[0] as List?) ?? [];
        _violations = (results[1] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor() {
    final status = _seller['seller_status'] ?? _seller['status'] ?? '';
    switch (status.toUpperCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Details'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with status
                  _buildHeaderSection(),
                  // Personal information
                  _buildPersonalInfoSection(),
                  // Store information
                  _buildStoreInfoSection(),
                  // Approval history
                  _buildApprovalHistorySection(),
                  // Violations
                  _buildViolationsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    final status = _seller['seller_status'] ?? _seller['status'] ?? 'UNKNOWN';
    final name = _seller['full_name'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      color: _getStatusColor().withOpacity(0.1),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: _getStatusColor().withOpacity(0.3),
            child: Icon(
              status == 'APPROVED' ? Icons.check_circle : Icons.person,
              size: 40,
              color: _getStatusColor(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Phone Number', _seller['phone_number'] ?? 'N/A'),
            _buildInfoRow('Address', _seller['address'] ?? 'N/A'),
            _buildInfoRow(
              'Registered',
              DateFormat('MMM dd, yyyy').format(
                DateTime.parse(
                  _seller['created_at'] ?? DateTime.now().toIso8601String(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Store Name', _seller['store_name'] ?? 'N/A'),
            _buildInfoRow(
              'Description',
              _seller['store_description'] ?? 'N/A',
              maxLines: 3,
            ),
            _buildInfoRow(
              'Documents Verified',
              (_seller['seller_documents_verified'] ?? false) ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalHistorySection() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _approvalHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No approval history',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _approvalHistory.length,
                    itemBuilder: (context, index) {
                      final record = _approvalHistory[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(record.toString()),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsSection() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Violations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _violations.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No violations',
                      style: TextStyle(color: Colors.green),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _violations.length,
                    itemBuilder: (context, index) {
                      final violation = _violations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(violation.toString()),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
