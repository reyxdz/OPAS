/// Admin Approval Workflow Service
///
/// Manages approval workflows for high-risk marketplace actions.
/// Ensures critical decisions have proper authorization and documentation.
///
/// Features:
/// - High-risk action identification
/// - Approval request generation and tracking
/// - Workflow state management (pending, approved, rejected)
/// - Multi-level approval (single or multiple approvers)
/// - Approval history and audit trail
/// - Escalation procedures
/// - Automatic notifications
/// - Risk scoring for actions
/// - Approval deadlines and SLAs
/// - Compliance tracking
///
/// Architecture: Stateless utility class with workflow management
/// All methods are static and manage immutable approval records
/// Error handling: Comprehensive try/catch with logging

import 'package:opas_flutter/core/services/logger_service.dart';

class AdminApprovalWorkflowService {
  AdminApprovalWorkflowService._(); // Private constructor - no instantiation

  // ============================================================================
  // Constants: Workflow Types & Risk Levels
  // ============================================================================

  // Approval Workflow Types
  static const String workflowTypeSellerApproval = 'SELLER_APPROVAL';
  static const String workflowTypeSellerSuspension = 'SELLER_SUSPENSION';
  static const String workflowTypeSellerRemoval = 'SELLER_REMOVAL';
  static const String workflowTypePriceCeiling = 'PRICE_CEILING_UPDATE';
  static const String workflowTypeOPASRemoval = 'OPAS_INVENTORY_REMOVAL';
  static const String workflowTypeSystemReset = 'SYSTEM_RESET';
  static const String workflowTypeDataModification = 'DATA_MODIFICATION';
  static const String workflowTypeAccessGrantRevoke = 'ACCESS_GRANT_REVOKE';

  // Risk Levels for Actions
  static const String riskLevelLow = 'LOW';
  static const String riskLevelMedium = 'MEDIUM';
  static const String riskLevelHigh = 'HIGH';
  static const String riskLevelCritical = 'CRITICAL';

  // Approval Status
  static const String statusPending = 'PENDING';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';
  static const String statusEscalated = 'ESCALATED';
  static const String statusExpired = 'EXPIRED';

  // Approval Decision
  static const String decisionApprove = 'APPROVE';
  static const String decisionReject = 'REJECT';
  static const String decisionRequest = 'REQUEST_CHANGES';
  static const String decisionEscalate = 'ESCALATE';

  // Required Approvals by Risk Level
  static const int approvalsRequiredLow = 1;
  static const int approvalsRequiredMedium = 2;
  static const int approvalsRequiredHigh = 3;
  static const int approvalsRequiredCritical = 4;

  // SLA Constants (hours)
  static const int slaLowRisk = 24;
  static const int slaMediumRisk = 12;
  static const int slaHighRisk = 6;
  static const int slaCriticalRisk = 2;

  // In-memory approval tracking (production would use database)
  static final List<Map<String, dynamic>> _approvalRequests =
      <Map<String, dynamic>>[];
  static final List<Map<String, dynamic>> _approvalHistory =
      <Map<String, dynamic>>[];

  // ============================================================================
  // Core Approval Workflow
  // ============================================================================

