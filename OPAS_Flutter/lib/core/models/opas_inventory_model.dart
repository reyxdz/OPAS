// OPAS Inventory Model - Represents OPAS stock management
// Tracks product inventory with storage, expiry, and stock status

import 'package:flutter/material.dart';

class OPASInventoryModel {
  final int id;
  final int productId;
  final String productName;
  final String productCategory;
  final double quantity; // Current quantity in stock
  final String unit; // kg, liter, piece, etc.
  final double quantityIn; // Total quantity received
  final double quantityOut; // Total quantity used/sold
  final String storageLocation; // Warehouse section/address
  final DateTime inDate; // Date product entered storage
  final DateTime expiryDate; // Expiry/best-before date
  final String status; // OK, LOW_STOCK, EXPIRING, EXPIRED
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String batchNumber; // For traceability
  final int? supplierId; // Seller who supplied this batch
  final String? supplierName;
  final double? costPerUnit; // What OPAS paid per unit
  final String? qualityGrade; // A, B, C, etc.
  final int? lowStockThreshold; // Alert when below this

  OPASInventoryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.quantity,
    required this.unit,
    required this.quantityIn,
    required this.quantityOut,
    required this.storageLocation,
    required this.inDate,
    required this.expiryDate,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    required this.batchNumber,
    this.supplierId,
    this.supplierName,
    this.costPerUnit,
    this.qualityGrade,
    this.lowStockThreshold,
  });

  /// Create OPASInventoryModel from JSON
  factory OPASInventoryModel.fromJson(Map<String, dynamic> json) {
    return OPASInventoryModel(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      productCategory: json['product_category'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
      quantityIn: (json['quantity_in'] as num?)?.toDouble() ?? 0.0,
      quantityOut: (json['quantity_out'] as num?)?.toDouble() ?? 0.0,
      storageLocation: json['storage_location'] as String? ?? 'Unknown',
      inDate: json['in_date'] != null
          ? DateTime.parse(json['in_date'] as String)
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      status: json['status'] as String? ?? 'OK',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      batchNumber: json['batch_number'] as String? ?? '',
      supplierId: json['supplier_id'] as int?,
      supplierName: json['supplier_name'] as String?,
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble(),
      qualityGrade: json['quality_grade'] as String?,
      lowStockThreshold: json['low_stock_threshold'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'quantity': quantity,
      'unit': unit,
      'quantity_in': quantityIn,
      'quantity_out': quantityOut,
      'storage_location': storageLocation,
      'in_date': inDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'batch_number': batchNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'cost_per_unit': costPerUnit,
      'quality_grade': qualityGrade,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  /// Get status color for UI
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'OK':
        return const Color(0xFF4CAF50); // Green
      case 'LOW_STOCK':
        return const Color(0xFFFFC107); // Amber
      case 'EXPIRING':
        return const Color(0xFFFF9800); // Orange
      case 'EXPIRED':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get status icon
  IconData getStatusIcon() {
    switch (status.toUpperCase()) {
      case 'OK':
        return Icons.check_circle;
      case 'LOW_STOCK':
        return Icons.warning;
      case 'EXPIRING':
        return Icons.schedule;
      case 'EXPIRED':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  /// Get status display text
  String getStatusDisplay() {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  /// Check if expired
  bool isExpired() {
    return DateTime.now().isAfter(expiryDate);
  }

  /// Check if expiring soon (within 7 days)
  bool isExpiringSoon() {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
  }

  /// Get days until expiry
  int getDaysUntilExpiry() {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// Check if low stock
  bool isLowStock() {
    if (lowStockThreshold == null) return false;
    return quantity < lowStockThreshold!;
  }

  /// Format quantity display
  String formatQuantity() {
    return '${quantity.toStringAsFixed(2)} $unit';
  }

  /// Format cost per unit
  String formatCostPerUnit() {
    if (costPerUnit == null) return 'N/A';
    return 'PKR ${costPerUnit!.toStringAsFixed(2)}/$unit';
  }

  /// Calculate total inventory value
  double? getTotalInventoryValue() {
    if (costPerUnit == null) return null;
    return quantity * costPerUnit!;
  }

  /// Get days in storage
  int getDaysInStorage() {
    return DateTime.now().difference(inDate).inDays;
  }
}
