// OPAS Purchase History Model - Represents completed OPAS transactions
// Tracks all purchase orders, payments, and stock movements

import 'package:flutter/material.dart';

class OPASPurchaseHistoryModel {
  final int id;
  final int sellerId;
  final String sellerName;
  final int productId;
  final String productName;
  final String productCategory;
  final double quantity; // Quantity purchased
  final String unit; // kg, liter, piece, etc.
  final double unitPrice; // Price per unit
  final double totalAmount; // Total cost (quantity * unitPrice)
  final DateTime purchaseDate;
  final DateTime? deliveryDate;
  final String status; // PENDING, COMPLETED, CANCELLED
  final String paymentStatus; // PENDING, PAID, REFUNDED
  final String? purchaseOrderId; // Reference to PO
  final String? invoiceNumber; // Generated invoice
  final String? qualityGrade; // A, B, C
  final String? notes; // Transaction notes
  final String? deliveryLocation; // Where delivered
  final double? discount; // Applied discount
  final double? tax; // Applied tax

  OPASPurchaseHistoryModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalAmount,
    required this.purchaseDate,
    this.deliveryDate,
    required this.status,
    required this.paymentStatus,
    this.purchaseOrderId,
    this.invoiceNumber,
    this.qualityGrade,
    this.notes,
    this.deliveryLocation,
    this.discount,
    this.tax,
  });

  /// Create OPASPurchaseHistoryModel from JSON
  factory OPASPurchaseHistoryModel.fromJson(Map<String, dynamic> json) {
    return OPASPurchaseHistoryModel(
      id: json['id'] as int? ?? 0,
      sellerId: json['seller_id'] as int? ?? 0,
      sellerName: json['seller_name'] as String? ?? 'Unknown',
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      productCategory: json['product_category'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : DateTime.now(),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      status: json['status'] as String? ?? 'PENDING',
      paymentStatus: json['payment_status'] as String? ?? 'PENDING',
      purchaseOrderId: json['purchase_order_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      qualityGrade: json['quality_grade'] as String?,
      notes: json['notes'] as String?,
      deliveryLocation: json['delivery_location'] as String?,
      discount: (json['discount'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
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
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'purchase_date': purchaseDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'status': status,
      'payment_status': paymentStatus,
      'purchase_order_id': purchaseOrderId,
      'invoice_number': invoiceNumber,
      'quality_grade': qualityGrade,
      'notes': notes,
      'delivery_location': deliveryLocation,
      'discount': discount,
      'tax': tax,
    };
  }

  /// Get status color for UI
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFC107); // Amber
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // Green
      case 'CANCELLED':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get payment status color
  Color getPaymentStatusColor() {
    switch (paymentStatus.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFC107); // Amber
      case 'PAID':
        return const Color(0xFF4CAF50); // Green
      case 'REFUNDED':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Format unit price
  String formatUnitPrice() {
    return 'PKR ${unitPrice.toStringAsFixed(2)}/$unit';
  }

  /// Format total amount
  String formatTotalAmount() {
    return 'PKR ${totalAmount.toStringAsFixed(2)}';
  }

  /// Get days since purchase
  int getDaysSincePurchase() {
    return DateTime.now().difference(purchaseDate).inDays;
  }

  /// Check if pending
  bool isPending() => status.toUpperCase() == 'PENDING';

  /// Check if completed
  bool isCompleted() => status.toUpperCase() == 'COMPLETED';

  /// Check if cancelled
  bool isCancelled() => status.toUpperCase() == 'CANCELLED';

  /// Check if paid
  bool isPaid() => paymentStatus.toUpperCase() == 'PAID';

  /// Calculate final amount after discount and tax
  double calculateFinalAmount() {
    double amount = totalAmount;
    if (discount != null) amount -= discount!;
    if (tax != null) amount += tax!;
    return amount;
  }

  /// Format final amount
  String formatFinalAmount() {
    return 'PKR ${calculateFinalAmount().toStringAsFixed(2)}';
  }
}
