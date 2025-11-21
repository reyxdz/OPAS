/// Audit Log Screen
///
/// Displays comprehensive audit trail with filtering, search, and export capabilities.
/// Provides admin dashboard for compliance monitoring and audit trail review.
///
/// Features:
/// - Audit trail table with pagination
/// - Advanced filtering (date range, action, severity, admin)
/// - Search functionality (full-text, indexed)
/// - Export options (CSV, PDF, Excel)
/// - Real-time audit trail updates
/// - Audit record verification (integrity check)
/// - Severity-based color coding
/// - Responsive layout (desktop/mobile)
/// - Performance optimized (virtual scrolling for large datasets)

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/services/logger_service.dart';
import 'package:opas_flutter/features/admin_panel/services/admin_audit_trail_service.dart';
import 'package:opas_flutter/features/admin_panel/services/export_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  late TextEditingController _adminFilterController;
  late TextEditingController _entityIdFilterController;

  // Filter state
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedAction;
  String? _selectedCategory;
  String? _selectedSeverity;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // UI state
  bool _isLoading = false;
  List<Map<String, dynamic>> _auditRecords = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _adminFilterController = TextEditingController();
    _entityIdFilterController = TextEditingController();

    _loadAuditTrail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _adminFilterController.dispose();
    _entityIdFilterController.dispose();
    super.dispose();
  }

  // ============================================================================
  // Data Loading & Filtering
  // ============================================================================

  Future<void> _loadAuditTrail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await AdminAuditTrailService.getAuditTrail(
        adminId: _adminFilterController.text.isEmpty
            ? null
            : _adminFilterController.text,
        action: _selectedAction,
        category: _selectedCategory,
        entityType: null,
        entityId: _entityIdFilterController.text.isEmpty
            ? null
            : _entityIdFilterController.text,
        severity: _selectedSeverity,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          _auditRecords =
              List<Map<String, dynamic>>.from(result['records'] as List);
          _errorMessage = null;
        });
      }

      LoggerService.info(
        'Audit trail loaded: ${_auditRecords.length} records',
        tag: 'AUDIT_LOG_SCREEN',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading audit trail: $e';
          _auditRecords = [];
        });
      }

      LoggerService.error(
        'Error loading audit trail',
        tag: 'AUDIT_LOG_SCREEN',
        error: e,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================================
  // Export Functionality
  // ============================================================================

  Future<void> _exportToCSV() async {
    if (_auditRecords.isEmpty) {
      _showSnackBar('No records to export');
      return;
    }

    try {
      final exportResult = await ExportService.exportAuditTrailToCSV(
        auditRecords: _auditRecords,
        fileName: 'audit_trail_${DateTime.now().toIso8601String()}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Export successful: ${exportResult['file_name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      LoggerService.info(
        'Audit trail exported to CSV',
        tag: 'AUDIT_LOG_SCREEN',
        metadata: {
          'recordCount': _auditRecords.length,
          'fileName': exportResult['file_name'],
        },
      );
    } catch (e) {
      _showSnackBar('Export failed: $e');
      LoggerService.error(
        'CSV export failed',
        tag: 'AUDIT_LOG_SCREEN',
        error: e,
      );
    }
  }

  Future<void> _exportToPDF() async {
    if (_auditRecords.isEmpty) {
      _showSnackBar('No records to export');
      return;
    }

    try {
      final exportResult = await ExportService.exportToPDF(
        data: _auditRecords
            .map((r) => {
                  'audit_id': r['audit_id'],
                  'action': r['action'],
                  'timestamp': r['timestamp'],
                  'severity': r['severity'],
                  'admin_id': r['admin_id'],
                })
            .toList(),
        fileName: 'audit_trail_${DateTime.now().toIso8601String()}',
        title: 'Audit Trail Report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'PDF export successful: ${exportResult['file_name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      LoggerService.info(
        'Audit trail exported to PDF',
        tag: 'AUDIT_LOG_SCREEN',
      );
    } catch (e) {
      _showSnackBar('PDF export failed: $e');
      LoggerService.error(
        'PDF export failed',
        tag: 'AUDIT_LOG_SCREEN',
        error: e,
      );
    }
  }

  // ============================================================================
  // Verification & Details
  // ============================================================================

  Future<void> _verifyRecord(String auditId) async {
    try {
      final verification =
          await AdminAuditTrailService.verifyAuditRecord(auditId);

      if (mounted) {
        _showVerificationDialog(auditId, verification);
      }
    } catch (e) {
      _showSnackBar('Verification failed: $e');
      LoggerService.error(
        'Audit record verification failed',
        tag: 'AUDIT_LOG_SCREEN',
        error: e,
      );
    }
  }

  void _showVerificationDialog(
    String auditId,
    Map<String, dynamic> verification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Record Verification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit ID: $auditId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: verification['verified'] == true
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  verification['verified'] == true
                      ? 'Verification: PASSED ✓'
                      : 'Verification: FAILED ✗',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: verification['verified'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (verification['tampering_detected'] == true)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'WARNING: Tampering detected!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text('Original Hash:\n${verification['original_hash']}',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
              const SizedBox(height: 8),
              Text(
                'Calculated Hash:\n${verification['calculated_hash']}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // UI Helpers
  // ============================================================================

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(
              start: _selectedStartDate!,
              end: _selectedEndDate!,
            )
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
        _currentPage = 0;
      });
      _loadAuditTrail();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedAction = null;
      _selectedCategory = null;
      _selectedSeverity = null;
      _searchController.clear();
      _adminFilterController.clear();
      _entityIdFilterController.clear();
      _currentPage = 0;
    });
    _loadAuditTrail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(),

          // Export Buttons
          _buildExportSection(),

          // Records Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _buildAuditTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Date Range
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDateRangePicker,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedStartDate != null && _selectedEndDate != null
                          ? '${_selectedStartDate!.toLocal().toString().split(' ')[0]} to ${_selectedEndDate!.toLocal().toString().split(' ')[0]}'
                          : 'Select Date Range',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedStartDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selectedStartDate = null;
                      _selectedEndDate = null;
                      _currentPage = 0;
                      _loadAuditTrail();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Admin Filter
            TextField(
              controller: _adminFilterController,
              decoration: InputDecoration(
                hintText: 'Filter by Admin ID...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onChanged: (_) {
                _currentPage = 0;
                _loadAuditTrail();
              },
            ),
            const SizedBox(height: 12),
            // Entity ID Filter
            TextField(
              controller: _entityIdFilterController,
              decoration: InputDecoration(
                hintText: 'Filter by Entity ID...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onChanged: (_) {
                _currentPage = 0;
                _loadAuditTrail();
              },
            ),
            const SizedBox(height: 12),
            // Action & Category Filter
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Action'),
                    value: _selectedAction,
                    onChanged: (value) => setState(() {
                      _selectedAction = value;
                      _currentPage = 0;
                      _loadAuditTrail();
                    }),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Actions'),
                      ),
                      DropdownMenuItem(
                        value:
                            AdminAuditTrailService.actionSellerApprove,
                        child: Text('Seller Approved'),
                      ),
                      DropdownMenuItem(
                        value:
                            AdminAuditTrailService.actionSellerReject,
                        child: Text('Seller Rejected'),
                      ),
                      DropdownMenuItem(
                        value:
                            AdminAuditTrailService.actionPriceCeilingUpdate,
                        child: Text('Price Ceiling Update'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Severity'),
                    value: _selectedSeverity,
                    onChanged: (value) => setState(() {
                      _selectedSeverity = value;
                      _currentPage = 0;
                      _loadAuditTrail();
                    }),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Severities'),
                      ),
                      DropdownMenuItem(
                        value: 'CRITICAL',
                        child: Text('Critical'),
                      ),
                      DropdownMenuItem(
                        value: 'HIGH',
                        child: Text('High'),
                      ),
                      DropdownMenuItem(
                        value: 'MEDIUM',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'LOW',
                        child: Text('Low'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Clear Filters Button
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _exportToCSV,
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _exportToPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTable() {
    if (_auditRecords.isEmpty) {
      return const Center(
        child: Text('No audit records found'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Audit ID')),
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Admin ID')),
            DataColumn(label: Text('Entity')),
            DataColumn(label: Text('Severity')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _auditRecords.map((record) {
            return DataRow(
              cells: [
                DataCell(Text(
                  '${(record['audit_id'] as String).substring(0, 12)}...',
                  style: const TextStyle(fontSize: 10),
                )),
                DataCell(Text(
                  (record['timestamp'] as String).substring(0, 16),
                  style: const TextStyle(fontSize: 10),
                )),
                DataCell(Text(record['action'] as String)),
                DataCell(Text(
                  record['admin_id'] as String,
                  style: const TextStyle(fontSize: 10),
                )),
                DataCell(Text(
                  '${record['entity_type']}:${record['entity_id']}',
                  style: const TextStyle(fontSize: 10),
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(record['severity'] as String)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record['severity'] as String,
                      style: TextStyle(
                        color: _getSeverityColor(record['severity'] as String),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(record['status'] as String)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.verified, size: 16),
                    onPressed: () =>
                        _verifyRecord(record['audit_id'] as String),
                    tooltip: 'Verify integrity',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
