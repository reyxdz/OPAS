import 'package:flutter/material.dart';

/// Document Upload Widget
/// Handles upload of Business Permit and Government ID documents
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Clear document requirements and status
/// - Security: File type and size validation messages
/// - Resource Management: Efficient file selection
class DocumentUploadWidget extends StatefulWidget {
  final Function(String documentType) onDocumentUpload;
  final Map<String, bool> uploadedDocuments;
  final Map<String, String>? fieldErrors;

  const DocumentUploadWidget({
    super.key,
    required this.onDocumentUpload,
    required this.uploadedDocuments,
    this.fieldErrors,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  @override
  Widget build(BuildContext context) {
    final requiredDocs = [
      {
        'type': 'Business Permit',
        'id': 'BUSINESS_PERMIT',
        'description': 'Official business registration certificate',
      },
      {
        'type': 'Government ID',
        'id': 'VALID_GOVERNMENT_ID',
        'description': 'Valid government-issued identification',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Upload Documents',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Required documents must be verified before approval',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 24),

        // Document Upload Cards
        Column(
          children: requiredDocs.map((doc) {
            final isUploaded = widget.uploadedDocuments[doc['id']] ?? false;
            return _buildDocumentCard(
              context,
              documentType: doc['type']!,
              documentId: doc['id']!,
              description: doc['description']!,
              isUploaded: isUploaded,
            );
          }).toList(),
        ),

        // Documents error message if needed
        if (widget.fieldErrors?.containsKey('documents') ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.fieldErrors!['documents']!,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),
        // File Requirements Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Requirements',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildRequirement('Formats: PDF, JPG, PNG'),
              _buildRequirement('Max size: 5 MB per file'),
              _buildRequirement('Clear and legible documents'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a document upload card
  Widget _buildDocumentCard(
    BuildContext context, {
    required String documentType,
    required String documentId,
    required String description,
    required bool isUploaded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isUploaded ? const Color(0xFF00B464) : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isUploaded
            ? const Color(0xFF00B464).withOpacity(0.05)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFF00B464).withOpacity(0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle : Icons.document_scanner,
              color: isUploaded ? const Color(0xFF00B464) : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (isUploaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Uploaded ✓',
                      style: TextStyle(
                        color: const Color(0xFF00B464),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Upload Button
          ElevatedButton.icon(
            onPressed: () => widget.onDocumentUpload(documentId),
            icon: Icon(isUploaded ? Icons.edit : Icons.upload),
            label: Text(isUploaded ? 'Replace' : 'Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isUploaded ? Colors.orange : const Color(0xFF00B464),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// Build requirement text
  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
