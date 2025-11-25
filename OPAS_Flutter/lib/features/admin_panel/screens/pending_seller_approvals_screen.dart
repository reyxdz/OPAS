import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/utils/admin_permissions.dart';

class PendingSellerApprovalsScreen extends StatefulWidget {
  const PendingSellerApprovalsScreen({super.key});

  @override
  State<PendingSellerApprovalsScreen> createState() =>
      _PendingSellerApprovalsScreenState();
}

class _PendingSellerApprovalsScreenState
    extends State<PendingSellerApprovalsScreen> {
  late Future<List<Map<String, dynamic>>> _pendingApplicationsFuture;
  List<Map<String, dynamic>> _pendingApprovals = [];

  @override
  void initState() {
    super.initState();
    _loadPendingApplications();
  }

  Future<void> _loadPendingApplications() async {
    _pendingApplicationsFuture = _fetchPendingApplications();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingApplications() async {
    try {
      final approvals = await AdminService.getPendingSellerApprovals();
      print('DEBUG: Received ${approvals.length} approvals from API');
      print('DEBUG: Approvals type: ${approvals.runtimeType}');
      if (approvals.isNotEmpty) {
        print('DEBUG: First approval: ${approvals.first}');
      }
      
      _pendingApprovals = List<Map<String, dynamic>>.from(
        approvals.map((item) {
          print('DEBUG: Processing item: $item');
          return _parseApplication(item as Map<String, dynamic>);
        }),
      );
      print('DEBUG: Parsed ${_pendingApprovals.length} applications');
      return _pendingApprovals;
    } catch (e) {
      print('ERROR loading pending applications: $e');
      if (kDebugMode) {
        print('Error loading pending applications: $e');
      }
      return [];
    }
  }

  Map<String, dynamic> _parseApplication(Map<String, dynamic> item) {
    // API returns flat structure with seller_email and seller_full_name directly
    final submittedAt = item['submitted_at'] as String? ?? '';
    final sellerFullName = item['seller_full_name'] as String? ?? '';
    final sellerEmail = item['seller_email'] as String? ?? '';
    
    // Use seller_full_name if available, otherwise extract from email
    String displayName = sellerFullName.isNotEmpty 
        ? sellerFullName 
        : sellerEmail.split('@').first;
    
    return {
      'id': item['id'],
      'name': displayName.isNotEmpty ? displayName : 'Unknown',
      'farmName': item['farm_name'] ?? '',
      'farmLocation': item['farm_location'] ?? '',
      'storeName': item['store_name'] ?? '',
      'storeDescription': item['store_description'] ?? '',
      'appliedDate': _formatDate(submittedAt),
      'phoneNumber': item['phone_number'] ?? '',  // May not exist in API
      'email': sellerEmail,
      'status': item['status'] ?? 'PENDING',
      'rejectionReason': item['rejection_reason'] ?? '',
      'productsGrown': item['products_grown'] ?? '',
    };
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pending Seller Approvals'),
        centerTitle: true,
      ),
      body: FutureBuilder<bool>(
        future: AdminPermissions.canApproveSellers(),
        builder: (context, permissionSnapshot) {
          // Check if user has permission
          if (permissionSnapshot.hasData && !permissionSnapshot.data!) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have permission to view pending seller approvals.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Show loading while checking permissions
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // User has permission, show pending applications
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _pendingApplicationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading applications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadPendingApplications();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final applications = snapshot.data ?? [];

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All applications approved!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadPendingApplications();
                      });
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final approval = applications[index];
              return _buildApprovalCard(context, approval, index);
            },
          );
            }
          );
        }
      ),
    );
  }

  Widget _buildApprovalCard(
      BuildContext context, Map<String, dynamic> approval, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF00B464),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approval['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approval['farmName'] as String,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applied: ${approval['appliedDate']}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoSection('Farm Information', [
                    _buildInfoRow(
                      'Farm Name',
                      approval['farmName'] as String,
                      Icons.landscape,
                    ),
                    _buildInfoRow(
                      'Location',
                      approval['farmLocation'] as String,
                      Icons.location_on,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Store Information', [
                    _buildInfoRow(
                      'Store Name',
                      approval['storeName'] as String,
                      Icons.store,
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Description',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            approval['storeDescription'] as String,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Contact Information', [
                    _buildInfoRow(
                      'Email',
                      approval['email'] as String,
                      Icons.email,
                    ),
                    _buildInfoRow(
                      'Phone',
                      approval['phoneNumber'] as String,
                      Icons.phone,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _handleApprove(context, approval, index),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _handleReject(context, approval, index),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B464), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
      BuildContext context, Map<String, dynamic> approval, int index) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text(
            'Are you sure you want to approve ${approval['name']} as a seller?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                await AdminService.approveSeller(approval['id'].toString());
                if (!mounted) return;
                setState(() => _pendingApprovals.removeAt(index));

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${approval['name']} has been approved as a seller!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (kDebugMode) {
                  print('Error approving application: $e');
                }
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error approving application: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(
      BuildContext context, Map<String, dynamic> approval, int index) async {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Are you sure you want to reject ${approval['name']}\'s application?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                await AdminService.rejectSeller(
                  approval['id'].toString(),
                  reason: reasonController.text.isEmpty ? '' : reasonController.text,
                );
                if (!mounted) return;
                reasonController.dispose();
                setState(() => _pendingApprovals.removeAt(index));

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${approval['name']} application rejected.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                reasonController.dispose();
                if (kDebugMode) {
                  print('Error rejecting application: $e');
                }
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error rejecting application: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
