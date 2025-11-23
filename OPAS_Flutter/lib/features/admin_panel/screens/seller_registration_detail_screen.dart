import 'package:flutter/material.dart';
import '../models/admin_registration_list_model.dart';
import '../services/seller_registration_admin_service.dart';
import '../widgets/registration_status_badge.dart';
import '../widgets/document_viewer_widget.dart';
import '../dialogs/action_dialogs.dart';

/// Seller Registration Detail Screen
/// Admin interface for viewing detailed seller registration information
/// and managing approval/rejection decisions
/// 
/// Features:
/// - Display complete registration information
/// - Show all uploaded documents with verification status
/// - Approval history
/// - Action buttons (Approve, Reject, Request Info)
/// - Loading and error states
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Clear information hierarchy, action buttons
/// - Resource Management: Single API call for all details, efficient display
/// - Security & Authorization: Admin-only operations
class SellerRegistrationDetailScreen extends StatefulWidget {
  final int registrationId;
  final VoidCallback? onRegistrationUpdated;

  const SellerRegistrationDetailScreen({
    super.key,
    required this.registrationId,
    this.onRegistrationUpdated,
  });

  @override
  State<SellerRegistrationDetailScreen> createState() =>
      _SellerRegistrationDetailScreenState();
}

class _SellerRegistrationDetailScreenState
    extends State<SellerRegistrationDetailScreen> {
  AdminRegistrationDetail? _registration;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRegistrationDetails();
  }

  Future<void> _loadRegistrationDetails() async {
    try {
      final registration =
          await SellerRegistrationAdminService.getRegistrationDetails(
        widget.registrationId,
      );

      setState(() {
        _registration = registration;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove() async {
    final state = showDialog<bool>(
      context: context,
      builder: (context) => ApprovalFormWidget(
        buyerName: _registration?.buyerName,
        isLoading: _isProcessing,
        onApprove: () {
          // Get notes from widget context if needed
          Navigator.pop(context, true);
        },
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    final shouldApprove = await state;
    if (shouldApprove == true) {
      setState(() => _isProcessing = true);

      try {
        final updated =
            await SellerRegistrationAdminService.approveRegistration(
          widget.registrationId,
          adminNotes: '', // Could be passed from dialog
        );

        setState(() {
          _registration = updated;
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onRegistrationUpdated?.call();
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => RejectionFormWidget(
        buyerName: _registration?.buyerName,
        isLoading: _isProcessing,
        onReject: () {
          Navigator.pop(context, {'reason': '', 'notes': ''});
        },
        onCancel: () => Navigator.pop(context),
      ),
    );

    if (result != null) {
      setState(() => _isProcessing = true);

      try {
        final updated =
            await SellerRegistrationAdminService.rejectRegistration(
          widget.registrationId,
          rejectionReason: result['reason'] ?? '',
          adminNotes: result['notes'],
        );

        setState(() {
          _registration = updated;
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration rejected'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onRegistrationUpdated?.call();
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRequestInfo() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => InfoRequestFormWidget(
        buyerName: _registration?.buyerName,
        isLoading: _isProcessing,
        onRequest: () {
          Navigator.pop(context, {'info': '', 'days': 7, 'notes': ''});
        },
        onCancel: () => Navigator.pop(context),
      ),
    );

    if (result != null) {
      setState(() => _isProcessing = true);

      try {
        final updated =
            await SellerRegistrationAdminService.requestMoreInfo(
          widget.registrationId,
          requiredInfo: result['info'] ?? '',
          deadlineInDays: result['days'] ?? 7,
          adminNotes: result['notes'],
        );

        setState(() {
          _registration = updated;
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Information request sent'),
              backgroundColor: Colors.blue,
            ),
          );
          widget.onRegistrationUpdated?.call();
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBuyerInfo() {
    if (_registration == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buyer Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', _registration!.buyerName),
            _buildInfoRow('Email', _registration!.buyerEmail),
            _buildInfoRow('Phone', _registration!.buyerPhone),
            _buildInfoRow('Status', _registration!.status),
            _buildInfoRow('Days Pending', '${_registration!.daysPending} days'),
            _buildInfoRow(
              'Submitted',
              _registration!.submittedAt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmInfo() {
    if (_registration == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Farm Name', _registration!.farmName),
            _buildInfoRow('Location', _registration!.farmLocation),
            _buildInfoRow('Size', _registration!.farmSize),
            _buildInfoRow(
              'Products',
              _registration!.productsGrown.join(', '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    if (_registration == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Store Name', _registration!.storeName),
            _buildInfoRow(
              'Description',
              _registration!.storeDescription,
              multiline: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    if (_registration == null || _registration!.documents.isEmpty) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents & Verification',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ..._registration!.documents.map((doc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DocumentViewerWidget(
                  documentType: doc.documentType,
                  fileUrl: doc.fileUrl,
                  status: doc.status,
                  uploadedAt: doc.uploadedAt,
                  verificationNotes: doc.verificationNotes,
                  verifiedBy: doc.verifiedBy,
                  onPreview: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document preview not yet implemented'),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalHistory() {
    if (_registration == null ||
        _registration!.approvalHistory == null ||
        _registration!.approvalHistory!.isEmpty) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approval History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ..._registration!.approvalHistory!.map((history) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            history.getDecisionDisplay(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _getDecisionColor(history.decision),
                            ),
                          ),
                          Text(
                            history.createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${history.adminName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (history.adminNotes != null &&
                          history.adminNotes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          history.adminNotes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getDecisionColor(String decision) {
    switch (decision) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'REQUEST_MORE_INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: multiline ? null : 1,
              overflow: multiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_registration == null ||
        _registration!.status == 'APPROVED' ||
        _registration!.status == 'REJECTED') {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Approve'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleRequestInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Request Info'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Details'),
        elevation: 0,
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
                        _errorMessage ?? 'An error occurred',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRegistrationDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status header
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey.shade50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Status',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                if (_registration != null)
                                  RegistrationStatusBadge(
                                    status: _registration!.status,
                                  ),
                              ],
                            ),
                          ),

                          // Information sections
                          _buildBuyerInfo(),
                          _buildFarmInfo(),
                          _buildStoreInfo(),
                          _buildDocumentsSection(),
                          _buildApprovalHistory(),
                        ],
                      ),
                    ),

                    // Action buttons at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildActionButtons(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
