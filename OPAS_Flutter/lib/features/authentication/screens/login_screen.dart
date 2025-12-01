import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import './registration_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routing/admin_router.dart';

// Custom input formatter for phone numbers (exactly 11 digits)
class LoginPhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    // Format: XXXX XXX XXXX (with space dividers)
    String formatted = '';
    if (digitsOnly.isNotEmpty) {
      formatted += digitsOnly.substring(0, digitsOnly.length > 4 ? 4 : digitsOnly.length);
    }
    if (digitsOnly.length > 4) {
      formatted += ' ${digitsOnly.substring(4, digitsOnly.length > 7 ? 7 : digitsOnly.length)}';
    }
    if (digitsOnly.length > 7) {
      formatted += ' ${digitsOnly.substring(7)}';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection(
        baseOffset: formatted.length,
        extentOffset: formatted.length,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // OPAS Logo
                    Center(
                      child: Image.asset(
                        'assets/images/opas_logo.png',
                        height: 60,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Header
                    _buildHeader(context),
                    
                    const SizedBox(height: 32),
                    
                    // Form Section
                    _buildFormSection(context),
                    
                    const SizedBox(height: 32),
                    
                    // Login Button
                    _buildLoginButton(context),
                    
                    const SizedBox(height: 16),
                    
                    // Sign Up Link
                    _buildSignUpLink(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header Section
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Dear!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Log in to your OPAS account',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Main Form Section
  Widget _buildFormSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Number Field
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+63 XXXX XXX XXXX',
          keyboardType: TextInputType.number,
          inputFormatters: [LoginPhoneNumberInputFormatter()],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly.length != 10) {
              return 'Phone number must be exactly 11 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // Password Field with Visibility Toggle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                errorStyle: TextStyle(
                  color: Colors.red[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              // Handle forgot password
            },
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: const Color(0xFF00B464),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Reusable Text Field with Modern Design
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00B464), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            suffixIcon: isPassword
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: const Icon(Icons.visibility_off_outlined, size: 20),
                      onPressed: () {},
                      color: Colors.grey[500],
                    ),
                  )
                : null,
            errorStyle: TextStyle(
              color: Colors.red[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// Login Button
  Widget _buildLoginButton(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B464), Color(0xFF009450)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B464).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Log In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Sign Up Link
  Widget _buildSignUpLink(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Don\'t have an account? ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: 'Sign Up',
              style: const TextStyle(
                color: Color(0xFF00B464),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Remove spaces from phone number for API call
      final phone = _phoneController.text.trim().replaceAll(' ', '');
      LoggerService.info(
        'User login attempt',
        tag: 'AUTH',
        metadata: {'phone': phone},
      );

      final response = await ApiService.loginUser(phone, _passwordController.text);

      // Debug: Log full response
      debugPrint('🔐 Login response: $response');

      LoggerService.info(
        'Login successful',
        tag: 'AUTH',
        metadata: {'phone': phone, 'role': response['role']},
      );

      if (!mounted) return;

      // Save tokens to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access', response['access'] ?? '');
      await prefs.setString('refresh', response['refresh'] ?? '');
      await prefs.setString('phone_number', response['phone_number'] ?? '');
      debugPrint('📱 Login: Stored phone_number=${response['phone_number']}');
      await prefs.setString('email', response['email'] ?? '');
      await prefs.setString('first_name', response['first_name'] ?? '');
      await prefs.setString('last_name', response['last_name'] ?? '');
      await prefs.setString('address', response['address'] ?? '');
      await prefs.setString('role', response['role'] ?? 'BUYER');
      
      // Store user_id for notification history tracking
      // user_id is the database primary key and never changes, making it ideal for persistent storage keys
      if (response['id'] != null) {
        await prefs.setString('user_id', response['id'].toString());
        debugPrint('👤 Login: Stored user_id (PK) from response[id]=${response['id']}');
      } else if (response['user_id'] != null) {
        await prefs.setString('user_id', response['user_id'].toString());
        debugPrint('👤 Login: Stored user_id (PK) from response[user_id]=${response['user_id']}');
      } else {
        // Fallback: Extract user_id from JWT token
        final accessToken = response['access'] as String?;
        if (accessToken != null) {
          final userIdFromJwt = _extractUserIdFromJwt(accessToken);
          if (userIdFromJwt != null) {
            await prefs.setString('user_id', userIdFromJwt);
            debugPrint('👤 Login: Stored user_id from JWT: $userIdFromJwt');
          } else {
            debugPrint('⚠️ Login: Could not extract user_id from JWT');
          }
        } else {
          debugPrint('⚠️ Login: No user_id found in response and no access token');
        }
      }
      
      // Restore backed-up cart from logout if it exists
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final cartBackupKey = 'cart_items_$userId';
        final backedUpCart = prefs.getString(cartBackupKey);
        if (backedUpCart != null) {
          debugPrint('🛒 Login: Restoring backed-up cart from key=$cartBackupKey');
          // Cart will be loaded by CartScreen._initializeCart() when it initializes
        } else {
          debugPrint('🛒 Login: No backed-up cart found for user_id=$userId');
        }
      }
      
      // Store seller information if available
      if (response['store_name'] != null) {
        await prefs.setString('store_name', response['store_name'] ?? '');
      }
      if (response['farm_municipality'] != null) {
        await prefs.setString('farm_municipality', response['farm_municipality'] ?? '');
      }
      if (response['farm_barangay'] != null) {
        await prefs.setString('farm_barangay', response['farm_barangay'] ?? '');
      }
      
      if (response['role'] == 'ADMIN') {
        await prefs.setString('admin_role', response['admin_role'] ?? 'SUPER_ADMIN');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
      
      // Route based on user role
      final role = response['role'] ?? 'BUYER';
      if (role == 'ADMIN') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AdminRoutes.adminDashboard,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      LoggerService.error(
        'Login failed',
        tag: 'AUTH',
        error: e,
        metadata: {'phone': _phoneController.text.trim()},
      );
      final message = e.toString().replaceAll('Exception: ', '');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Extract user_id from JWT token payload
  /// JWT format: header.payload.signature
  String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode payload (add padding if needed)
      String payload = parts[1];
      payload = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
      
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
      final userId = decoded['user_id'];
      debugPrint('🔐 Extracted user_id from JWT: $userId');
      return userId?.toString();
    } catch (e) {
      debugPrint('❌ Error extracting user_id from JWT: $e');
      return null;
    }
  }
}