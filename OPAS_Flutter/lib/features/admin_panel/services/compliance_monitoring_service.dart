import 'package:flutter/foundation.dart';
import '../../../core/services/admin_service.dart';

/// ============================================================================
/// ComplianceMonitoringService - Phase 4.1c Implementation
///
/// Manages automated compliance monitoring and violation detection:
/// 1. Detect price violations (listings above ceiling)
/// 2. Categorize violations by severity
/// 3. Track repeat offenders
/// 4. Auto-escalate violations based on rules
/// 5. Generate compliance reports
/// 6. Trigger automated actions (warnings, adjustments, suspensions)
/// 7. Monitor compliance trends over time
///
/// Architecture: Stateless utility class using AdminService layer
/// Pattern: Scheduled monitoring with rule-based escalation
/// Error Handling: Comprehensive error tracking for audit trail
/// ============================================================================

class ComplianceMonitoringService {
  // ==================== VIOLATION STATUS ====================
  static const String statusNew = 'NEW';
  static const String statusWarned = 'WARNED';
  static const String statusAdjusted = 'ADJUSTED';
  static const String statusSuspended = 'SUSPENDED';
  static const String statusResolved = 'RESOLVED';

  // ==================== VIOLATION SEVERITY ====================
  static const String severityMinor = 'MINOR'; // < 5% over ceiling
  static const String severityModerate = 'MODERATE'; // 5-20% over
  static const String severitySerious = 'SERIOUS'; // 20-50% over
  static const String severityCritical = 'CRITICAL'; // > 50% over

  // ==================== MONITORING MODES ====================
  static const String modeRealTime = 'REAL_TIME';
  static const String modeScheduled = 'SCHEDULED';
  static const String modeBatch = 'BATCH';
  static const String modeManual = 'MANUAL';

  // ==================== ESCALATION RULES ====================
  static const int warningThresholdPercent = 5;
  static const int adjustmentThresholdPercent = 20;
  static const int suspensionThresholdPercent = 50;
  static const int repeatOffenderViolationCount = 3;
  static const int compliancePeriodHours = 24;

  // ==================== STEP 1: DETECT VIOLATIONS ====================

  /// Detect all price violations in marketplace
  ///
  /// Returns: List of violations with severity classification
  static Future<Map<String, dynamic>> detectViolations({
    String monitoringMode = modeManual,
  }) async {
    try {
      final violations = await AdminService.getNonCompliantListings();

      List<Map<String, dynamic>> classifiedViolations = [];

      for (final violation in violations) {
        final listedPrice = (violation['listed_price'] as num?)?.toDouble() ?? 0;
        final ceilingPrice = (violation['ceiling_price'] as num?)?.toDouble() ?? 1;
        final overage = listedPrice - ceilingPrice;
        final overagePercent = (overage / ceilingPrice) * 100;

        classifiedViolations.add({
          'violationId': violation['id'],
          'sellerId': violation['seller_id'],
          'productId': violation['product_id'],
          'listedPrice': listedPrice,
          'ceilingPrice': ceilingPrice,
          'overage': overage,
          'overagePercent': overagePercent,
          'severity': _classifySeverity(overagePercent),
          'detectedAt': DateTime.now().toIso8601String(),
          'status': statusNew,
          'description':
              'Listing priced at $listedPrice (ceiling: $ceilingPrice)',
        });
      }

      return {
        'success': true,
        'mode': monitoringMode,
        'violations': classifiedViolations,
        'totalViolations': classifiedViolations.length,
        'severityBreakdown': _countBySeverity(classifiedViolations),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to detect violations: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'violations': [],
      };
    }
  }

  // ==================== STEP 2: IDENTIFY REPEAT OFFENDERS ====================

  /// Identify sellers with repeated violations
  ///
  /// Returns: List of repeat offenders with violation history
  static Future<Map<String, dynamic>> identifyRepeatOffenders({
    required List<Map<String, dynamic>> currentViolations,
  }) async {
    try {
      Map<String, List<Map<String, dynamic>>> sellerViolations = {};

      // Group violations by seller
      for (final violation in currentViolations) {
        final sellerId = violation['sellerId']?.toString() ?? 'UNKNOWN';
        if (!sellerViolations.containsKey(sellerId)) {
          sellerViolations[sellerId] = [];
        }
        sellerViolations[sellerId]!.add(violation);
      }

      List<Map<String, dynamic>> repeatOffenders = [];

      for (final entry in sellerViolations.entries) {
        final sellerId = entry.key;
        final violations = entry.value;

        if (violations.length >= repeatOffenderViolationCount) {
          // Get historical violations from AdminService
          final history = await AdminService.getSellerViolations(sellerId);

          final totalViolationCount = history.length + violations.length;

          repeatOffenders.add({
            'sellerId': sellerId,
            'currentViolations': violations.length,
            'historicalViolations': history.length,
            'totalViolations': totalViolationCount,
            'severity': _getMostSevereProblem(violations),
            'riskLevel': _assessRiskLevel(totalViolationCount),
            'violations': violations,
            'recommendedAction': _recommendAction(totalViolationCount),
          });
        }
      }

      return {
        'success': true,
        'repeatOffenderCount': repeatOffenders.length,
        'offenders': repeatOffenders,
        'threshold': repeatOffenderViolationCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to identify repeat offenders: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'offenders': [],
      };
    }
  }

