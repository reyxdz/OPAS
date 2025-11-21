// OPAS Purchase History Screen - Transaction tracking and reporting
// View completed purchases with summary cards, filtering, and export capability

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/opas_purchase_history_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/opas_purchase_history_tile.dart';

class OPASPurchaseHistoryScreen extends StatefulWidget {
  const OPASPurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OPASPurchaseHistoryScreen> createState() =>
      _OPASPurchaseHistoryScreenState();
}

class _OPASPurchaseHistoryScreenState extends State<OPASPurchaseHistoryScreen> {
  late TextEditingController _searchController;

  String _selectedStatus = 'ALL'; // ALL, COMPLETED, CANCELLED
  String _selectedPaymentStatus = 'ALL'; // ALL, PAID, PENDING
  DateTimeRange? _dateRange;

  List<OPASPurchaseHistoryModel> _transactions = [];
  List<OPASPurchaseHistoryModel> _filteredTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await AdminService.getOPASPurchaseHistory();
      setState(() {
        _transactions = history
            .map((item) =>
                OPASPurchaseHistoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    _filteredTransactions = _transactions.where((t) {
      if (_selectedStatus != 'ALL' && t.status.toUpperCase() != _selectedStatus) return false;
      if (_selectedPaymentStatus != 'ALL' && t.paymentStatus.toUpperCase() != _selectedPaymentStatus) return false;
      if (_dateRange != null &&
          (t.purchaseDate.isBefore(_dateRange!.start) ||
              t.purchaseDate.isAfter(_dateRange!.end))) return false;
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return t.sellerName.toLowerCase().contains(query) ||
            t.productName.toLowerCase().contains(query) ||
            (t.invoiceNumber?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    _filteredTransactions.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  /// Calculate summary statistics
  Map<String, dynamic> _calculateSummary() {
    if (_filteredTransactions.isEmpty) {
      return {
        'totalPurchases': 0,
        'totalSpent': 0.0,
        'avgPrice': 0.0,
        'itemsCount': 0,
      };
    }

    double totalSpent = 0;
    double totalQuantity = 0;
    for (var t in _filteredTransactions) {
      totalSpent += t.calculateFinalAmount();
      totalQuantity += t.quantity;
    }

    return {
      'totalPurchases': _filteredTransactions.length,
      'totalSpent': totalSpent,
      'avgPrice': totalSpent / _filteredTransactions.length,
      'itemsCount': totalQuantity,
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = _calculateSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OPAS Purchase History'),
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export to CSV functionality coming soon')),
              );
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    // Summary Cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildSummaryCard(
                              'Total Purchases',
                              '${summary['totalPurchases']}',
                              Icons.shopping_cart,
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              'Total Spent',
                              'PKR ${(summary['totalSpent'] as double).toStringAsFixed(0)}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              'Avg Transaction',
                              'PKR ${(summary['avgPrice'] as double).toStringAsFixed(0)}',
                              Icons.trending_up,
                              Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              'Items Purchased',
                              (summary['itemsCount'] as double).toStringAsFixed(0),
                              Icons.inventory_2,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Search & Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search seller, product, invoice...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => setState(() => _applyFiltersAndSort()),
                      ),
                    ),
                    // Status Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ...['ALL', 'COMPLETED', 'CANCELLED'].map((status) {
                            return FilterChip(
                              label: Text(status),
                              selected: _selectedStatus == status,
                              onSelected: (s) {
                                setState(() => _selectedStatus = status);
                                _applyFiltersAndSort();
                              },
                            );
                          }),
                          const SizedBox(width: 8),
                          ...['ALL', 'PAID', 'PENDING'].map((payment) {
                            return FilterChip(
                              label: Text('Payment: $payment'),
                              selected: _selectedPaymentStatus == payment,
                              onSelected: (s) {
                                setState(() => _selectedPaymentStatus = payment);
                                _applyFiltersAndSort();
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    // Transaction List
                    Expanded(
                      child: _filteredTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text('No transactions found',
                                      style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _filteredTransactions[index];
                                return OPASPurchaseHistoryTile(
                                  transaction: transaction,
                                  onViewDetails: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Transaction Details'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _detailRow('Date', DateFormat('MMM dd, yyyy – hh:mm a').format(transaction.purchaseDate)),
                                              _detailRow('Seller', transaction.sellerName),
                                              _detailRow('Product', transaction.productName),
                                              _detailRow('Quantity', '${transaction.quantity.toStringAsFixed(2)} ${transaction.unit}'),
                                              _detailRow('Unit Price', transaction.formatUnitPrice()),
                                              _detailRow('Total', transaction.formatTotalAmount()),
                                              if (transaction.discount != null)
                                                _detailRow('Discount', 'PKR ${transaction.discount!.toStringAsFixed(2)}'),
                                              if (transaction.tax != null)
                                                _detailRow('Tax', 'PKR ${transaction.tax!.toStringAsFixed(2)}'),
                                              _detailRow('Final Amount', transaction.formatFinalAmount()),
                                              _detailRow('Status', transaction.status),
                                              _detailRow('Payment', transaction.paymentStatus),
                                              if (transaction.notes != null)
                                                _detailRow('Notes', transaction.notes!),
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
                                  },
                                  onViewInvoice: () {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Invoice ${transaction.invoiceNumber} - Download coming soon')),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