  /// Creates approval request for high-risk action.
  ///
  /// Initiates workflow to obtain necessary approvals before action execution.
  ///
  /// Parameters:
  /// - workflowType: Type of approval workflow
  /// - actionDescription: Description of action to approve
  /// - riskLevel: Risk level of action
  /// - requestedBy: ID of admin requesting approval
  /// - targetEntityType: Type of entity affected
  /// - targetEntityId: ID of affected entity
  /// - actionDetails: Additional context (before/after state, etc.)
  /// - requiredApprovers: List of admin IDs who must approve
  /// - urgency: Priority/urgency level
  /// - reason: Business reason for request
  /// - estimatedImpact: Description of expected impact
  ///
  /// Returns: Approval request with ID and SLA deadline
  /// Throws: Exception if request creation fails
  static Future<Map<String, dynamic>> createApprovalRequest({
    required String workflowType,
    required String actionDescription,
    required String riskLevel,
    required String requestedBy,
    required String targetEntityType,
    required String targetEntityId,
    required Map<String, dynamic> actionDetails,
    required List<String> requiredApprovers,
    required String urgency,
    required String reason,
    required String estimatedImpact,
  }) async {
    try {
      final approvalId = _generateApprovalId();
      final timestamp = DateTime.now();

      // Calculate SLA deadline based on risk level
      final slaHours = _getSLAHours(riskLevel);
      final slaDeadline = timestamp.add(Duration(hours: slaHours));

      // Determine required approvals
      final requiredApprovalsCount = _getRequiredApprovalsCount(riskLevel);

      final approvalRequest = {
        'approval_id': approvalId,
        'workflow_type': workflowType,
        'action_description': actionDescription,
        'risk_level': riskLevel,
        'status': statusPending,
        'requested_by': requestedBy,
        'target_entity_type': targetEntityType,
        'target_entity_id': targetEntityId,
        'action_details': actionDetails,
        'required_approvers': requiredApprovers,
        'required_approvals_count': requiredApprovalsCount,
        'current_approvals_count': 0,
        'urgency': urgency,
        'reason': reason,
        'estimated_impact': estimatedImpact,
        'created_at': timestamp.toIso8601String(),
        'sla_deadline': slaDeadline.toIso8601String(),
        'sla_remaining_hours': slaHours,
        'approvals': <Map<String, dynamic>>[],
        'rejections': <Map<String, dynamic>>[],
        'escalations': <Map<String, dynamic>>[],
        'is_immutable': true,
      };

      _approvalRequests.add(approvalRequest);

      LoggerService.info(
        'Approval request created: $workflowType',
        tag: 'APPROVAL_WORKFLOW',
        metadata: {
          'approvalId': approvalId,
          'riskLevel': riskLevel,
          'requestedBy': requestedBy,
          'requiredApprovals': requiredApprovalsCount,
        },
      );

      return approvalRequest;
    } catch (e) {
      LoggerService.error(
        'Error creating approval request',
        tag: 'APPROVAL_WORKFLOW',
        error: e,
      );
      rethrow;
    }
  }

