import 'package:flutter/material.dart';
import '../services/seller_service.dart';

class InventoryListingScreen extends StatefulWidget {
  const InventoryListingScreen({Key? key}) : super(key: key);

  @override
  State<InventoryListingScreen> createState() => _InventoryListingScreenState();
}

class _InventoryListingScreenState extends State<InventoryListingScreen> {
  late Future<List<Map<String, dynamic>>> _inventoryFuture;
  List<Map<String, dynamic>> _allInventory = [];
  List<Map<String, dynamic>> _filteredInventory = [];
  
  String _filterType = 'ALL'; // ALL, LOW_STOCK, ACTIVE
  String _sortBy = 'NAME'; // NAME, STOCK_ASC, STOCK_DESC
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshInventory();
    _searchController.addListener(_applyFiltersAndSort);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshInventory() {
    _inventoryFuture = SellerService.getInventoryByProduct();
    return _inventoryFuture.then((data) {
      setState(() {
        _allInventory = data;
        _applyFiltersAndSort();
      });
    });
  }

  void _applyFiltersAndSort() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();

      // Apply filters
      List<Map<String, dynamic>> filtered = _allInventory;

      // Filter by type
      if (_filterType == 'LOW_STOCK') {
        filtered = filtered
            .where((item) => (item['is_low_stock'] as bool? ?? false))
            .toList();
      } else if (_filterType == 'ACTIVE') {
        filtered =
            filtered.where((item) => item['status'] == 'ACTIVE').toList();
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        filtered = filtered
            .where((item) =>
                (item['name'] as String? ?? '').toLowerCase().contains(_searchQuery))
            .toList();
      }

      // Sort
      switch (_sortBy) {
        case 'STOCK_ASC':
          filtered.sort((a, b) =>
              (a['stock_level'] as int? ?? 0)
                  .compareTo(b['stock_level'] as int? ?? 0));
          break;
        case 'STOCK_DESC':
          filtered.sort((a, b) =>
              (b['stock_level'] as int? ?? 0)
                  .compareTo(a['stock_level'] as int? ?? 0));
          break;
        case 'NAME':
        default:
          filtered.sort((a, b) =>
              (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
      }

      _filteredInventory = filtered;
    });
  }

  Color _getStockStatusColor(bool isLowStock) {
    return isLowStock ? Colors.red : Colors.green;
  }

  String _getStockStatusText(bool isLowStock) {
    return isLowStock ? 'Low Stock' : 'Adequate';
  }

  void _navigateToUpdateStock(Map<String, dynamic> item) {
    Navigator.pushNamed(
      context,
      '/seller/inventory/update',
      arguments: {
        'productId': item['id'],
        'productName': item['name'],
        'currentStock': item['stock_level'],
        'minimumStock': item['minimum_stock'],
        'unit': item['unit'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filter and Sort Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Filter dropdown
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterType,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filterType = value);
                        _applyFiltersAndSort();
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Products')),
                      DropdownMenuItem(value: 'LOW_STOCK', child: Text('Low Stock')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Sort dropdown
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _applyFiltersAndSort();
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'NAME', child: Text('Name (A-Z)')),
                      DropdownMenuItem(value: 'STOCK_ASC', child: Text('Stock (Low-High)')),
                      DropdownMenuItem(value: 'STOCK_DESC', child: Text('Stock (High-Low)')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inventory List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _inventoryFuture,
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
                        const Text('Failed to load inventory'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshInventory,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredInventory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('No inventory items found'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshInventory,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredInventory.length,
                    itemBuilder: (context, index) {
                      final item = _filteredInventory[index];
                      final isLowStock = item['is_low_stock'] as bool? ?? false;
                      final currentStock = item['stock_level'] as int? ?? 0;
                      final minimumStock = item['minimum_stock'] as int? ?? 0;
                      final productName = item['name'] as String? ?? 'Unknown';
                      final unit = item['unit'] as String? ?? 'units';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Product Name and Status Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Unit: $unit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStockStatusColor(isLowStock)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStockStatusColor(isLowStock),
                                      ),
                                    ),
                                    child: Text(
                                      _getStockStatusText(isLowStock),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getStockStatusColor(isLowStock),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Stock Information
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Stock',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$currentStock',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Minimum Required',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$minimumStock',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isLowStock)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Deficit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${minimumStock - currentStock}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Stock Level Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: minimumStock > 0
                                      ? (currentStock / minimumStock).clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isLowStock
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _navigateToUpdateStock(item),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Update Stock'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1976D2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (isLowStock)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showReorderDialog(
                                            item, minimumStock - currentStock),
                                        icon: const Icon(Icons.shopping_cart),
                                        label: const Text('Reorder'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshInventory,
        tooltip: 'Refresh inventory',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showReorderDialog(Map<String, dynamic> item, int deficit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${item['name']}'),
            const SizedBox(height: 8),
            Text(
              'Current stock is below minimum level.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Reorder quantity: $deficit ${item['unit']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToUpdateStock(item);
            },
            child: const Text('Update Stock'),
          ),
        ],
      ),
    );
  }
}
