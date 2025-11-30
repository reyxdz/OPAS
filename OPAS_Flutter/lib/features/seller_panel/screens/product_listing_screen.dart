import 'package:flutter/material.dart';
import 'dart:async';
import '../models/seller_product_model.dart';
import '../services/seller_service.dart';
import '../../../core/services/api_service.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> with WidgetsBindingObserver {
  late Future<List<SellerProduct>> _productsFuture;
  List<SellerProduct> _allProducts = [];
  String _filterStatus = 'ALL'; // ALL, ACTIVE, EXPIRED, PENDING
  String _sortOrder = 'newest'; // newest, price_asc, price_desc, stock_low
  
  // Search
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  bool _needsRefresh = false;
  // Overlay state for top toast/modals so we don't stack multiple overlays
  OverlayEntry? _activeOverlayEntry;
  void Function(bool)? _activeSetVisible;
  Timer? _activeOverlayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _productsFuture = SellerService.getProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needsRefresh && mounted) {
      _refreshProducts();
      _needsRefresh = false;
    }
  }

  // _markNeedsRefresh was unused and has been removed.

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
      // Refresh the future to get fresh data from API
      _productsFuture = SellerService.getProducts();
    });
    try {
      final products = await SellerService.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return Future.value();
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

  /// Ensure URL is absolute by prepending base URL if needed
  String? _ensureAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Relative URL - prepend the API base URL
    // Remove leading slash if present to avoid double slashes
    final path = url.startsWith('/') ? url : '/$url';
    return '${ApiService.baseUrl}$path';
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
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
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
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                            const SizedBox(height: 100),
                            // Empty state
                            Center(
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
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

                          // Products List or Empty State
                          Expanded(
                            child: displayProducts.isEmpty
                                ? SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 100),
                                          Icon(
                                            Icons.search_off,
                                            size: 64,
                                            color: Colors.grey.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No products found',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Try adjusting your filters or search',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: displayProducts.length,
                                    itemBuilder: (context, index) {
                                      return _buildProductCard(
                                        context,
                                        displayProducts[index],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              );
            },
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
      imageUrl = _ensureAbsoluteUrl(product.primaryImage!['image_url']);
    } else if (product.images != null && product.images!.isNotEmpty) {
      imageUrl = _ensureAbsoluteUrl(product.images!.first);
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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error for $imageUrl: $error');
                      return Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      );
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
                  onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.of(context).pushNamed(
                          '/seller/product/edit',
                          arguments: product,
                        );
                        // If an updated product was returned, refresh the list
                        if (result != null && mounted) {
                          await _refreshProducts();
                        }
                      } else if (value == 'expired') {
                        _showMarkExpiredConfirmation(context, product);
                      } else if (value == 'repost') {
                        _showRepostConfirmation(context, product);
                      } else if (value == 'delete') {
                      _showDeleteConfirmation(context, product);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final List<PopupMenuEntry<String>> items = [];

                    items.add(const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ));

                    if (!product.isExpired) {
                      items.add(const PopupMenuItem(
                        value: 'expired',
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_disabled, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Mark as Expired', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ));
                    } else {
                      // For expired products show 'Repost' instead of 'Mark as Expired'
                      items.add(const PopupMenuItem(
                          value: 'repost',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Reactivate', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ));
                    }

                    items.add(const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ));

                    return items;
                  },
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
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Delete Product',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _deleteProduct(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMarkExpiredConfirmation(BuildContext context, SellerProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_disabled,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Mark as Expired',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This will mark "${product.name}" as expired and it will move to your Expired tab. Proceed?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _markProductExpired(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('Mark Expired', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRepostConfirmation(BuildContext context, SellerProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.refresh,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Submit for Review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.previousStatus != null && product.previousStatus!.isNotEmpty
                      ? 'This will restore "${product.name}" to ${product.previousStatus} and preserve its history. Proceed?'
                      : 'This will submit "${product.name}" for admin review and set its status to PENDING. It will not be visible publicly until approved. Proceed?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _repostProduct(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.previousStatus != null && product.previousStatus!.isNotEmpty ? Colors.green : Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          product.previousStatus != null && product.previousStatus!.isNotEmpty
                              ? 'Restore to ${product.previousStatus}'
                              : 'Submit for review',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markProductExpired(SellerProduct product) async {
    try {
      final updated = await SellerService.updateProduct(product.id, {'status': 'EXPIRED', 'previous_status': product.status});
      if (mounted) {
        // show top overlay with message and refresh
        _showTopSuccessToast(updated, title: 'Product marked expired', message: '${updated.name} moved to Expired tab', bgColor: Colors.orange[700], iconColor: Colors.white, asModal: false);
        await _refreshProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking product expired: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _repostProduct(SellerProduct product) async {
    try {
      // Build a create payload from the expired product's fields
      // Build payload using the same required keys as the Add Product form.
      // Provide reasonable defaults for fields that may not be present on the expired product.
      final Map<String, dynamic> payload = {
        'name': product.name,
        'description': product.description,
        // If product has a category that maps to product_type, prefer it; otherwise default to 'VEGETABLE'
        'product_type': product.category ?? 'VEGETABLE',
        'quality_grade': 'STANDARD',
        'price': product.price,
        'stock_level': product.stockLevel > 0 ? product.stockLevel : 1,
        'unit': 'kg',
      };

      // Prefer primary image as image_url when available
      if (product.primaryImage != null && product.primaryImage!['image_url'] != null) {
        payload['image_url'] = product.primaryImage!['image_url'];
      }

      // Instead of creating a duplicate, reactivate the existing product so
      // sales/rating/history remain attached.
      // Mark the product PENDING again so the admin can review it before it goes public.
      // Determine which status to restore: prefer saved previousStatus, otherwise fall back to PENDING
      final String restoreStatus = product.previousStatus != null && product.previousStatus!.isNotEmpty
          ? product.previousStatus!
          : 'PENDING';

      final updated = await SellerService.updateProduct(product.id, {
        'status': restoreStatus,
        'expiry_date': null,
        'previous_status': null,
      });
      if (mounted) {
        final bool nowPending = (updated.previousStatus == null || updated.previousStatus!.isEmpty) || updated.status == 'PENDING';
        if (nowPending) {
          _showTopSuccessToast(updated, title: 'Product submitted for review', message: '${updated.name} is now pending admin review', bgColor: Colors.orange[700], iconColor: Colors.white, asModal: false);
        } else {
          _showTopSuccessToast(updated, title: 'Product restored', message: '${updated.name} restored to ${updated.status}', bgColor: Colors.green[700], iconColor: Colors.white, asModal: false);
        }

        // Wait a short tick so the toast can animate in, then open the Edit screen
        // so seller can fine-tune details. Guard use of the BuildContext across
        // the async gap by verifying the widget is still mounted before using it.
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return; // avoid using context if widget was disposed
        await Navigator.of(context).pushNamed(
          '/seller/product/edit',
          arguments: updated,
        );

        // Refresh product lists when we return
        if (mounted) await _refreshProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reposting product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProduct(SellerProduct product) async {
    try {
      await SellerService.deleteProduct(product.id);
      if (mounted) {
          _showTopSuccessToast(product);
        // Refresh the product list immediately
        await _refreshProducts();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if this is an order protection error
        if (errorMessage.contains('ORDER_PROTECTION')) {
          // Parse the error: ORDER_PROTECTION|orderCount|message
          final parts = errorMessage.split('|');
          int orderCount = 0;
          String message = 'Cannot delete product with active orders';
          
          if (parts.length >= 3) {
            try {
              orderCount = int.parse(parts[1]);
              message = parts[2];
            } catch (_) {
              // Use defaults if parsing fails
            }
          }
          
          _showCannotDeleteDialog(product, orderCount, message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show error dialog when product cannot be deleted due to active orders
  void _showCannotDeleteDialog(SellerProduct product, int orderCount, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Cannot Delete Product',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This product has $orderCount active order${orderCount != 1 ? 's' : ''}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please complete or cancel all orders for "${product.name}" before deleting it.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Once all orders are fulfilled, you can delete this product.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B464),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Understood',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show a temporary top overlay toast (rounded card) with a small entry animation.
  void _showTopSuccessToast(
    SellerProduct product, {
    bool asModal = false,
    String title = 'Product deleted',
    String? message,
    Color? bgColor,
    Color? iconColor,
  }) {
    final overlay = Overlay.of(context);

    final topSafe = MediaQuery.of(context).padding.top;
    final snackTop = topSafe + kToolbarHeight + 8.0;

    late OverlayEntry entry;

    // ensure we don't stack multiple overlays: remove active one first
    if (_activeOverlayEntry != null) {
      try {
        _activeSetVisible?.call(false);
      } catch (_) {}
      _activeOverlayTimer?.cancel();
      try {
        _activeOverlayEntry?.remove();
      } catch (_) {}
      _activeOverlayEntry = null;
      _activeSetVisible = null;
    }

    // Use a StatefulBuilder inside the overlay so we can control visibility and animate in/out
    void Function(bool)? setToastVisible;
    bool visible = false;

    entry = OverlayEntry(
      builder: (context) {
        // if modal requested, render centered small modal overlay; otherwise top toast
        if (asModal) {
          return Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.18),
              child: StatefulBuilder(
                builder: (context, sbSetState) {
                  setToastVisible = (bool v) => sbSetState(() => visible = v);
                  final double targetScale = visible ? 1.0 : 0.92;
                  final double targetOpacity = visible ? 1.0 : 0.0;

                  return Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      opacity: targetOpacity,
                      child: Transform.scale(
                        scale: targetScale,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00B464),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Product deleted',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${product.name} was removed from your inventory',
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        // default: top toast
        return Positioned(
          top: snackTop,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, sbSetState) {
                // capture setter so outer scope can toggle visibility
                setToastVisible = (bool v) => sbSetState(() => visible = v);

                final double targetScale = visible ? 1.0 : 0.92;
                final double targetOpacity = visible ? 1.0 : 0.0;

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: targetOpacity,
                  child: Transform.scale(
                    scale: targetScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor ?? Colors.green[800],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: iconColor ?? Colors.green[800], size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message ?? '${product.name} was removed from your inventory',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.92),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // store active entry / setter and timers so subsequent invocations can remove/debounce
    _activeOverlayEntry = entry;
    _activeSetVisible = (bool v) => setToastVisible?.call(v);
    overlay.insert(entry);

    // Control timings: small delay before showing, visible duration, then exit animation, then remove
    const int visibleMs = 2200; // visible time (keeps toast on-screen a bit longer)
    const int exitMs = 260; // exit animation time

    // Show (animate in)
    Future.delayed(const Duration(milliseconds: 60), () {
      // builder will have assigned setToastVisible; call it to animate in
      if (setToastVisible != null) setToastVisible!(true);
    });

    // After visibleMs, start exit animation
    Future.delayed(const Duration(milliseconds: 60 + visibleMs), () {
      if (setToastVisible != null) setToastVisible!(false);
    });

    // Finally remove after exit finishes (store timer so it can be cancelled when another toast arrives)
    _activeOverlayTimer?.cancel();
    _activeOverlayTimer = Timer(const Duration(milliseconds: 60 + visibleMs + exitMs), () {
      try {
        entry.remove();
      } catch (_) {}
      if (_activeOverlayEntry == entry) {
        _activeOverlayEntry = null;
        _activeSetVisible = null;
        _activeOverlayTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
