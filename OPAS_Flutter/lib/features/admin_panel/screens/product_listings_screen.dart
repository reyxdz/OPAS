import 'package:flutter/material.dart';
import '../../../core/services/admin_service.dart';

class ProductListingsScreen extends StatefulWidget {
  const ProductListingsScreen({super.key});

  @override
  State<ProductListingsScreen> createState() => _ProductListingsScreenState();
}

class _ProductListingsScreenState extends State<ProductListingsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final products = await AdminService.getAllProducts();

      setState(() {
        _products = products;
        _isLoading = false;
      });

      debugPrint('DEBUG: Fetched ${_products.length} products');
    } catch (e) {
      debugPrint('DEBUG: Error fetching products: $e');
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final category = (product['product_type'] ?? '').toString().toLowerCase();

        return name.contains(query) || category.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Listings'),
        elevation: 0,
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          : _errorMessage != null
              ? Center(
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
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildProductCount(),
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No products found',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProducts.length,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search by product name or category...',
          prefixIcon: const Icon(Icons.search, color: Colors.purple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.purple, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildProductCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing: ${_filteredProducts.length} products',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            'Total: ${_products.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'N/A';
    final category = product['category'] ?? product['product_type'] ?? 'N/A';
    final price = product['price'];
    final stock = product['stock_level'] ?? 0;
    final sellerName = product['seller_name'] ?? 'Unknown Seller';
    final image = product['primary_image'] ?? product['image'] ?? product['images'];

    // Parse price if it's a string
    double priceValue = 0.0;
    if (price is String) {
      priceValue = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      priceValue = price.toDouble();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: image != null
                  ? Image.network(
                      image.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        );
                      },
                    )
                  : Icon(
                      Icons.image,
                      color: Colors.grey[400],
                      size: 40,
                    ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    name.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Category and Seller
                  Text(
                    '$category • $sellerName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Price and Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            '₱${priceValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stock',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            '$stock units',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
}

