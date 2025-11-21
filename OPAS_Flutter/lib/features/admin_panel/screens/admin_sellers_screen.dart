// Admin Sellers Management Screen
// Displays list of sellers with filtering, sorting, search, and quick actions
// Follows clean architecture with separation of concerns

import 'package:flutter/material.dart';

import '../../../core/models/seller_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/seller_list_tile.dart';
import '../widgets/seller_filter_panel.dart';
import 'seller_details_admin_screen.dart';
import '../dialogs/seller_approval_dialog.dart';


class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({Key? key}) : super(key: key);

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}


class _AdminSellersScreenState extends State<AdminSellersScreen> {
  late TextEditingController _searchController;
  
  // Filter & Sort State
  String _selectedStatus = 'ALL'; // ALL, PENDING, APPROVED, SUSPENDED
  String _sortBy = 'name'; // name, date, status
  bool _sortAscending = true;
  DateTimeRange? _dateRange;
  
  // Data State
  List<SellerModel> _sellers = [];
  List<SellerModel> _filteredSellers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all sellers from API
  Future<void> _loadSellers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AdminService.getSellers();
      setState(() {
        _sellers = (response as List)
            .map((item) => SellerModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sellers: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply filters and sorting to sellers list
  void _applyFiltersAndSort() {
    _filteredSellers = _sellers.where((seller) {
      // Status filter
      if (_selectedStatus != 'ALL') {
        if (seller.status.toUpperCase() != _selectedStatus) {
          return false;
        }
      }

      // Date range filter
      if (_dateRange != null) {
        final sellerDate = seller.createdAt;
        if (sellerDate.isBefore(_dateRange!.start) || 
            sellerDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return seller.fullName.toLowerCase().contains(query) ||
               seller.email.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredSellers.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  /// Show seller details screen
  void _viewSellerDetails(SellerModel seller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SellerDetailsAdminScreen(
          seller: {
            'id': seller.id,
            'full_name': seller.fullName,
            'email': seller.email,
            'phone_number': seller.phoneNumber,
            'address': seller.address ?? '',
            'store_name': seller.storeName,
            'store_description': seller.storeDescription,
            'seller_status': seller.status,
            'created_at': seller.createdAt.toIso8601String(),
            'seller_documents_verified': seller.documentVerified,
          },
        ),
      ),
    );
  }

  /// Show approval dialog
  void _showApprovalDialog(SellerModel seller) {
    showDialog(
      context: context,
      builder: (context) => SellerApprovalDialog(
        seller: {
          'full_name': seller.fullName,
          'id': seller.id,
          'email': seller.email,
          'seller_status': seller.status,
        },
        onDecision: (action, notes) {
          _loadSellers(); // Refresh list after decision
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seller $action: ${seller.fullName}'),
              backgroundColor: action == 'approve' 
                  ? Colors.green 
                  : Colors.orange,
            ),
          );
        },
      ),
    );
  }

  /// Show filter panel
  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SellerFilterPanel(
        selectedStatus: _selectedStatus,
        selectedSort: _sortBy,
        sortAscending: _sortAscending,
        dateRange: _dateRange,
        onStatusChanged: (status) {
          setState(() => _selectedStatus = status);
          _applyFiltersAndSort();
          Navigator.pop(context);
        },
        onSortChanged: (sort, ascending) {
          setState(() {
            _sortBy = sort;
            _sortAscending = ascending;
          });
          _applyFiltersAndSort();
          Navigator.pop(context);
        },
        onDateRangeChanged: (range) {
          setState(() => _dateRange = range);
          _applyFiltersAndSort();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedStatus = 'ALL';
            _sortBy = 'name';
            _sortAscending = true;
            _dateRange = null;
            _searchController.clear();
          });
          _applyFiltersAndSort();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Management'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSellers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterPanel,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),
                    // Status filter chips
                    _buildStatusChips(),
                    // Sellers list or empty state
                    Expanded(
                      child: _filteredSellers.isEmpty
                          ? _buildEmptyState()
                          : _buildSellersList(),
                    ),
                  ],
                ),
    );
  }

  /// Error widget
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
            onPressed: _loadSellers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Search bar widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
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

  /// Status filter chips
  Widget _buildStatusChips() {
    final statuses = ['ALL', 'PENDING', 'APPROVED', 'SUSPENDED'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return FilterChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedStatus = status);
              _applyFiltersAndSort();
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.blue.withOpacity(0.3),
          );
        }).toList(),
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No sellers found',
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
                : 'No sellers in system yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Sellers list widget
  Widget _buildSellersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredSellers.length,
      itemBuilder: (context, index) {
        final seller = _filteredSellers[index];
        return SellerListTile(
          seller: seller,
          onTap: () => _viewSellerDetails(seller),
          onApprove: () => _showApprovalDialog(seller),
          onReject: () => _showApprovalDialog(seller),
          onSuspend: () => _showApprovalDialog(seller),
        );
      },
    );
  }
}
