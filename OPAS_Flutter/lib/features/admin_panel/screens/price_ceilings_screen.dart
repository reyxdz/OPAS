import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/price_ceiling_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/price_ceiling_tile.dart';
import '../dialogs/update_price_ceiling_dialog.dart';
import 'price_advisory_screen.dart';

class PriceCeilingsScreen extends StatefulWidget {
  const PriceCeilingsScreen({Key? key}) : super(key: key);

  @override
  State<PriceCeilingsScreen> createState() => _PriceCeilingsScreenState();
}

class _PriceCeilingsScreenState extends State<PriceCeilingsScreen> {
  late TextEditingController _searchController;

  // Data state
  List<PriceCeilingModel> _ceilings = [];
  List<PriceCeilingModel> _filteredCeilings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _selectedCategory = 'ALL';
  DateTimeRange? _dateRange;
  String _sortBy = 'product'; // product, price, date

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadCeilings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all price ceilings from API
  Future<void> _loadCeilings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ceilings = await AdminService.getPriceCeilings();
      setState(() {
        _ceilings = (ceilings)
            .map((item) => item is PriceCeilingModel
                ? item
                : PriceCeilingModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load price ceilings: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    _filteredCeilings = _ceilings.where((ceiling) {
      // Category filter
      if (_selectedCategory != 'ALL') {
        if (ceiling.productCategory.toUpperCase() !=
            _selectedCategory.toUpperCase()) {
          return false;
        }
      }

      // Date range filter
      if (_dateRange != null) {
        if (ceiling.lastChangedAt != null) {
          if (ceiling.lastChangedAt!.isBefore(_dateRange!.start) ||
              ceiling.lastChangedAt!.isAfter(_dateRange!.end)) {
            return false;
          }
        }
      }

      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return ceiling.productName.toLowerCase().contains(query) ||
            ceiling.productCategory.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredCeilings.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'product':
          comparison = a.productName.compareTo(b.productName);
          break;
        case 'price':
          comparison = a.currentCeiling.compareTo(b.currentCeiling);
          break;
        case 'date':
          comparison = (b.lastChangedAt ?? DateTime(2000))
              .compareTo(a.lastChangedAt ?? DateTime(2000));
          break;
      }

      return comparison;
    });
  }

  /// Show update ceiling dialog
  void _showUpdateDialog(PriceCeilingModel ceiling) {
    showDialog(
      context: context,
      builder: (context) => UpdatePriceCeilingDialog(
        ceiling: ceiling,
        onUpdate: (newCeiling, reason, justification, effectiveDate) {
          _loadCeilings();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Price ceiling updated: ${ceiling.productName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// Show price advisory creation dialog
  void _showAdvisoryDialog(PriceCeilingModel ceiling) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PriceAdvisoryScreen(
          initialProductName: ceiling.productName,
          initialCeiling: ceiling.currentCeiling,
        ),
      ),
    );
  }

  /// Show price history
  void _showPriceHistory(PriceCeilingModel ceiling) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price History - ${ceiling.productName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Ceiling: ${ceiling.formatCeiling()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Previous Ceiling: ${ceiling.formatPreviousCeiling()}',
              ),
              const SizedBox(height: 8),
              if (ceiling.reasonForChange != null) ...[
                Text(
                  'Reason: ${ceiling.reasonForChange}',
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Effective Date: ${DateFormat('MMM dd, yyyy').format(ceiling.effectiveDate)}',
              ),
              const SizedBox(height: 8),
              if (ceiling.lastChangedAt != null)
                Text(
                  'Last Changed: ${DateFormat('MMM dd, yyyy HH:mm').format(ceiling.lastChangedAt!)}',
                ),
              if (ceiling.lastChangedBy != null) ...[
                const SizedBox(height: 8),
                Text('Changed By: ${ceiling.lastChangedBy}'),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Management'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCeilings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterChips(),
                    _buildSortOptions(),
                    Expanded(
                      child: _filteredCeilings.isEmpty
                          ? _buildEmptyState()
                          : _buildCeilingsList(),
                    ),
                  ],
                ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by product name or category...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFiltersAndSort();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (_) {
          setState(() => _applyFiltersAndSort());
        },
      ),
    );
  }

  /// Build filter chips for categories
  Widget _buildFilterChips() {
    final categories = [
      'ALL',
      'Vegetables',
      'Fruits',
      'Grains',
      'Dairy',
      'Meat'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedCategory = category);
              _applyFiltersAndSort();
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.blue.withOpacity(0.3),
          );
        }).toList(),
      ),
    );
  }

  /// Build sort options
  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'product', child: Text('Sort by Product')),
                DropdownMenuItem(value: 'price', child: Text('Sort by Price')),
                DropdownMenuItem(value: 'date', child: Text('Sort by Date Changed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _applyFiltersAndSort();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                  _applyFiltersAndSort();
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _dateRange != null
                    ? 'Date: ${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}'
                    : 'Date Range',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCeilings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No price ceilings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'No price ceilings in system yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build ceilings list
  Widget _buildCeilingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredCeilings.length,
      itemBuilder: (context, index) {
        final ceiling = _filteredCeilings[index];
        return PriceCeilingTile(
          ceiling: ceiling,
          onTap: () => _showPriceHistory(ceiling),
          onEdit: () => _showUpdateDialog(ceiling),
          onViewHistory: () => _showPriceHistory(ceiling),
          onCreateAdvisory: () => _showAdvisoryDialog(ceiling),
        );
      },
    );
  }
}
