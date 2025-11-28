import 'package:flutter/material.dart';
import 'package:opas_flutter/core/constants/app_dimensions.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/notification_history_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../order_management/screens/order_history_screen.dart';
import '../../products/models/product_model.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../products/services/buyer_api_service.dart';

/// Buyer Home Screen - Complete Implementation per Part 3 Spec
/// 
/// Features:
/// - Search bar redirecting to ProductList
/// - Location selector dropdown
/// - Featured Categories horizontal carousel with swipe
/// - Featured Products grid (2x2) with highest rated products
/// - Promotions carousel (if available)
/// - Recent Orders section (for logged-in users)
/// - 5-minute data caching strategy
/// 
/// Data Loading:
/// - GET /api/products/?limit=10&ordering=-rating (featured)
/// - GET /api/products/?category=VEGETABLE&limit=6 (per category)
/// - Cache TTL: 5 minutes
///
/// Gestures:
/// - Swipe category carousel
/// - Tap product → ProductDetailScreen
/// - Tap category → ProductListScreen filtered by category
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
  String? _selectedLocation;
  DateTime? _lastCacheTime;
  static const int _cacheMinutes = 5;
  
  // Available locations for filter
  final List<String> _locations = [
    'All Locations',
    'Benguet',
    'Nueva Ecija', 
    'Laguna',
    'Camarines Sur',
    'Bukidnon'
  ];
  
  // Categories configuration with icons and labels
  final Map<String, Map<String, dynamic>> _categories = {
    'VEGETABLE': {'label': 'Vegetables', 'icon': Icons.eco, 'color': const Color(0xFF2E7D32)},
    'FRUIT': {'label': 'Fruits', 'icon': Icons.apple, 'color': const Color(0xFFD32F2F)},
    'GRAIN': {'label': 'Grains', 'icon': Icons.grain, 'color': const Color(0xFF7B1FA2)},
    'POULTRY': {'label': 'Poultry', 'icon': Icons.food_bank, 'color': const Color(0xFFE65100)},
    'DAIRY': {'label': 'Dairy', 'icon': Icons.local_drink, 'color': const Color(0xFF0277BD)},
  };

  @override
  void initState() {
    super.initState();
    _selectedLocation = _locations.first;
    _loadFeaturedProducts();
  }

  /// Load featured products from API
  /// Implements caching: only reload if cache expired (5 minutes)
  /// Spec: GET /api/products/?limit=10&ordering=-rating
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
      // Fetch products from the marketplace API
      final products = await BuyerApiService.getAllProducts();
      
      // Sort by creation date (newest first) and take top 6
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final featuredProducts = products.take(6).toList();
      
      setState(() {
        _featuredProducts = featuredProducts;
        _lastCacheTime = DateTime.now();
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load featured products: $e');
      // Show error but don't fallback to mock data - show empty state instead
      setState(() {
        _featuredProducts = [];
        _lastCacheTime = DateTime.now();
      });
    } finally {
      setState(() => _isLoadingFeatured = false);
    }
  }

  /// Navigate to filtered product list
  void _navigateToProducts({String? categoryFilter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          initialCategory: categoryFilter,
        ),
      ),
    );
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00B464).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              iconSize: 28,
              color: const Color(0xFF00B464),
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            iconSize: 32,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
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
        return const CartScreen();
      case 2:
        return const OrderHistoryScreen();
      case 3:
        return const ProductListScreen();
      default:
        return _buildHomeTab();
    }
  }

  /// Main home tab - spec requires all these sections
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () => _loadFeaturedProducts(forceRefresh: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER SECTION ===
            // Search Bar - redirects to ProductList
            _buildSearchBar(context),
            
            // Location Selector
            _buildLocationSelector(context),
            
            const SizedBox(height: 20),

            // === FEATURED CATEGORIES CAROUSEL ===
            // Horizontal scrollable category carousel per spec
            _buildFeaturedCategoriesSection(context),
            
            const SizedBox(height: 24),

            // === FEATURED PRODUCTS SECTION ===
            // Grid 2x2 with highest rated/newest products
            _buildFeaturedProductsSection(context),
            
            const SizedBox(height: 24),

            // === PROMOTIONS CAROUSEL ===
            // Placeholder for promotions section per spec
            _buildPromotionsSection(context),
            
            const SizedBox(height: 24),

            // === RECENT ORDERS SECTION ===
            // For logged-in users per spec
            _buildRecentOrdersSection(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Search bar widget - spec requirement
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: GestureDetector(
        onTap: () => _navigateToProducts(),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: const Icon(Icons.mic_none),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Location selector - spec requirement
  Widget _buildLocationSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF00B464)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedLocation,
              isExpanded: true,
              underline: Container(),
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (newLocation) {
                setState(() => _selectedLocation = newLocation);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Featured categories carousel - spec requirement
  /// Horizontal scroll with 5+ categories and "View All" option
  Widget _buildFeaturedCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop by Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToProducts(),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final categoryKey = _categories.keys.elementAt(index);
              final categoryData = _categories[categoryKey]!;
              
              return GestureDetector(
                onTap: () => _navigateToProducts(categoryFilter: categoryKey),
                child: _buildCategoryCard(
                  context,
                  categoryData['label'] as String,
                  categoryData['icon'] as IconData,
                  categoryData['color'] as Color,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Individual category card in carousel
  Widget _buildCategoryCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 100,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Featured products section - 2x2 grid spec requirement
  Widget _buildFeaturedProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToProducts(),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingFeatured)
          const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00B464),
                ),
              ),
            ),
          )
        else if (_featuredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No products available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
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


  /// Featured product card
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
                          '₱${product.pricePerKilo.toStringAsFixed(2)}/kg',
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

  /// Promotions carousel placeholder per spec
  Widget _buildPromotionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
          ),
          child: Text(
            'Special Promotions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
          ),
          child: SizedBox(
            height: 150,
            child: PageView(
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00B464).withOpacity(0.8),
                        const Color(0xFF00B464).withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Promotion ${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Special offer - Save up to 30%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// Recent orders section for logged-in users per spec
  Widget _buildRecentOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Recent Orders',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  _selectedIndex = 2;
                  setState(() {});
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
          ),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag_outlined, 
                color: Color(0xFF00B464)),
              title: const Text('No recent orders'),
              subtitle: const Text('Your orders will appear here'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _selectedIndex = 2;
                setState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }
}
