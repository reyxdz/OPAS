import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../../products/services/buyer_api_service.dart';
import '../../products/widgets/product_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String _viewMode = 'grid'; // 'grid' or 'list'

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await BuyerApiService.getAllProducts(
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query))
          .toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedCategory: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onApply: (category, min, max) {
          setState(() {
            _selectedCategory = category;
            _minPrice = min;
            _maxPrice = max;
          });
          Navigator.pop(context);
          _loadProducts();
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_viewMode == 'grid' ? Icons.list : Icons.grid_3x3),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: _showFilterBottomSheet,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Active Filters Display
          if (_selectedCategory != null ||
              _minPrice != null ||
              _maxPrice != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: Text(_selectedCategory!),
                      onDeleted: () {
                        setState(() => _selectedCategory = null);
                        _loadProducts();
                      },
                    ),
                  if (_minPrice != null || _maxPrice != null)
                    Chip(
                      label: Text(
                        '₱${_minPrice?.toStringAsFixed(2) ?? '0'} - ₱${_maxPrice?.toStringAsFixed(2) ?? '∞'}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                        });
                        _loadProducts();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Products Grid/List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
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
                          ],
                        ),
                      )
                    : _viewMode == 'grid'
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                                product: _filteredProducts[index],
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                                product: _filteredProducts[index],
                                isListView: true,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
