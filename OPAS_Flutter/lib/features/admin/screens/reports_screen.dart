import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/report_model.dart';
import 'package:opas_flutter/features/admin/widgets/report_card.dart';
import 'package:opas_flutter/features/admin/widgets/alert_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ReportModel>> _reportsFuture;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String _selectedReportType = 'sales_summary';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedFromDate = DateTime.now().subtract(const Duration(days: 30));
    _selectedToDate = DateTime.now();
    _reportsFuture = _fetchReports();
  }

  Future<List<ReportModel>> _fetchReports() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      return [
        ReportModel(
          reportId: 'R001',
          reportName: 'Sales Summary - December 2024',
          reportType: 'sales_summary',
          dateFrom: DateTime.now().subtract(const Duration(days: 30)),
          dateTo: DateTime.now(),
          metrics: {
            'total_sales': 2500000,
            'orders': 450,
            'unique_customers': 3200,
            'avg_order_value': 5556,
          },
          status: 'completed',
          generatedAt: DateTime.now().subtract(const Duration(days: 2)),
          exportFormats: ['PDF', 'CSV', 'Excel'],
        ),
        ReportModel(
          reportId: 'R002',
          reportName: 'OPAS Purchases - Last Quarter',
          reportType: 'opas_purchases',
          dateFrom: DateTime.now().subtract(const Duration(days: 90)),
          dateTo: DateTime.now(),
          metrics: {
            'total_purchases': 1850000,
            'units_sold': 12500,
            'num_transactions': 280,
            'avg_transaction': 6607,
          },
          status: 'completed',
          generatedAt: DateTime.now().subtract(const Duration(days: 5)),
          exportFormats: ['PDF', 'CSV'],
        ),
        ReportModel(
          reportId: 'R003',
          reportName: 'Seller Participation Metrics',
          reportType: 'seller_participation',
          dateFrom: DateTime.now().subtract(const Duration(days: 60)),
          dateTo: DateTime.now(),
          metrics: {
            'active_sellers': 1180,
            'new_sellers': 45,
            'seller_retention': 92.5,
            'avg_listings': 145,
          },
          status: 'completed',
          generatedAt: DateTime.now().subtract(const Duration(days: 1)),
          exportFormats: ['PDF', 'CSV', 'Excel'],
        ),
        ReportModel(
          reportId: 'R004',
          reportName: 'Market Impact Analysis',
          reportType: 'market_impact',
          dateFrom: DateTime.now().subtract(const Duration(days: 45)),
          dateTo: DateTime.now(),
          metrics: {
            'price_compliance': 96.8,
            'market_health': 8.7,
            'violations_count': 8,
            'alerts_triggered': 12,
          },
          status: 'processing',
          exportFormats: ['PDF'],
        ),
        ReportModel(
          reportId: 'R005',
          reportName: 'Custom Report - Electronics Category',
          reportType: 'custom',
          dateFrom: DateTime.now().subtract(const Duration(days: 30)),
          dateTo: DateTime.now(),
          metrics: {},
          status: 'pending',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to load reports: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available Reports'),
            Tab(text: 'Generate Custom'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {
          _reportsFuture = _fetchReports();
        }),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailableReportsTab(),
            _buildGenerateCustomTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableReportsTab() {
    return FutureBuilder<List<ReportModel>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AlertWidget(
              title: 'Error',
              message: 'Failed to load reports',
              severity: 'critical',
              icon: Icons.error,
            ),
          );
        }

        final reports = snapshot.data ?? [];
        final completedReports = reports.where((r) => r.status == 'completed').toList();
        final processingReports = reports.where((r) => r.status == 'processing').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (processingReports.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...processingReports.map((report) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ReportCard(
                            reportName: report.reportName,
                            reportType: report.reportType,
                            dateRange:
                                '${DateFormat('MMM dd').format(report.dateFrom)} - ${DateFormat('MMM dd').format(report.dateTo)}',
                            status: report.status,
                            metricsCount: report.metrics.length,
                            generatedAt: report.generatedAt,
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                ),
              Text(
                'Completed Reports',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              if (completedReports.isEmpty)
                const AlertWidget(
                  title: 'No Reports',
                  message: 'No completed reports available',
                  severity: 'info',
                  icon: Icons.info,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = completedReports[index];
                    return ReportCard(
                      reportName: report.reportName,
                      reportType: report.reportType,
                      dateRange:
                          '${DateFormat('MMM dd').format(report.dateFrom)} - ${DateFormat('MMM dd').format(report.dateTo)}',
                      status: report.status,
                      metricsCount: report.metrics.length,
                      generatedAt: report.generatedAt,
                      onTap: () => _showReportDetails(report),
                      onDownload: () => _downloadReport(report),
                      onShare: () => _shareReport(report),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenerateCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Custom Report',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Report Type Selection
          Text(
            'Report Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildReportTypeOption('Sales Summary', 'sales_summary',
                  'Overview of all sales transactions'),
              _buildReportTypeOption('OPAS Purchases', 'opas_purchases',
                  'OPAS program purchase details'),
              _buildReportTypeOption('Seller Participation', 'seller_participation',
                  'Seller activity and metrics'),
              _buildReportTypeOption('Market Impact', 'market_impact',
                  'Market health and compliance'),
            ],
          ),
          const SizedBox(height: 24),

          // Date Range Selection
          Text(
            'Date Range',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectFromDate,
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(_selectedFromDate!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectToDate,
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(_selectedToDate!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Export Format Selection
          Text(
            'Export Format',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['PDF', 'CSV', 'Excel'].map((format) {
              return FilterChip(
                label: Text(format),
                onSelected: (selected) {},
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.download),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scheduleReport,
              icon: const Icon(Icons.schedule),
              label: const Text('Schedule Report'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2196F3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReportTypeOption(
    String title,
    String value,
    String description,
  ) {
    final isSelected = _selectedReportType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReportType = value;
        });
      },
      child: Card(
        elevation: isSelected ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            width: 2,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate!,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedFromDate) {
      setState(() {
        _selectedFromDate = picked;
      });
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedToDate!,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedToDate) {
      setState(() {
        _selectedToDate = picked;
      });
    }
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report generation started'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _scheduleReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule options coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showReportDetails(ReportModel report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.reportName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...report.metrics.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _downloadReport(ReportModel report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${report.reportName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareReport(ReportModel report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${report.reportName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
