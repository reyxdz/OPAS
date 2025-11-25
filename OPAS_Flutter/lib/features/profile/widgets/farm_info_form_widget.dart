import 'package:flutter/material.dart';

/// Farm Information Form Widget
/// Handles input for farm details: name, location, size, and products grown
/// 
/// CORE PRINCIPLES APPLIED:
/// - Input Validation: Field-level validation with visual feedback
/// - User Experience: Clear labels, helpful hints, required indicators
/// - Resource Management: Efficient form state management
class FarmInfoFormWidget extends StatefulWidget {
  final TextEditingController farmNameController;
  final TextEditingController farmLocationController;
  final List<String> selectedProducts;
  final Function(List<String>) onProductsChanged;
  final Map<String, String>? fieldErrors;

  const FarmInfoFormWidget({
    super.key,
    required this.farmNameController,
    required this.farmLocationController,
    required this.selectedProducts,
    required this.onProductsChanged,
    this.fieldErrors,
  });

  @override
  State<FarmInfoFormWidget> createState() => _FarmInfoFormWidgetState();
}

class _FarmInfoFormWidgetState extends State<FarmInfoFormWidget> {
  static const List<String> productOptions = [
    'Fruits',
    'Vegetables',
    'Livestock',
    'Others'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Farm Information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),

        // Farm Name Field
        _buildTextField(
          label: 'Farm Name *',
          hint: 'e.g., Green Valley Farm',
          controller: widget.farmNameController,
          errorText: widget.fieldErrors?['farm_name'],
        ),
        const SizedBox(height: 16),

        // Farm Location Field
        _buildTextField(
          label: 'Farm Location *',
          hint: 'e.g., Bukidnon, Philippines',
          controller: widget.farmLocationController,
          errorText: widget.fieldErrors?['farm_location'],
        ),
        const SizedBox(height: 24),

        // Products Grown Section
        Text(
          'Products Grown *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select all that apply',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),

        // Product Checkboxes
        Column(
          children: productOptions.map((product) {
            final isSelected = widget.selectedProducts.contains(product);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00B464)
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? const Color(0xFF00B464).withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (bool? value) {
                  if (value ?? false) {
                    widget.onProductsChanged([
                      ...widget.selectedProducts,
                      product,
                    ]);
                  } else {
                    widget.onProductsChanged(
                      widget.selectedProducts
                          .where((p) => p != product)
                          .toList(),
                    );
                  }
                },
                title: Text(product),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }).toList(),
        ),

        // Error message for products if needed
        if (widget.fieldErrors?.containsKey('products_grown') ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.fieldErrors!['products_grown']!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a text input field with error display
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(_getIconForField(label)),
            errorText: null,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red[400]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red[600]! : const Color(0xFF00B464),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Get appropriate icon for each field
  IconData _getIconForField(String label) {
    if (label.contains('Name')) return Icons.agriculture;
    if (label.contains('Location')) return Icons.location_on;
    return Icons.info;
  }
}
