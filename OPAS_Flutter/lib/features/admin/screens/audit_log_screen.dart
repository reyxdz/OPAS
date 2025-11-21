import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/audit_log_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin/widgets/audit_log_tile.dart';
import 'package:intl/intl.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  AuditLogScreenState createState() => AuditLogScreenState();
}

class AuditLogScreenState extends State<AuditLogScreen> {
  late TextEditingController _searchController;
  String _actionTypeFilter = 'all';
  String _adminFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;
  List<AuditLogModel> _auditLogs = [];
  List<AuditLogModel> _filteredLogs = [];
  bool _isLoading = false;
  String? _error;
  List<String> _adminList = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_applyFilters);
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await AdminService.getAuditLogs(
        actionType: _actionTypeFilter != 'all' ? _actionTypeFilter : null,
        adminId: _adminFilter != 'all' ? _adminFilter : null,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      final logs = response
          .map((item) => AuditLogModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Extract unique admin names
      final admins = <String>{'all'};
      for (var log in logs) {
        admins.add(log.adminName);
      }

      setState(() {
        _auditLogs = logs;
        _adminList = admins.toList();
        _error = null;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _error = 'Failed to load audit logs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredLogs = _auditLogs.where((log) {
        // Search filter
        if (query.isNotEmpty &&
            !log.actionDescription.toLowerCase().contains(query) &&
            !log.adminName.toLowerCase().contains(query) &&
            !log.getActionLabel().toLowerCase().contains(query)) {
          return false;
        }

        // Action type filter
        if (_actionTypeFilter != 'all' && log.actionType != _actionTypeFilter) {
          return false;
        }

        // Admin filter
        if (_adminFilter != 'all' && log.adminName != _adminFilter) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final fromDate = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (fromDate == null) return;

    if (!mounted) return;
    final toDate = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: fromDate,
      lastDate: DateTime.now(),
    );

    if (toDate != null) {
      setState(() {
        _fromDate = fromDate;
        _toDate = toDate;
      });
      _loadAuditLogs();
    }
  }

  Future<void> _exportAuditLog() async {
    try {
      await AdminService.exportAuditLog(
        actionType: _actionTypeFilter != 'all' ? _actionTypeFilter : null,
        adminId: _adminFilter != 'all' ? _adminFilter : null,
        fromDate: _fromDate,
        toDate: _toDate,
        format: 'csv',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audit log exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting audit log: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Tooltip(
                message: 'Export audit log',
                child: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _exportAuditLog,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by action, admin, or description...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                            child: const Icon(Icons.clear, size: 20),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Action Type',
                        _actionTypeFilter,
                        [
                          'all',
                          'seller_approval',
                          'price_change',
                          'opas_decision',
                          'announcement',
                          'user_management',
                          'system_config'
                        ],
                        (value) {
                          setState(() => _actionTypeFilter = value);
                          _loadAuditLogs();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Admin',
                        _adminFilter,
                        _adminList,
                        (value) {
                          setState(() => _adminFilter = value);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                _fromDate != null && _toDate != null
                                    ? '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd').format(_toDate!)}'
                                    : 'Date Range',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_fromDate != null || _toDate != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                            });
                            _loadAuditLogs();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Audit Log List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAuditLogs,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text('No audit logs found'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = _filteredLogs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AuditLogTile(
                                  actionLabel: log.getActionLabel(),
                                  actionIcon: log.getActionIcon(),
                                  actionDescription: log.actionDescription,
                                  adminName: log.adminName,
                                  timestamp: log.timestamp,
                                  status: log.status,
                                  statusColor: log.getStatusColor(),
                                  onViewDetails: () {
                                    _showLogDetails(log);
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    ValueChanged<String> onSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<String>(
        value: currentValue,
        underline: const SizedBox(),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      option.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onSelected(value);
          }
        },
      ),
    );
  }

  void _showLogDetails(AuditLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.getActionLabel()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Admin', log.adminName),
              _buildDetailRow('Status', log.status.toUpperCase()),
              _buildDetailRow(
                'Timestamp',
                DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp),
              ),
              if (log.affectedItemsCount != null)
                _buildDetailRow(
                  'Affected Items',
                  '${log.affectedItemsCount}',
                ),
              if (log.ipAddress != null)
                _buildDetailRow('IP Address', log.ipAddress!),
              const SizedBox(height: 12),
              Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(log.actionDescription),
              if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Metadata',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.metadata.toString(),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
              if (log.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(log.errorMessage!),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
