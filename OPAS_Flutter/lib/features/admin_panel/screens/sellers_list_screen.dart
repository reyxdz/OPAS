import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/constants/app_dimensions.dart';
import 'package:intl/intl.dart';

class SellersListScreen extends StatefulWidget {
  const SellersListScreen({super.key});

  @override
  State<SellersListScreen> createState() => _SellersListScreenState();
}

class _SellersListScreenState extends State<SellersListScreen> {
  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sellers = await AdminService.getAllSellers();

      setState(() {
        _sellers = sellers;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('DEBUG: Fetched ${_sellers.length} sellers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error fetching sellers: $e');
      }
      setState(() {
        _errorMessage = 'Failed to load sellers: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSellers {
    var filtered = _sellers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((seller) {
        final fullName = (seller['full_name'] ?? '').toString().toLowerCase();
        final phone = (seller['phone_number'] ?? '').toString().toLowerCase();
        final storeName = (seller['store_name'] ?? '').toString().toLowerCase();
        final farmLocation = (seller['address'] ?? '').toString().toLowerCase();

        return fullName.contains(query) ||
            phone.contains(query) ||
            storeName.contains(query) ||
            farmLocation.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00B464),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Sellers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00B464),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchSellers,
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      _buildInfoBar(),
                      Expanded(
                        child: _filteredSellers.isEmpty
                            ? _buildEmptyState()
                            : _buildSellersList(),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Error state widget
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B464),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: _fetchSellers,
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Search section matching buyer home design
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search by owner, phone, store name, or location...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[400],
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00B464), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  /// Info bar showing counts
  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${_filteredSellers.length} sellers',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total on DB: ${_sellers.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
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
            Icons.store_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No sellers found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Sellers list with modern card design
  Widget _buildSellersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredSellers.length,
      itemBuilder: (context, index) {
        final seller = _filteredSellers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSellerCard(seller),
        );
      },
    );
  }

  /// Modern seller card matching buyer home screen design
  Widget _buildSellerCard(Map<String, dynamic> seller) {
    final fullName = seller['full_name'] ?? 'N/A';
    final phone = seller['phone_number'] ?? 'N/A';
    final storeName = seller['store_name_from_app'] ?? seller['store_name'] ?? 'Unnamed Store';
    final storeDescription = seller['store_description'] ?? '';
    final farmLocation = seller['address'] ?? 'Not provided';
    final createdAt = seller['created_at'];

    // Format creation date
    String formattedDate = 'N/A';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
      } catch (e) {
        formattedDate = createdAt.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[100]!),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and store name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SELLER',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF4CAF50),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Owner name
          if (fullName != 'N/A')
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Owner: $fullName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (fullName != 'N/A') const SizedBox(height: 6),

          // Store description
          if (storeDescription.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                storeDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (storeDescription.isNotEmpty) const SizedBox(height: 6),

          Divider(
            color: Colors.grey[200],
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 6),

          // Contact info
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Color(0xFF00B464)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phone.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF00B464),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  farmLocation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Joined: $formattedDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
