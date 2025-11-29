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

  /// Calculate inventory statistics
  Map<String, int> _calculateStats() {
    return {
      'total': _allInventory.length,
      'lowStock': _allInventory.where((item) => (item['is_low_stock'] as bool? ?? false)).length,
      'active': _allInventory.where((item) => item['status'] == 'ACTIVE').length,
    };
  }

  Color _getStockStatusColor(bool isLowStock) {
    return isLowStock ? Colors.red : const Color(0xFF00B464);
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Sales & Inventory'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00B464)));
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          return RefreshIndicator(
            onRefresh: _refreshInventory,
            color: const Color(0xFF00B464),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === STATISTICS HEADER ===
                  _buildStatsSection(context),

                  const SizedBox(height: 24),

                  // === SEARCH BAR ===
                  _buildSearchBar(),

                  const SizedBox(height: 16),

                  // === FILTER & SORT CHIPS ===
                  _buildFilterSortSection(context),

                  const SizedBox(height: 20),

                  // === INVENTORY LIST ===
                  _filteredInventory.isEmpty
                      ? _buildEmptyState(context)
                      : _buildInventoryList(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Statistics Header Section
  Widget _buildStatsSection(BuildContext context) {
    final stats = _calculateStats();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildStatCard(
                context,
                'Total Products',
                '${stats['total']}',
                Icons.inventory_2,
                const Color(0xFF00B464),
              ),
              _buildStatCard(
                context,
                'Low Stock',
                '${stats['lowStock']}',
                Icons.warning_amber,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Active',
                '${stats['active']}',
                Icons.check_circle,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual Stat Card
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00B464)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  /// Filter & Sort Chips
  Widget _buildFilterSortSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Products'),
                const SizedBox(width: 8),
                _buildFilterChip('LOW_STOCK', 'Low Stock'),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'Active Only'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('NAME', 'Name (A-Z)'),
                const SizedBox(width: 8),
                _buildSortChip('STOCK_ASC', 'Stock: Low→High'),
                const SizedBox(width: 8),
                _buildSortChip('STOCK_DESC', 'Stock: High→Low'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter Chip
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = value);
        _applyFiltersAndSort();
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF00B464).withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? const Color(0xFF00B464) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00B464) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// Sort Chip
  Widget _buildSortChip(String value, String label) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _sortBy = value);
        _applyFiltersAndSort();
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// Empty State
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No inventory items found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search query',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Error State
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Failed to load inventory',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshInventory,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B464),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Inventory List
  Widget _buildInventoryList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredInventory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _filteredInventory[index];
          return _buildInventoryCard(context, item);
        },
      ),
    );
  }

  /// Inventory Card
  Widget _buildInventoryCard(BuildContext context, Map<String, dynamic> item) {
    final isLowStock = item['is_low_stock'] as bool? ?? false;
    final currentStock = item['stock_level'] as int? ?? 0;
    final minimumStock = item['minimum_stock'] as int? ?? 0;
    final productName = item['name'] as String? ?? 'Unknown';
    final unit = item['unit'] as String? ?? 'units';
    final stockPercentage = minimumStock > 0 
        ? (currentStock / minimumStock).clamp(0.0, 1.0) 
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unit,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStockStatusColor(isLowStock).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStockStatusColor(isLowStock).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _getStockStatusText(isLowStock),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getStockStatusColor(isLowStock),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stock Information Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildStockInfoItem(
                    'Current Stock',
                    '$currentStock',
                    const Color(0xFF00B464),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockInfoItem(
                    'Minimum',
                    '$minimumStock',
                    Colors.blue,
                  ),
                ),
                if (isLowStock) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStockInfoItem(
                      'Deficit',
                      '${minimumStock - currentStock}',
                      Colors.red,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Stock Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(stockPercentage * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isLowStock ? Colors.red : const Color(0xFF00B464),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stockPercentage,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLowStock ? Colors.red : const Color(0xFF00B464),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToUpdateStock(item),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Update Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (isLowStock) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReorderDialog(item, minimumStock - currentStock),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Reorder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Stock Info Item
  Widget _buildStockInfoItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showReorderDialog(Map<String, dynamic> item, int deficit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Reorder Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product: ${item['name']}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Current stock is below minimum level.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                'Reorder: $deficit ${item['unit']}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToUpdateStock(item);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Update Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B464),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
