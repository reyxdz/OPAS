import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailModal extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailModal({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<ProductDetailModal> {
  late PageController _imageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  List<String> _getImageUrls() {
    final images = widget.product['images'] as List?;
    if (images != null && images.isNotEmpty) {
      return List<String>.from(images.cast<String>());
    }
    final imageUrl = widget.product['image_url'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return [imageUrl];
    }
    return [];
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  double _getPrice(dynamic priceValue) {
    if (priceValue is String) {
      return double.tryParse(priceValue) ?? 0.0;
    }
    return (priceValue as num?)?.toDouble() ?? 0.0;
  }

  Color _getTypeColor(String productType) {
    final typeColors = {
      'VEGETABLE': const Color(0xFF10B981),
      'FRUIT': const Color(0xFFF59E0B),
      'GRAIN': const Color(0xFF8B5CF6),
      'POULTRY': const Color(0xFFEC4899),
      'DAIRY': const Color(0xFF0EA5E9),
    };
    return typeColors[productType] ?? const Color(0xFF6B7280);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF10B981);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _getImageUrls();
    final productType = widget.product['category'] as String? ?? 'GENERAL';
    final status = widget.product['status_display'] as String? ?? 'Unknown';
    final price = _getPrice(widget.product['price']);
    final opasCeiling = _getPrice(widget.product['ceiling_price'] ?? 0);
    final opasRegulatedPrice = opasCeiling > 0 ? opasCeiling * 1.2 : price * 1.15;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image Section
                        if (imageUrls.isNotEmpty)
                          _buildImageGallery(imageUrls)
                        else
                          _buildImagePlaceholder(),

                        // Content Section
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Product Title and Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.product['name'] as String? ?? 'Unknown Product',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF121212),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Quick Info Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(productType).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          productType,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getTypeColor(productType),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(widget.product['created_at'] as String?),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF909090),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  _buildDivider(),
                                  const SizedBox(height: 16),

                                  // PRICING (Most Relevant)
                                  const Text(
                                    'Pricing',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF121212),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildPriceRow('Price', price, widget.product['unit'] ?? 'unit'),
                                  const SizedBox(height: 8),
                                  _buildPriceRow('Ceiling', opasCeiling, widget.product['unit'] ?? 'unit'),
                                  const SizedBox(height: 8),
                                  _buildPriceRow('OPAS Price', opasRegulatedPrice, widget.product['unit'] ?? 'unit'),

                                  const SizedBox(height: 16),
                                  _buildDivider(),
                                  const SizedBox(height: 16),

                                  // STOCK (Very Relevant)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Stock Level',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${widget.product['stock_level'] ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF121212),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Unit',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.product['unit'] as String? ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF121212),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ((widget.product['minimum_stock'] ?? 0) > 0)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Min Stock',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${widget.product['minimum_stock']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF121212),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  _buildDivider(),
                                  const SizedBox(height: 16),

                                  // SELLER (Relevant)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00B464).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.store,
                                          color: Color(0xFF00B464),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.product['seller_name'] as String? ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF121212),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  '4.8',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF121212),
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '(234)',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  _buildDivider(),
                                  const SizedBox(height: 16),

                                  // DESCRIPTION (Less Important but included)
                                  if (widget.product['description'] != null &&
                                      (widget.product['description'] as String).isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.product['description'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF424242),
                                            height: 1.4,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 20),

                                  // Close Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00B464),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _imageController,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00B464),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        if (imageUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (_currentImageIndex > 0)
                      GestureDetector(
                        onTap: () {
                          _imageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (_currentImageIndex < imageUrls.length - 1)
                      GestureDetector(
                        onTap: () {
                          _imageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'No image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildPriceRow(String label, double price, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF606060),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00B464).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '₱${price.toStringAsFixed(2)}/$unit',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00B464),
            ),
          ),
        ),
      ],
    );
  }
}
