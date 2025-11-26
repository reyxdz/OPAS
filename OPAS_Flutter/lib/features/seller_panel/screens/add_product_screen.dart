import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/seller_service.dart';

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

  String _selectedProductType = 'VEGETABLE';
  String _selectedQualityGrade = 'STANDARD';
  String _selectedUnit = 'kg';
  final List<File> _selectedImages = [];
  double? _ceilingPrice;
  bool _isLoading = false;
  bool _priceExceedsCeiling = false;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_checkCeilingPrice);
    _loadFormDraft();
  }

  Future<void> _loadFormDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load quality grade and migrate old values (A/B/C) to new values (PREMIUM/STANDARD/BASIC)
      String qualityGrade = prefs.getString('draft_product_quality') ?? 'STANDARD';
      
      // Migrate old values
      final qualityGradeMigration = {
        'A': 'PREMIUM',
        'B': 'STANDARD',
        'C': 'BASIC',
      };
      
      if (qualityGradeMigration.containsKey(qualityGrade)) {
        qualityGrade = qualityGradeMigration[qualityGrade]!;
        // Update stored value to new format
        await prefs.setString('draft_product_quality', qualityGrade);
      }
      
      // Ensure the value is valid
      final validGrades = ['PREMIUM', 'STANDARD', 'BASIC'];
      if (!validGrades.contains(qualityGrade)) {
        qualityGrade = 'STANDARD';
      }
      
      setState(() {
        _nameController.text = prefs.getString('draft_product_name') ?? '';
        _descriptionController.text =
            prefs.getString('draft_product_description') ?? '';
        _priceController.text = prefs.getString('draft_product_price') ?? '';
        _quantityController.text = prefs.getString('draft_product_quantity') ?? '';
        _selectedProductType =
            prefs.getString('draft_product_type') ?? 'VEGETABLE';
        _selectedQualityGrade = qualityGrade;
        _selectedUnit = prefs.getString('draft_product_unit') ?? 'kg';
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
      await prefs.setString('draft_product_type', _selectedProductType);
      await prefs.setString('draft_product_quality', _selectedQualityGrade);
      await prefs.setString('draft_product_unit', _selectedUnit);
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
      await prefs.remove('draft_product_type');
      await prefs.remove('draft_product_quality');
      await prefs.remove('draft_product_unit');
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
    _saveFormDraft();
    super.dispose();
  }

  Future<void> _checkCeilingPrice() async {
    if (_priceController.text.isEmpty || _selectedProductType.isEmpty) {
      return;
    }

    try {
      final result = await SellerService.checkCeilingPrice({
        'product_type': _selectedProductType,
      });

      final ceiling = (result['ceiling_price'] as num?)?.toDouble() ?? 0.0;
      final currentPrice = double.tryParse(_priceController.text) ?? 0.0;

      setState(() {
        _ceilingPrice = ceiling;
        _priceExceedsCeiling = currentPrice > ceiling;
      });
    } catch (e) {
      // Fail silently
    }
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

    if (_priceExceedsCeiling) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price exceeds ceiling price. Please adjust.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'name': name,
        'description': _descriptionController.text,
        'product_type': _selectedProductType,
        'quality_grade': _selectedQualityGrade,
        'price': double.parse(_priceController.text),
        'stock_level': int.parse(_quantityController.text),
        'unit': _selectedUnit,
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

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success! ✓'),
              content: Text('${product.name} has been created successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, product);
                  },
                  child: const Text('Done'),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Product',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              Text(
                'Product Name (3-100 characters)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'e.g., Fresh Tomatoes',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
                  ),
                ),
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
              const SizedBox(height: 20),

              // Product Type
              Text(
                'Product Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProductType,
                items: const [
                  DropdownMenuItem(value: 'VEGETABLE', child: Text('Vegetable')),
                  DropdownMenuItem(value: 'FRUIT', child: Text('Fruit')),
                  DropdownMenuItem(value: 'GRAIN', child: Text('Grain')),
                  DropdownMenuItem(value: 'POULTRY', child: Text('Poultry')),
                  DropdownMenuItem(value: 'DAIRY', child: Text('Dairy')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProductType = value;
                    });
                    _checkCeilingPrice();
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quality Grade
              Text(
                'Quality Grade',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedQualityGrade,
                items: const [
                  DropdownMenuItem(value: 'PREMIUM', child: Text('Premium')),
                  DropdownMenuItem(value: 'STANDARD', child: Text('Standard')),
                  DropdownMenuItem(value: 'BASIC', child: Text('Basic')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedQualityGrade = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Describe your product...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Price & Ceiling
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (₱)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _priceExceedsCeiling
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _priceExceedsCeiling
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _priceExceedsCeiling
                                    ? Colors.red
                                    : const Color(0xFF00B464),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Price is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid price';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Must be > 0';
                            }
                            return null;
                          },
                        ),
                        if (_priceExceedsCeiling && _ceilingPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '⚠ Exceeds ceiling: ₱${_ceilingPrice?.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_ceilingPrice != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ceiling (₱)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B464).withOpacity(0.1),
                              border: Border.all(
                                  color: const Color(0xFF00B464).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _ceilingPrice?.toStringAsFixed(2) ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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

              // Stock & Unit
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Level',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF00B464), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Stock is required';
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
                        Text(
                          'Unit',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                            DropdownMenuItem(
                                value: 'bundle', child: Text('bundle')),
                            DropdownMenuItem(value: 'box', child: Text('box')),
                            DropdownMenuItem(value: 'liter', child: Text('liter')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedUnit = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF00B464), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Images
              Text(
                'Product Images (Max 5, JPG/PNG)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 12),
              if (_selectedImages.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
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
                                if (index == 0)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: const Text(
                                        'Primary',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
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
                    const SizedBox(height: 12),
                  ],
                ),
              ElevatedButton.icon(
                onPressed: _selectedImages.length < 5 ? _pickImages : null,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  _selectedImages.isEmpty
                      ? 'Select Images'
                      : 'Add More (${_selectedImages.length}/5)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFF00B464),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF00B464), width: 2),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B464),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
