/// Escalation Workflow Service for Phase 4.4: Admin Collaboration
/// Manages escalation of complex issues to senior admins with SLA tracking
/// 
/// Architecture: Priority-based escalation with assignment, notifications, and audit trail
/// Supports multiple priority levels and automatic SLA enforcement

import 'package:opas_flutter/core/services/logger_service.dart';

// ignore_for_file: constant_identifier_names

/// Escalation priority levels
enum EscalationPriority {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL,
}

/// Escalation status
enum EscalationStatus {
  OPEN,
  IN_PROGRESS,
  ESCALATED_FURTHER,
  RESOLVED,
  REJECTED,
  EXPIRED,
}

/// Escalation workflow types
enum EscalationType {
  SELLER_SUSPENSION,
  PRICE_VIOLATION_SEVERE,
  OPAS_FRAUD_SUSPECTED,
  MARKETPLACE_CRITICAL_ISSUE,
  POLICY_VIOLATION,
  DATA_INTEGRITY_ISSUE,
  SYSTEM_ALERT,
  COMPLIANCE_VIOLATION,
}

/// Represents an escalation request
class EscalationRequest {
  final String escalationId;
  final String createdByAdminId;
  final String createdByAdminName;
  final EscalationType type;
  final EscalationPriority priority;
  final EscalationStatus status;
  final String title;
  final String description;
  final String entityType; // 'seller', 'listing', 'submission', etc.
  final String entityId;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? assignedToAdminId;
  final String? assignedToAdminName;
  final DateTime? assignedAt;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolutionAdminId;
  final List<String> relatedNoteIds;
  final List<String> watchers; // Admins monitoring this escalation
  final int escalationLevel; // 1 = initial, 2+ = escalated further
  final String? parentEscalationId; // If escalated further

  EscalationRequest({
    required this.escalationId,
    required this.createdByAdminId,
    required this.createdByAdminName,
    required this.type,
    required this.priority,
    required this.status,
    required this.title,
    required this.description,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.dueDate,
    this.assignedToAdminId,
    this.assignedToAdminName,
    this.assignedAt,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolutionAdminId,
    this.relatedNoteIds = const [],
    this.watchers = const [],
    this.escalationLevel = 1,
    this.parentEscalationId,
  });

  /// Get SLA hours based on priority
  int getSLAHours() {
    switch (priority) {
      case EscalationPriority.LOW:
        return 72; // 3 days
      case EscalationPriority.MEDIUM:
        return 48; // 2 days
      case EscalationPriority.HIGH:
        return 24; // 1 day
      case EscalationPriority.CRITICAL:
        return 4; // 4 hours
    }
  }

