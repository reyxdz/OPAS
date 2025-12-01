import 'package:flutter/material.dart';
import 'dart:async';
import '../../products/models/product_model.dart';
import '../../products/services/buyer_api_service.dart';
import '../../products/widgets/product_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialCategory;

  const ProductListScreen({super.key, this.initialCategory});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // Controllers
  final _searchController = TextEditingController();

  // State variables
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  int _totalCount = 0;

  // Filters
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  int? _minRating; // 3, 4, or 5
  bool _inStockOnly = false;
  String _sortOrder = 'newest'; // 'newest', 'price_asc', 'price_desc', 'rating'

  // UI State
  String _viewMode = 'grid'; // 'grid' or 'list'

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    _loadProducts(reset: true);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new debounce timer (500ms)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      _loadProducts(reset: true);
    });
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMoreItems = true;
    }

    if (!_hasMoreItems && !reset) return;

    setState(() {
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      // Build query parameters
      final Map<String, dynamic> params = {
        'page': _currentPage,
        'limit': _itemsPerPage,
      };

      if (_selectedCategory != null) {
        params['category'] = _selectedCategory;
      }

      if (_minPrice != null) {
        params['min_price'] = _minPrice!.toStringAsFixed(2);
      }

      if (_maxPrice != null) {
        params['max_price'] = _maxPrice!.toStringAsFixed(2);
      }

      if (_searchController.text.isNotEmpty) {
        params['search'] = _searchController.text;
      }

      if (_inStockOnly) {
        params['in_stock'] = 'true';
      }

      // Add ordering based on sort
      switch (_sortOrder) {
        case 'price_asc':
          params['ordering'] = 'price_per_kilo';
          break;
        case 'price_desc':
          params['ordering'] = '-price_per_kilo';
          break;
        case 'rating':
          params['ordering'] = '-seller_rating';
          break;
        case 'newest':
        default:
          params['ordering'] = '-created_at';
          break;
      }

      // Call API
      final response = await BuyerApiService.getProductsPaginated(params);

      setState(() {
        _totalCount = response['count'] ?? 0;
        final List<dynamic> results = response['results'] ?? [];

        if (reset) {
          _allProducts = results.cast<Product>();
          _filteredProducts = _allProducts;
        } else {
          _allProducts.addAll(results.cast<Product>());
          _filteredProducts = _allProducts;
        }

        // Check if there are more items
        _hasMoreItems = _currentPage * _itemsPerPage < _totalCount;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load products: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMoreProducts() {
    if (!_isLoadingMore && _hasMoreItems) {
      _currentPage++;
      _loadProducts(reset: false);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedCategory: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        inStockOnly: _inStockOnly,
        sortOrder: _sortOrder,
        onApply: ({
          String? category,
          double? minPrice,
          double? maxPrice,
          int? minRating,
          bool? inStockOnly,
          String? sortOrder,
        }) {
          setState(() {
            if (category != null) _selectedCategory = category;
            if (minPrice != null) _minPrice = minPrice;
            if (maxPrice != null) _maxPrice = maxPrice;
            if (minRating != null) _minRating = minRating;
            if (inStockOnly != null) _inStockOnly = inStockOnly;
            if (sortOrder != null) _sortOrder = sortOrder;
          });
          Navigator.pop(context);
          _currentPage = 1;
          _loadProducts(reset: true);
        },
        onClear: () {
          setState(() {
            _selectedCategory = null;
            _minPrice = null;
            _maxPrice = null;
            _minRating = null;
            _inStockOnly = false;
            _sortOrder = 'newest';
            _searchController.clear();
          });
          Navigator.pop(context);
          _currentPage = 1;
          _loadProducts(reset: true);
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = widget.initialCategory;
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _inStockOnly = false;
      _sortOrder = 'newest';
      _searchController.clear();
    });
    _currentPage = 1;
    _loadProducts(reset: true);
  }

  Widget _buildShimmerCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: Colors.grey[300],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Colors.blue.shade100,
      labelStyle: TextStyle(color: Colors.blue.shade900),
    );
  }

  Widget _buildActiveFiltersRow() {
    if (_selectedCategory == null &&
        _minPrice == null &&
        _maxPrice == null &&
        _minRating == null &&
        !_inStockOnly &&
        _sortOrder == 'newest') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              children: [
                if (_selectedCategory != null)
                  _buildFilterChip(
                    'Category: $_selectedCategory',
                    () {
                      setState(() => _selectedCategory = null);
                      _currentPage = 1;
                      _loadProducts(reset: true);
                    },
                  ),
                if (_minPrice != null || _maxPrice != null)
                  _buildFilterChip(
                    '₱${_minPrice?.toStringAsFixed(0) ?? '0'} - ₱${_maxPrice?.toStringAsFixed(0) ?? '∞'}',
                    () {
                      setState(() {
                        _minPrice = null;
                        _maxPrice = null;
                      });
                      _currentPage = 1;
                      _loadProducts(reset: true);
                    },
                  ),
                if (_minRating != null)
                  _buildFilterChip(
                    '★ $_minRating+',
                    () {
                      setState(() => _minRating = null);
                      _currentPage = 1;
                      _loadProducts(reset: true);
                    },
                  ),
                if (_inStockOnly)
                  _buildFilterChip(
                    'In Stock',
                    () {
                      setState(() => _inStockOnly = false);
                      _currentPage = 1;
                      _loadProducts(reset: true);
                    },
                  ),
                if (_sortOrder != 'newest')
                  _buildFilterChip(
                    'Sort: $_sortOrder',
                    () {
                      setState(() => _sortOrder = 'newest');
                      _currentPage = 1;
                      _loadProducts(reset: true);
                    },
                  ),
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_viewMode == 'grid' ? Icons.list : Icons.grid_3x3),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
              });
            },
            tooltip: _viewMode == 'grid' ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showFilterBottomSheet,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters Display
          _buildActiveFiltersRow(),

          // Products count and loading indicator
          if (!_isLoading && _filteredProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: $_totalCount products',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_isLoadingMore)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

          // Products Grid/List with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadProducts(reset: true);
                // Wait for products to load
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: _isLoading
                  ? _buildShimmerLoadingGrid()
                  : _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : _buildProductsView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsView() {
    if (_viewMode == 'grid') {
      return _buildGridView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 150),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredProducts.length) {
          _loadMoreProducts();
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ProductCard(
          product: _filteredProducts[index],
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 150),
      itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredProducts.length) {
          _loadMoreProducts();
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        final product = _filteredProducts[index];
        return _buildListProductCard(product);
      },
    );
  }

  Widget _buildListProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  // Category and Stock
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!product.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '₱${product.pricePerKilo.toStringAsFixed(2)}/kg',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Seller Info
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.sellerRating.toStringAsFixed(1)} · ${product.sellerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
