import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/admin_alert_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin/widgets/alert_tile.dart';
import 'package:intl/intl.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AdminAlertsScreenState createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _severityFilter = 'all'; // 'all', 'critical', 'warning', 'info'
  String _categoryFilter = 'all';
  String _statusFilter = 'all'; // 'all', 'pending', 'reviewed', 'resolved'
  List<AdminAlertModel> _currentAlerts = [];
  List<AdminAlertModel> _alertHistory = [];
  bool _isLoadingCurrent = false;
  bool _isLoadingHistory = false;
  String? _errorCurrent;
  String? _errorHistory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    _loadCurrentAlerts();
    _loadAlertHistory();
  }

  Future<void> _loadCurrentAlerts() async {
    setState(() => _isLoadingCurrent = true);
    try {
      final response = await AdminService.getAdminAlerts(
        status: _statusFilter != 'all' ? _statusFilter : null,
      );

      List<AdminAlertModel> alerts = response
          .map((item) => AdminAlertModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Apply filters
      if (_severityFilter != 'all') {
        alerts = alerts
            .where((a) => a.severity == _severityFilter)
            .toList();
      }
      if (_categoryFilter != 'all') {
        alerts = alerts
            .where((a) => a.category == _categoryFilter)
            .toList();
      }

      setState(() {
        _currentAlerts = alerts;
        _errorCurrent = null;
      });
        } catch (e) {
      setState(() => _errorCurrent = 'Failed to load alerts: $e');
    } finally {
      setState(() => _isLoadingCurrent = false);
    }
  }

  Future<void> _loadAlertHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final response = await AdminService.getAdminAlerts(
        category: _categoryFilter != 'all' ? _categoryFilter : null,
        status: 'resolved',
      );

      List<AdminAlertModel> alerts = response
          .map((item) => AdminAlertModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _alertHistory = alerts;
        _errorHistory = null;
      });
        } catch (e) {
      setState(() => _errorHistory = 'Failed to load history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _acknowledgeAlert(AdminAlertModel alert) async {
    try {
      await AdminService.acknowledgeAlert(alert.alertId);
      setState(() {
        alert.isReviewed = true;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert marked as reviewed')),
      );
      _loadAlerts();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resolveAlert(AdminAlertModel alert) async {
    _showResolveDialog(alert);
  }

  void _showResolveDialog(AdminAlertModel alert) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alert: ${alert.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Add resolution notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AdminService.resolveAlert(
                  alert.alertId,
                  notesController.text,
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert resolved successfully')),
                );
                _loadAlerts();
              } catch (e) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF2196F3),
          tabs: [
            Tab(text: 'Current Alerts (${_currentAlerts.length})'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Alerts Tab
          _buildCurrentAlertsTab(),
          // Alert History Tab
          _buildAlertHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentAlertsTab() {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Severity',
                      _severityFilter,
                      ['all', 'critical', 'warning', 'info'],
                      (value) => setState(() {
                        _severityFilter = value;
                        _loadCurrentAlerts();
                      }),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Category',
                      _categoryFilter,
                      [
                        'all',
                        'price_violation',
                        'low_inventory',
                        'seller_issue',
                        'system'
                      ],
                      (value) => setState(() {
                        _categoryFilter = value;
                        _loadCurrentAlerts();
                      }),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Status',
                      _statusFilter,
                      ['all', 'pending', 'reviewed', 'resolved'],
                      (value) => setState(() {
                        _statusFilter = value;
                        _loadCurrentAlerts();
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Alerts List
        Expanded(
          child: _isLoadingCurrent
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorCurrent != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_errorCurrent!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCurrentAlerts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _currentAlerts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text('No alerts at this time'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _currentAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = _currentAlerts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AlertTile(
                                title: alert.title,
                                message: alert.message,
                                severity: alert.severity,
                                category: alert.category,
                                timestamp: alert.createdAt,
                                isReviewed: alert.isReviewed,
                                onTap: () {
                                  _showAlertDetails(alert);
                                },
                                onReview: () {
                                  _acknowledgeAlert(alert);
                                },
                                onResolve: () {
                                  _resolveAlert(alert);
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildAlertHistoryTab() {
    return _isLoadingHistory
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : _errorHistory != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorHistory!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAlertHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _alertHistory.isEmpty
                ? const Center(
                    child: Text('No alert history'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alertHistory.length,
                    itemBuilder: (context, index) {
                      final alert = _alertHistory[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: alert.isResolved()
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      alert.isResolved()
                                          ? 'Resolved'
                                          : 'Pending',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: alert.isResolved()
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alert.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm')
                                        .format(alert.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (alert.isResolved())
                                    Text(
                                      'Resolved by ${alert.resolvedBy ?? 'System'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onSelected,
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

  void _showAlertDetails(AdminAlertModel alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Severity', alert.severity),
              _buildDetailRow('Category', alert.category),
              _buildDetailRow('Status', alert.isResolved() ? 'Resolved' : 'Active'),
              const SizedBox(height: 12),
              Text(
                'Message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(alert.message),
              const SizedBox(height: 12),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(alert.createdAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (alert.resolutionNotes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolution Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(alert.resolutionNotes!),
                    ],
                  ),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
