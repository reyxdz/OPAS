// Marketplace Alert Model - Represents alerts requiring admin attention
// Tracks price violations, seller issues, unusual activity, compliance problems

import 'package:flutter/material.dart';

class MarketplaceAlertModel {
  final int id;
  final String alertCategory;
  final String alertType;
  final String severity;
  final String status;
  final String title;
  final String description;
  final int? affectedListingId;
  final String? affectedListingName;
  final int? sellerId;
  final String? sellerName;
  final String? reason;
  final String? recommendedAction;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;
  final int? escalationLevel;
  final bool requiresEscalation;
  final Map<String, dynamic>? metadata;

  MarketplaceAlertModel({
    required this.id,
    required this.alertCategory,
    required this.alertType,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    this.affectedListingId,
    this.affectedListingName,
    this.sellerId,
    this.sellerName,
    this.reason,
    this.recommendedAction,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    this.escalationLevel,
    required this.requiresEscalation,
    this.metadata,
  });

  factory MarketplaceAlertModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceAlertModel(
      id: json['id'] as int? ?? 0,
      alertCategory: json['alert_category'] as String? ?? 'OTHER',
      alertType: json['alert_type'] as String? ?? 'UNKNOWN',
      severity: json['severity'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'ACTIVE',
      title: json['title'] as String? ?? 'Untitled Alert',
      description: json['description'] as String? ?? '',
      affectedListingId: json['affected_listing_id'] as int?,
      affectedListingName: json['affected_listing_name'] as String?,
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      reason: json['reason'] as String?,
      recommendedAction: json['recommended_action'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      escalationLevel: json['escalation_level'] as int?,
      requiresEscalation: json['requires_escalation'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alert_category': alertCategory,
      'alert_type': alertType,
      'severity': severity,
      'status': status,
      'title': title,
      'description': description,
      'affected_listing_id': affectedListingId,
      'affected_listing_name': affectedListingName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'reason': reason,
      'recommended_action': recommendedAction,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolution_notes': resolutionNotes,
      'escalation_level': escalationLevel,
      'requires_escalation': requiresEscalation,
      'metadata': metadata,
    };
  }

  bool isResolved() => status.toUpperCase() == 'RESOLVED';
  bool isActive() => status.toUpperCase() == 'ACTIVE';
  bool isAcknowledged() => status.toUpperCase() == 'ACKNOWLEDGED';

  Color getSeverityColor() {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color.fromARGB(255, 244, 67, 54); // Deep red
      case 'HIGH':
        return const Color.fromARGB(255, 244, 67, 54); // Red
      case 'MEDIUM':
        return const Color.fromARGB(255, 255, 193, 7); // Amber
      case 'LOW':
        return const Color.fromARGB(255, 76, 175, 80); // Green
      default:
        return const Color.fromARGB(255, 33, 150, 243); // Blue
    }
  }

  String getSeverityIcon() {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return '🚨';
      case 'HIGH':
        return '⚠️';
      case 'MEDIUM':
        return '⚡';
      case 'LOW':
        return 'ℹ️';
      default:
        return '📌';
    }
  }

  String getCategoryLabel() {
    switch (alertCategory.toUpperCase()) {
      case 'PRICE_VIOLATION':
        return 'Price Violation';
      case 'SELLER_ISSUE':
        return 'Seller Issue';
      case 'UNUSUAL_ACTIVITY':
        return 'Unusual Activity';
      case 'COMPLIANCE':
        return 'Compliance';
      case 'FRAUD_DETECTION':
        return 'Fraud Detection';
      case 'INVENTORY':
        return 'Inventory Issue';
      case 'QUALITY':
        return 'Quality Issue';
      default:
        return 'Other';
    }
  }

  String getStatusLabel() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      case 'RESOLVED':
        return 'Resolved';
      case 'ESCALATED':
        return 'Escalated';
      default:
        return 'Unknown';
    }
  }

  String getDaysOld() => DateTime.now().difference(createdAt).inDays.toString();

  String formatCreatedAt() {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
