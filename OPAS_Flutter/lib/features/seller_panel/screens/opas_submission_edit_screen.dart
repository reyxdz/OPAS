import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/seller_service.dart';

class OPASSubmissionEditScreen extends StatefulWidget {
  final Map<String, dynamic> submission;

  const OPASSubmissionEditScreen({
    Key? key,
    required this.submission,
  }) : super(key: key);

  @override
  State<OPASSubmissionEditScreen> createState() =>
      _OPASSubmissionEditScreenState();
}

class _OPASSubmissionEditScreenState extends State<OPASSubmissionEditScreen> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  List<File> _newImages = [];
  List<Map<String, dynamic>> _existingImages = [];
  bool _isLoading = false;
  bool _isFetchingImages = true;
  final ImagePicker _imagePicker = ImagePicker();

  // Accent color matching app theme
  static const Color accentColor = Color(0xFF00B464);

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.submission['quantity_offered'].toString(),
    );
    _priceController = TextEditingController(
      text: widget.submission['offered_price'].toString(),
    );
    _fetchExistingImages();
  }

  Future<void> _fetchExistingImages() async {
    try {
      // Try to get product ID from submission
      int? productId = widget.submission['product'] as int?;
      
      // If product ID is 0 or null, try to fetch from submission details
      if (productId == null || productId == 0) {
        final submissionId = widget.submission['id'] as int?;
        if (submissionId != null && submissionId > 0) {
          try {
            final details = await SellerService.getOPASRequestDetails(submissionId);
            productId = details['product'] as int?;
          } catch (e) {
            // Continue with what we have
          }
        }
      }
      
      if (productId != null && productId > 0) {
        final images = await SellerService.getProductImages(productId);
        if (mounted) {
          setState(() {
            _existingImages = images;
            _isFetchingImages = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isFetchingImages = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingImages = false);
      }
      print('Error fetching images: $e');
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeExistingImage(int imageId, int index) async {
    try {
      final productId = widget.submission['product'] as int?;
      if (productId == null) return;

      setState(() => _isLoading = true);
      await SellerService.deleteProductImage(
        productId: productId,
        imageId: imageId,
      );

      if (mounted) {
        setState(() {
          _existingImages.removeAt(index);
        });
        _showSuccessSnackbar('Image removed');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to remove image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages = pickedFiles.map((file) => File(file.path)).toList();
        });
        _showSuccessSnackbar('${pickedFiles.length} image(s) selected');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick images: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        setState(() {
          _newImages.add(File(pickedFile.path));
        });
        _showSuccessSnackbar('Image captured');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to capture image: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _updateSubmission() async {
    if (_quantityController.text.isEmpty || _priceController.text.isEmpty) {
      _showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productId = widget.submission['product'] as int?;

      // Upload new images if any
      if (_newImages.isNotEmpty && productId != null) {
        for (int i = 0; i < _newImages.length; i++) {
          await SellerService.uploadProductImage(
            productId: productId,
            imagePath: _newImages[i].path,
            isPrimary: false,
            altText: 'Product image ${_existingImages.length + i + 1}',
          );
        }
      }

      _showSuccessSnackbar('Submission updated successfully');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update submission: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Submission',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Content Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info Card
                  _buildProductInfoCard(),
                  const SizedBox(height: 32),

                  // Quantity Section
                  _buildFormSection(
                    label: 'Quantity Offered',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter quantity',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: accentColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.submission['unit'] ?? 'kg',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Section
                  _buildFormSection(
                    label: 'Offered Price',
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter price',
                        prefixText: '₱ ',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: accentColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Photos Section
                  _buildFormSection(
                    label: 'Product Photos',
                    child: _isFetchingImages
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            children: [
                              // Existing Photos
                              if (_existingImages.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Photos (${_existingImages.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: _existingImages.length,
                                      itemBuilder: (context, index) {
                                        final image = _existingImages[index];
                                        return _buildExistingPhotoTile(
                                          imageUrl: image['image'],
                                          imageId: image['id'],
                                          index: index,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),

                              // New Photos
                              if (_newImages.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New Photos to Add (${_newImages.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: _newImages.length,
                                      itemBuilder: (context, index) {
                                        return _buildNewPhotoTile(
                                          file: _newImages[index],
                                          onDelete: () =>
                                              _removeNewImage(index),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              // Add Photo Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildImagePickerButton(
                                      icon: Icons.photo_library,
                                      label: 'Gallery',
                                      onPressed: _pickImages,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildImagePickerButton(
                                      icon: Icons.camera_alt,
                                      label: 'Camera',
                                      onPressed: _pickImageFromCamera,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateSubmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.submission['product_name'] ?? 'Unknown Product',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${widget.submission['submission_number'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: accentColor),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: accentColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildNewPhotoTile({
    required File file,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
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
    );
  }

  Widget _buildExistingPhotoTile({
    required String imageUrl,
    required int imageId,
    required int index,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : () => _removeExistingImage(imageId, index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile({
    required File file,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
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
    );
  }
}
