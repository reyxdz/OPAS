import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/services/admin_service.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  bool _isLoadingClassifications = false;
  bool _isLoadingTypes = false;
  bool _isLoadingSubtypes = false;
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedSubtype;
  String _selectedUnit = 'kg';
  bool _isAvailableForDelivery = false;
  bool _isAvailableForPickup = false;
  final int _maxImages = 5;

  // Static category map matching buyer home screen
  final Map<String, Map<String, dynamic>> _categoryMap = {
    'VEGETABLE': {'label': 'Vegetables', 'icon': Icons.eco, 'color': const Color(0xFF2E7D32)},
    'FRUIT': {'label': 'Fruits', 'icon': Icons.apple, 'color': const Color(0xFFD32F2F)},
    'LIVESTOCK': {'label': 'Livestock', 'icon': Icons.pets, 'color': const Color(0xFF8B4513)},
    'POULTRY': {'label': 'Poultry', 'icon': Icons.egg_outlined, 'color': const Color(0xFFE65100)},
    'SEEDS': {'label': 'Seeds', 'icon': Icons.grain, 'color': const Color(0xFF7B1FA2)},
    'FERTILIZERS': {'label': 'Fertilizers', 'icon': Icons.landscape, 'color': const Color(0xFF9C7C38)},
    'FEEDS': {'label': 'Feeds', 'icon': Icons.food_bank, 'color': const Color(0xFF6D4C41)},
    'MEDICINES': {'label': 'Medicines', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFC2185B)},
  };

  // Dynamically fetched data from API
  List<String> _availableTypes = [];
  List<String> _availableSubtypes = [];
  bool _isInitialLoading = true;

  /// Initialize the screen with default category data
  Future<void> _initializeScreen() async {
    try {
      // Set initial loading to true
      setState(() => _isInitialLoading = true);
      
      // Optionally pre-fetch types for the first category (optional)
      // This ensures the screen is ready when user opens it
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error initializing screen: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  /// Fetch types for selected category from API
  Future<List<String>> _fetchTypesForCategory(String category) async {
    try {
      setState(() => _isLoadingTypes = true);
      final types = await AdminService.getTypesForCategory(category);
      setState(() {
        _availableTypes = types;
        _isLoadingTypes = false;
      });
      debugPrint('✅ Loaded ${types.length} types for $category');
      return types;
    } catch (e) {
      debugPrint('❌ Error fetching types: $e');
      setState(() => _isLoadingTypes = false);
      return [];
    }
  }

  /// Fetch subtypes for selected type from API
  Future<List<String>> _fetchSubtypesForType(String category, String type) async {
    try {
      setState(() => _isLoadingSubtypes = true);
      final subtypes = await AdminService.getSubtypesForType(category, type);
      setState(() {
        _availableSubtypes = subtypes;
        _isLoadingSubtypes = false;
      });
      debugPrint('✅ Loaded ${subtypes.length} subtypes for $category > $type');
      return subtypes;
    } catch (e) {
      debugPrint('❌ Error fetching subtypes: $e');
      setState(() => _isLoadingSubtypes = false);
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize the screen with loading spinner
    _initializeScreen();
  }

  void _showAddTypeDialog() {
    final typeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product Type'),
        content: TextField(
          controller: typeController,
          decoration: const InputDecoration(
            hintText: 'Enter type name (e.g., "Specialty", "Organic")',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newType = typeController.text.trim();
              if (newType.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a type name')),
                );
                return;
              }
              
              try {
                // Call API to save and persist the new type to database
                final response = await AdminService.addProductType(
                  category: _selectedCategory!,
                  type: newType,
                );
                
                if (response['success'] == true) {
                  // Refresh types from API instead of updating local state
                  await _fetchTypesForCategory(_selectedCategory!);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Type added and saved: $newType')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: ${response['error']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error adding type: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddSubtypeDialog() {
    final subtypeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product Subtype'),
        content: TextField(
          controller: subtypeController,
          decoration: const InputDecoration(
            hintText: 'Enter subtype name (e.g., "Fresh", "Frozen")',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSubtype = subtypeController.text.trim();
              if (newSubtype.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a subtype name')),
                );
                return;
              }
              
              try {
                // Call API to save and persist the new subtype to database
                final response = await AdminService.addProductSubtype(
                  category: _selectedCategory!,
                  type: _selectedType!,
                  subtype: newSubtype,
                );
                
                if (response['success'] == true) {
                  // Refresh subtypes from API instead of updating local state
                  await _fetchSubtypesForType(_selectedCategory!, _selectedType!);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Subtype added and saved: $newSubtype')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: ${response['error']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error adding subtype: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images allowed')),
      );
      return;
    }

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product image')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (!_isAvailableForDelivery && !_isAvailableForPickup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one fulfillment option (Delivery or Pickup)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Convert delivery/pickup booleans to fulfillment_methods string
      String fulfillmentMethods;
      if (_isAvailableForDelivery && _isAvailableForPickup) {
        fulfillmentMethods = 'delivery_and_pickup';
      } else if (_isAvailableForDelivery) {
        fulfillmentMethods = 'delivery';
      } else {
        fulfillmentMethods = 'pickup';
      }

      // Use the first image as the primary image for now
      final imageBytes = await _selectedImages[0].readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'product_image.jpg',
      );

      // Call admin service to upload product
      final result = await AdminService.uploadOPASProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        quantity: _quantityController.text.trim(),
        category: _selectedCategory!,
        unit: _selectedUnit,
        fulfillmentMethods: fulfillmentMethods,
        productType: _selectedType,
        productSubtype: _selectedSubtype,
        imageFile: multipartFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product "${result['product_name']}" uploaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Wait a moment then pop back with true to indicate success
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while initializing
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upload New Product'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading form...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preparing categories and classifications',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload New Product'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              Text(
                'Product Images (Max $_maxImages)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _selectedImages.isNotEmpty
                  ? Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF00B464),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (_selectedImages.length < _maxImages)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                              onTap: _isUploading ? null : _pickImage,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[50],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add image (${_selectedImages.length}/$_maxImages)',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select product images',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Product Name
              Text(
                'Product Name',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Fresh Tomatoes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category (Read-only from Buyer Home Screen)
              Text(
                'Category',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  hintText: 'Select category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _categoryMap.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value['label'] as String),
                  );
                }).toList(),
                onChanged: _isUploading ? null : (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedType = null;
                    _selectedSubtype = null;
                    _availableTypes = [];
                    _availableSubtypes = [];
                  });
                  if (value != null) {
                    _fetchTypesForCategory(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product Type - Fetched from API
              Text(
                'Product Type',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _selectedCategory == null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Select category first',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              hintText: 'Select type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _availableTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (_isUploading || _isLoadingTypes) ? null : (value) {
                              setState(() {
                                _selectedType = value;
                                _selectedSubtype = null;
                                _availableSubtypes = [];
                              });
                              if (value != null && _selectedCategory != null) {
                                _fetchSubtypesForType(_selectedCategory!, value);
                              }
                            },
                            validator: (value) {
                              if (_selectedCategory != null && (value == null || value.isEmpty)) {
                                return 'Please select a type';
                              }
                              return null;
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add new type',
                    onPressed: _selectedCategory == null || _isUploading || _isLoadingTypes ? null : () => _showAddTypeDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Subtype - Fetched from API (Optional)
              Text(
                'Product Subtype (Optional)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _selectedType == null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Select type first',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedSubtype ?? 'NONE',
                            decoration: InputDecoration(
                              hintText: 'Select subtype',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'NONE',
                                child: Text('NONE'),
                              ),
                              ..._availableSubtypes.map((subtype) {
                                return DropdownMenuItem(
                                  value: subtype,
                                  child: Text(subtype),
                                );
                              }).toList(),
                            ],
                            onChanged: (_isUploading || _isLoadingSubtypes) ? null : (value) {
                              setState(() => _selectedSubtype = value == 'NONE' ? null : value);
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add new subtype',
                    onPressed: _selectedType == null || _isUploading || _isLoadingSubtypes ? null : () => _showAddSubtypeDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price
              Text(
                'Price (₱)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixText: '₱ ',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              Text(
                'Quantity Available',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit
              Text(
                'Unit',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  hintText: 'Select unit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: ['kg', 'piece', 'box', 'bundle', 'dozen', 'liter', 'gram']
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: _isUploading ? null : (value) {
                  setState(() => _selectedUnit = value ?? 'kg');
                },
              ),
              const SizedBox(height: 16),

              // Fulfillment Options
              Text(
                'Fulfillment Options',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.withOpacity(0.02),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _isAvailableForDelivery,
                      onChanged: _isUploading ? null : (value) {
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
                    ),
                    CheckboxListTile(
                      value: _isAvailableForPickup,
                      onChanged: _isUploading ? null : (value) {
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
                        'Buyers can pick up this product in person',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B464), Color(0xFF009850)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isUploading ? null : _uploadProduct,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Upload Product',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
