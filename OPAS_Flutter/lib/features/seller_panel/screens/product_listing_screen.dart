import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/seller_product_model.dart';
import '../services/seller_service.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late Future<List<SellerProduct>> _productsFuture;
  List<SellerProduct> _allProducts = [];
  String _filterStatus = 'ALL'; // ALL, ACTIVE, EXPIRED, PENDING
  String _sortOrder = 'newest'; // newest, price_asc, price_desc, stock_low
  bool _isLoading = false;
  
  // Search
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _productsFuture = SellerService.getProducts();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new debounce timer (500ms)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFiltersAndSort();
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await SellerService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pure function - no setState, safe to call from build
  List<SellerProduct> _getFilteredAndSortedProducts(List<SellerProduct> allProducts) {
    List<SellerProduct> filtered = allProducts;

    // Apply status filter
    if (_filterStatus == 'ALL') {
      // Keep all
    } else if (_filterStatus == 'ACTIVE') {
      filtered = filtered.where((p) => p.isActive).toList();
    } else if (_filterStatus == 'EXPIRED') {
      filtered = filtered.where((p) => p.isExpired).toList();
    } else if (_filterStatus == 'PENDING') {
      filtered = filtered.where((p) => p.isPending).toList();
    }

    // Apply search filter (case-insensitive)
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery) ||
              p.category!.toLowerCase().contains(searchQuery))
          .toList();
    }

    // Apply sort
    switch (_sortOrder) {
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_low':
        filtered.sort((a, b) => a.stockLevel.compareTo(b.stockLevel));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => (b.createdAt)
            .compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  void _applyFiltersAndSort() {
    // Just trigger rebuild - filtering is now done in build method
    setState(() {});
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _filterStatus = newFilter;
    });
    _applyFiltersAndSort();
  }

  void _onSortChanged(String newSort) {
    setState(() {
      _sortOrder = newSort;
    });
    _applyFiltersAndSort();
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
          FutureBuilder<List<SellerProduct>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _allProducts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading products',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (_allProducts.isEmpty && snapshot.hasData) {
                _allProducts = snapshot.data ?? [];
              }

              // Use pure function to get filtered/sorted products
              final displayProducts = _getFilteredAndSortedProducts(_allProducts);

              return RefreshIndicator(
                onRefresh: _refreshProducts,
                child: _allProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products yet',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first product to get started',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search products...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
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

                          // Filter and Sort Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildFilterChip(
                                          'ALL',
                                          'All (${_allProducts.length})',
                                          _filterStatus == 'ALL',
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          'ACTIVE',
                                          'Active (${_allProducts.where((p) => p.isActive).length})',
                                          _filterStatus == 'ACTIVE',
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          'PENDING',
                                          'Pending (${_allProducts.where((p) => p.isPending).length})',
                                          _filterStatus == 'PENDING',
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          'EXPIRED',
                                          'Expired (${_allProducts.where((p) => p.isExpired).length})',
                                          _filterStatus == 'EXPIRED',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sort Dropdown
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: DropdownButton<String>(
                              value: _sortOrder,
                              isExpanded: true,
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
                                DropdownMenuItem(
                                  value: 'stock_low',
                                  child: Text('Low Stock First'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _onSortChanged(value);
                                }
                              },
                            ),
                          ),

                          // Product count
                          if (displayProducts.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${displayProducts.length} product${displayProducts.length != 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),

                          // Product List
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : displayProducts.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No $_filterStatus products',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8)
                                            .copyWith(bottom: 100),
                                        itemCount: displayProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              displayProducts[index];
                                          return _buildProductCard(
                                              context, product);
                                        },
                                      ),
                          ),
                        ],
                      ),
              );
            },
          ),
          Positioned(
            bottom: 105,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/seller/products/add');
              },
              backgroundColor: const Color(0xFF00B464),
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onFilterChanged(value);
        }
      },
      backgroundColor: Colors.grey.withOpacity(0.2),
      selectedColor: const Color(0xFF00B464).withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00B464) : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, SellerProduct product) {
    final statusColor = product.isActive
        ? Colors.green
        : product.isExpired
            ? Colors.red
            : Colors.orange;
    final statusText = product.isActive
        ? 'ACTIVE'
        : product.isExpired
            ? 'EXPIRED'
            : 'PENDING';

    // Get image URL with priority: primaryImage > images array > null
    String? imageUrl;
    if (product.primaryImage != null &&
        product.primaryImage!['image_url'] != null) {
      imageUrl = product.primaryImage!['image_url'];
    } else if (product.images != null && product.images!.isNotEmpty) {
      imageUrl = product.images!.first;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return const Icon(Icons.image_not_supported);
                    },
                  ),
                )
              : const Icon(Icons.image, color: Colors.grey),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '₱${product.price.toStringAsFixed(2)} • Stock: ${product.stockLevel} units',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (product.priceExceedsCeiling)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Price exceeds ceiling (₱${product.ceilingPrice})',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ),
            if (product.isLowStock)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Low stock',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).pushNamed(
                        '/seller/product/edit',
                        arguments: product,
                      );
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, product);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SellerProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteProduct(product);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(SellerProduct product) async {
    try {
      await SellerService.deleteProduct(product.id);
      setState(() {
        _allProducts.removeWhere((p) => p.id == product.id);
        _applyFiltersAndSort();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
