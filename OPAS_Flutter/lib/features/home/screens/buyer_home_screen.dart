import 'package:flutter/material.dart';
import 'package:opas_flutter/core/constants/app_dimensions.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import '../../marketplace/screens/product_list_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../order_management/screens/order_history_screen.dart';
import '../models/notification_model.dart';
import '../../products/services/buyer_api_service.dart';

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
            onPressed: () {},
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
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip(context, 'Vegetables', Icons.eco),
                      const SizedBox(width: 8),
                      _buildCategoryChip(context, 'Fruits', Icons.restaurant),
                      const SizedBox(width: 8),
                      _buildCategoryChip(context, 'Grains', Icons.grain),
                      const SizedBox(width: 8),
                      _buildCategoryChip(context, 'Dairy', Icons.coffee),
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
              childAspectRatio: AppDimensions.gridChildAspectRatio,
              crossAxisSpacing: AppDimensions.gridSpacing,
              mainAxisSpacing: AppDimensions.gridSpacing,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1),
                        child: Icon(
                          Icons.image,
                          size: AppDimensions.iconLarge,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product $index',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimensions.paddingXSmall),
                          Text(
                            '₱999.99',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Promotional Banner
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00B464).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00B464)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎉 Special Offers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get up to 20% off on selected items this week!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProductListScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B464),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Shop Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductListScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00B464), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
