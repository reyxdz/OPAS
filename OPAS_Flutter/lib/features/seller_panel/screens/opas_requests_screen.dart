import 'package:flutter/material.dart';
import '../services/seller_service.dart';

class OPASRequestsScreen extends StatefulWidget {
  const OPASRequestsScreen({Key? key}) : super(key: key);

  @override
  State<OPASRequestsScreen> createState() => _OPASRequestsScreenState();
}

class _OPASRequestsScreenState extends State<OPASRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  String _selectedStatus = 'ALL'; // ALL, PENDING, ACCEPTED, REJECTED
  String _selectedSort = 'DATE_DESC'; // DATE_DESC, DATE_ASC, PRICE_DESC, PRICE_ASC

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

  Future<void> _refreshRequests() {
    _requestsFuture = SellerService.getSellToOPASRequests().then((data) {
      // ignore: unnecessary_type_check
      final list = (data is List) ? data : [];
      return list.map((item) => {
        'id': item['id'] ?? 0,
        'product_type': item['product_type'] ?? 'Unknown',
        'quantity': item['quantity'] ?? 0,
        'offered_price': item['offered_price'] ?? '0',
        'status': item['status'] ?? 'PENDING',
        'created_at': item['created_at'] ?? '',
        'quality_grade': item['quality_grade'] ?? 'Standard',
      }).toList();
    });
    return _requestsFuture;
  }

  List<Map<String, dynamic>> _applyFiltersAndSort(
      List<Map<String, dynamic>> data) {
    // Apply status filter
    List<Map<String, dynamic>> filtered = data;
    if (_selectedStatus != 'ALL') {
      filtered = filtered
          .where((item) => item['status'] == _selectedStatus)
          .toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'DATE_ASC':
        filtered.sort((a, b) => (a['created_at'] as String)
            .compareTo(b['created_at'] as String));
        break;
      case 'PRICE_DESC':
        filtered.sort((a, b) {
          final priceA = double.tryParse(a['offered_price'].toString()) ?? 0;
          final priceB = double.tryParse(b['offered_price'].toString()) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'PRICE_ASC':
        filtered.sort((a, b) {
          final priceA = double.tryParse(a['offered_price'].toString()) ?? 0;
          final priceB = double.tryParse(b['offered_price'].toString()) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'DATE_DESC':
      default:
        filtered.sort((a, b) => (b['created_at'] as String)
            .compareTo(a['created_at'] as String));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPAS Requests'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
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
                  const Text('Failed to load OPAS requests'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _refreshRequests()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];
          final filtered = _applyFiltersAndSort(requests);

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No OPAS requests available'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshRequests,
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
                        _buildFilterChip('PENDING', 'Pending'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ACCEPTED', 'Accepted'),
                        const SizedBox(width: 8),
                        _buildFilterChip('REJECTED', 'Rejected'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sort Options
                  const Text(
                    'Sort by',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'DATE_DESC',
                        label: Text('Newest'),
                      ),
                      ButtonSegment<String>(
                        value: 'DATE_ASC',
                        label: Text('Oldest'),
                      ),
                      ButtonSegment<String>(
                        value: 'PRICE_DESC',
                        label: Text('High Price'),
                      ),
                      ButtonSegment<String>(
                        value: 'PRICE_ASC',
                        label: Text('Low Price'),
                      ),
                    ],
                    selected: <String>{_selectedSort},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedSort = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Requests List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final request = filtered[index];
                      return _buildRequestCard(request);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, 'sellerOPASSubmit'),
        tooltip: 'Submit OPAS Offer',
        child: const Icon(Icons.add),
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'PENDING';
    final statusColor = _getStatusColor(status);
    final offeredPrice = double.tryParse(
            request['offered_price'].toString()) ??
        0;

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
                        request['product_type'] as String? ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quality: ${request['quality_grade'] as String? ?? 'Standard'}',
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

            // Details Row
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
                      '${request['quantity']} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date
            Text(
              'Submitted: ${_formatDate(request['created_at'] as String? ?? '')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
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