  /// Check if escalation is overdue
  bool isOverdue() {
    if (dueDate == null || status == EscalationStatus.RESOLVED) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Get time remaining in hours
  double? getHoursRemaining() {
    if (dueDate == null) return null;
    final remaining = dueDate!.difference(DateTime.now());
    return remaining.inMinutes / 60;
  }

  /// Create a copy with updated fields
  EscalationRequest copyWith({
    String? escalationId,
    String? createdByAdminId,
    String? createdByAdminName,
    EscalationType? type,
    EscalationPriority? priority,
    EscalationStatus? status,
    String? title,
    String? description,
    String? entityType,
    String? entityId,
    DateTime? createdAt,
    DateTime? dueDate,
    String? assignedToAdminId,
    String? assignedToAdminName,
    DateTime? assignedAt,
    String? resolutionNotes,
    DateTime? resolvedAt,
    String? resolutionAdminId,
    List<String>? relatedNoteIds,
    List<String>? watchers,
    int? escalationLevel,
    String? parentEscalationId,
  }) {
    return EscalationRequest(
      escalationId: escalationId ?? this.escalationId,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdByAdminName: createdByAdminName ?? this.createdByAdminName,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      assignedToAdminId: assignedToAdminId ?? this.assignedToAdminId,
      assignedToAdminName: assignedToAdminName ?? this.assignedToAdminName,
      assignedAt: assignedAt ?? this.assignedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionAdminId: resolutionAdminId ?? this.resolutionAdminId,
      relatedNoteIds: relatedNoteIds ?? this.relatedNoteIds,
      watchers: watchers ?? this.watchers,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      parentEscalationId: parentEscalationId ?? this.parentEscalationId,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'escalationId': escalationId,
    'createdByAdminId': createdByAdminId,
    'createdByAdminName': createdByAdminName,
    'type': type.name,
    'priority': priority.name,
    'status': status.name,
    'title': title,
    'description': description,
    'entityType': entityType,
    'entityId': entityId,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'assignedToAdminId': assignedToAdminId,
    'assignedToAdminName': assignedToAdminName,
    'assignedAt': assignedAt?.toIso8601String(),
    'resolutionNotes': resolutionNotes,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolutionAdminId': resolutionAdminId,
    'relatedNoteIds': relatedNoteIds,
    'watchers': watchers,
    'escalationLevel': escalationLevel,
    'parentEscalationId': parentEscalationId,
  };

  /// Create from JSON
  factory EscalationRequest.fromJson(Map<String, dynamic> json) {
    return EscalationRequest(
      escalationId: json['escalationId'] as String,
      createdByAdminId: json['createdByAdminId'] as String,
      createdByAdminName: json['createdByAdminName'] as String,
      type: EscalationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => EscalationType.SYSTEM_ALERT,
      ),
      priority: EscalationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => EscalationPriority.MEDIUM,
      ),
      status: EscalationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EscalationStatus.OPEN,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      assignedToAdminId: json['assignedToAdminId'] as String?,
      assignedToAdminName: json['assignedToAdminName'] as String?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolutionAdminId: json['resolutionAdminId'] as String?,
      relatedNoteIds:
          List<String>.from(json['relatedNoteIds'] as List? ?? []),
      watchers: List<String>.from(json['watchers'] as List? ?? []),
      escalationLevel: json['escalationLevel'] as int? ?? 1,
      parentEscalationId: json['parentEscalationId'] as String?,
    );
  }
}

/// Service for managing escalations
class EscalationWorkflowService {
  static final List<EscalationRequest> _escalations = [];
  static int _escalationIdCounter = 2000;

  /// Create new escalation request
  static Future<EscalationRequest> createEscalation({
    required String createdByAdminId,
    required String createdByAdminName,
    required EscalationType type,
    required EscalationPriority priority,
    required String title,
    required String description,
    required String entityType,
    required String entityId,
    List<String> relatedNoteIds = const [],
    List<String> watchers = const [],
  }) async {
    try {
      LoggerService.info('Creating escalation: $type - $title');

      final escalationId = 'esc_${_escalationIdCounter++}';
      final slaHours = _getSLAHours(priority);
      final dueDate = DateTime.now().add(Duration(hours: slaHours));

      final escalation = EscalationRequest(
        escalationId: escalationId,
        createdByAdminId: createdByAdminId,
        createdByAdminName: createdByAdminName,
        type: type,
        priority: priority,
        status: EscalationStatus.OPEN,
        title: title,
        description: description,
        entityType: entityType,
        entityId: entityId,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        relatedNoteIds: relatedNoteIds,
        watchers: [createdByAdminId, ...watchers],
      );

      _escalations.add(escalation);

      LoggerService.info('Escalation created: $escalationId');
      return escalation;
    } catch (e) {
      LoggerService.error('Failed to create escalation: $e');
      rethrow;
    }
  }

