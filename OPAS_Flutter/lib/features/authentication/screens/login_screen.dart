import 'package:flutter/material.dart';
import '../widgets/auth_text_field.dart';
import './registration_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routing/admin_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    // Logo
                    Image.asset(
                      'assets/images/opas_logo.png',
                      height: 50,
                    ),
                    const SizedBox(height: 60),
                    
                    // Phone Number field
                    AuthTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    AuthTextField(
                      label: 'Password',
                      isPassword: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: Text(
                          'Forgot your password?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Log In'),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegistrationScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign up!',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      LoggerService.info(
        'User login attempt',
        tag: 'AUTH',
        metadata: {'phone': phone},
      );

      final response = await ApiService.loginUser(phone, _passwordController.text);

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
      await prefs.setString('email', response['email'] ?? '');
      await prefs.setString('first_name', response['first_name'] ?? '');
      await prefs.setString('last_name', response['last_name'] ?? '');
      await prefs.setString('address', response['address'] ?? '');
      await prefs.setString('role', response['role'] ?? 'BUYER');
      
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
}