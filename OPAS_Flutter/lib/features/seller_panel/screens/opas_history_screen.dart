// ignore_for_file: unnecessary_type_check

import 'package:flutter/material.dart';
import '../services/seller_service.dart';

class OPASHistoryScreen extends StatefulWidget {
  const OPASHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OPASHistoryScreen> createState() => _OPASHistoryScreenState();
}

class _OPASHistoryScreenState extends State<OPASHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  String _selectedStatus = 'ALL'; // ALL, ACCEPTED, REJECTED, PENDING

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  Future<void> _refreshHistory() {
    _historyFuture = SellerService.getOPASHistory().then((data) {
      final list = (data is List) ? data : [];
      return list.map((item) => {
        'id': item['id'] ?? 0,
        'product_type': item['product_type'] ?? 'Unknown',
        'quantity': item['quantity'] ?? 0,
        'offered_price': item['offered_price'] ?? '0',
        'final_price': item['final_price'] ?? '0',
        'status': item['status'] ?? 'PENDING',
        'created_at': item['created_at'] ?? '',
        'updated_at': item['updated_at'] ?? '',
        'quality_grade': item['quality_grade'] ?? 'Standard',
      }).toList();
    });
    return _historyFuture;
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> data) {
    if (_selectedStatus == 'ALL') return data;
    return data.where((item) => item['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPAS Transaction History'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text('Failed to load transaction history'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _refreshHistory()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data ?? [];
          final filtered = _applyFilter(transactions);

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No transaction history available'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  const Text(
                    'Filter by Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ACCEPTED', 'Accepted'),
                        const SizedBox(width: 8),
                        _buildFilterChip('REJECTED', 'Rejected'),
                        const SizedBox(width: 8),
                        _buildFilterChip('PENDING', 'Pending'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Cards
                  _buildStatisticsCards(filtered),
                  const SizedBox(height: 24),

                  // Transactions List
                  const Text(
                    'Transaction Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final transaction = filtered[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatus = value);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade300,
    );
  }

  Widget _buildStatisticsCards(List<Map<String, dynamic>> transactions) {
    final accepted =
        transactions.where((t) => t['status'] == 'ACCEPTED').toList();
    final rejected =
        transactions.where((t) => t['status'] == 'REJECTED').toList();
    final pending =
        transactions.where((t) => t['status'] == 'PENDING').toList();

    // ignore: unused_local_variable
    for (var transaction in accepted) {
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Accepted',
            value: '${accepted.length}',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Rejected',
            value: '${rejected.length}',
            icon: Icons.cancel,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Pending',
            value: '${pending.length}',
            icon: Icons.pending_actions,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final status = transaction['status'] as String? ?? 'PENDING';
    final statusColor = _getStatusColor(status);
    final offeredPrice = double.tryParse(
            transaction['offered_price'].toString()) ??
        0;
    final finalPrice = double.tryParse(
            transaction['final_price'].toString()) ??
        0;
    final quantity = transaction['quantity'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['product_type'] as String? ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quality: ${transaction['quality_grade'] as String? ?? 'Standard'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offered Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_formatCurrency(offeredPrice)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (status == 'ACCEPTED')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Final Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${_formatCurrency(finalPrice)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted: ${_formatDate(transaction['created_at'] as String? ?? '')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (status != 'PENDING')
                  Text(
                    'Updated: ${_formatDate(transaction['updated_at'] as String? ?? '')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.amber;
    }
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
