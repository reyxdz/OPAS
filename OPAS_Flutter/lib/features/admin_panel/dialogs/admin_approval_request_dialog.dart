/// Admin Approval Request Dialog
///
/// Displays high-risk action approval request for admin decision making.
/// Shows action details, risk assessment, and approval form.
///
/// Features:
/// - Action details display (risk level, impact, reason)
/// - Approval workflow information (progress, SLA, required approvals)
/// - Decision form (approve, reject, request changes, escalate)
/// - Comments/notes input
/// - Action consequences display
/// - Before/after state comparison
/// - SLA status indicator
/// - Workflow progress visualization

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/services/logger_service.dart';
import 'package:opas_flutter/features/admin_panel/services/admin_approval_workflow_service.dart';

class AdminApprovalRequestDialog extends StatefulWidget {
  final String approvalId;
  final String actionDescription;
  final String riskLevel;
  final String workflowType;
  final Map<String, dynamic> actionDetails;
  final String estimatedImpact;
  final int requiredApprovalsCount;
  final int currentApprovalsCount;
  final DateTime slaDeadline;
  final VoidCallback? onApprovalComplete;

  const AdminApprovalRequestDialog({
    Key? key,
    required this.approvalId,
    required this.actionDescription,
    required this.riskLevel,
    required this.workflowType,
    required this.actionDetails,
    required this.estimatedImpact,
    required this.requiredApprovalsCount,
    required this.currentApprovalsCount,
    required this.slaDeadline,
    this.onApprovalComplete,
  }) : super(key: key);

  @override
  State<AdminApprovalRequestDialog> createState() =>
      _AdminApprovalRequestDialogState();
}

class _AdminApprovalRequestDialogState
    extends State<AdminApprovalRequestDialog> {
  late TextEditingController _commentsController;
  late TextEditingController _changesController;
  late TextEditingController _escalationReasonController;

  String? _selectedDecision;
  String? _escalateToLevel;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
    _changesController = TextEditingController();
    _escalationReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _changesController.dispose();
    _escalationReasonController.dispose();
    super.dispose();
  }

  // ============================================================================
  // Approval Decision Handling
  // ============================================================================

  Future<void> _submitDecision(String decision) async {
    if (!mounted) return;

    // Validate inputs
    if (_commentsController.text.isEmpty && decision == 'APPROVE') {
      _showSnackBar('Please add approval comments', Colors.orange);
      return;
    }

    if (_changesController.text.isEmpty && decision == 'REQUEST_CHANGES') {
      _showSnackBar('Please specify required changes', Colors.orange);
      return;
    }

    if (_escalationReasonController.text.isEmpty && decision == 'ESCALATE') {
      _showSnackBar('Please provide escalation reason', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      const adminId = 'admin_001'; // In production, get from UserService
      String? changesText;
      String? escalationReason;
      String? escalateTo;

      if (decision == 'REQUEST_CHANGES') {
        changesText = _changesController.text;
      } else if (decision == 'ESCALATE') {
        escalationReason = _escalationReasonController.text;
        escalateTo = _escalateToLevel ?? 'SENIOR_ADMIN';
      }

      // Submit decision to workflow service
      await AdminApprovalWorkflowService.submitApprovalDecision(
        approvalId: widget.approvalId,
        approverId: adminId,
        decision: decision,
        comments: _commentsController.text.isEmpty
            ? null
            : _commentsController.text,
        requiredChanges: changesText,
        escalationReason: escalationReason,
        escalateToLevel: escalateTo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Decision recorded: $decision'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Notify parent of completion
        widget.onApprovalComplete?.call();

        // Close dialog
        Navigator.pop(context);
      }

      LoggerService.info(
        'Approval decision submitted: $decision',
        tag: 'APPROVAL_DIALOG',
        metadata: {
          'approvalId': widget.approvalId,
          'decision': decision,
          'adminId': adminId,
        },
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error submitting decision: $e', Colors.red);
      }

      LoggerService.error(
        'Error submitting approval decision',
        tag: 'APPROVAL_DIALOG',
        error: e,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ============================================================================
  // UI Helpers
  // ============================================================================

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  Color _getRiskColor() {
    switch (widget.riskLevel) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTimeRemaining() {
    final remaining = widget.slaDeadline.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'OVERDUE';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return '${hours}h ${minutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Approval Request',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Risk Level Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRiskColor().withOpacity(0.1),
                  border: Border.all(color: _getRiskColor()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getRiskColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Risk Level: ${widget.riskLevel}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Approval ID and SLA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval ID: ${widget.approvalId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workflow Type: ${widget.workflowType}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _getTimeRemaining(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.slaDeadline.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Description
              Text(
                'Action Description',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.actionDescription),
              ),
              const SizedBox(height: 16),

              // Estimated Impact
              Text(
                'Estimated Impact',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.estimatedImpact),
              ),
              const SizedBox(height: 16),

              // Approval Progress
              Text(
                'Approval Progress',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: widget.requiredApprovalsCount > 0
                          ? widget.currentApprovalsCount /
                              widget.requiredApprovalsCount
                          : 0,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.currentApprovalsCount}/${widget.requiredApprovalsCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Details
              if (widget.actionDetails.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Action Details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.actionDetails.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Decision Section
              Text(
                'Your Decision',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              // Decision Radio Buttons
              Column(
                children: [
                  RadioListTile(
                    title: const Text('Approve'),
                    value: 'APPROVE',
                    groupValue: _selectedDecision,
                    onChanged: (value) =>
                        setState(() => _selectedDecision = value),
                  ),
                  RadioListTile(
                    title: const Text('Reject'),
                    value: 'REJECT',
                    groupValue: _selectedDecision,
                    onChanged: (value) =>
                        setState(() => _selectedDecision = value),
                  ),
                  RadioListTile(
                    title: const Text('Request Changes'),
                    value: 'REQUEST_CHANGES',
                    groupValue: _selectedDecision,
                    onChanged: (value) =>
                        setState(() => _selectedDecision = value),
                  ),
                  RadioListTile(
                    title: const Text('Escalate'),
                    value: 'ESCALATE',
                    groupValue: _selectedDecision,
                    onChanged: (value) =>
                        setState(() => _selectedDecision = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Comments Section
              if (_selectedDecision == 'APPROVE' ||
                  _selectedDecision == 'REJECT')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add comments...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Required Changes Section
              if (_selectedDecision == 'REQUEST_CHANGES')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Changes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _changesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Specify required changes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Escalation Section
              if (_selectedDecision == 'ESCALATE')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escalation Reason',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _escalationReasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Why are you escalating this request?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Escalate to Level'),
                      value: _escalateToLevel,
                      onChanged: (value) =>
                          setState(() => _escalateToLevel = value),
                      items: const [
                        DropdownMenuItem(
                          value: 'SENIOR_ADMIN',
                          child: Text('Senior Admin'),
                        ),
                        DropdownMenuItem(
                          value: 'MANAGER',
                          child: Text('Manager'),
                        ),
                        DropdownMenuItem(
                          value: 'EXECUTIVE',
                          child: Text('Executive'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing || _selectedDecision == null
                        ? null
                        : () => _submitDecision(_selectedDecision!),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Submit Decision'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
