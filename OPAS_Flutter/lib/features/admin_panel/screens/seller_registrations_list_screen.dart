import 'package:flutter/material.dart';
import '../models/admin_registration_list_model.dart';
import '../services/seller_registration_admin_service.dart';
import '../widgets/registration_status_badge.dart';
import 'seller_registration_detail_screen.dart';

/// Seller Registrations List Screen
/// Admin interface for viewing and managing seller registrations
/// 
/// Features:
/// - Tabbed view: All / Pending / Approved / Rejected / More Info
/// - Searchable list with filtering
/// - Pagination support
/// - Quick actions (view, approve, reject)
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Tabbed interface with clear filtering
/// - Resource Management: Lazy loading, efficient pagination
/// - Input Validation: Server-side validation on filters
class SellerRegistrationsListScreen extends StatefulWidget {
  const SellerRegistrationsListScreen({super.key});

  @override
  State<SellerRegistrationsListScreen> createState() =>
      _SellerRegistrationsListScreenState();
}

class _SellerRegistrationsListScreenState
    extends State<SellerRegistrationsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  
  bool _isLoading = false;
  String? _errorMessage;
  List<AdminRegistrationListItem> _registrations = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  String _selectedStatus = 'PENDING';
  String _sortBy = 'submitted_at';
  String _sortOrder = 'desc';

  // Tab statuses
  final Map<int, String?> _tabStatusMap = {
    0: null, // All
    1: 'PENDING',
    2: 'APPROVED',
    3: 'REJECTED',
    4: 'REQUEST_MORE_INFO',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController = TextEditingController();
    _tabController.addListener(_onTabChanged);
    _loadRegistrations();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _currentPage = 1;
    final status = _tabStatusMap[_tabController.index];
    setState(() {
      _selectedStatus = status ?? '';
      _errorMessage = null;
    });
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registrations =
          await SellerRegistrationAdminService.getRegistrationsList(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      setState(() {
        _registrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    _currentPage = 1;
    _loadRegistrations();
  }

  void _handleViewDetails(AdminRegistrationListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellerRegistrationDetailScreen(
          registrationId: item.id,
          onRegistrationUpdated: _loadRegistrations,
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(AdminRegistrationListItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleViewDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.buyerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.farmName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  RegistrationStatusBadge(
                    status: item.status,
                    fontSize: 11,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone: ${item.buyerPhone}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Store: ${item.storeName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.daysPending} days',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.daysPending > 30
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.hasAllDocuments
                              ? Colors.green.shade100
                              : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.hasAllDocuments ? 'Complete' : 'Incomplete',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.hasAllDocuments
                                ? Colors.green.shade700
                                : Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: 'Search by buyer name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sort options
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isExpanded: true,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'submitted_at',
                      child: Text('Submission Date'),
                    ),
                    const DropdownMenuItem(
                      value: 'days_pending',
                      child: Text('Days Pending'),
                    ),
                    const DropdownMenuItem(
                      value: 'buyer_name',
                      child: Text('Buyer Name'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _sortBy = value ?? 'submitted_at');
                          _loadRegistrations();
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortOrder,
                  isExpanded: true,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Order',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                    DropdownMenuItem(value: 'desc', child: Text('Descending')),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _sortOrder = value ?? 'desc');
                          _loadRegistrations();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Registrations'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
              Tab(text: 'More Info'),
            ],
          ),

          // Filters
          _buildFilterBar(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
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
                              _errorMessage ?? 'An error occurred',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRegistrations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _registrations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No registrations found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _registrations.length,
                            itemBuilder: (context, index) {
                              return _buildRegistrationCard(
                                _registrations[index],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
