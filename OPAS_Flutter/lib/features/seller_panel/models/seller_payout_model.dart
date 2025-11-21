/// Payout Model for Seller
/// Represents payout and transaction history for sellers
class SellerPayout {
  final int id;
  final int sellerId;
  final double amount;
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED
  final String paymentMethod; // BANK_TRANSFER, CHECK, WALLET
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final int orderCount;
  final double totalEarnings;
  final double deductions;
  final DateTime periodStart;
  final DateTime periodEnd;

  SellerPayout({
    required this.id,
    required this.sellerId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.failureReason,
    required this.orderCount,
    required this.totalEarnings,
    required this.deductions,
    required this.periodStart,
    required this.periodEnd,
  });

  factory SellerPayout.fromJson(Map<String, dynamic> json) {
    return SellerPayout(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['payment_method'] ?? 'BANK_TRANSFER',
      transactionId: json['transaction_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      failureReason: json['failure_reason'] as String?,
      orderCount: json['order_count'] ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : DateTime.now(),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'amount': amount,
    'status': status,
    'payment_method': paymentMethod,
    'transaction_id': transactionId,
    'created_at': createdAt.toIso8601String(),
    'processed_at': processedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'failure_reason': failureReason,
    'order_count': orderCount,
    'total_earnings': totalEarnings,
    'deductions': deductions,
    'period_start': periodStart.toIso8601String(),
    'period_end': periodEnd.toIso8601String(),
  };

  bool get isPending => status == 'PENDING';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get canRetry => status == 'FAILED';
  double get netEarnings => totalEarnings - deductions;
  double get deductionPercentage => (deductions / totalEarnings * 100);
  int get daysInPeriod => periodEnd.difference(periodStart).inDays;
  double get avgEarningsPerDay => totalEarnings / (daysInPeriod + 1);
}
