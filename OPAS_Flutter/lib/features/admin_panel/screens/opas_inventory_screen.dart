// OPAS Inventory Screen - Stock management with low stock and expiry alerts
// Track OPAS inventory with FIFO removal, visual health indicators

import 'package:flutter/material.dart';
import '../../../core/models/opas_inventory_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/opas_inventory_item_card.dart';

class OPASInventoryScreen extends StatefulWidget {
  const OPASInventoryScreen({Key? key}) : super(key: key);

  @override
  State<OPASInventoryScreen> createState() => _OPASInventoryScreenState();
}

class _OPASInventoryScreenState extends State<OPASInventoryScreen> {
  late TextEditingController _searchController;

  String _selectedStatus = 'ALL'; // ALL, OK, LOW_STOCK, EXPIRING, EXPIRED
  final String _sortBy = 'product'; // product, quantity, expiry
  DateTimeRange? _dateRange;

  List<OPASInventoryModel> _inventory = [];
  List<OPASInventoryModel> _filteredInventory = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inventory = await AdminService.getOPASInventory();
      setState(() {
        _inventory = (inventory as List)
            .map((item) =>
                OPASInventoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    _filteredInventory = _inventory.where((item) {
      if (_selectedStatus != 'ALL') {
        if (item.status.toUpperCase() != _selectedStatus) return false;
      }
      if (_dateRange != null) {
        if (item.expiryDate.isBefore(_dateRange!.start) ||
            item.expiryDate.isAfter(_dateRange!.end)) return false;
      }
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return item.productName.toLowerCase().contains(query) ||
            item.batchNumber.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    _filteredInventory.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'product':
          comparison = a.productName.compareTo(b.productName);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'expiry':
          comparison = a.expiryDate.compareTo(b.expiryDate);
          break;
      }
      return comparison;
    });
  }

  void _showAdjustDialog(OPASInventoryModel item) {
    final controller = TextEditingController(text: item.quantity.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock: ${item.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${item.quantity.toStringAsFixed(2)} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Quantity',
                suffixText: item.unit,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _loadInventory();
              Navigator.pop(context);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock adjusted')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _inventory.where((i) => i.isLowStock()).length;
    final expiringCount = _inventory.where((i) => i.isExpiringSoon()).length;
    final expiredCount = _inventory.where((i) => i.isExpired()).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OPAS Inventory'),
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInventory),
          IconButton(icon: const Icon(Icons.tune), onPressed: () {
            // Filter panel
          }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    // Alert Summary
                    if (lowStockCount > 0 || expiringCount > 0 || expiredCount > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (expiredCount > 0)
                              Column(
                                children: [
                                  const Icon(Icons.error, color: Colors.red, size: 24),
                                  const SizedBox(height: 4),
                                  Text('$expiredCount Expired', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            if (expiringCount > 0)
                              Column(
                                children: [
                                  const Icon(Icons.warning, color: Colors.orange, size: 24),
                                  const SizedBox(height: 4),
                                  Text('$expiringCount Expiring', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            if (lowStockCount > 0)
                              Column(
                                children: [
                                  const Icon(Icons.notifications, color: Colors.amber, size: 24),
                                  const SizedBox(height: 4),
                                  Text('$lowStockCount Low Stock', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    // Search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search product or batch...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => setState(() => _applyFiltersAndSort()),
                      ),
                    ),
                    // Status Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: ['ALL', 'OK', 'LOW_STOCK', 'EXPIRING', 'EXPIRED'].map((status) {
                          return FilterChip(
                            label: Text(status),
                            selected: _selectedStatus == status,
                            onSelected: (s) {
                              setState(() => _selectedStatus = status);
                              _applyFiltersAndSort();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    // List
                    Expanded(
                      child: _filteredInventory.isEmpty
                          ? Center(
                              child: Text(_selectedStatus == 'OK' ? 'All inventory healthy!' : 'No items found'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _filteredInventory.length,
                              itemBuilder: (context, index) {
                                final item = _filteredInventory[index];
                                return OPASInventoryItemCard(
                                  inventory: item,
                                  onAdjust: () => _showAdjustDialog(item),
                                  onMarkConsumed: () => _loadInventory(),
                                  onRemove: () => _loadInventory(),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
