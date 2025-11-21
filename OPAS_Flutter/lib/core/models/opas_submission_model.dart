// OPAS Submission Model - Represents seller's "Sell to OPAS" offer
// Includes submission details, quality assessment, and approval tracking

import 'package:flutter/material.dart';

class OPASSubmissionModel {
  final int id;
  final int sellerId;
  final String sellerName;
  final int productId;
  final String productName;
  final String productCategory;
  final double quantity; // kg/units
  final String unit; // kg, liter, piece, etc.
  final double offeredPrice; // Per unit
  final String qualityGrade; // A, B, C, Grade 1, Grade 2, etc.
  final String description; // Condition, notes about product
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime submittedAt;
  final DateTime? approvedAt;
  final String? approvalNotes;
  final double? quantityAccepted;
  final double? finalPrice; // Final negotiated price per unit
  final String? deliveryTerms; // Pickup, delivery, etc.
  final String? purchaseOrderId; // Generated on approval
  final int? violationCount; // Number of times seller exceeded quality standards

  OPASSubmissionModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.quantity,
    required this.unit,
    required this.offeredPrice,
    required this.qualityGrade,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.approvedAt,
    this.approvalNotes,
    this.quantityAccepted,
    this.finalPrice,
    this.deliveryTerms,
    this.purchaseOrderId,
    this.violationCount,
  });

  /// Create OPASSubmissionModel from JSON
  factory OPASSubmissionModel.fromJson(Map<String, dynamic> json) {
    return OPASSubmissionModel(
      id: json['id'] as int? ?? 0,
      sellerId: json['seller_id'] as int? ?? 0,
      sellerName: json['seller_name'] as String? ?? 'Unknown',
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      productCategory: json['product_category'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
      offeredPrice: (json['offered_price'] as num?)?.toDouble() ?? 0.0,
      qualityGrade: json['quality_grade'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvalNotes: json['approval_notes'] as String?,
      quantityAccepted: (json['quantity_accepted'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      deliveryTerms: json['delivery_terms'] as String?,
      purchaseOrderId: json['purchase_order_id'] as String?,
      violationCount: json['violation_count'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'quantity': quantity,
      'unit': unit,
      'offered_price': offeredPrice,
      'quality_grade': qualityGrade,
      'description': description,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approval_notes': approvalNotes,
      'quantity_accepted': quantityAccepted,
      'final_price': finalPrice,
      'delivery_terms': deliveryTerms,
      'purchase_order_id': purchaseOrderId,
      'violation_count': violationCount,
    };
  }

  /// Get status color for UI
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFC107); // Amber
      case 'APPROVED':
        return const Color(0xFF4CAF50); // Green
      case 'REJECTED':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Format offered price
  String formatOfferedPrice() {
    return 'PKR ${offeredPrice.toStringAsFixed(2)}/$unit';
  }

  /// Format final price (if approved)
  String formatFinalPrice() {
    if (finalPrice == null) return 'N/A';
    return 'PKR ${finalPrice!.toStringAsFixed(2)}/$unit';
  }

  /// Calculate total offered value
  double getTotalOfferedValue() {
    return quantity * offeredPrice;
  }

  /// Calculate total final value (if approved)
  double? getTotalFinalValue() {
    if (quantityAccepted == null || finalPrice == null) return null;
    return quantityAccepted! * finalPrice!;
  }

  /// Get days since submission
  int getDaysSinceSubmission() {
    return DateTime.now().difference(submittedAt).inDays;
  }

  /// Check if submission is pending review
  bool isPending() => status.toUpperCase() == 'PENDING';


  /// Check if submission is approved
  bool isApproved() => status.toUpperCase() == 'APPROVED';

  /// Check if submission is rejected
  bool isRejected() => status.toUpperCase() == 'REJECTED';
}
