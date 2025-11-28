import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/common_search_bar.dart';
import '../../authentication/models/location_data.dart';
import '../models/product_model.dart';
import '../services/buyer_api_service.dart';
import 'product_detail_screen.dart';

/// Products Screen - Display all available products
/// - Grid layout matching home screen design
/// - Functional API integration
/// - Search and filtering capabilities
class ProductListScreen extends StatefulWidget {
  final String? initialCategory;

  const ProductListScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String? _selectedMunicipality;
  late List<String> _municipalities;

  @override
  void initState() {
    super.initState();
    // Initialize municipalities from LocationData
    _municipalities = ['All Municipalities', ...LocationData.municipalities];
    _selectedMunicipality = _municipalities.first;
    
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await BuyerApiService.getAllProducts(
        category: _selectedCategory,
        searchTerm: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) =>
                product.name.toLowerCase().contains(searchTerm) ||
                product.description.toLowerCase().contains(searchTerm) ||
                product.sellerName.toLowerCase().contains(searchTerm))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          CommonSearchBar(
            controller: _searchController,
            enabled: true,
            onChanged: (_) => _filterProducts(),
          ),
          
          // Dual Filter Row - Municipality and Category
          _buildFilterRow(context),
          
          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00B464),
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Try different search terms',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(context, product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Dual filter row - Municipality and Category filters side by side
  Widget _buildFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: 8,
      ),
      child: Row(
        children: [
          // Municipality Filter - Left Half
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButton<String>(
                  value: _selectedMunicipality,
                  isExpanded: true,
                  underline: Container(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00B464), size: 18),
                  dropdownColor: Colors.white,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  items: _municipalities.map((municipality) {
                    return DropdownMenuItem(
                      value: municipality,
                      child: Text(municipality),
                    );
                  }).toList(),
                  onChanged: (newMunicipality) {
                    if (newMunicipality != null) {
                      setState(() => _selectedMunicipality = newMunicipality);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Category Filter - Right Half
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButton<String?>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: Container(),
                  hint: const Text('Category'),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00B464), size: 18),
                  dropdownColor: Colors.white,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    const DropdownMenuItem(
                      value: 'VEGETABLE',
                      child: Text('Vegetables'),
                    ),
                    const DropdownMenuItem(
                      value: 'FRUIT',
                      child: Text('Fruits'),
                    ),
                    const DropdownMenuItem(
                      value: 'GRAIN',
                      child: Text('Grains'),
                    ),
                    const DropdownMenuItem(
                      value: 'POULTRY',
                      child: Text('Poultry'),
                    ),
                    const DropdownMenuItem(
                      value: 'DAIRY',
                      child: Text('Dairy'),
                    ),
                  ],
                  onChanged: (newCategory) {
                    setState(() {
                      _selectedCategory = newCategory;
                      _loadProducts();
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Product card matching home screen design
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
            // Product Image
            Container(
              height: 100,
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
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.sellerName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${product.pricePerKilo.toStringAsFixed(2)}/${product.unit}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF00B464),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${product.sellerRating.toStringAsFixed(1)}★',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.amber[50],
                        ),
                      ],
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
