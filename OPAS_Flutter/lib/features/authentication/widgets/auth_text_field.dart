// lib/features/authentication/widgets/auth_text_field.dart
// Reusable text field widget for authentication screens
import 'package:flutter/material.dart';

// Convert to StatefulWidget since we need to manage visibility state
class AuthTextField extends StatefulWidget {
  // Define required and optional parameters
  final String label;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.controller,
    this.validator,
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
      decoration: InputDecoration(
        labelText: widget.label,
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
      ),
      validator: widget.validator,
    );
  }
}