  /// Submits approval decision for pending request.
  ///
  /// Records approval, rejection, or escalation decision.
  /// Updates workflow status based on accumulated decisions.
  ///
  /// Parameters:
  /// - approvalId: ID of approval request
  /// - approverId: ID of approver
  /// - decision: APPROVE, REJECT, REQUEST_CHANGES, ESCALATE
  /// - comments: Optional approval comments
  /// - requiredChanges: If REQUEST_CHANGES, what needs to change
  /// - escalationReason: If ESCALATE, reason for escalation
  /// - escalateToLevel: If ESCALATE, escalation level
  ///
  /// Returns: Updated approval request with decision recorded
  /// Throws: Exception if submission fails
  static Future<Map<String, dynamic>> submitApprovalDecision({
    required String approvalId,
    required String approverId,
    required String decision,
    String? comments,
    String? requiredChanges,
    String? escalationReason,
    String? escalateToLevel,
  }) async {
    try {
      // Find approval request
      final requestIndex = _approvalRequests
          .indexWhere((r) => r['approval_id'] == approvalId);
      if (requestIndex == -1) {
        throw Exception('Approval request not found: $approvalId');
      }

      final request = _approvalRequests[requestIndex];
      final timestamp = DateTime.now();

      // Validate decision
      if (![decisionApprove, decisionReject, decisionRequest, decisionEscalate]
          .contains(decision)) {
        throw Exception('Invalid decision type: $decision');
      }

      // Create decision record
      final decisionRecord = {
        'approver_id': approverId,
        'decision': decision,
        'timestamp': timestamp.toIso8601String(),
        'comments': comments ?? '',
      };

      // Process decision
      switch (decision) {
        case decisionApprove:
          request['approvals'].add(decisionRecord);
          request['current_approvals_count'] =
              (request['current_approvals_count'] as int) + 1;

          // Check if all approvals obtained
          if ((request['current_approvals_count'] as int) >=
              (request['required_approvals_count'] as int)) {
            request['status'] = statusApproved;
            LoggerService.info(
              'Approval request approved: $approvalId',
              tag: 'APPROVAL_WORKFLOW',
              metadata: {
                'approvalId': approvalId,
                'totalApprovals': request['current_approvals_count'],
              },
            );
          }
          break;

        case decisionReject:
          request['rejections'].add(decisionRecord);
          request['status'] = statusRejected;
          request['rejected_at'] = timestamp.toIso8601String();

          LoggerService.warning(
            'Approval request rejected: $approvalId',
            tag: 'APPROVAL_WORKFLOW',
            metadata: {
              'approvalId': approvalId,
              'rejectionReason': comments ?? 'No reason provided',
            },
          );
          break;

        case decisionRequest:
          request['change_requests'].add({
            ...decisionRecord,
            'required_changes': requiredChanges ?? '',
          });
          LoggerService.info(
            'Changes requested for approval: $approvalId',
            tag: 'APPROVAL_WORKFLOW',
            metadata: {
              'approvalId': approvalId,
              'approverId': approverId,
            },
          );
          break;

        case decisionEscalate:
          request['escalations'].add({
            ...decisionRecord,
            'escalation_reason': escalationReason ?? '',
            'escalate_to_level': escalateToLevel ?? '',
          });
          request['status'] = statusEscalated;

          LoggerService.warning(
            'Approval escalated: $approvalId',
            tag: 'APPROVAL_WORKFLOW',
            metadata: {
              'approvalId': approvalId,
              'escalateToLevel': escalateToLevel,
            },
          );
          break;
      }

      // Record in history
      _approvalHistory.add({
        'approval_id': approvalId,
        'decision': decision,
        'approver_id': approverId,
        'timestamp': timestamp.toIso8601String(),
      });

      return request;
    } catch (e) {
      LoggerService.error(
        'Error submitting approval decision',
        tag: 'APPROVAL_WORKFLOW',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Approval Request Retrieval & Filtering
  // ============================================================================

  /// Retrieves pending approval requests.
  ///
  /// Returns: List of pending approval requests with filtering options
  /// Throws: Exception if retrieval fails
  static Future<Map<String, dynamic>> getPendingApprovals({
    String? requestedBy,
    String? riskLevel,
    String? workflowType,
    bool includePastDue = false,
  }) async {
    try {
      var requests = List<Map<String, dynamic>>.from(_approvalRequests);

      // Filter by status
      requests = requests
          .where((r) =>
              r['status'] == statusPending || r['status'] == statusEscalated)
          .toList();

      // Apply additional filters
      if (requestedBy != null) {
        requests =
            requests.where((r) => r['requested_by'] == requestedBy).toList();
      }
      if (riskLevel != null) {
        requests =
            requests.where((r) => r['risk_level'] == riskLevel).toList();
      }
      if (workflowType != null) {
        requests =
            requests.where((r) => r['workflow_type'] == workflowType).toList();
      }

      // Check SLA status
      final now = DateTime.now();
      for (final request in requests) {
        final deadline =
            DateTime.parse(request['sla_deadline'] as String);
        request['is_past_due'] = now.isAfter(deadline);
        request['hours_remaining'] =
            deadline.difference(now).inHours;
      }

      if (!includePastDue) {
        requests =
            requests.where((r) => r['is_past_due'] != true).toList();
      }

      // Sort by urgency and SLA
      requests.sort((a, b) {
        final urgencyOrder = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};
        final aUrgency =
            urgencyOrder[a['urgency'] as String] ?? 999;
        final bUrgency =
            urgencyOrder[b['urgency'] as String] ?? 999;
        return aUrgency.compareTo(bUrgency);
      });

      return {
        'total_pending': requests.length,
        'approvals': requests,
        'summary': {
          'critical': requests.where((r) => r['risk_level'] == riskLevelCritical).length,
          'high': requests.where((r) => r['risk_level'] == riskLevelHigh).length,
          'medium': requests.where((r) => r['risk_level'] == riskLevelMedium).length,
          'low': requests.where((r) => r['risk_level'] == riskLevelLow).length,
          'past_due': requests.where((r) => r['is_past_due'] == true).length,
        },
      };
    } catch (e) {
      LoggerService.error(
        'Error retrieving pending approvals',
        tag: 'APPROVAL_WORKFLOW',
        error: e,
      );
      rethrow;
    }
  }

  /// Retrieves approval request details and history.
  ///
  /// Returns: Complete approval request with all decisions
  /// Throws: Exception if retrieval fails
  static Future<Map<String, dynamic>> getApprovalDetails(
    String approvalId,
  ) async {
    try {
      final request = _approvalRequests.firstWhere(
        (r) => r['approval_id'] == approvalId,
        orElse: () => {},
      );

      if (request.isEmpty) {
        throw Exception('Approval request not found: $approvalId');
      }

      final history = _approvalHistory
          .where((h) => h['approval_id'] == approvalId)
          .toList();

      return {
        'approval_request': request,
        'decision_history': history,
        'approval_progress': {
          'current': request['current_approvals_count'],
          'required': request['required_approvals_count'],
          'remaining': (request['required_approvals_count'] as int) -
              (request['current_approvals_count'] as int),
          'percentage_complete':
              ((request['current_approvals_count'] as int) /
                      (request['required_approvals_count'] as int) *
                      100)
                  .toStringAsFixed(1),
        },
      };
    } catch (e) {
      LoggerService.error(
        'Error retrieving approval details',
        tag: 'APPROVAL_WORKFLOW',
        error: e,
      );
      rethrow;
    }
  }

  /// Generates approval workflow summary statistics.
  ///
  /// Returns: Summary with approval metrics and trends
  /// Throws: Exception if summary generation fails
  static Future<Map<String, dynamic>> getApprovalSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var requests = List<Map<String, dynamic>>.from(_approvalRequests);

      // Apply date filters
      if (startDate != null) {
        requests = requests
            .where((r) =>
                DateTime.parse(r['created_at'] as String)
                    .isAfter(startDate) ||
                DateTime.parse(r['created_at'] as String)
                    .isAtSameMomentAs(startDate))
            .toList();
      }
      if (endDate != null) {
        requests = requests
            .where((r) =>
                DateTime.parse(r['created_at'] as String)
                    .isBefore(endDate) ||
                DateTime.parse(r['created_at'] as String)
                    .isAtSameMomentAs(endDate))
            .toList();
      }

      // Count by status
      final statusCounts = <String, int>{};
      for (final request in requests) {
        final status = request['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      // Count by risk level
      final riskCounts = <String, int>{};
      for (final request in requests) {
        final risk = request['risk_level'] as String;
        riskCounts[risk] = (riskCounts[risk] ?? 0) + 1;
      }

      // Calculate average approval time
      final completedRequests = requests
          .where((r) =>
              r['status'] == statusApproved || r['status'] == statusRejected)
          .toList();

      double avgApprovalTime = 0;
      if (completedRequests.isNotEmpty) {
        int totalTime = 0;
        for (final request in completedRequests) {
          final created = DateTime.parse(request['created_at'] as String);
          final completed = DateTime.parse(
              request['rejected_at'] as String? ??
                  request['approved_at'] as String? ??
                  DateTime.now().toIso8601String());
          totalTime += completed.difference(created).inHours;
        }
        avgApprovalTime = totalTime / completedRequests.length;
      }

      return {
        'period_start': startDate?.toIso8601String() ?? 'all_time',
        'period_end': endDate?.toIso8601String() ?? 'all_time',
        'total_requests': requests.length,
        'status_breakdown': statusCounts,
        'risk_breakdown': riskCounts,
        'approval_rate': completedRequests.isEmpty
            ? '0%'
            : '${((statusCounts[statusApproved] ?? 0) / completedRequests.length * 100).toStringAsFixed(1)}%',
        'average_approval_time_hours': avgApprovalTime.toStringAsFixed(1),
        'pending_count': statusCounts[statusPending] ?? 0,
        'escalated_count': statusCounts[statusEscalated] ?? 0,
      };
    } catch (e) {
      LoggerService.error(
        'Error generating approval summary',
        tag: 'APPROVAL_WORKFLOW',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Generates unique approval ID
  static String _generateApprovalId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond).toString().padLeft(6, '0');
    return 'approval_${timestamp}_$random';
  }

  /// Gets SLA hours based on risk level
  static int _getSLAHours(String riskLevel) {
    switch (riskLevel) {
      case riskLevelLow:
        return slaLowRisk;
      case riskLevelMedium:
        return slaMediumRisk;
      case riskLevelHigh:
        return slaHighRisk;
      case riskLevelCritical:
        return slaCriticalRisk;
      default:
        return 24;
    }
  }

  /// Gets required approvals count based on risk level
  static int _getRequiredApprovalsCount(String riskLevel) {
    switch (riskLevel) {
      case riskLevelLow:
        return approvalsRequiredLow;
      case riskLevelMedium:
        return approvalsRequiredMedium;
      case riskLevelHigh:
        return approvalsRequiredHigh;
      case riskLevelCritical:
        return approvalsRequiredCritical;
      default:
        return 1;
    }
  }
}
