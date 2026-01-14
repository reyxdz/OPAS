import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/seller_service.dart';

class SubmitOPASOfferScreen extends StatefulWidget {
  const SubmitOPASOfferScreen({Key? key}) : super(key: key);

  @override
  State<SubmitOPASOfferScreen> createState() => _SubmitOPASOfferScreenState();
}

class _SubmitOPASOfferScreenState extends State<SubmitOPASOfferScreen> {
  late TextEditingController _productNameController;
  late TextEditingController _productTypeController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;

  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  // Form validation state
  Map<String, String?> _errors = {};

  final List<String> _unitOptions = ['kg', 'g', 'lbs', 'ml', 'l', 'pc', 'dozen'];

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productTypeController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _unitController = TextEditingController(text: 'kg');
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productTypeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  bool _validateForm() {
    setState(() => _errors = {});
    
    final newErrors = <String, String?>{};
    
    if (_productNameController.text.trim().isEmpty) {
      newErrors['productName'] = 'Product name is required';
    }
    if (_productTypeController.text.trim().isEmpty) {
      newErrors['productType'] = 'Product type is required';
    }
    if (_priceController.text.isEmpty) {
      newErrors['price'] = 'Price is required';
    } else {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        newErrors['price'] = 'Price must be greater than 0';
      }
    }
    if (_quantityController.text.isEmpty) {
      newErrors['quantity'] = 'Quantity is required';
    } else {
      final quantity = double.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        newErrors['quantity'] = 'Quantity must be greater than 0';
      }
    }
    
    setState(() => _errors = newErrors);
    return newErrors.isEmpty;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  double _getEstimatedTotal() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    return price * quantity;
  }

  Future<void> _submitOPASoffer() async {
    if (!_validateForm()) {
      _showError('Please fix the errors above');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);
      final quantity = double.parse(_quantityController.text);
      
      // Get image paths from selected files
      final imagePaths = _selectedImages.map((file) => file.path).toList();

      final result = await SellerService.submitOPASoffer(
        productType: _productTypeController.text.trim(),
        quantity: quantity.toInt(),
        qualityGrade: 'STANDARD',
        estimatedPrice: price,
        imagePaths: imagePaths,  // Pass selected images
      );

      if (!mounted) return;

      if (result != null) {
        _showSuccess('Offer submitted to OPAS successfully!');
        
        // Clear form and navigate back after a brief delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? errorKey,
    String? suffix,
    Widget? suffixWidget,
  }) {
    final hasError = _errors.containsKey(errorKey) && _errors[errorKey] != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (suffix != null)
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: const Color(0xFF00B464)),
            suffixIcon: suffixWidget,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00B464),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorText: hasError ? _errors[errorKey] : null,
            errorMaxLines: 2,
          ),
          onChanged: (_) {
            if (hasError && errorKey != null) {
              setState(() {
                _errors.remove(errorKey);
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedTotal = _getEstimatedTotal();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sell to OPAS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== INFO CARD =====
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00B464).withOpacity(0.08),
                border: Border.all(
                  color: const Color(0xFF00B464).withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B464).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00B464),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Submit your product details for OPAS to review and approve',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ===== PRODUCT DETAILS SECTION =====
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildFormField(
              label: 'Product Name',
              hint: 'e.g., Premium Tomatoes',
              controller: _productNameController,
              icon: Icons.local_florist,
              errorKey: 'productName',
            ),
            const SizedBox(height: 16),

            _buildFormField(
              label: 'Product Type/Category',
              hint: 'e.g., Vegetables, Rice, Fruits',
              controller: _productTypeController,
              icon: Icons.category,
              errorKey: 'productType',
            ),
            const SizedBox(height: 28),

            // ===== PRICING & QUANTITY SECTION =====
            Text(
              'Pricing & Quantity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildFormField(
              label: 'Price per Unit',
              hint: '0.00',
              controller: _priceController,
              icon: Icons.currency_exchange,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              errorKey: 'price',
              suffix: '₱/unit',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'Quantity',
                    hint: '0.00',
                    controller: _quantityController,
                    icon: Icons.scale,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    errorKey: 'quantity',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _unitController.text,
                          underline: Container(),
                          items: _unitOptions.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _unitController.text = newValue);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF00B464),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== ESTIMATED TOTAL CARD =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Total Value',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${estimatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00B464),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B464).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(double.tryParse(_quantityController.text) ?? 0).toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00B464),
                          ),
                        ),
                        Text(
                          _unitController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ===== PRODUCT IMAGES SECTION =====
            Text(
              'Product Images',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add photos to help OPAS review your product (optional)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00B464),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF00B464).withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: const Color(0xFF00B464).withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Add Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00B464),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to select product images',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF00B464),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF00B464).withOpacity(0.05),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xFF00B464),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedImages.removeAt(index));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
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
                ],
              ),
            const SizedBox(height: 32),

            // ===== SUBMIT BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOPASoffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B464),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Submit Offer to OPAS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
