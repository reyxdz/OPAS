// Marketplace Alerts Screen - Manages marketplace alerts with categorization and bulk actions
// Displays categorized alerts with status tracking, details, and resolution workflows

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/marketplace_alert_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin_panel/widgets/alert_card.dart';

class MarketplaceAlertsScreen extends StatefulWidget {
  const MarketplaceAlertsScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceAlertsScreen> createState() =>
      MarketplaceAlertsScreenState();
}

class MarketplaceAlertsScreenState extends State<MarketplaceAlertsScreen> {

  // State variables
  List<dynamic> _allAlerts = [];
  List<dynamic> _filteredAlerts = [];
  final Set<int> _selectedAlertIds = {};

  String _selectedCategory = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedSeverity = 'ALL';
  bool _isLoading = false;
  String? _errorMessage;

  // Alert counts by category
  final Map<String, int> _alertCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AdminService.getMarketplaceAlerts();
      setState(() {
        _allAlerts = response as List? ?? [];
        _filteredAlerts = _allAlerts;
        _calculateAlertCounts();
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading alerts: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateAlertCounts() {
    _alertCounts.clear();
    const categories = [
      'ALL',
      'PRICE_VIOLATION',
      'SELLER_ISSUE',
      'UNUSUAL_ACTIVITY',
      'COMPLIANCE',
      'FRAUD_DETECTION',
      'INVENTORY',
      'QUALITY'
    ];

    for (var category in categories) {
      if (category == 'ALL') {
        _alertCounts[category] = _allAlerts.length;
      } else {
        _alertCounts[category] = _allAlerts
            .where((item) => (item as Map)['alert_category'] == category)
            .length;
      }
    }
  }

  void _applyFilters() {
    _filteredAlerts = _allAlerts;

    // Apply category filter
    if (_selectedCategory != 'ALL') {
      _filteredAlerts = _filteredAlerts
          .where((item) =>
              (item as Map)['alert_category'] == _selectedCategory)
          .toList();
    }

    // Apply status filter
    if (_selectedStatus != 'ALL') {
      _filteredAlerts = _filteredAlerts
          .where((item) =>
              (item as Map)['status'] == _selectedStatus)
          .toList();
    }

    // Apply severity filter
    if (_selectedSeverity != 'ALL') {
      _filteredAlerts = _filteredAlerts
          .where((item) =>
              (item as Map)['severity'] == _selectedSeverity)
          .toList();
    }

    // Sort by creation time (newest first)
    _filteredAlerts.sort((a, b) {
      final timeA = DateTime.parse((a as Map)['created_at'] as String);
      final timeB = DateTime.parse((b as Map)['created_at'] as String);
      return timeB.compareTo(timeA);
    });
  }

  Future<void> _handleBulkAction(String action) async {
    if (_selectedAlertIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select alerts first')),
      );
      return;
    }

    try {
      switch (action) {
        case 'ACKNOWLEDGE':
          await Future.forEach(_selectedAlertIds, (int id) async {
            await AdminService.acknowledgeAlert(id.toString());
          });
          break;
        case 'RESOLVE':
          await Future.forEach(_selectedAlertIds, (int id) async {
            await AdminService.resolveAlert(id.toString(), 'Bulk resolved');
          });
          break;
        case 'ESCALATE':
          // Note: No escalate method in current AdminService
          // Consider adding this method or using a different approach
          break;
      }

      setState(() {
        _selectedAlertIds.clear();
      });
      await _loadAlerts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedAlertIds.length} alerts $action successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error performing action: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Alerts'),
        elevation: 0,
        actions: [
          if (_selectedAlertIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${_selectedAlertIds.length} selected',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter section
                    _buildFilterSection(),
                    // Bulk actions bar
                    if (_selectedAlertIds.isNotEmpty) _buildBulkActionsBar(),
                    // Alerts list
                    Expanded(
                      child: _buildAlertsList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Alerts',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('ALL', _alertCounts['ALL'] ?? 0),
                _buildCategoryChip('PRICE_VIOLATION', _alertCounts['PRICE_VIOLATION'] ?? 0),
                _buildCategoryChip('SELLER_ISSUE', _alertCounts['SELLER_ISSUE'] ?? 0),
                _buildCategoryChip('UNUSUAL_ACTIVITY', _alertCounts['UNUSUAL_ACTIVITY'] ?? 0),
                _buildCategoryChip('COMPLIANCE', _alertCounts['COMPLIANCE'] ?? 0),
                _buildCategoryChip('FRAUD_DETECTION', _alertCounts['FRAUD_DETECTION'] ?? 0),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status and severity filters
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter(
                  'Status',
                  _selectedStatus,
                  ['ALL', 'ACTIVE', 'ACKNOWLEDGED', 'RESOLVED', 'ESCALATED'],
                  (value) {
                    setState(() {
                      _selectedStatus = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownFilter(
                  'Severity',
                  _selectedSeverity,
                  ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
                  (value) {
                    setState(() {
                      _selectedSeverity = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, int count) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text('$category ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedAlertIds.length} alert(s) selected',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: () => _handleBulkAction('ACKNOWLEDGE'),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Acknowledge'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
          TextButton.icon(
            onPressed: () => _handleBulkAction('RESOLVE'),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Resolve'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
          TextButton.icon(
            onPressed: () => _handleBulkAction('ESCALATE'),
            icon: const Icon(Icons.arrow_upward, size: 16),
            label: const Text('Escalate'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _allAlerts.isEmpty
                  ? 'No alerts at this time'
                  : 'No alerts match filters',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAlerts.length,
      itemBuilder: (context, index) {
        final alert = MarketplaceAlertModel.fromJson(_filteredAlerts[index]);
        final isSelected = _selectedAlertIds.contains(alert.id);

        return InkWell(
          onLongPress: () {
            setState(() {
              if (isSelected) {
                _selectedAlertIds.remove(alert.id);
              } else {
                _selectedAlertIds.add(alert.id);
              }
            });
          },
          child: Container(
            color: isSelected ? Colors.blue[50] : null,
            child: AlertCard(
              alert: alert,
              onTap: () {
                if (_selectedAlertIds.isNotEmpty) {
                  setState(() {
                    if (isSelected) {
                      _selectedAlertIds.remove(alert.id);
                    } else {
                      _selectedAlertIds.add(alert.id);
                    }
                  });
                }
              },
              onAcknowledge: () async {
                try {
                  await AdminService.acknowledgeAlert(alert.id.toString());
                  await _loadAlerts();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert acknowledged'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              onResolve: () async {
                try {
                  await AdminService.resolveAlert(alert.id.toString(), 'Resolved');
                  await _loadAlerts();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert resolved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              onEscalate: () async {
                try {
                  // Note: No escalate method in current AdminService
                  // Could implement escalation through a different mechanism
                  await _loadAlerts();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert escalation not yet implemented'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
