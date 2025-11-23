import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../../products/models/review_model.dart';
import '../../products/services/buyer_api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _productFuture;
  late Future<List<ProductReview>> _reviewsFuture;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture =
        BuyerApiService.getProductDetail(widget.productId);
    _reviewsFuture =
        BuyerApiService.getProductReviews(widget.productId);
  }

  Future<void> _addToCart(Product product) async {
    try {
      await BuyerApiService.addToCart(product.id, _quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$_quantity × ${product.name} added to cart!'),
          backgroundColor: Colors.green,
        ),
      );
      // Optionally navigate back or refresh
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey[400],
                            );
                          },
                        )
                      : Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style:
                                      Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          if (!product.isWithinRegulatedPrice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'High Price',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price per ${product.unit}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '₱${product.pricePerKilo.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF00B464),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OPAS Regulated Price',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    Text(
                                      '₱${product.opasRegulatedPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      // Product Details Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _buildDetailCard(
                            context,
                            'Stock',
                            '${product.stock} ${product.unit}s',
                            Icons.inventory_2,
                            product.isAvailable
                                ? Colors.green
                                : Colors.red,
                          ),
                          _buildDetailCard(
                            context,
                            'Seller Rating',
                            product.sellerRating.toStringAsFixed(1),
                            Icons.star,
                            Colors.amber,
                          ),
                          _buildDetailCard(
                            context,
                            'Seller',
                            product.sellerName,
                            Icons.store,
                            Colors.blue,
                          ),
                          _buildDetailCard(
                            context,
                            'Status',
                            product.isAvailable
                                ? 'Available'
                                : 'Out of Stock',
                            Icons.check_circle,
                            product.isAvailable
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Reviews Section
                      Text(
                        'Customer Reviews',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<ProductReview>>(
                        future: _reviewsFuture,
                        builder: (context, reviewSnapshot) {
                          if (reviewSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (reviewSnapshot.hasError || reviewSnapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No reviews yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            );
                          }

                          final reviews = reviewSnapshot.data!
                              .take(3)
                              .toList();
                          return Column(
                            children: reviews
                                .map((review) =>
                                    _buildReviewCard(context, review))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final product = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 40,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            controller: TextEditingController(
                              text: _quantity.toString(),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _quantity = parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _quantity < product.stock
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: product.isAvailable
                        ? () => _addToCart(product)
                        : null,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.buyerName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < review.rating.toInt()
                          ? Icons.star
                          : Icons.star_outline,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            review.comment,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
