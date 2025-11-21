// Seller model for admin panel
import 'package:flutter/material.dart';

class SellerModel {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? address;
  final String storeName;
  final String? storeDescription;
  final String status; // PENDING, APPROVED, SUSPENDED
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final bool documentVerified;

  SellerModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.address,
    required this.storeName,
    this.storeDescription,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.suspensionReason,
    this.suspendedAt,
    required this.documentVerified,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'],
      storeName: json['store_name'] ?? '',
      storeDescription: json['store_description'],
      status: json['seller_status'] ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['seller_approval_date'] != null 
          ? DateTime.parse(json['seller_approval_date']) 
          : null,
      suspensionReason: json['suspension_reason'],
      suspendedAt: json['suspended_at'] != null 
          ? DateTime.parse(json['suspended_at']) 
          : null,
      documentVerified: json['seller_documents_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone_number': phoneNumber,
    'address': address,
    'store_name': storeName,
    'store_description': storeDescription,
    'seller_status': status,
    'created_at': createdAt.toIso8601String(),
    'seller_approval_date': approvedAt?.toIso8601String(),
    'suspension_reason': suspensionReason,
    'suspended_at': suspendedAt?.toIso8601String(),
    'seller_documents_verified': documentVerified,
  };

  /// Get status badge color
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'SUSPENDED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get status display text
  String getStatusDisplay() {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'SUSPENDED':
        return 'Suspended';
      case 'PENDING':
        return 'Pending Approval';
      default:
        return status;
    }
  }
}
