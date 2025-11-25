import 'package:flutter/material.dart';
import 'package:opas_flutter/core/constants/app_dimensions.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/notification_history_screen.dart';
import '../../marketplace/screens/product_list_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../order_management/screens/order_history_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _selectedIndex = 0;

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

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                );
              },
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          // Categories Quick Link
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop by Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryBox(context, 'Vegetables', Icons.eco),
                      const SizedBox(width: 12),
                      _buildCategoryBox(context, 'Fruits', Icons.apple),
                      const SizedBox(width: 12),
                      _buildCategoryBox(context, 'Meats', Icons.food_bank),
                      const SizedBox(width: 12),
                      _buildCategoryBox(context, 'Fishes', Icons.water),
                      const SizedBox(width: 12),
                      _buildCategoryBox(context, 'Agricultural\nProducts', Icons.grain),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Featured Products Section
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductListScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppDimensions.gridCrossAxisCount,
              childAspectRatio: 0.65,
              crossAxisSpacing: AppDimensions.gridSpacing,
              mainAxisSpacing: AppDimensions.gridSpacing,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    // Product Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Product Name
                            Text(
                              'Fresh Tomato Vegetable',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Product Price
                            Text(
                              '₱199.99/kg',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: const Color(0xFF00B464),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            // Seller Location
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    'Benguet Farm',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // Add to Cart Button
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart!'),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Color(0xFF00B464),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.shopping_cart, size: 14),
                                label: const Text('Add'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00B464),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBox(
      BuildContext context, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductListScreen()),
        );
      },
      child: SizedBox(
        width: 100,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
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
                Icon(icon, color: const Color(0xFF00B464), size: 32),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
