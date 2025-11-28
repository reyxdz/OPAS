import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/cart_item_model.dart';
import 'checkout_screen.dart';
import '../../products/screens/product_list_screen.dart';

/// Cart Screen - Fully Functional Shopping Cart with Local Persistence
/// 
/// Features:
/// - Local state management with SharedPreferences persistence
/// - Real-time cart updates (add, remove, update quantity)
/// - Modern card-based product display with images
/// - Quantity increment/decrement controls
/// - Order summary with total calculation
/// - Empty state with "Continue Shopping" button
/// - Error handling and user feedback
/// - Checkout flow integration
class CartScreen extends StatefulWidget {
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onContinueShopping});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  late Future<List<CartItem>> _cartFuture;
  bool _isCheckoutExpanded = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);
    // Initialize _cartFuture immediately with a default empty future
    _cartFuture = Future.value([]);
    _initializeCart();
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh cart when app resumes (return from other screen)
    if (state == AppLifecycleState.resumed) {
      debugPrint('🛒 CartScreen: App resumed, refreshing cart');
      setState(() {
        _cartFuture = _getCartFromStorage();
      });
    }
  }

  Future<void> _initializeCart() async {
    // Get user ID from SharedPreferences (set during login)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    debugPrint('🛒 CartScreen._initializeCart: Got user_id=$userId');
    
    setState(() {
      _userId = userId;
      // After getting user_id, load the correct cart
      _cartFuture = _getCartFromStorage();
    });
    
    // Debug: Show all SharedPreferences keys that start with 'cart_items'
    final allKeys = prefs.getKeys();
    final cartKeys = allKeys.where((key) => key.startsWith('cart_items')).toList();
    debugPrint('🛒 CartScreen: All cart keys in SharedPreferences: $cartKeys');
    for (final key in cartKeys) {
      final value = prefs.getString(key);
      debugPrint('🛒   $key = ${value != null ? value.substring(0, min(100, value.length)) : 'null'}...');
    }
  }

  String get _cartKey => 'cart_items_${_userId ?? 'guest'}';

  /// Get cart items from SharedPreferences
  Future<List<CartItem>> _getCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey) ?? '[]';
      debugPrint('🛒 _getCartFromStorage: key=$_cartKey, json=$cartJson');
      final List<dynamic> decoded = jsonDecode(cartJson);
      final items = decoded
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
      debugPrint('🛒 _getCartFromStorage: Loaded ${items.length} items from cart');
      return items;
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      return [];
    }
  }

  /// Save cart items to SharedPreferences
  Future<void> _saveCartToStorage(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
      // Refresh UI
      setState(() {
        _cartFuture = _getCartFromStorage();
      });
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  /// Add item to cart or update quantity if already exists
  Future<void> _addItemToCart(CartItem newItem) async {
    try {
      final cart = await _getCartFromStorage();
      
      // Check if item already in cart
      final existingIndex = cart.indexWhere((item) => item.productId == newItem.productId);
      
      if (existingIndex >= 0) {
        // Update quantity
        cart[existingIndex].quantity += newItem.quantity;
      } else {
        // Add new item
        cart.add(newItem);
      }
      
      await _saveCartToStorage(cart);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newItem.productName} added to cart'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Update item quantity in cart
  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) {
      _removeItem(item);
      return;
    }

    try {
      final cart = await _getCartFromStorage();
      final index = cart.indexWhere((i) => i.id == item.id);
      
      if (index >= 0) {
        cart[index].quantity = newQuantity;
        await _saveCartToStorage(cart);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Remove item from cart
  Future<void> _removeItem(CartItem item) async {
    try {
      final cart = await _getCartFromStorage();
      cart.removeWhere((i) => i.id == item.id);
      await _saveCartToStorage(cart);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productName} removed from cart'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Clear entire cart
  Future<void> _clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      setState(() {
        _cartFuture = _getCartFromStorage();
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart cleared'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _isCheckoutExpanded ? () => setState(() => _isCheckoutExpanded = false) : null,
        child: FutureBuilder<List<CartItem>>(
          future: _cartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final cartItems = snapshot.data ?? [];

            if (cartItems.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _cartFuture = _getCartFromStorage();
                  });
                  // Wait a bit for the future to complete
                  await _cartFuture;
                },
                color: const Color(0xFF00B464),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add products to your cart to get started',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onContinueShopping?.call();
                              },
                              child: const Text('Continue Shopping'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final totalAmount =
                cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _cartFuture = _getCartFromStorage();
                });
              },
              color: const Color(0xFF00B464),
              child: Stack(
                children: [
                  // Cart Items List
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItemCard(context, item);
                    },
                  ),
                  
                  // Checkout Panel (Collapsible)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: !_isCheckoutExpanded
                          ? () => setState(() => _isCheckoutExpanded = true)
                          : null,
                      child: _isCheckoutExpanded
                          ? ScaleTransition(
                              scale: AlwaysStoppedAnimation(1.0),
                              child: FadeTransition(
                                opacity: AlwaysStoppedAnimation(1.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: MediaQuery.of(context).size.width - 32,
                                  height: 180,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: _buildExpandedCheckout(context, totalAmount, cartItems),
                                ),
                              ),
                            )
                          : ScaleTransition(
                              scale: AlwaysStoppedAnimation(1.0),
                              child: FadeTransition(
                                opacity: AlwaysStoppedAnimation(1.0),
                                child: Center(
                                  child: _buildCollapsedCheckout(context, totalAmount),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedCheckout(BuildContext context, double totalAmount) {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF00B464),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B464).withOpacity(0.4),
              blurRadius: 5,
              spreadRadius: 0.5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildExpandedCheckout(BuildContext context, double totalAmount, List<CartItem> cartItems) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isCheckoutExpanded = false),
                child: Icon(
                  Icons.close,
                  size: 24,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₱${totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00B464),
                ),
              ),
              Text(
                '₱${totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00B464),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      cartItems: cartItems,
                      totalAmount: totalAmount,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B464),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                image: item.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl.isEmpty
                  ? Icon(Icons.image_not_supported, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.sellerName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeItem(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        '₱${item.pricePerKilo.toStringAsFixed(2)}/${item.unit}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF00B464),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: item.quantity > 1
                                  ? () => _updateQuantity(item, item.quantity - 1)
                                  : null,
                            ),
                            SizedBox(
                              width: 32,
                              child: Text(
                                item.quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () => _updateQuantity(item, item.quantity + 1),
                            ),
                          ],
                        ),
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: onPressed == null ? Colors.grey[400] : Colors.black87,
          ),
        ),
      ),
    );
  }
}