  /// Assign escalation to an admin
  static Future<EscalationRequest> assignEscalation({
    required String escalationId,
    required String assignedToAdminId,
    required String assignedToAdminName,
    required String assigningAdminId,
  }) async {
    try {
      LoggerService.info('Assigning escalation $escalationId to $assignedToAdminName');

      final index = _escalations.indexWhere((e) => e.escalationId == escalationId);
      if (index == -1) throw Exception('Escalation not found');

      final escalation = _escalations[index];
      if (escalation.status != EscalationStatus.OPEN &&
          escalation.status != EscalationStatus.IN_PROGRESS) {
        throw Exception('Cannot assign resolved or expired escalation');
      }

      final updated = escalation.copyWith(
        assignedToAdminId: assignedToAdminId,
        assignedToAdminName: assignedToAdminName,
        assignedAt: DateTime.now(),
        status: EscalationStatus.IN_PROGRESS,
        watchers: <String>{
          ...escalation.watchers,
          assignedToAdminId,
          assigningAdminId,
        }.toList(),
      );

      _escalations[index] = updated;

      LoggerService.info('Escalation assigned: $escalationId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to assign escalation: $e');
      rethrow;
    }
  }

  /// Escalate further (bump priority/level)
  static Future<EscalationRequest> escalateFurther({
    required String escalationId,
    required String escalatingAdminId,
    required String escalatingAdminName,
    required String reason,
  }) async {
    try {
      LoggerService.info('Escalating further: $escalationId');

      final index = _escalations.indexWhere((e) => e.escalationId == escalationId);
      if (index == -1) throw Exception('Escalation not found');

      final original = _escalations[index];

      // Create new escalation at higher level
      final newEscalationId = 'esc_${_escalationIdCounter++}';
      final newSlaHours = _getSLAHours(
        _getHigherPriority(original.priority),
      );
      final newDueDate = DateTime.now().add(Duration(hours: newSlaHours));

      final escalated = EscalationRequest(
        escalationId: newEscalationId,
        createdByAdminId: escalatingAdminId,
        createdByAdminName: escalatingAdminName,
        type: original.type,
        priority: _getHigherPriority(original.priority),
        status: EscalationStatus.OPEN,
        title: '[ESCALATED] ${original.title}',
        description: '$reason\n\nOriginal: ${original.description}',
        entityType: original.entityType,
        entityId: original.entityId,
        createdAt: DateTime.now(),
        dueDate: newDueDate,
        relatedNoteIds: original.relatedNoteIds,
        watchers: original.watchers,
        escalationLevel: original.escalationLevel + 1,
        parentEscalationId: escalationId,
      );

      _escalations.add(escalated);

      // Mark original as escalated
      final updated = original.copyWith(
        status: EscalationStatus.ESCALATED_FURTHER,
      );
      _escalations[index] = updated;

      LoggerService.info('Escalation escalated further: $newEscalationId');
      return escalated;
    } catch (e) {
      LoggerService.error('Failed to escalate further: $e');
      rethrow;
    }
  }

  /// Resolve escalation
  static Future<EscalationRequest> resolveEscalation({
    required String escalationId,
    required String resolutionAdminId,
    required String resolutionAdminName,
    required String resolutionNotes,
  }) async {
    try {
      LoggerService.info('Resolving escalation: $escalationId');

      final index = _escalations.indexWhere((e) => e.escalationId == escalationId);
      if (index == -1) throw Exception('Escalation not found');

      final escalation = _escalations[index];
      final updated = escalation.copyWith(
        status: EscalationStatus.RESOLVED,
        resolutionNotes: resolutionNotes,
        resolvedAt: DateTime.now(),
        resolutionAdminId: resolutionAdminId,
      );

      _escalations[index] = updated;

      LoggerService.info('Escalation resolved: $escalationId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to resolve escalation: $e');
      rethrow;
    }
  }

