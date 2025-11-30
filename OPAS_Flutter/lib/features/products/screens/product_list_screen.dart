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
  final String? initialSearchQuery;

  const ProductListScreen({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
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
    
    // Set initial search query if provided
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
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
      // Load all products (without category filter to backend)
      // This avoids backend 500 errors with search parameter
      final products = await BuyerApiService.getAllProducts(
        category: null, // Don't pass to API - filter locally instead
        searchTerm: null,
      );
      
      setState(() {
        _allProducts = products;
        _filterProducts(); // Apply local filtering with category and search term
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
      _filteredProducts = _allProducts.where((product) {
        // Filter by category if selected
        bool categoryMatch = _selectedCategory == null || _selectedCategory!.isEmpty 
            ? true 
            : product.category.toUpperCase() == _selectedCategory!.toUpperCase();
        
        // Filter by municipality if not "All Municipalities"
        // farmLocation format: "Barangay, Municipality, Province" (e.g., "Balite, Kawayan, Biliran")
        bool municipalityMatch = _selectedMunicipality == null || _selectedMunicipality == 'All Municipalities'
            ? true
            : (product.farmLocation != null && product.farmLocation!.isNotEmpty)
                ? product.farmLocation!.split(',')[1].trim() == _selectedMunicipality
                : false;
        
        // Filter by search term
        bool searchMatch = searchTerm.isEmpty ||
            product.name.toLowerCase().contains(searchTerm) ||
            product.description.toLowerCase().contains(searchTerm) ||
            product.sellerName.toLowerCase().contains(searchTerm);
        
        return categoryMatch && municipalityMatch && searchMatch;
      }).toList();
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
                        padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMedium, AppDimensions.paddingMedium, AppDimensions.paddingMedium, 150),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
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
                      _filterProducts();
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
                      value: 'LIVESTOCK',
                      child: Text('Livestock'),
                    ),
                    const DropdownMenuItem(
                      value: 'POULTRY',
                      child: Text('Poultry'),
                    ),
                    const DropdownMenuItem(
                      value: 'SEEDS',
                      child: Text('Seeds'),
                    ),
                    const DropdownMenuItem(
                      value: 'FERTILIZERS',
                      child: Text('Fertilizers'),
                    ),
                    const DropdownMenuItem(
                      value: 'FEEDS',
                      child: Text('Feeds'),
                    ),
                    const DropdownMenuItem(
                      value: 'MEDICINES',
                      child: Text('Medicines'),
                    ),
                  ],
                  onChanged: (newCategory) {
                    setState(() {
                      _selectedCategory = newCategory;
                    });
                    _filterProducts();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern product card with clean, professional design matching Sales & Inventory tab
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
                  ? Icon(Icons.image, size: 40, color: Colors.grey[300])
                  : null,
            ),
            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Seller Name
                  Text(
                    product.sellerName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Farm Address
                  if (product.farmLocation != null && product.farmLocation!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        product.farmLocation!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Fulfillment Methods
                  if (product.fulfillmentMethods != null && product.fulfillmentMethods!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B464).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatFulfillmentMethod(product.fulfillmentMethods!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF00B464),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Divider
                  Divider(
                    color: Colors.grey[200],
                    thickness: 1,
                    height: 8,
                  ),
                  const SizedBox(height: 4),
                  // Price and Rating Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₱${product.pricePerKilo.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF00B464),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'per ${product.unit}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rating',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
                            ),
                            child: Text(
                              '${product.sellerRating.toStringAsFixed(1)} ★',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
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

  /// Format fulfillment method display
  String _formatFulfillmentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'delivery':
        return 'For delivery only';
      case 'pickup':
        return 'For pickup only';
      case 'delivery_and_pickup':
      case 'both':
        return 'For delivery & pickup';
      default:
        return method;
    }
  }
}