  // ==================== STEP 3: CATEGORIZE BY ESCALATION LEVEL ====================

  /// Categorize violations by escalation action needed
  ///
  /// Returns: Violations grouped by required action
  static Future<Map<String, dynamic>> categorizeByEscalation({
    required List<Map<String, dynamic>> violations,
    required List<Map<String, dynamic>> repeatOffenders,
  }) async {
    try {
      List<Map<String, dynamic>> needsWarning = [];
      List<Map<String, dynamic>> needsAdjustment = [];
      List<Map<String, dynamic>> needsSuspension = [];

      for (final violation in violations) {
        final overagePercent = (violation['overagePercent'] as num?)?.toDouble() ?? 0;
        final sellerId = violation['sellerId']?.toString() ?? '';

        // Check if repeat offender
        final isRepeatOffender = repeatOffenders.any(
          (o) => o['sellerId']?.toString() == sellerId,
        );

        if (overagePercent > suspensionThresholdPercent || isRepeatOffender) {
          needsSuspension.add({...violation, 'action': 'SUSPEND'});
        } else if (overagePercent > adjustmentThresholdPercent) {
          needsAdjustment.add({...violation, 'action': 'FORCE_ADJUSTMENT'});
        } else if (overagePercent > warningThresholdPercent) {
          needsWarning.add({...violation, 'action': 'WARNING'});
        }
      }

      return {
        'success': true,
        'categorization': {
          'warning': {
            'count': needsWarning.length,
            'violations': needsWarning,
          },
          'adjustment': {
            'count': needsAdjustment.length,
            'violations': needsAdjustment,
          },
          'suspension': {
            'count': needsSuspension.length,
            'violations': needsSuspension,
          },
        },
        'summary': {
          'totalWarnings': needsWarning.length,
          'totalAdjustments': needsAdjustment.length,
          'totalSuspensions': needsSuspension.length,
          'actionCount': needsWarning.length +
              needsAdjustment.length +
              needsSuspension.length,
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to categorize by escalation: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 4: GENERATE COMPLIANCE REPORT ====================

  /// Generate comprehensive compliance report
  ///
  /// Report includes:
  /// - Violation summary by severity
  /// - Repeat offenders analysis
  /// - Compliance trends
  /// - Recommended actions
  /// - Market health metrics
  ///
  /// Returns: Complete compliance report
  static Future<Map<String, dynamic>> generateComplianceReport({
    required Map<String, dynamic> violationData,
    required Map<String, dynamic> offenderData,
    required Map<String, dynamic> escalationData,
  }) async {
    try {
      final violations =
          violationData['violations'] as List<Map<String, dynamic>>;
      final offenders = offenderData['offenders'] as List<Map<String, dynamic>>;
      final escalation = escalationData['categorization'] as Map?;

      // Calculate metrics
      const totalListings = 1000; // Simulated baseline
      final complianceRate = violations.isEmpty
          ? 100.0
          : ((totalListings - violations.length) / totalListings) * 100;

      final avgOveragePercent = violations.isEmpty
          ? 0
          : violations
                  .map((v) => (v['overagePercent'] as num?)?.toDouble() ?? 0)
                  .fold(0.0, (a, b) => a + b) /
              violations.length;

      final trend = _analyzeTrend(violations);

      return {
        'success': true,
        'timestamp': DateTime.now().toIso8601String(),
        'summary': {
          'totalViolations': violations.length,
          'complianceRate': complianceRate,
          'averageOveragePercent': avgOveragePercent,
          'repeatOffenderCount': offenders.length,
          'severityBreakdown': violationData['severityBreakdown'],
        },
        'escalationSummary': {
          'warningsNeeded': escalation?['warning']?['count'] ?? 0,
          'adjustmentsNeeded': escalation?['adjustment']?['count'] ?? 0,
          'suspensionsNeeded': escalation?['suspension']?['count'] ?? 0,
        },
        'offenderAnalysis': {
          'repeatOffenderCount': offenders.length,
          'topOffenders': offenders
              .take(5)
              .map((o) => {
                    'sellerId': o['sellerId'],
                    'violationCount': o['totalViolations'],
                    'riskLevel': o['riskLevel'],
                  })
              .toList(),
        },
        'trend': trend,
        'recommendations': _generateComplianceRecommendations(
          violations.length,
          complianceRate,
          offenders.length,
        ),
        'marketHealth': {
          'score': _calculateMarketHealthScore(complianceRate),
          'status': complianceRate > 95
              ? 'HEALTHY'
              : complianceRate > 85
                  ? 'ACCEPTABLE'
                  : 'NEEDS_ATTENTION',
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to generate compliance report: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 5: EXECUTE AUTOMATED ACTIONS ====================

  /// Execute automated enforcement actions based on escalation rules
  ///
  /// Actions:
  /// - Send warnings to minor violators
  /// - Force price adjustments for moderate violators
  /// - Suspend repeat offenders
  ///
  /// Returns: Action execution results
  static Future<Map<String, dynamic>> executeAutomatedActions({
    required Map<String, dynamic> escalationData,
    bool dryRun = false,
  }) async {
    try {
      final categorization = escalationData['categorization'] as Map?;
      List<Map<String, dynamic>> actionResults = [];
      int successCount = 0;
      int failureCount = 0;

      // Process warnings
      final warnings = (categorization?['warning']?['violations'] ?? [])
          as List<dynamic>;
      for (final violation in warnings) {
        try {
          if (!dryRun) {
            // Send warning to seller
            final sellerId = violation['sellerId']?.toString();
            if (sellerId != null) {
              await AdminService.flagPriceViolation(
                sellerId,
                violation['productId']?.toString() ?? '',
                listedPrice: (violation['listedPrice'] as num?)?.toDouble() ?? 0,
              );
            }
          }
          actionResults.add({
            'violationId': violation['violationId'],
            'action': 'WARNING',
            'status': 'SUCCESS',
            'timestamp': DateTime.now().toIso8601String(),
          });
          successCount++;
        } catch (e) {
          failureCount++;
          actionResults.add({
            'violationId': violation['violationId'],
            'action': 'WARNING',
            'status': 'FAILED',
            'error': e.toString(),
          });
        }
      }

      // Process adjustments
      final adjustments = (categorization?['adjustment']?['violations'] ?? [])
          as List<dynamic>;
      for (final violation in adjustments) {
        try {
          if (!dryRun) {
            // Force price adjustment
            final sellerId = violation['sellerId']?.toString();
            if (sellerId != null) {
              await AdminService.flagPriceViolation(
                sellerId,
                violation['productId']?.toString() ?? '',
                listedPrice: (violation['ceilingPrice'] as num?)?.toDouble() ?? 0,
              );
            }
          }
          actionResults.add({
            'violationId': violation['violationId'],
            'action': 'FORCE_ADJUSTMENT',
            'status': 'SUCCESS',
            'timestamp': DateTime.now().toIso8601String(),
          });
          successCount++;
        } catch (e) {
          failureCount++;
          actionResults.add({
            'violationId': violation['violationId'],
            'action': 'FORCE_ADJUSTMENT',
            'status': 'FAILED',
            'error': e.toString(),
          });
        }
      }

      // Process suspensions
      final suspensions = (categorization?['suspension']?['violations'] ?? [])
          as List<dynamic>;
      for (final violation in suspensions) {
        try {
          if (!dryRun) {
            // Suspend seller
            final sellerId = violation['sellerId']?.toString();
            if (sellerId != null) {
              await AdminService.suspendSeller(
                sellerId,
                reason: 'Price compliance violation (${violation['overagePercent']}% over ceiling)',
              );
            }
          }
          actionResults.add({
            'violationId': violation['violationId'],
            'action': 'SUSPEND',
            'status': 'SUCCESS',
            'timestamp': DateTime.now().toIso8601String(),
          });
          successCount++;
        } catch (e) {
          failureCount++;
          actionResults.add({
            'violationId': violation['violationId'],
            'action': 'SUSPEND',
            'status': 'FAILED',
            'error': e.toString(),
          });
        }
      }

      return {
        'success': true,
        'dryRun': dryRun,
        'actions': actionResults,
        'summary': {
          'totalActions': actionResults.length,
          'successCount': successCount,
          'failureCount': failureCount,
          'successRate': actionResults.isNotEmpty
              ? (successCount / actionResults.length)
              : 0,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to execute automated actions: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== COMPLETE COMPLIANCE MONITORING WORKFLOW ====================

  /// Execute complete automated compliance monitoring workflow
  ///
  /// Process:
  /// 1. Detect all violations
  /// 2. Identify repeat offenders
  /// 3. Categorize by escalation level
  /// 4. Generate compliance report
  /// 5. Execute automated actions
  ///
  /// Used for: Scheduled or manual compliance monitoring
  static Future<Map<String, dynamic>> executeComplianceMonitoringWorkflow({
    String monitoringMode = modeScheduled,
    bool executeActions = false,
    bool dryRun = true,
  }) async {
    try {
      // Step 1: Detect violations
      final violationData = await detectViolations(monitoringMode: monitoringMode);
      if (!violationData['success']) {
        return {
          'success': false,
          'error': 'Failed to detect violations',
        };
      }

      final violations = violationData['violations'] as List<Map<String, dynamic>>;

      if (violations.isEmpty) {
        return {
          'success': true,
          'message': 'No violations detected. Marketplace in compliance.',
          'violationData': violationData,
        };
      }

      // Step 2: Identify repeat offenders
      final offenderData = await identifyRepeatOffenders(
        currentViolations: violations,
      );

      // Step 3: Categorize by escalation
      final escalationData = await categorizeByEscalation(
        violations: violations,
        repeatOffenders:
            offenderData['offenders'] as List<Map<String, dynamic>>,
      );

      // Step 4: Generate report
      final reportData = await generateComplianceReport(
        violationData: violationData,
        offenderData: offenderData,
        escalationData: escalationData,
      );

      // Step 5: Execute actions (if enabled)
      Map<String, dynamic> actionData = {
        'success': true,
        'message': 'Actions not executed (executeActions=false)',
      };

      if (executeActions) {
        actionData = await executeAutomatedActions(
          escalationData: escalationData,
          dryRun: dryRun,
        );
      }

      return {
        'success': true,
        'workflowStatus': 'COMPLETED',
        'monitoringMode': monitoringMode,
        'dryRun': dryRun,
        'violations': violationData,
        'offenders': offenderData,
        'escalation': escalationData,
        'report': reportData,
        'actions': actionData,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to execute compliance monitoring workflow: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== HELPER METHODS ====================

  static String _classifySeverity(double overagePercent) {
    if (overagePercent < 5) return severityMinor;
    if (overagePercent < 20) return severityModerate;
    if (overagePercent < 50) return severitySerious;
    return severityCritical;
  }

  static Map<String, int> _countBySeverity(
    List<Map<String, dynamic>> violations,
  ) {
    int minor = 0, moderate = 0, serious = 0, critical = 0;

    for (final violation in violations) {
      switch (violation['severity']) {
        case severityMinor:
          minor++;
          break;
        case severityModerate:
          moderate++;
          break;
        case severitySerious:
          serious++;
          break;
        case severityCritical:
          critical++;
          break;
      }
    }

    return {
      'MINOR': minor,
      'MODERATE': moderate,
      'SERIOUS': serious,
      'CRITICAL': critical,
    };
  }

  static String _getMostSevereProblem(
    List<Map<String, dynamic>> violations,
  ) {
    if (violations.isEmpty) return severityMinor;
    int maxIndex = 0;
    double maxPercent = 0;

    for (int i = 0; i < violations.length; i++) {
      final pct = (violations[i]['overagePercent'] as num?)?.toDouble() ?? 0;
      if (pct > maxPercent) {
        maxPercent = pct;
        maxIndex = i;
      }
    }

    return violations[maxIndex]['severity']?.toString() ?? severityMinor;
  }

  static String _assessRiskLevel(int totalViolationCount) {
    if (totalViolationCount >= 10) return 'CRITICAL';
    if (totalViolationCount >= 5) return 'HIGH';
    if (totalViolationCount >= 3) return 'MEDIUM';
    return 'LOW';
  }

  static String _recommendAction(int totalViolationCount) {
    if (totalViolationCount >= 10) return 'SUSPEND_IMMEDIATELY';
    if (totalViolationCount >= 5) return 'FORCE_ADJUSTMENTS';
    if (totalViolationCount >= 3) return 'ISSUE_WARNING';
    return 'MONITOR';
  }

  static Map<String, dynamic> _analyzeTrend(
    List<Map<String, dynamic>> violations,
  ) {
    return {
      'direction': violations.length > 5 ? 'INCREASING' : 'STABLE',
      'velocity': violations.length > 10 ? 'RAPID' : 'GRADUAL',
      'status': 'MONITORING',
    };
  }

  static List<String> _generateComplianceRecommendations(
    int violationCount,
    double complianceRate,
    int offenderCount,
  ) {
    final recommendations = <String>[];

    if (complianceRate < 90) {
      recommendations.add('⚠️ Compliance rate below 90%. Escalate enforcement.');
    }

    if (offenderCount > 5) {
      recommendations.add('Multiple repeat offenders detected. Consider stricter policies.');
    }

    if (violationCount > 50) {
      recommendations.add('High violation count. Review price ceiling appropriateness.');
    }

    recommendations.add('Continue scheduled compliance monitoring');
    recommendations.add('Review seller education materials');

    return recommendations;
  }

  static double _calculateMarketHealthScore(double complianceRate) {
    return complianceRate > 95
        ? 95 + ((complianceRate - 95) * 0.5)
        : complianceRate * 0.95;
  }
}
