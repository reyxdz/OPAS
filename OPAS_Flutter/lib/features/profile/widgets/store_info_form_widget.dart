import 'package:flutter/material.dart';

/// Store Information Form Widget
/// Handles input for store details: store name and description
/// 
/// CORE PRINCIPLES APPLIED:
/// - Input Validation: Field-level validation with character counters
/// - User Experience: Clear descriptions, character limits, helpful formatting
/// - Resource Management: Efficient state management
class StoreInfoFormWidget extends StatefulWidget {
  final TextEditingController storeNameController;
  final TextEditingController storeDescriptionController;
  final Map<String, String>? fieldErrors;

  const StoreInfoFormWidget({
    super.key,
    required this.storeNameController,
    required this.storeDescriptionController,
    this.fieldErrors,
  });

  @override
  State<StoreInfoFormWidget> createState() => _StoreInfoFormWidgetState();
}

class _StoreInfoFormWidgetState extends State<StoreInfoFormWidget> {
  static const int _descriptionMax = 500;

  @override
  Widget build(BuildContext context) {
    final storeNameError = widget.fieldErrors?['store_name'];
    final descError = widget.fieldErrors?['store_description'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Store Information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),

        // Store Name Field
        _buildTextField(
          label: 'Store Name *',
          hint: 'e.g., Premium Farm Fresh',
          controller: widget.storeNameController,
          errorText: storeNameError,
          maxLines: 1,
        ),
        const SizedBox(height: 16),

        // Store Description Field with counter
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.storeDescriptionController,
              maxLines: 4,
              maxLength: _descriptionMax,
              decoration: InputDecoration(
                labelText: 'Store Description *',
                hintText: 'Tell customers about your store, products, and what makes you special',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: (descError != null && descError.isNotEmpty)
                        ? Colors.red[400]!
                        : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: (descError != null && descError.isNotEmpty)
                        ? Colors.red[600]!
                        : const Color(0xFF00B464),
                  ),
                ),
              ),
            ),
            if (descError != null && descError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  descError,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
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
    int maxLines = 1,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: const Icon(Icons.store),
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
}