  /// Get pending escalations
  static Future<List<EscalationRequest>> getPendingEscalations({
    String? assignedToAdminId,
    EscalationType? type,
    EscalationPriority? priority,
  }) async {
    try {
      var escalations = _escalations
          .where((e) =>
              e.status == EscalationStatus.OPEN ||
              e.status == EscalationStatus.IN_PROGRESS)
          .toList();

      if (assignedToAdminId != null) {
        escalations = escalations
            .where((e) => e.assignedToAdminId == assignedToAdminId)
            .toList();
      }

      if (type != null) {
        escalations = escalations.where((e) => e.type == type).toList();
      }

      if (priority != null) {
        escalations = escalations.where((e) => e.priority == priority).toList();
      }

      // Sort: overdue first, then by priority, then by creation date
      escalations.sort((a, b) {
        if (a.isOverdue() != b.isOverdue()) {
          return a.isOverdue() ? -1 : 1;
        }
        final priorityOrder = [
          EscalationPriority.CRITICAL,
          EscalationPriority.HIGH,
          EscalationPriority.MEDIUM,
          EscalationPriority.LOW,
        ];
        final aPriority = priorityOrder.indexOf(a.priority);
        final bPriority = priorityOrder.indexOf(b.priority);
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return a.createdAt.compareTo(b.createdAt);
      });

      LoggerService.info('Retrieved ${escalations.length} pending escalations');
      return escalations;
    } catch (e) {
      LoggerService.error('Failed to get pending escalations: $e');
      rethrow;
    }
  }

  /// Get escalation details
  static Future<EscalationRequest> getEscalation(String escalationId) async {
    try {
      final escalation = _escalations.firstWhere(
        (e) => e.escalationId == escalationId,
        orElse: () => throw Exception('Escalation not found'),
      );

      LoggerService.info('Retrieved escalation: $escalationId');
      return escalation;
    } catch (e) {
      LoggerService.error('Failed to get escalation: $e');
      rethrow;
    }
  }

  /// Get escalation chain (parent + children)
  static Future<List<EscalationRequest>> getEscalationChain(
    String escalationId,
  ) async {
    try {
      final escalation = await getEscalation(escalationId);
      final chain = [escalation];

      // Get parent if exists
      if (escalation.parentEscalationId != null) {
        final parent = await getEscalation(escalation.parentEscalationId!);
        chain.insert(0, parent);
      }

      // Get children
      final children = _escalations
          .where((e) => e.parentEscalationId == escalationId)
          .toList();
      chain.addAll(children);

      LoggerService.info('Retrieved escalation chain: ${chain.length} items');
      return chain;
    } catch (e) {
      LoggerService.error('Failed to get escalation chain: $e');
      rethrow;
    }
  }

  /// Get statistics
  static Future<Map<String, dynamic>> getEscalationStatistics() async {
    try {
      final stats = {
        'totalEscalations': _escalations.length,
        'openEscalations':
            _escalations.where((e) => e.status == EscalationStatus.OPEN).length,
        'inProgressEscalations': _escalations
            .where((e) => e.status == EscalationStatus.IN_PROGRESS)
            .length,
        'resolvedEscalations':
            _escalations.where((e) => e.status == EscalationStatus.RESOLVED).length,
        'overdueEscalations':
            _escalations.where((e) => e.isOverdue()).length,
        'escalationsByPriority': {
          for (final priority in EscalationPriority.values)
            priority.name: _escalations
                .where((e) => e.priority == priority)
                .length,
        },
        'escalationsByType': {
          for (final type in EscalationType.values)
            type.name: _escalations.where((e) => e.type == type).length,
        },
      };

      LoggerService.info('Escalation statistics: ${stats['totalEscalations']} total');
      return stats;
    } catch (e) {
      LoggerService.error('Failed to get escalation statistics: $e');
      rethrow;
    }
  }

  /// Helper: Get SLA hours for priority
  static int _getSLAHours(EscalationPriority priority) {
    switch (priority) {
      case EscalationPriority.LOW:
        return 72;
      case EscalationPriority.MEDIUM:
        return 48;
      case EscalationPriority.HIGH:
        return 24;
      case EscalationPriority.CRITICAL:
        return 4;
    }
  }

  /// Helper: Get higher priority level
  static EscalationPriority _getHigherPriority(EscalationPriority current) {
    switch (current) {
      case EscalationPriority.LOW:
        return EscalationPriority.MEDIUM;
      case EscalationPriority.MEDIUM:
        return EscalationPriority.HIGH;
      case EscalationPriority.HIGH:
      case EscalationPriority.CRITICAL:
        return EscalationPriority.CRITICAL;
    }
  }
}
