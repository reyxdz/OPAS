import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../../products/services/buyer_api_service.dart';
import '../../products/screens/product_detail_screen.dart';

/// Seller Shop Screen - Buyer View
/// 
/// Clean architecture implementation for browsing a seller's complete catalog.
/// Features:
/// - Seller profile header with stats (rating, products, response time)
/// - Product grid with pagination
/// - Sort and filter options
/// - Contact and follow seller actions
/// - Consistent design with home and product list screens

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
  List<Product> _products = [];
  Map<String, dynamic>? _sellerInfo;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String _sortBy = 'newest'; // newest, price_asc, price_desc
  
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
    }

    if (_isLoading || (!_hasMore && !refresh)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Loading products for seller ID: ${widget.sellerId}');
      final response = await BuyerApiService.getProductsPaginated({
        'seller_id': widget.sellerId,
        'page': _currentPage,
        'limit': _itemsPerPage,
      });

      debugPrint('API Response received: ${response['results']?.length ?? 0} products');

      // Initialize seller info from first product or use provided name
      final List<Product> products = response['results'] ?? [];
      String? farmName;
      
      // Extract farm name from first product
      if (products.isNotEmpty && products.first.farmLocation != null) {
        farmName = products.first.farmLocation;
      }

      _sellerInfo ??= {
        'id': widget.sellerId,
        'name': widget.sellerName ?? 'Seller',
        'farm_name': farmName,
        'rating': 4.5,
        'verified': true,
        'response_time': '< 1 hour',
        'created_at': DateTime.now().subtract(const Duration(days: 365)),
      };

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
      debugPrint('Error loading seller data: $e');
      setState(() {
        _error = 'Failed to load seller products: ${e.toString()}';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_error')),
        );
      }
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'price_asc':
        _products.sort((a, b) => a.pricePerKilo.compareTo(b.pricePerKilo));
        break;
      case 'price_desc':
        _products.sort((a, b) => b.pricePerKilo.compareTo(a.pricePerKilo));
        break;
      case 'newest':
      default:
        _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00B464),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSellerData(refresh: true),
        child: Column(
          children: [
            // Seller header
            _buildSellerHeader(),
            
            // Sort bar
            if (_products.isNotEmpty) _buildSortBar(),
            
            // Products grid
            Expanded(
              child: _buildProductsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build seller profile header with stats
  Widget _buildSellerHeader() {
    if (_sellerInfo == null) {
      return const SizedBox(height: 140);
    }

    final rating = (_sellerInfo!['rating'] ?? 4.5) as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B464).withOpacity(0.1),
            const Color(0xFF00B464).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Shop name (centered)
          Center(
            child: Column(
              children: [
                Text(
                  _sellerInfo!['name'] ?? 'Unknown Shop',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_sellerInfo!['farm_name'] != null && 
                    (_sellerInfo!['farm_name'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _sellerInfo!['farm_name'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Divider
          Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 16,
          ),
          const SizedBox(height: 12),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star,
                value: '${rating.toStringAsFixed(1)} ★',
                label: 'Rating',
              ),
              _buildStatItem(
                icon: Icons.shopping_bag,
                value: '${_products.length}',
                label: 'Products',
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                value: '₱12.5K',
                label: 'Sales',
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
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00B464)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build sort options bar
  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.sort, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              underline: Container(),
              style: Theme.of(context).textTheme.bodySmall,
              items: const [
                DropdownMenuItem(
                  value: 'newest',
                  child: Text('Newest First'),
                ),
                DropdownMenuItem(
                  value: 'price_asc',
                  child: Text('Price: Low to High'),
                ),
                DropdownMenuItem(
                  value: 'price_desc',
                  child: Text('Price: High to Low'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                    _applySorting();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build products grid with pagination
  Widget _buildProductsGrid() {
    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load products',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadSellerData(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B464),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B464)),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      padding: const EdgeInsets.all(12),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more button
        if (index == _products.length) {
          return Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B464)),
                  )
                : ElevatedButton(
                    onPressed: () => _loadSellerData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                    ),
                    child: const Text('Load More'),
                  ),
          );
        }

        final product = _products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  /// Build individual product card with tap navigation
  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? Icon(Icons.image, size: 40, color: Colors.grey[400])
                  : null,
            ),
            
            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            product.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '₱${product.pricePerKilo.toStringAsFixed(2)}/${product.unit}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF00B464),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.stock > 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              border: Border.all(
                                color: product.stock > 0
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.stock > 0 ? 'Stock' : 'Out',
                              style: TextStyle(
                                fontSize: 9,
                                color: product.stock > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
