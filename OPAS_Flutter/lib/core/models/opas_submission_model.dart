// OPAS Submission Model - Represents seller's "Sell to OPAS" offer
// Includes submission details, quality assessment, and approval tracking

import 'package:flutter/material.dart';

class OPASSubmissionModel {
  final int id;
  final int? opasOrderId; // OPASPurchaseOrder ID for marking delivery
  final int sellerId;
  final String sellerName;
  final String? sellerAddress;
  final int productId;
  final String productName;
  final String productCategory;
  final double quantity; // kg/units
  final String unit; // kg, liter, piece, etc.
  final double offeredPrice; // Per unit
  final String qualityGrade; // A, B, C, Grade 1, Grade 2, etc.
  final String description; // Condition, notes about product
  final String status; // PENDING, ACCEPTED, APPROVED, REJECTED
  final DateTime submittedAt;
  final DateTime? approvedAt;
  final String? approvalNotes;
  final double? quantityAccepted;
  final double? finalPrice; // Final negotiated price per unit
  final String? deliveryTerms; // Pickup, delivery, etc.
  final String? purchaseOrderId; // Generated on approval
  final int? violationCount; // Number of times seller exceeded quality standards
  final List<String> imageUrls; // URLs to product images
  final List<String> deliveryProofUrls; // URLs to delivery proof images

  OPASSubmissionModel({
    required this.id,
    this.opasOrderId,
    required this.sellerId,
    required this.sellerName,
    this.sellerAddress,
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
    this.imageUrls = const [],
    this.deliveryProofUrls = const [],
  });

  /// Create OPASSubmissionModel from JSON
  factory OPASSubmissionModel.fromJson(Map<String, dynamic> json) {
    // Parse image URLs - can be a list of strings or a list of objects with 'image' field
    List<String> imageUrls = [];
    try {
      if (json['images'] != null && json['images'] is List) {
        final images = json['images'] as List;
        imageUrls = images.map((img) {
          if (img is String) return img;
          if (img is Map && img.containsKey('image')) return img['image'].toString();
          return '';
        }).where((url) => url.isNotEmpty).toList();
      }
    } catch (e) {
      // If parsing images fails, just use empty list
      imageUrls = [];
    }

    // Parse delivery proof images
    List<String> deliveryProofUrls = [];
    try {
      if (json['delivery_proof_images'] != null && json['delivery_proof_images'] is List) {
        final proofImages = json['delivery_proof_images'] as List;
        deliveryProofUrls = proofImages.map((img) {
          if (img is String) return img;
          if (img is Map && img.containsKey('image')) return img['image'].toString();
          return '';
        }).where((url) => url.isNotEmpty).toList();
      }
    } catch (e) {
      // If parsing delivery proof images fails, just use empty list
      deliveryProofUrls = [];
    }

    return OPASSubmissionModel(
      id: json['id'] as int? ?? 0,
      opasOrderId: json['purchase_order_id'] as int?,
      sellerId: json['seller'] as int? ?? 0,
      sellerName: json['seller_name'] as String? ?? 'Unknown',
      sellerAddress: json['seller_address'] as String?,
      productId: json['product'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      productCategory: json['product_type'] as String? ?? 'Unknown',
      quantity: _parseDouble(json['quantity_offered']) ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
      offeredPrice: _parseDouble(json['offered_price']) ?? 0.0,
      qualityGrade: json['quality_grade'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      submittedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      approvedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      approvalNotes: json['rejection_reason'] as String?,
      quantityAccepted: _parseDouble(json['approved_quantity']),
      finalPrice: _parseDouble(json['final_price']),
      deliveryTerms: json['delivery_terms'] as String?,
      purchaseOrderId: json['submission_number'] as String?,
      violationCount: null,
      imageUrls: imageUrls,
      deliveryProofUrls: deliveryProofUrls,
    );
  }
  
  /// Helper to parse double from either num or string
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
      'images': imageUrls,
      'delivery_proof_images': deliveryProofUrls,
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
  bool isApproved() => status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'ACCEPTED';

  /// Check if submission is rejected
  bool isRejected() => status.toUpperCase() == 'REJECTED';

  /// Get image URLs safely (never null)
  List<String> getImageUrls() {
    return imageUrls ?? [];
  }
}
