import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _refreshRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((item) =>
              (item['product_type'] as String? ?? '')
                  .toLowerCase()
                  .contains(query))
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACCEPTED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'PENDING':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Submission Status',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text('Failed to load submissions'),
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

          // Count submissions by status
          final pendingCount = requests
              .where((r) => r['status'] == 'PENDING')
              .length;
          final approvedCount = requests
              .where((r) => r['status'] == 'ACCEPTED')
              .length;
          final rejectedCount = requests
              .where((r) => r['status'] == 'REJECTED')
              .length;

          return RefreshIndicator(
            onRefresh: _refreshRequests,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ===== STATS SECTION =====
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Submissions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                        children: [
                          _buildStatCard(
                            label: 'Pending',
                            count: pendingCount,
                            color: Colors.orange,
                            icon: Icons.schedule,
                          ),
                          _buildStatCard(
                            label: 'Approved',
                            count: approvedCount,
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                          _buildStatCard(
                            label: 'Rejected',
                            count: rejectedCount,
                            color: Colors.red,
                            icon: Icons.cancel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // ===== SEARCH & FILTERS =====
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search product...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF00B464),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      // Status filter chips
                      Wrap(
                        spacing: 8,
                        children: ['ALL', 'PENDING', 'ACCEPTED', 'REJECTED']
                            .map((status) {
                          final isSelected = _selectedStatus == status;
                          return FilterChip(
                            label: Text(
                              status == 'PENDING'
                                  ? 'Pending ($pendingCount)'
                                  : status == 'ACCEPTED'
                                      ? 'Approved ($approvedCount)'
                                      : status == 'REJECTED'
                                          ? 'Rejected ($rejectedCount)'
                                          : 'All',
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedStatus = status);
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF00B464).withOpacity(0.2),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF00B464)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00B464)
                                  : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Sort dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSort,
                          underline: Container(),
                          items: [
                            ('DATE_DESC', 'Sort by: Newest First'),
                            ('DATE_ASC', 'Sort by: Oldest First'),
                            ('PRICE_DESC', 'Sort by: Highest Price'),
                            ('PRICE_ASC', 'Sort by: Lowest Price'),
                          ]
                              .map((item) => DropdownMenuItem(
                                    value: item.$1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(item.$2),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSort = value);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF00B464),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== REQUESTS LIST =====
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No submissions found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or submit a new offer',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(
                        filtered.length,
                        (index) {
                          final request = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRequestCard(request),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, 'sellerOPASSubmit'),
        backgroundColor: const Color(0xFF00B464),
        icon: const Icon(Icons.add),
        label: const Text('New Offer'),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'PENDING';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final offeredPrice =
        double.tryParse(request['offered_price'].toString()) ?? 0;
    final createdAt = request['created_at'] as String? ?? '';

    DateTime? submittedDate;
    try {
      if (createdAt.isNotEmpty) {
        submittedDate = DateTime.parse(createdAt);
      }
    } catch (e) {
      // Invalid date format
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with status
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
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    label: 'Quantity',
                    value: '${request['quantity']} kg',
                    icon: Icons.scale,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    label: 'Offered Price',
                    value: '₱${offeredPrice.toStringAsFixed(2)}/unit',
                    icon: Icons.currency_exchange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    label: 'Submitted',
                    value: submittedDate != null
                        ? DateFormat('MMM dd, yyyy').format(submittedDate)
                        : 'N/A',
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    label: 'Total Value',
                    value: '₱${((request['quantity'] as int) * offeredPrice).toStringAsFixed(0)}',
                    icon: Icons.price_check,
                  ),
                ),
              ],
            ),

            // Status message or action button
            if (status == 'PENDING') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Awaiting OPAS review. You will be notified when they respond.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'ACCEPTED') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Congratulations! OPAS has approved your submission.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'REJECTED') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'OPAS did not accept this offer. You can submit another.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
