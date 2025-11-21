// Marketplace Activity Screen - Displays real-time marketplace activity
// Provides overview stats, activity feed, search, and listing flag functionality

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/marketplace_activity_model.dart';
import 'package:opas_flutter/core/models/marketplace_listing_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin_panel/widgets/activity_feed_item.dart';
import 'package:opas_flutter/features/admin_panel/dialogs/listing_flag_dialog.dart';

class MarketplaceActivityScreen extends StatefulWidget {
  const MarketplaceActivityScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceActivityScreen> createState() =>
      _MarketplaceActivityScreenState();
}

class _MarketplaceActivityScreenState extends State<MarketplaceActivityScreen> {
  late TextEditingController _searchController;

  // State variables
  List<dynamic> _allActivities = [];
  List<dynamic> _filteredActivities = [];
  List<dynamic> _allListings = [];
  List<dynamic> _filteredListings = [];

  String _searchQuery = '';
  String _activityFilter = 'ALL';
  bool _isLoading = false;
  String? _errorMessage;

  // Stats
  int _activeListings = 0;
  int _salesToday = 0;
  int _marketplaceHealth = 100;
  int _flaggedListings = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadMarketplaceData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketplaceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load listings and alerts in parallel (available methods)
      final listingsResponse = await AdminService.getMarketplaceListings();
      final alertsResponse = await AdminService.getMarketplaceAlerts();

      setState(() {
        _allListings = listingsResponse as List? ?? [];
        _allActivities = alertsResponse as List? ?? [];
        _filteredActivities = _allActivities;
        _filteredListings = _allListings;

        // Calculate stats
        _calculateStats();
        _applyFiltersAndSearch();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading marketplace data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    _activeListings = _allListings.length;
    _flaggedListings = _allListings
        .where((item) => (item as Map)['status'] == 'FLAGGED')
        .length;

    // Calculate sales today (from activities)
    final today = DateTime.now();
    _salesToday = _allActivities
        .where((item) {
          final activity = item as Map;
          if (activity['activity_type'] != 'COMPLETED_ORDER') return false;
          final actTime = DateTime.parse(activity['activity_time'] as String);
          return actTime.year == today.year &&
              actTime.month == today.month &&
              actTime.day == today.day;
        })
        .length;

    // Calculate marketplace health (100% - violation %)
    final violationCount = _allListings
        .where((item) => (item as Map)['is_suspicious'] == true)
        .length;
    _marketplaceHealth = (100 - ((violationCount / _activeListings) * 100)).toInt();
    if (_marketplaceHealth < 0) _marketplaceHealth = 0;
  }

  void _applyFiltersAndSearch() {
    _filteredActivities = _allActivities;
    _filteredListings = _allListings;

    // Apply activity type filter
    if (_activityFilter != 'ALL') {
      _filteredActivities = _allActivities
          .where((item) =>
              (item as Map)['activity_type'] == _activityFilter)
          .toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      _filteredListings = _allListings
          .where((item) {
            final listing = item as Map;
            final seller = listing['seller_name'].toString().toLowerCase();
            final product = listing['product_name'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return seller.contains(query) || product.contains(query);
          })
          .toList();
    }
  }

  void _handleFlagListing(MarketplaceListingModel listing) {
    showDialog(
      context: context,
      builder: (context) => ListingFlagDialog(
        listing: listing,
        onSubmit: (reason, details) {
          _flagListingAction(listing.id, reason, details);
        },
      ),
    );
  }

  Future<void> _flagListingAction(int listingId, String reason, String details) async {
    try {
      await AdminService.flagListing(listingId.toString(), reason: reason, severity: 'high');
      _loadMarketplaceData(); // Reload data
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing flagged successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error flagging listing: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marketplace Oversight'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activity Feed'),
              Tab(text: 'Listings'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMarketplaceData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildActivityTab(),
                      _buildListingsTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Overview stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marketplace Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'Active Listings',
                      _activeListings.toString(),
                      Colors.blue,
                      Icons.store,
                    ),
                    _buildStatCard(
                      'Sales Today',
                      _salesToday.toString(),
                      Colors.green,
                      Icons.shopping_cart,
                    ),
                    _buildStatCard(
                      'Marketplace Health',
                      '$_marketplaceHealth%',
                      _marketplaceHealth >= 80 ? Colors.green : Colors.orange,
                      Icons.health_and_safety,
                    ),
                    _buildStatCard(
                      'Flagged Listings',
                      _flaggedListings.toString(),
                      Colors.red,
                      Icons.flag,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                // Activity type filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'ALL'),
                      _buildFilterChip('New Listings', 'NEW_LISTING'),
                      _buildFilterChip('Orders', 'COMPLETED_ORDER'),
                      _buildFilterChip('Price Changes', 'PRICE_CHANGE'),
                      _buildFilterChip('Unusual', 'UNUSUAL_ACTIVITY'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Activity feed
          if (_filteredActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No activities to display'),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _filteredActivities.map((item) {
                final activity = MarketplaceActivityModel.fromJson(item);
                return ActivityFeedItem(
                  activity: activity,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Activity: ${activity.getActivityLabel()}')),
                    );
                  },
                  onFlag: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Activity flagged')),
                    );
                  },
                  onDismiss: () {
                    setState(() {
                      _filteredActivities.remove(item);
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildListingsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSearch();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by seller, product, or price range...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFiltersAndSearch();
                          });
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
            ),
          ),
          if (_filteredListings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.store_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No listings found'),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _filteredListings.map((item) {
                final listing = MarketplaceListingModel.fromJson(item);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: listing.getStatusColor(),
                      child: Icon(
                        listing.status == 'FLAGGED'
                            ? Icons.flag
                            : Icons.store,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(listing.productName),
                    subtitle: Text('${listing.sellerName} • ${listing.formatPrice()}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('View Details'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Viewing: ${listing.productName}'),
                              ),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Flag Listing'),
                          onTap: () => _handleFlagListing(listing),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activityFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _activityFilter = value;
            _applyFiltersAndSearch();
          });
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
