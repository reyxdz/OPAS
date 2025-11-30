import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cart/models/cart_item_model.dart';
import '../../products/services/buyer_api_service.dart';
import '../../order_management/screens/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String? _selectedFulfillmentMethod;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('address') ?? '';
    setState(() {
      _addressController.text = address;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFulfillmentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a fulfillment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send productId instead of item.id (item.id is just a local timestamp)
      final cartItemIds = widget.cartItems.map((item) => int.parse(item.productId)).toList();
      final order = await BuyerApiService.placeOrder(
        cartItemIds: cartItemIds,
        paymentMethod: _selectedFulfillmentMethod!,
        deliveryAddress: _addressController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === CHECKOUT PROGRESS INDICATOR ===
              _buildCheckoutProgress(),
              const SizedBox(height: 32),

              // === ORDER ITEMS SECTION ===
              _buildOrderItemsSection(context),
              const SizedBox(height: 32),

              // === DELIVERY ADDRESS SECTION ===
              _buildDeliveryAddressSection(context),
              const SizedBox(height: 32),

              // === FULFILLMENT METHOD SECTION ===
              _buildFulfillmentMethodSection(context),
              const SizedBox(height: 32),

              // === ORDER SUMMARY CARD ===
              _buildOrderSummaryCard(context),
              const SizedBox(height: 20),

              // === TERMS AND CONDITIONS ===
              _buildTermsSection(context),
              const SizedBox(height: 28),

              // === PLACE ORDER BUTTON ===
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _placeOrder,
                  icon: _isLoading ? null : const Icon(Icons.check_circle_outline),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B464),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: const Color(0xFF00B464).withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Checkout Progress Indicator
  Widget _buildCheckoutProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildProgressStep(1, 'Cart', true),
        Container(
          width: 40,
          height: 2,
          color: const Color(0xFF00B464),
        ),
        _buildProgressStep(2, 'Checkout', true),
        Container(
          width: 40,
          height: 2,
          color: Colors.grey[300],
        ),
        _buildProgressStep(3, 'Confirm', false),
      ],
    );
  }

  Widget _buildProgressStep(int step, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF00B464) : Colors.grey[200],
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: active ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? Colors.black : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  /// Order Items Section
  Widget _buildOrderItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00B464).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.cartItems.length} items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF00B464),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.cartItems.map((item) {
          return _buildOrderItemCard(context, item);
        }).toList(),
      ],
    );
  }

  Widget _buildOrderItemCard(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
              image: (item.imageUrl?.isNotEmpty ?? false)
                  ? DecorationImage(
                      image: NetworkImage(item.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (item.imageUrl?.isEmpty ?? true)
                ? Icon(Icons.image_not_supported, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity} × ₱${item.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₱${item.subtotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00B464),
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

  /// Delivery Address Section
  Widget _buildDeliveryAddressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00B464).withOpacity(0.1),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFF00B464), size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Delivery Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Text(
            _addressController.text.isEmpty
                ? 'No address selected'
                : _addressController.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _addressController.text.isEmpty
                  ? Colors.grey[400]
                  : Colors.black,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Fulfillment Method Section (Delivery/Pickup based on seller options)
  Widget _buildFulfillmentMethodSection(BuildContext context) {
    // Determine available fulfillment options from cart items
    bool allItemsAllowDelivery = widget.cartItems.isNotEmpty;
    bool allItemsAllowPickup = widget.cartItems.isNotEmpty;

    for (var item in widget.cartItems) {
      // Assuming CartItem has these properties or we check from product data
      // For now, we'll show both options as available if items support it
    }

    List<Map<String, dynamic>> fulfillmentOptions = [];
    
    // Add delivery option if available
    fulfillmentOptions.add({
      'id': 'delivery',
      'name': 'Delivery',
      'description': 'Get your order delivered to your address',
      'icon': Icons.local_shipping,
    });

    // Add pickup option if available
    fulfillmentOptions.add({
      'id': 'pickup',
      'name': 'Pickup',
      'description': 'Pick up your order from the seller',
      'icon': Icons.storefront,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00B464).withOpacity(0.1),
              ),
              child: const Icon(Icons.local_shipping, color: Color(0xFF00B464), size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Fulfillment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedFulfillmentMethod != null)
          _buildSelectedFulfillmentDisplay(context, _selectedFulfillmentMethod!)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Center(
              child: Text(
                'Select a fulfillment method',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showFulfillmentMethodSelector(context, fulfillmentOptions);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Change Fulfillment Method'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF00B464)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFulfillmentDisplay(BuildContext context, String method) {
    String displayName = 'Delivery';
    String description = 'Get your order delivered to your address';
    IconData icon = Icons.local_shipping;

    if (method == 'pickup') {
      displayName = 'Pickup';
      description = 'Pick up your order from the seller';
      icon = Icons.storefront;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00B464), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF00B464).withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B464).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00B464),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00B464),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFulfillmentMethodSelector(BuildContext context, List<Map<String, dynamic>> options) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Fulfillment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFulfillmentMethodOption(
                    context,
                    option['id'],
                    option['name'],
                    option['description'],
                    option['icon'],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFulfillmentMethodOption(
    BuildContext context,
    String id,
    String name,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedFulfillmentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFulfillmentMethod = id);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF00B464) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF00B464).withOpacity(0.08) : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00B464).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF00B464) : Colors.grey[100],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00B464),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Order Summary Card
  Widget _buildOrderSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF00B464).withOpacity(0.05),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱${widget.totalAmount.toStringAsFixed(2)}',
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
                'Delivery Fee',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱0.00',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₱${widget.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00B464),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Terms and Conditions Section
  Widget _buildTermsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() => _agreedToTerms = value ?? false);
              },
              activeColor: const Color(0xFF00B464),
              side: BorderSide(
                color: _agreedToTerms ? const Color(0xFF00B464) : Colors.grey[300]!,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // Show terms and conditions
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms and Conditions dialog coming soon'),
                      ),
                    );
                  },
                  child: Text(
                    'I agree to the Terms and Conditions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF00B464),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By continuing, you agree to OPAS marketplace policies',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
