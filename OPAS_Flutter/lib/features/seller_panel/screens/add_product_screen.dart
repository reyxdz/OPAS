import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/seller_service.dart';
import '../models/product_category_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedUnit = 'kg';
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _productCreatedSuccessfully = false;

  // Category dropdown state
  List<ProductCategory> _categories = [];
  ProductCategory? _selectedCategory;
  bool _categoriesLoading = true;

  // Delivery and Pickup options
  bool _isAvailableForDelivery = false;
  bool _isAvailableForPickup = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFormDraft();
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await SellerService.getProductCategories();
      setState(() {
        _categories = categoriesData
            .map((data) => ProductCategory.fromJson(data))
            .toList();
        _categoriesLoading = false;
      });
      print('Categories loaded: ${_categories.length}');
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categoriesLoading = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load categories: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadFormDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _nameController.text = prefs.getString('draft_product_name') ?? '';
        _descriptionController.text =
            prefs.getString('draft_product_description') ?? '';
        _priceController.text = prefs.getString('draft_product_price') ?? '';
        _quantityController.text =
            prefs.getString('draft_product_quantity') ?? '';
        _selectedUnit = prefs.getString('draft_product_unit') ?? 'kg';

        // Load category selection
        final draftCategoryId = prefs.getInt('draft_product_category_id');

        if (draftCategoryId != null && _categories.isNotEmpty) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == draftCategoryId,
            orElse: () => _categories.first,
          );
        }

        // Load delivery and pickup options
        _isAvailableForDelivery = prefs.getBool('draft_product_delivery') ?? false;
        _isAvailableForPickup = prefs.getBool('draft_product_pickup') ?? false;
      });
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _saveFormDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_product_name', _nameController.text);
      await prefs.setString(
          'draft_product_description', _descriptionController.text);
      await prefs.setString('draft_product_price', _priceController.text);
      await prefs.setString('draft_product_quantity', _quantityController.text);
      await prefs.setString('draft_product_unit', _selectedUnit);

      // Save category selection
      if (_selectedCategory != null) {
        await prefs.setInt('draft_product_category_id', _selectedCategory!.id);
      }

      // Save delivery and pickup options
      await prefs.setBool('draft_product_delivery', _isAvailableForDelivery);
      await prefs.setBool('draft_product_pickup', _isAvailableForPickup);
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _clearFormDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_product_name');
      await prefs.remove('draft_product_description');
      await prefs.remove('draft_product_price');
      await prefs.remove('draft_product_quantity');
      await prefs.remove('draft_product_unit');
      await prefs.remove('draft_product_category_id');
      await prefs.remove('draft_product_delivery');
      await prefs.remove('draft_product_pickup');
    } catch (e) {
      // Fail silently
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _quantityController.clear();
    setState(() {
      _selectedUnit = 'kg';
      _selectedCategory = null;
      _selectedImages.clear();
      _isAvailableForDelivery = false;
      _isAvailableForPickup = false;
    });
    _formKey.currentState?.reset();
    _saveClearedFormState();
  }

  Future<void> _saveClearedFormState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_product_name', '');
      await prefs.setString('draft_product_description', '');
      await prefs.setString('draft_product_price', '');
      await prefs.setString('draft_product_quantity', '');
      await prefs.setString('draft_product_unit', 'kg');
      await prefs.remove('draft_product_category_id');
      await prefs.setBool('draft_product_delivery', false);
      await prefs.setBool('draft_product_pickup', false);
    } catch (e) {
      // Fail silently
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    // Only save draft if product was NOT created successfully
    if (!_productCreatedSuccessfully) {
      _saveFormDraft();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFiles.isEmpty) return;

      // Validate format
      final validFormats = ['jpg', 'jpeg', 'png'];
      final invalidImages = <String>[];

      for (final file in pickedFiles) {
        final ext = file.path.split('.').last.toLowerCase();
        if (!validFormats.contains(ext)) {
          invalidImages.add(file.name);
        }
      }

      if (invalidImages.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Invalid format: ${invalidImages.join(', ')}. Only JPG and PNG allowed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check max 5 images
      if (_selectedImages.length + pickedFiles.length > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 5 images allowed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImages.addAll(
          pickedFiles.map((file) => File(file.path)).toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 3 || name.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product name must be between 3-100 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that at least one delivery option is selected
    if (!_isAvailableForDelivery && !_isAvailableForPickup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one delivery option (Delivery or Pickup)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use selected category
      final categoryId = _selectedCategory?.id;

      final productData = {
        'name': name,
        'description': _descriptionController.text,
        if (categoryId != null) 'category': categoryId,
        'price': double.parse(_priceController.text),
        'stock_level': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'is_available_for_delivery': _isAvailableForDelivery,
        'is_available_for_pickup': _isAvailableForPickup,
      };

      final product = await SellerService.createProduct(productData);

      // Upload images
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            await SellerService.uploadProductImage(
              productId: product.id,
              imagePath: _selectedImages[i].path,
              isPrimary: i == 0,
              altText: product.name,
            );
          } catch (imageError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Warning: Failed to upload image ${i + 1}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }

      await _clearFormDraft();
      _resetForm();

      // Save cleared state to ensure it doesn't reload on next init
      await _saveClearedFormState();

      // Mark product as successfully created
      _productCreatedSuccessfully = true;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon with Animation
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B464).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF00B464),
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Success Title
                    const Text(
                      'Product Created!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00B464),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Success Message
                    const Text(
                      'Your product has been successfully added to your inventory.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Done Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Return true to indicate product was successfully created
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B464),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error Creating Product'),
              content: SingleChildScrollView(
                child: Text('$e'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String hintText,
      {bool hasError = false}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFF00B464),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00B464),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
              _buildSectionCard(
                title: 'BASIC INFORMATION',
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        maxLength: 100,
                        decoration: _buildInputDecoration(
                            'e.g., Fresh Organic Tomatoes'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Product name is required';
                          }
                          if (value.length < 3) {
                            return 'Minimum 3 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            _buildInputDecoration('Describe your product...'),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Details Card
              _buildSectionCard(
                title: 'PRODUCT DETAILS',
                children: [
                  // Category Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _categoriesLoading
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<ProductCategory>(
                              value: _selectedCategory,
                              hint: const Text('Select Category'),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              decoration: _buildInputDecoration(''),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Delivery Options
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fulfillment Options',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.withOpacity(0.02),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _isAvailableForDelivery,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailableForDelivery = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF00B464),
                              title: const Text(
                                'Available for Delivery',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: const Text(
                                'Buyers can have this product delivered',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const Divider(height: 12),
                            CheckboxListTile(
                              value: _isAvailableForPickup,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailableForPickup = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF00B464),
                              title: const Text(
                                'Available for Pickup',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: const Text(
                                'Buyers can pick up this product from your store',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing & Inventory Card
              _buildSectionCard(
                title: 'PRICING & INVENTORY',
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price per Unit (₱)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _buildInputDecoration('0.00'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Price is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid price';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stock Level',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration('0'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                if (int.parse(value) <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                            ),
                          ],
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
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              items: const [
                                DropdownMenuItem(
                                    value: 'kg', child: Text('kg')),
                                DropdownMenuItem(
                                    value: 'pcs', child: Text('pcs')),
                                DropdownMenuItem(
                                    value: 'bundle', child: Text('bundle')),
                                DropdownMenuItem(
                                    value: 'box', child: Text('box')),
                                DropdownMenuItem(
                                    value: 'liter', child: Text('liter')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedUnit = value;
                                  });
                                }
                              },
                              decoration: _buildInputDecoration(''),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Images Card
              _buildSectionCard(
                title: 'PRODUCT IMAGES',
                children: [
                  if (_selectedImages.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00B464),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          child: const Text(
                                            'Primary',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.red.withOpacity(0.3),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
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
                        const SizedBox(height: 14),
                      ],
                    ),
                  GestureDetector(
                    onTap: _selectedImages.length < 5 ? _pickImages : null,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedImages.length < 5
                              ? const Color(0xFF00B464).withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedImages.length < 5
                            ? const Color(0xFF00B464).withOpacity(0.02)
                            : Colors.grey.withOpacity(0.02),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 32,
                              color: _selectedImages.length < 5
                                  ? const Color(0xFF00B464)
                                  : Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Tap to add images'
                                  : _selectedImages.length < 5
                                      ? 'Add more (${_selectedImages.length}/5)'
                                      : 'Maximum images reached',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _selectedImages.length < 5
                                    ? const Color(0xFF00B464)
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG • Max 5 images',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B464),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isLoading ? 0 : 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
