import 'package:flutter/material.dart';

/// Document Viewer Widget
/// Displays document information with preview/download capabilities
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Clear document display with metadata
/// - Resource Management: Efficient lazy loading with URL-based viewing
class DocumentViewerWidget extends StatelessWidget {
  final String documentType;
  final String fileUrl;
  final String status;
  final String uploadedAt;
  final String? verificationNotes;
  final String? verifiedBy;
  final VoidCallback? onPreview;
  final VoidCallback? onDownload;

  const DocumentViewerWidget({
    super.key,
    required this.documentType,
    required this.fileUrl,
    required this.status,
    required this.uploadedAt,
    this.verificationNotes,
    this.verifiedBy,
    this.onPreview,
    this.onDownload,
  });

  /// Get document type display name
  String _getDocumentTypeDisplay() {
    switch (documentType) {
      case 'BUSINESS_PERMIT':
        return 'Business Permit';
      case 'VALID_GOVERNMENT_ID':
        return 'Valid Government ID';
      default:
        return 'Document';
    }
  }

  /// Get status color
  Color _getStatusColor() {
    switch (status) {
      case 'VERIFIED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// Get status icon
  IconData _getStatusIcon() {
    switch (status) {
      case 'VERIFIED':
        return Icons.verified;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  /// Get status display text
  String _getStatusDisplay() {
    switch (status) {
      case 'VERIFIED':
        return 'Verified';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending Review';
    }
  }

  /// Get file type icon
  IconData _getFileTypeIcon() {
    if (fileUrl.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg') ||
        fileUrl.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.file_present;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document header with type and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileTypeIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDocumentTypeDisplay(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Uploaded: $uploadedAt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 14,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusDisplay(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Verification details (if available)
            if (verificationNotes != null || verifiedBy != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (verifiedBy != null) ...[
                      Text(
                        'Verified by: $verifiedBy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (verificationNotes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Notes: $verificationNotes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onPreview != null)
                  TextButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                  ),
                if (onDownload != null)
                  TextButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
