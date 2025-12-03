import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../../../services/cart_storage_service.dart';
import 'checkout_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/notification_history_screen.dart';

/// Cart Screen - Fully Functional Shopping Cart with Modern Professional Design
/// 
/// Features:
/// - Local state management with SharedPreferences persistence
/// - Real-time cart updates (add, remove, update quantity)
/// - Modern card-based product display matching SALES & INVENTORY design
/// - Quantity increment/decrement controls with modern styling
/// - Order summary with collapsible checkout panel
/// - Empty state with "Continue Shopping" button
/// - Error handling and user feedback
/// - Checkout flow integration
/// - Professional UI with subtle shadows and borders
class CartScreen extends StatefulWidget {
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onContinueShopping});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  late Future<List<CartItem>> _cartFuture;
  List<CartItem> _cachedCartItems = []; // Cache to preserve order during quantity updates
  bool _isCheckoutExpanded = false;
  String? _userId;
  final _cartService = CartStorageService();
  bool _isInitialized = false;  // Track if cart has been initialized
  AppLifecycleState? _lastLifecycleState;  // Track last lifecycle state
  
  // User data
  String _userFirstName = 'Guest';
  String _userLastName = '';

  @override
  void initState() {
    super.initState();
    // Initialize _cartFuture with empty list to prevent LateInitializationError
    _cartFuture = Future.value([]);
    // Register lifecycle observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _initializeCart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cart when screen comes back into focus (after navigation)
    debugPrint('🛒 CartScreen: didChangeDependencies called - refreshing cart');
    if (_isInitialized) {
      setState(() {
        _cartFuture = _getCartFromStorage();
      });
    }
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Load user first name and last name from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? 'Guest';
      final lastName = prefs.getString('last_name') ?? '';
      setState(() {
        _userFirstName = firstName;
        _userLastName = lastName;
      });
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🛒 CartScreen: Lifecycle state changed to $state (was $_lastLifecycleState)');
    
    // Only refresh cart when app actually resumes from background (paused -> resumed)
    // Don't refresh on every navigation or screen change
    if (state == AppLifecycleState.resumed && _lastLifecycleState == AppLifecycleState.paused) {
      debugPrint('🛒 CartScreen: App resumed from background, refreshing cart');
      if (mounted && _isInitialized) {
        setState(() {
          _cartFuture = _getCartFromStorage();
        });
      }
    }
    
    _lastLifecycleState = state;
  }

  Future<void> _initializeCart() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      debugPrint('🛒 CartScreen._initializeCart: Already initialized, skipping');
      return;
    }
    
    // Get user ID from SharedPreferences (set during login)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    debugPrint('🛒 CartScreen._initializeCart: Got user_id=$userId');
    
    if (userId != null) {
      // Migrate any backed-up cart from logout to SQLite/SharedPreferences
      await _cartService.migrateCartIfNeeded(userId);
    }
    
    if (!mounted) return;
    
    setState(() {
      _userId = userId ?? 'guest';
      // After getting user_id, load the correct cart from SQLite
      _cartFuture = _getCartFromStorage();
      _isInitialized = true;
    });
  }

  /// Get cart items from SQLite
  Future<List<CartItem>> _getCartFromStorage() async {
    try {
      debugPrint('🛒 _getCartFromStorage: Loading cart for userId=$_userId');
      final items = await _cartService.getCartItems(_userId ?? 'guest');
      debugPrint('🛒 _getCartFromStorage: Loaded ${items.length} items from SQLite');
      return items;
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      return [];
    }
  }

  /// Group cart items by seller while preserving insertion order
  /// Returns a map where key is seller name and value is list of items from that seller
  Map<String, List<CartItem>> _groupItemsBySeller(List<CartItem> items) {
    final Map<String, List<CartItem>> groupedItems = {};
    final List<String> sellerOrder = []; // Preserve the order sellers appear
    
    for (final item in items) {
      final sellerName = item.sellerName;
      
      if (!groupedItems.containsKey(sellerName)) {
        groupedItems[sellerName] = [];
        sellerOrder.add(sellerName);
      }
      
      groupedItems[sellerName]!.add(item);
    }
    
    // Return as a new map with sellers in the order they were first added
    final orderedMap = <String, List<CartItem>>{};
    for (final seller in sellerOrder) {
      orderedMap[seller] = groupedItems[seller]!;
    }
    
    return orderedMap;
  }

  /// Save cart items to SharedPreferences
  Future<void> _saveCartToStorage(List<CartItem> items) async {
    try {
      // Update cache
      _cachedCartItems = items;
      
      // Clear existing cart and add all items
      await _cartService.clearCart(_userId ?? 'guest');
      for (final item in items) {
        await _cartService.addOrUpdateCartItem(_userId ?? 'guest', item);
      }
      // Refresh UI with cached data
      setState(() {
        _cartFuture = Future.value(_cachedCartItems);
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
      debugPrint('🛒 _updateQuantity: Setting ${item.productId} quantity to $newQuantity');
      
      // Update in storage
      await _cartService.updateQuantity(_userId ?? 'guest', item.productId, newQuantity);
      
      // Update in cache to preserve order and arrangement
      final index = _cachedCartItems.indexWhere((i) => i.productId == item.productId);
      if (index >= 0) {
        _cachedCartItems[index].quantity = newQuantity;
        
        if (!mounted) return;
        debugPrint('🛒 _updateQuantity: Successfully updated cache, refreshing UI without reordering');
        
        // Minimal setState - just triggers rebuild with cached data (no refetch)
        setState(() {
          _cartFuture = Future.value(_cachedCartItems);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        debugPrint('⚠️ _updateQuantity: Item not found in cache! Looking for ${item.productId}');
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
      debugPrint('🛒 _removeItem: Removing ${item.productId} (${item.productName})');
      await _cartService.removeCartItem(_userId ?? 'guest', item.productId);
      
      if (!mounted) return;
      
      // Wait a moment to ensure database write is complete on mobile
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Update cache and refresh cart view
      _cachedCartItems.removeWhere((i) => i.productId == item.productId);
      debugPrint('🛒 _removeItem: Refreshing cart after removal');
      setState(() {
        _cartFuture = Future.value(_cachedCartItems);
      });
      
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
      await _cartService.clearCart(_userId ?? 'guest');
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
    return FutureBuilder<List<CartItem>>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: const Center(child: CircularProgressIndicator(color: Color(0xFF00B464))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final cartItems = snapshot.data ?? [];
        
        // Update cache whenever cart loads to preserve order during updates
        if (cartItems.isNotEmpty) {
          _cachedCartItems = cartItems;
          debugPrint('🛒 build: Updated cache with ${cartItems.length} items');
        }

        if (cartItems.isEmpty) {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _cartFuture = _getCartFromStorage();
                });
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
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add products to your cart to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onContinueShopping?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B464),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Continue Shopping'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final totalAmount = cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);

        return PopScope(
          onPopInvoked: (_) {
            // Refresh cart when returning to this screen
            debugPrint('🛒 CartScreen: PopScope detected pop, refreshing cart');
            setState(() {
              _cartFuture = _getCartFromStorage();
            });
          },
          child: Scaffold(
            body: GestureDetector(
              onTap: _isCheckoutExpanded ? () => setState(() => _isCheckoutExpanded = false) : null,
              child: Stack(
                children: [
                  // Cart Items List with Header wrapped in RefreshIndicator
                  RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _cartFuture = _getCartFromStorage();
                      });
                      // Wait for cart to load
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: const Color(0xFF00B464),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section - Matching Home Screen
                          _buildCartHeader(context),
                          const SizedBox(height: 16),
                          Divider(
                            color: Colors.grey[200],
                            thickness: 1,
                            height: 1,
                          ),
                          const SizedBox(height: 24),
                          // Group items by seller
                          ..._buildSellerGroupedItems(context, cartItems),
                        ],
                      ),
                    ),
                  ),
                  
                  // Floating Collapsible Order Summary
                  if (!_isCheckoutExpanded)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 100),
                        child: GestureDetector(
                          onTap: () => setState(() => _isCheckoutExpanded = true),
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B464),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00B464).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 100),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 32,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _buildExpandedCheckout(context, totalAmount, cartItems),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }  Widget _buildExpandedCheckout(BuildContext context, double totalAmount, List<CartItem> cartItems) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '₱${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B464),
              ),
            ),
            Text(
              '₱${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B464),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 40,
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build seller-grouped sections with items
  /// Returns a list of widgets: seller headers followed by their items
  List<Widget> _buildSellerGroupedItems(BuildContext context, List<CartItem> items) {
    if (items.isEmpty) return [];
    
    final groupedItems = _groupItemsBySeller(items);
    final widgets = <Widget>[];
    
    int sellerIndex = 0;
    groupedItems.forEach((sellerName, sellerItems) {
      // Add seller header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00B464).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF00B464).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.storefront,
                  color: const Color(0xFF00B464),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sellerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF00B464),
                    ),
                  ),
                ),
                Text(
                  '${sellerItems.length} item${sellerItems.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Add items for this seller
      for (int itemIndex = 0; itemIndex < sellerItems.length; itemIndex++) {
        final item = sellerItems[itemIndex];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 8),
            child: _buildModernCartItemCard(context, item),
          ),
        );
      }
      
      // Add divider between sellers (except after the last seller)
      sellerIndex++;
      if (sellerIndex < groupedItems.length) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Colors.grey[200],
              thickness: 1,
              height: 1,
            ),
          ),
        );
      }
    });
    
    return widgets;
  }

  Widget _buildModernCartItemCard(BuildContext context, CartItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              image: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(item.imageUrl!),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        debugPrint('❌ Failed to load image: ${item.imageUrl}');
                      },
                    )
                  : null,
            ),
            child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                ? Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name and Remove Button
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _removeItem(item),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Price, Subtotal, and Quantity Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₱${item.price.toStringAsFixed(2)}/${item.unit}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${item.subtotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00B464),
                          ),
                        ),
                      ],
                    ),
                    
                    // Quantity Selector
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: item.quantity > 1
                                  ? () => _updateQuantity(item, item.quantity - 1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: item.quantity > 1 ? Colors.black87 : Colors.grey[400],
                                ),
                              ),
                            ),
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _updateQuantity(item, item.quantity + 1),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
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
    );
  }

  /// Build header widget for cart screen
  Widget _buildCartHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_userFirstName $_userLastName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'OPAS Cart',
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
}
