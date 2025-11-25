import 'package:flutter/material.dart';
import '../models/seller_registration_model.dart';
import '../models/registration_status_enum.dart';

/// Registration Status Widget
/// Displays the current status of seller registration application
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Clear status indication with color coding
/// - Resource Management: Efficient status message generation
class RegistrationStatusWidget extends StatelessWidget {
  final SellerRegistration? registration;
  final bool isLoading;
  final VoidCallback? onReapply;

  const RegistrationStatusWidget({
    super.key,
    this.registration,
    this.isLoading = false,
    this.onReapply,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (registration == null) {
      return _buildNoRegistration(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Card
        _buildStatusCard(context),
        const SizedBox(height: 24),

        // Status Details
        _buildStatusDetails(context),

        const SizedBox(height: 24),

        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  /// Build status card with color-coded indicator
  Widget _buildStatusCard(BuildContext context) {
    final statusColor = Color(registration!.status.getColorValue());
    final daysPending = registration!.getDaysPending();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(registration!.status),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      registration!.status.displayName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Message
          Text(
            registration!.status.getMessage(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          // Rejection Reason (if rejected)
          if (registration!.status.isRejected && registration!.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.red.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Rejection Reason',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      registration!.rejectionReason!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          if (registration!.status.isPending)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Submitted $daysPending day${daysPending != 1 ? 's' : ''} ago',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build status details section
  Widget _buildStatusDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Application Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Farm Information
        _buildDetailSection(
          context,
          title: 'Farm',
          icon: Icons.agriculture,
          items: [
            (label: 'Name', value: registration!.farmName),
            (label: 'Location', value: registration!.farmLocation),
          ],
        ),
        const SizedBox(height: 16),

        // Store Information
        _buildDetailSection(
          context,
          title: 'Store',
          icon: Icons.store,
          items: [
            (label: 'Name', value: registration!.storeName),
            (label: 'Description', value: registration!.storeDescription),
          ],
        ),
        const SizedBox(height: 16),

        // Document Status
        _buildDocumentStatus(context),
      ],
    );
  }

  /// Build detail section
  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<({String label, String value})> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00B464), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${item.label}:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.value,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Build document status section
  Widget _buildDocumentStatus(BuildContext context) {
    final verified = registration!.getVerifiedDocuments();
    final pending = registration!.getPendingDocuments();
    final rejected = registration!.getRejectedDocuments();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Color(0xFF00B464), size: 18),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (verified.isNotEmpty)
            _buildDocumentStatusItem(
              'Verified',
              verified.length.toString(),
              Colors.green,
              Icons.check_circle,
            ),
          if (pending.isNotEmpty)
            _buildDocumentStatusItem(
              'Pending Review',
              pending.length.toString(),
              Colors.orange,
              Icons.schedule,
            ),
          if (rejected.isNotEmpty)
            _buildDocumentStatusItem(
              'Rejected',
              rejected.length.toString(),
              Colors.red,
              Icons.error,
            ),
        ],
      ),
    );
  }

  /// Build document status item
  Widget _buildDocumentStatusItem(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    if (registration!.status.isApproved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Congratulations! You can now start selling on OPAS.'),
              ),
            );
          },
          icon: const Icon(Icons.celebration),
          label: const Text('Start Selling'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B464),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    if (registration!.status.isRejected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onReapply,
          icon: const Icon(Icons.refresh),
          label: const Text('Reapply'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B464),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF00B464),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading registration status...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build no registration state
  Widget _buildNoRegistration(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Registration Found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You have not submitted a seller registration application yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get status icon based on registration status
  IconData _getStatusIcon(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.pending:
        return Icons.schedule;
      case RegistrationStatus.approved:
        return Icons.check_circle;
      case RegistrationStatus.rejected:
        return Icons.cancel;
      case RegistrationStatus.requestMoreInfo:
        return Icons.help;
    }
  }
}
