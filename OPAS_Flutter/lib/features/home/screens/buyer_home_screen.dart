import 'package:flutter/material.dart';
import 'package:opas_flutter/core/constants/app_dimensions.dart';
import 'package:opas_flutter/core/widgets/common_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/notification_history_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../order_management/screens/order_history_screen.dart';
import '../../products/models/product_model.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../products/services/buyer_api_service.dart';

/// Buyer Home Screen - Modern Design matching Sales & Inventory Tab
/// 
/// Features:
/// - Professional search bar with modern styling
/// - Quick access category cards
/// - Featured Products grid with modern card design
/// - Recent Orders section
/// - Clean, minimal whitespace
/// - Consistent with Sales & Inventory tab design
/// 
/// Data Loading:
/// - GET /api/products/?limit=10&ordering=-rating (featured)
/// - Cache TTL: 5 minutes
///
/// Gestures:
/// - Tap category → ProductListScreen filtered by category
/// - Tap product → ProductDetailScreen
/// - Tap search → ProductListScreen
class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _selectedIndex = 0;
  
  // Home tab state management
  List<Product> _featuredProducts = [];
  bool _isLoadingFeatured = false;
  DateTime? _lastCacheTime;
  static const int _cacheMinutes = 5;
  
  // User data
  String _userFirstName = 'Guest';
  
  // Search controller
  final _searchController = TextEditingController();
  
  // Dynamic categories loaded from API
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadFeaturedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load available categories from API
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    
    try {
      final categoryKeys = await BuyerApiService.getAvailableCategories();
      debugPrint('📁 Loaded category keys: $categoryKeys');
      
      // Map category keys to display data
      final categoryMap = {
        'VEGETABLE': {'label': 'Vegetables', 'icon': Icons.eco, 'color': const Color(0xFF2E7D32)},
        'FRUIT': {'label': 'Fruits', 'icon': Icons.apple, 'color': const Color(0xFFD32F2F)},
        'LIVESTOCK': {'label': 'Livestock', 'icon': Icons.pets, 'color': const Color(0xFF8B4513)},
        'POULTRY': {'label': 'Poultry', 'icon': Icons.egg_outlined, 'color': const Color(0xFFE65100)},
        'SEEDS': {'label': 'Seeds', 'icon': Icons.grain, 'color': const Color(0xFF7B1FA2)},
        'FERTILIZERS': {'label': 'Fertilizers', 'icon': Icons.landscape, 'color': const Color(0xFF9C7C38)},
        'FEEDS': {'label': 'Feeds', 'icon': Icons.food_bank, 'color': const Color(0xFF6D4C41)},
        'MEDICINES': {'label': 'Medicines', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFC2185B)},
      };
      
      final availableCategories = <Map<String, dynamic>>[];
      for (var key in categoryKeys) {
        if (categoryMap.containsKey(key)) {
          availableCategories.add({
            'label': categoryMap[key]!['label'],
            'icon': categoryMap[key]!['icon'],
            'color': categoryMap[key]!['color'],
            'key': key,
          });
          debugPrint('✅ Added category: $key');
        } else {
          debugPrint('⚠️ Unknown category: $key');
        }
      }
      
      debugPrint('📊 Total categories to display: ${availableCategories.length}');
      setState(() {
        _categories = availableCategories;
      });
    } catch (e) {
      debugPrint('❌ Failed to load categories: $e');
      // Use default categories on error
      _setDefaultCategories();
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  /// Set default categories as fallback
  void _setDefaultCategories() {
    _categories = [
      {'label': 'Vegetables', 'icon': Icons.eco, 'color': const Color(0xFF2E7D32), 'key': 'VEGETABLE'},
      {'label': 'Fruits', 'icon': Icons.apple, 'color': const Color(0xFFD32F2F), 'key': 'FRUIT'},
      {'label': 'Livestock', 'icon': Icons.pets, 'color': const Color(0xFF8B4513), 'key': 'LIVESTOCK'},
      {'label': 'Poultry', 'icon': Icons.egg_outlined, 'color': const Color(0xFFE65100), 'key': 'POULTRY'},
      {'label': 'Seeds', 'icon': Icons.grain, 'color': const Color(0xFF7B1FA2), 'key': 'SEEDS'},
      {'label': 'Fertilizers', 'icon': Icons.landscape, 'color': const Color(0xFF9C7C38), 'key': 'FERTILIZERS'},
      {'label': 'Feeds', 'icon': Icons.food_bank, 'color': const Color(0xFF6D4C41), 'key': 'FEEDS'},
      {'label': 'Medicines', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFC2185B), 'key': 'MEDICINES'},
    ];
  }

  /// Load user first name from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? 'Guest';
      setState(() {
        _userFirstName = firstName;
      });
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  /// Load featured products from API with caching
  Future<void> _loadFeaturedProducts({bool forceRefresh = false}) async {
    // Check cache validity
    if (!forceRefresh && _lastCacheTime != null) {
      final elapsedMinutes = DateTime.now().difference(_lastCacheTime!).inMinutes;
      if (elapsedMinutes < _cacheMinutes && _featuredProducts.isNotEmpty) {
        return; // Use cached data
      }
    }

    if (_isLoadingFeatured) return;
    
    setState(() => _isLoadingFeatured = true);
    
    try {
      final products = await BuyerApiService.getAllProducts();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final featuredProducts = products.take(6).toList();
      
      setState(() {
        _featuredProducts = featuredProducts;
        _lastCacheTime = DateTime.now();
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load featured products: $e');
      setState(() {
        _featuredProducts = [];
        _lastCacheTime = DateTime.now();
      });
    } finally {
      setState(() => _isLoadingFeatured = false);
    }
  }

  /// Navigate to filtered product list
  void _navigateToProducts({String? categoryFilter, String? searchQuery}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          initialCategory: categoryFilter,
          initialSearchQuery: searchQuery,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(),
          CustomBottomNavBar(
            selectedIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return CartScreen(
          onContinueShopping: () {
            setState(() {
              _selectedIndex = 3;
            });
          },
        );
      case 2:
        return const OrderHistoryScreen();
      case 3:
        return const ProductListScreen();
      default:
        return _buildHomeTab();
    }
  }

  /// Main Home Tab - Modern Design
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () => _loadFeaturedProducts(forceRefresh: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Profile and Notifications
            _buildHeaderSection(context),
            
            const SizedBox(height: 16),

            // Search Bar Section
            _buildSearchBarSection(context),
            
            const SizedBox(height: 20),

            // Quick Categories Section
            _buildCategoriesSection(context),
            
            const SizedBox(height: 20),

            // Featured Products Section
            _buildFeaturedProductsSection(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Header section with profile and notifications
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Home, $_userFirstName!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover OPAS Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00B464).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_outline),
                  color: const Color(0xFF00B464),
                  iconSize: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: Colors.red,
                  iconSize: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Search Bar Section - Reusable
  Widget _buildSearchBarSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: CommonSearchBar(
        controller: _searchController,
        enabled: true,
        onChanged: (value) {
          // Real-time search (optional - can implement later if needed)
        },
        onSubmitted: (query) => _performSearch(),
        onTap: () => _performSearch(),
        hintText: 'Search products, farmers...',
      ),
    );
  }

  /// Perform search and navigate to products screen
  void _performSearch() {
    final query = _searchController.text.trim();
    _navigateToProducts(searchQuery: _searchController.text);
  }

  /// Quick Access Categories - Modern Cards
  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
          child: Text(
            'Shop by Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
          child: Row(
            children: _categories.asMap().entries.map((entry) {
              final category = entry.value;
              return Padding(
                padding: EdgeInsets.only(right: entry.key < _categories.length - 1 ? 10 : 0),
                child: _buildCategoryCard(context, category),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Individual Category Card
  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    final color = category['color'] as Color;
    return GestureDetector(
      onTap: () => _navigateToProducts(categoryFilter: category['key'] as String),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(category['icon'] as IconData, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              category['label'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Featured Products Section
  Widget _buildFeaturedProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToProducts(),
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF00B464), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingFeatured)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium, vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00B464),
              ),
            ),
          )
        else if (_featuredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium, vertical: 32),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'No products available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: _featuredProducts.take(4).length,
              itemBuilder: (context, index) {
                final product = _featuredProducts[index];
                return _buildFeaturedProductCard(context, product);
              },
            ),
          ),
      ],
    );
  }

  /// Featured product card with modern design
  Widget _buildFeaturedProductCard(BuildContext context, Product product) {
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
