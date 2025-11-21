/// Escalation Request Dialog and Management Screen for Phase 4.4
/// UI components for creating and managing escalations with SLA tracking
/// 
/// Architecture: Dialog for escalation creation, screen for management and tracking
/// Features: Priority selection, admin assignment, SLA countdown, escalation chain

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/services/logger_service.dart';
import 'package:opas_flutter/features/admin_panel/services/escalation_workflow_service.dart';

/// Dialog for creating escalation requests
class EscalationRequestDialog extends StatefulWidget {
  final String adminId;
  final String adminName;
  final EscalationType? defaultType;
  final String? entityType;
  final String? entityId;

  const EscalationRequestDialog({
    Key? key,
    required this.adminId,
    required this.adminName,
    this.defaultType,
    this.entityType,
    this.entityId,
  }) : super(key: key);

  @override
  State<EscalationRequestDialog> createState() =>
      _EscalationRequestDialogState();
}

class _EscalationRequestDialogState extends State<EscalationRequestDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late EscalationType _type;
  late EscalationPriority _priority;
  late String _entityType;
  late String _entityId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _type = widget.defaultType ?? EscalationType.SYSTEM_ALERT;
    _priority = EscalationPriority.MEDIUM;
    _entityType = widget.entityType ?? 'general';
    _entityId = widget.entityId ?? 'system';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getPriorityColor() {
    switch (_priority) {
      case EscalationPriority.LOW:
        return Colors.blue;
      case EscalationPriority.MEDIUM:
        return Colors.orange;
      case EscalationPriority.HIGH:
        return Colors.red.shade400;
      case EscalationPriority.CRITICAL:
        return Colors.red;
    }
  }

  Future<void> _createEscalation() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final escalation = await EscalationWorkflowService.createEscalation(
        createdByAdminId: widget.adminId,
        createdByAdminName: widget.adminName,
        type: _type,
        priority: _priority,
        title: _titleController.text,
        description: _descriptionController.text,
        entityType: _entityType,
        entityId: _entityId,
      );

      LoggerService.info('Escalation created: ${escalation.escalationId}');

      if (mounted) {
        Navigator.pop(context, escalation);
      }
    } catch (e) {
      LoggerService.error('Failed to create escalation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Escalation Request'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Escalation Type
            Text(
              'Issue Type',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<EscalationType>(
              value: _type,
              items: EscalationType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name.replaceAll('_', ' '),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority
            Text(
              'Priority',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: EscalationPriority.values
                    .map(
                      (priority) => RadioListTile(
                        title: Text(priority.name),
                        subtitle: Text(
                          _getPrioritySLA(priority),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: priority,
                        groupValue: _priority,
                        activeColor: _getPriorityColor(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _priority = value);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Title',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Brief summary of the issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Detailed description and context',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createEscalation,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  String _getPrioritySLA(EscalationPriority priority) {
    final slaMap = {
      EscalationPriority.LOW: 72,
      EscalationPriority.MEDIUM: 48,
      EscalationPriority.HIGH: 24,
      EscalationPriority.CRITICAL: 4,
    };
    final hours = slaMap[priority] ?? 48;
    return 'SLA: $hours hours';
  }
}

/// Widget for escalation card in list
class EscalationCard extends StatelessWidget {
  final EscalationRequest escalation;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onEscalateFurther;
  final VoidCallback? onResolve;

  const EscalationCard({
    Key? key,
    required this.escalation,
    this.onTap,
    this.onAssign,
    this.onEscalateFurther,
    this.onResolve,
  }) : super(key: key);

  Color _getPriorityColor() {
    switch (escalation.priority) {
      case EscalationPriority.LOW:
        return Colors.blue;
      case EscalationPriority.MEDIUM:
        return Colors.orange;
      case EscalationPriority.HIGH:
        return Colors.red.shade400;
      case EscalationPriority.CRITICAL:
        return Colors.red;
    }
  }

  Color _getStatusColor() {
    switch (escalation.status) {
      case EscalationStatus.OPEN:
        return Colors.orange;
      case EscalationStatus.IN_PROGRESS:
        return Colors.blue;
      case EscalationStatus.ESCALATED_FURTHER:
        return Colors.purple;
      case EscalationStatus.RESOLVED:
        return Colors.green;
      case EscalationStatus.REJECTED:
        return Colors.grey;
      case EscalationStatus.EXPIRED:
        return Colors.red;
    }
  }

  String _getTimeRemaining() {
    if (escalation.dueDate == null) return 'No SLA';
    final remaining = escalation.getHoursRemaining();
    if (remaining == null) return 'Resolved';
    if (remaining < 0) return 'Overdue by ${(-remaining).toStringAsFixed(1)}h';
    return 'Due in ${remaining.toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOverdue = escalation.isOverdue();

    return Card(
      color: isOverdue ? Colors.red.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title, Priority, Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          escalation.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created by ${escalation.createdByAdminName} on ${dateFormat.format(escalation.createdAt)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      escalation.priority.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      escalation.status.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description preview
              Text(
                escalation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),

              // Metadata: Assigned to, SLA, Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned to',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                      Text(
                        escalation.assignedToAdminName ?? 'Unassigned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getTimeRemaining(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isOverdue ? Colors.red : Colors.grey[600],
                              fontWeight: isOverdue ? FontWeight.bold : null,
                            ),
                      ),
                      Text(
                        'Level ${escalation.escalationLevel}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (escalation.status == EscalationStatus.OPEN &&
                      onAssign != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton.icon(
                        onPressed: onAssign,
                        icon: const Icon(Icons.assignment, size: 16),
                        label: const Text('Assign'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  if ((escalation.status == EscalationStatus.OPEN ||
                          escalation.status == EscalationStatus.IN_PROGRESS) &&
                      onEscalateFurther != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton.icon(
                        onPressed: onEscalateFurther,
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: const Text('Escalate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  if ((escalation.status == EscalationStatus.OPEN ||
                          escalation.status == EscalationStatus.IN_PROGRESS) &&
                      onResolve != null)
                    ElevatedButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
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

/// Screen for managing escalations
class EscalationManagementScreen extends StatefulWidget {
  final String? adminId;

  const EscalationManagementScreen({
    Key? key,
    this.adminId,
  }) : super(key: key);

  @override
  State<EscalationManagementScreen> createState() =>
      _EscalationManagementScreenState();
}

class _EscalationManagementScreenState extends State<EscalationManagementScreen> {
  late Future<List<EscalationRequest>> _escalationsFuture;
  EscalationPriority? _selectedPriority;
  EscalationType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadEscalations();
  }

  void _loadEscalations() {
    _escalationsFuture = EscalationWorkflowService.getPendingEscalations(
      assignedToAdminId: widget.adminId,
      priority: _selectedPriority,
      type: _selectedType,
    );
  }

  Future<void> _showAssignDialog(EscalationRequest escalation) async {
    final adminIdController = TextEditingController();
    final adminNameController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Escalation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adminIdController,
              decoration: const InputDecoration(
                labelText: 'Admin ID',
                hintText: 'e.g., admin_001',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminNameController,
              decoration: const InputDecoration(
                labelText: 'Admin Name',
                hintText: 'e.g., John Doe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (adminIdController.text.isNotEmpty &&
                  adminNameController.text.isNotEmpty) {
                // Capture messenger before async operation
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await EscalationWorkflowService.assignEscalation(
                    escalationId: escalation.escalationId,
                    assignedToAdminId: adminIdController.text,
                    assignedToAdminName: adminNameController.text,
                    assigningAdminId: widget.adminId ?? 'admin_000',
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (mounted) {
                    setState(() => _loadEscalations());
                  }

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Escalation assigned')),
                    );
                  }
                } catch (e) {
                  LoggerService.error('Failed to assign escalation: $e');
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escalation Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<EscalationPriority>(
                    value: _selectedPriority,
                    hint: const Text('Filter by priority'),
                    isExpanded: true,
                    items: [null, ...EscalationPriority.values]
                        .map(
                          (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(
                              priority == null
                                  ? 'All Priorities'
                                  : priority.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value;
                        _loadEscalations();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<EscalationType>(
                    value: _selectedType,
                    hint: const Text('Filter by type'),
                    isExpanded: true,
                    items: [null, ...EscalationType.values]
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type == null
                                  ? 'All Types'
                                  : type.name.replaceAll('_', ' '),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        _loadEscalations();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Escalations list
          Expanded(
            child: FutureBuilder<List<EscalationRequest>>(
              future: _escalationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final escalations = snapshot.data ?? [];

                if (escalations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No escalations found',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: escalations.length,
                  itemBuilder: (context, index) {
                    final escalation = escalations[index];
                    return EscalationCard(
                      escalation: escalation,
                      onAssign: escalation.status == EscalationStatus.OPEN
                          ? () => _showAssignDialog(escalation)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
