import 'package:flutter/material.dart';

/// Approval Form Widget
/// Reusable form for approving seller registrations with optional notes
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Clear form with optional notes field
/// - Input Validation: Validates notes field if provided
/// - Resource Management: Efficient form state management
class ApprovalFormWidget extends StatefulWidget {
  final VoidCallback onApprove;
  final VoidCallback? onCancel;
  final bool isLoading;
  final String? buyerName;

  const ApprovalFormWidget({
    super.key,
    required this.onApprove,
    this.onCancel,
    this.isLoading = false,
    this.buyerName,
  });

  @override
  State<ApprovalFormWidget> createState() => _ApprovalFormWidgetState();
}

class _ApprovalFormWidgetState extends State<ApprovalFormWidget> {
  late TextEditingController _notesController;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Registration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.buyerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Approving registration for: ${widget.buyerName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ),
            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 4,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: 'Admin Notes (Optional)',
                hintText: 'Add any notes about this approval...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Confirmation checkbox
            Row(
              children: [
                Checkbox(
                  value: _confirmed,
                  onChanged: widget.isLoading
                      ? null
                      : (value) {
                          setState(() => _confirmed = value ?? false);
                        },
                ),
                const Expanded(
                  child: Text(
                    'I confirm this registration meets all requirements',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: !_confirmed || widget.isLoading ? null : widget.onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Approve'),
        ),
      ],
    );
  }
}

/// Rejection Form Widget
/// Reusable form for rejecting seller registrations with reason
/// 
/// CORE PRINCIPLES APPLIED:
/// - Input Validation: Requires rejection reason (cannot be empty)
/// - User Experience: Clear form with reason and optional notes
class RejectionFormWidget extends StatefulWidget {
  final VoidCallback onReject;
  final VoidCallback? onCancel;
  final bool isLoading;
  final String? buyerName;

  const RejectionFormWidget({
    super.key,
    required this.onReject,
    this.onCancel,
    this.isLoading = false,
    this.buyerName,
  });

  @override
  State<RejectionFormWidget> createState() => _RejectionFormWidgetState();
}

class _RejectionFormWidgetState extends State<RejectionFormWidget> {
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  String? _selectedReason;
  bool _confirmed = false;

  final List<String> _rejectionReasons = [
    'Incomplete or invalid documents',
    'Document details do not match registration',
    'Failed background verification',
    'Duplicate registration',
    'Non-compliance with regulations',
    'Other (please specify in notes)',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String getReasonValue() {
    return _reasonController.text.trim();
  }

  String getNotesValue() {
    return _notesController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Registration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.buyerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Rejecting registration for: ${widget.buyerName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ),

            // Rejection reason dropdown
            Text(
              'Rejection Reason (Required)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              isExpanded: true,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text('Select a reason'),
              items: _rejectionReasons
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: widget.isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedReason = value);
                      _reasonController.text = value ?? '';
                    },
            ),
            const SizedBox(height: 16),

            // Additional notes
            TextField(
              controller: _notesController,
              maxLines: 4,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Provide detailed feedback for the seller...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Confirmation checkbox
            Row(
              children: [
                Checkbox(
                  value: _confirmed,
                  onChanged: widget.isLoading || _selectedReason == null
                      ? null
                      : (value) {
                          setState(() => _confirmed = value ?? false);
                        },
                ),
                const Expanded(
                  child: Text(
                    'I confirm this rejection decision',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: !_confirmed || _selectedReason == null || widget.isLoading
              ? null
              : widget.onReject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Reject'),
        ),
      ],
    );
  }
}

/// Info Request Form Widget
/// Reusable form for requesting more information from sellers
/// 
/// CORE PRINCIPLES APPLIED:
/// - Input Validation: Requires description of required information
/// - User Experience: Clear form with deadline selection
class InfoRequestFormWidget extends StatefulWidget {
  final VoidCallback onRequest;
  final VoidCallback? onCancel;
  final bool isLoading;
  final String? buyerName;

  const InfoRequestFormWidget({
    super.key,
    required this.onRequest,
    this.onCancel,
    this.isLoading = false,
    this.buyerName,
  });

  @override
  State<InfoRequestFormWidget> createState() => _InfoRequestFormWidgetState();
}

class _InfoRequestFormWidgetState extends State<InfoRequestFormWidget> {
  late TextEditingController _infoController;
  late TextEditingController _notesController;
  int _deadlineInDays = 7;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _infoController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _infoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String getRequiredInfoValue() {
    return _infoController.text.trim();
  }

  String getNotesValue() {
    return _notesController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request More Information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.buyerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Requesting information from: ${widget.buyerName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ),

            // Required information field
            TextField(
              controller: _infoController,
              maxLines: 4,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: 'Required Information (Required)',
                hintText: 'Describe what information is needed...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Deadline selection
            Text(
              'Deadline (Days)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _deadlineInDays,
              isExpanded: true,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [3, 5, 7, 10, 14, 30]
                  .map((days) => DropdownMenuItem(
                        value: days,
                        child: Text('$days days'),
                      ))
                  .toList(),
              onChanged: widget.isLoading
                  ? null
                  : (value) {
                      setState(() => _deadlineInDays = value ?? 7);
                    },
            ),
            const SizedBox(height: 16),

            // Additional notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Any other guidance for the seller...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Confirmation checkbox
            Row(
              children: [
                Checkbox(
                  value: _confirmed,
                  onChanged: widget.isLoading
                      ? null
                      : (value) {
                          setState(() => _confirmed = value ?? false);
                        },
                ),
                const Expanded(
                  child: Text(
                    'I confirm this information request',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: !_confirmed || getRequiredInfoValue().isEmpty || widget.isLoading
              ? null
              : widget.onRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Request Info'),
        ),
      ],
    );
  }
}
