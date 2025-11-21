// Report Model - Pre-built and custom reports
class ReportModel {
  final String reportId;
  final String reportName;
  final String reportType;
  final DateTime dateFrom;
  final DateTime dateTo;
  final Map<String, dynamic> metrics;
  final String status;
  final DateTime? generatedAt;
  final List<String>? exportFormats;

  ReportModel({
    required this.reportId,
    required this.reportName,
    required this.reportType,
    required this.dateFrom,
    required this.dateTo,
    required this.metrics,
    required this.status,
    this.generatedAt,
    this.exportFormats,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id'] as String? ?? '',
      reportName: json['report_name'] as String? ?? 'Untitled Report',
      reportType: json['report_type'] as String? ?? 'custom',
      dateFrom: json['date_from'] != null
          ? DateTime.parse(json['date_from'] as String)
          : DateTime.now().subtract(const Duration(days: 30)),
      dateTo: json['date_to'] != null
          ? DateTime.parse(json['date_to'] as String)
          : DateTime.now(),
      metrics: (json['metrics'] as Map<String, dynamic>?) ?? {},
      status: json['status'] as String? ?? 'pending',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : null,
      exportFormats: json['export_formats'] != null
          ? List<String>.from(json['export_formats'] as List)
          : ['PDF', 'CSV'],
    );
  }

  String getStatusBadgeColor() {
    if (status == 'completed') return '#4CAF50';
    if (status == 'processing') return '#2196F3';
    if (status == 'failed') return '#F44336';
    return '#9E9E9E';
  }

  String getReportTypeLabel() {
    switch (reportType) {
      case 'sales_summary':
        return 'Sales Summary';
      case 'opas_purchases':
        return 'OPAS Purchases';
      case 'seller_participation':
        return 'Seller Participation';
      case 'market_impact':
        return 'Market Impact';
      default:
        return 'Custom Report';
    }
  }

  bool isReady() => status == 'completed';
}
