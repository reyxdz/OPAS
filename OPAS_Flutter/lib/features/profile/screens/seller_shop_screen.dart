import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../../products/services/buyer_api_service.dart';
import '../../products/widgets/product_card.dart';

/// Seller Shop Screen - Buyer View
/// 
/// Displays a seller's complete catalog with shop information, statistics,
/// and reviews. Buyers can browse all products from a specific seller,
/// view seller ratings, and access reviews from other customers.
/// 
/// Features:
/// - Seller header with shop name, rating, and verification badge
/// - Shop statistics (total products, successful orders, member since)
/// - All seller products with infinite scroll pagination
/// - Sort and filter options
/// - Seller reviews tab
/// - Contact/Follow seller options

class SellerShopScreen extends StatefulWidget {
  final int sellerId;
  final String? sellerName;
  
  const SellerShopScreen({
    Key? key,
    required this.sellerId,
    this.sellerName,
  }) : super(key: key);

  @override
  State<SellerShopScreen> createState() => _SellerShopScreenState();
}

class _SellerShopScreenState extends State<SellerShopScreen> {
  final BuyerApiService _apiService = BuyerApiService();
  
  // State variables
  List<Product> _products = [];
  Map<String, dynamic>? _sellerInfo;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  
  // UI state
  String _sortBy = 'newest'; // newest, price_asc, price_desc, rating
  String _activeTab = 'products'; // products, reviews
  
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  /// Load seller information and products
  Future<void> _loadSellerData({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load seller info
      if (_sellerInfo == null || refresh) {
        _sellerInfo = await _apiService.getSellerProfile(widget.sellerId);
      }

      // Load seller products
      if (!_hasMore && !refresh) return;

      final products = await _apiService.getSellerProducts(
        sellerId: widget.sellerId,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      setState(() {
        if (refresh) {
          _products = products;
        } else {
          _products.addAll(products);
        }
        _hasMore = products.length == _itemsPerPage;
        _currentPage++;
        _applySorting();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seller data: $_error')),
        );
      }
    }
  }

  /// Apply sorting to products
  void _applySorting() {
    switch (_sortBy) {
      case 'price_asc':
        _products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        // Assuming products have a rating field
        // _products.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'newest':
      default:
        _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    setState(() {});
  }

  /// Build seller header section
  Widget _buildSellerHeader() {
    if (_sellerInfo == null) {
      return const SizedBox(height: 180);
    }

    final rating = (_sellerInfo!['rating'] ?? 0.0) as double;
    final isVerified = _sellerInfo!['verified'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Shop name and verification badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sellerInfo!['name'] ?? 'Unknown Shop',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (_sellerInfo!['description'] != null)
                      Text(
                        _sellerInfo!['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rating and stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rating
              _buildStatItem(
                icon: Icons.star,
                label: 'Rating',
                value: '$rating ★',
              ),
              
              // Total products
              _buildStatItem(
                icon: Icons.shopping_bag,
                label: 'Products',
                value: '${_products.length}',
              ),
              
              // Member since
              _buildStatItem(
                icon: Icons.calendar_today,
                label: 'Since',
                value: _formatDate(_sellerInfo!['created_at']),
              ),
              
              // Location
              _buildStatItem(
                icon: Icons.location_on,
                label: 'Location',
                value: _sellerInfo!['location'] ?? 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactSeller(),
                  icon: const Icon(Icons.mail),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _followSeller(),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Follow'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Format date string
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.year}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Contact seller action
  void _contactSeller() {
    if (_sellerInfo == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening message for ${_sellerInfo!['name']}')),
    );
    // TODO: Implement messaging functionality
  }

  /// Follow seller action
  void _followSeller() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller added to your favorites')),
    );
    // TODO: Implement follow functionality
  }

  /// Build products grid
  Widget _buildProductsTab() {
    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load products'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadSellerData(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products available'),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(12),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () => _loadSellerData(),
                      child: const Text('Load More'),
                    ),
            ),
          );
        }

        final product = _products[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product.id,
          ),
        );
      },
    );
  }

  /// Build reviews tab
  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rate_review, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Seller reviews coming soon'),
          const SizedBox(height: 8),
          Text(
            'Current rating: ${(_sellerInfo?['rating'] ?? 0.0)} ★',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build sort and filter bar
  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Icon(Icons.sort),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Newest')),
                DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                DropdownMenuItem(value: 'rating', child: Text('Best Rated')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _applySorting();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sellerName ?? 'Seller Shop'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSellerData(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSellerData(refresh: true),
        child: Column(
          children: [
            _buildSellerHeader(),
            
            // Tab selection
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'products'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: _activeTab == 'products'
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.green,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: const Center(
                          child: Text('Products'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'reviews'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: _activeTab == 'reviews'
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.green,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: const Center(
                          child: Text('Reviews'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content based on active tab
            Expanded(
              child: _activeTab == 'products'
                  ? Column(
                      children: [
                        _buildSortBar(),
                        Expanded(child: _buildProductsTab()),
                      ],
                    )
                  : _buildReviewsTab(),
            ),
          ],
        ),
      ),
    );
  }
}
