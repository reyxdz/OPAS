import 'package:flutter/material.dart';
import '../services/seller_service.dart';
import '../models/seller_payout_model.dart';

/// Payouts Listing Screen
/// Displays payout history with filtering and sorting
/// Features: Status filtering, date-based sorting, transaction details
class PayoutsListingScreen extends StatefulWidget {
  const PayoutsListingScreen({Key? key}) : super(key: key);

  @override
  State<PayoutsListingScreen> createState() => _PayoutsListingScreenState();
}

class _PayoutsListingScreenState extends State<PayoutsListingScreen> {
  String _selectedStatus = 'All';
  String _selectedSort = 'Recent';
  final List<String> _statusOptions = ['All', 'Pending', 'Completed', 'Failed'];
  final List<String> _sortOptions = ['Recent', 'Oldest', 'Highest', 'Lowest'];

  Future<void> _refreshPayouts() async {
    setState(() {});
  }

  List<SellerPayout> _applyFiltersAndSort(List<SellerPayout> payouts) {
    List<SellerPayout> filtered = payouts;
    
    if (_selectedStatus != 'All') {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }
    
    if (_selectedSort == 'Highest') {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_selectedSort == 'Lowest') {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (_selectedSort == 'Oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return filtered;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout History'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPayouts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<SellerPayout>>(
        future: SellerService.getPayouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading payouts'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshPayouts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final payouts = _applyFiltersAndSort(snapshot.data!);
          return RefreshIndicator(
            onRefresh: _refreshPayouts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Filter
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusOptions.length,
                    itemBuilder: (context, index) {
                      final status = _statusOptions[index];
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.green[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Sort Dropdown
                SizedBox(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    items: _sortOptions
                        .map((sort) => DropdownMenuItem(
                              value: sort,
                              child: Text(sort),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSort = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Payouts List
                if (payouts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('No payouts with status: $_selectedStatus'),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payouts.length,
                    itemBuilder: (context, index) {
                      final payout = payouts[index];
                      final status = payout.status;
                      final amount = payout.amount.toStringAsFixed(2);
                      final paymentMethod = payout.paymentMethod;
                      final createdAt = _formatDate(payout.createdAt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₱$amount',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        createdAt,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Payment Method',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        paymentMethod,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (payout.transactionId != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Reference',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          payout.transactionId ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Courier',
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
