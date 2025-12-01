// lib/features/authentication/widgets/auth_text_field.dart
// Reusable text field widget for authentication screens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Convert to StatefulWidget since we need to manage visibility state
class AuthTextField extends StatefulWidget {
  // Define required and optional parameters
  final String label;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.inputFormatters,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  // State variable to track password visibility
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    // Initialize visibility state based on whether it's a password field
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      // Use _obscureText state for password visibility
      obscureText: _obscureText,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        // Show suffix icon only for password fields
        suffixIcon: widget.isPassword
            ? IconButton(
                // Toggle visibility state when icon is clicked
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                // Change icon based on visibility state
                icon: Icon(
                  _obscureText 
                      ? Icons.visibility_outlined  // Show "show password" icon when password is hidden
                      : Icons.visibility_off_outlined,  // Show "hide password" icon when password is visible
                ),
              )
            : null,
        errorStyle: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: widget.validator,
    );
  }
}