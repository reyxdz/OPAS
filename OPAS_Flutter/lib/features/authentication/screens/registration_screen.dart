import 'package:flutter/material.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/services/api_service.dart';
import '../models/location_data.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedMunicipality;
  String? _selectedBarangay;
  String? _selectedFarmMunicipality;
  String? _selectedFarmBarangay;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    Image.asset(
                      'assets/images/opas_logo.png',
                      height: 50,
                    ),
                    const SizedBox(height: 40),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AuthTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Municipality Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select Municipality'),
                          value: _selectedMunicipality,
                          items: LocationData.municipalities
                              .map((municipality) => DropdownMenuItem(
                                    value: municipality,
                                    child: Text(municipality),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMunicipality = value;
                              _selectedBarangay = null; // Reset barangay
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Barangay Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select Barangay'),
                          value: _selectedBarangay,
                          items: _selectedMunicipality == null
                              ? []
                              : LocationData.getBarangays(_selectedMunicipality!)
                                  .map((barangay) => DropdownMenuItem(
                                        value: barangay,
                                        child: Text(barangay),
                                      ))
                                  .toList(),
                          onChanged: _selectedMunicipality == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedBarangay = value;
                                  });
                                },
                          disabledHint: const Text('Please select municipality first'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Farm Location Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Farm Location (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Farm Municipality Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select Farm Municipality'),
                          value: _selectedFarmMunicipality,
                          items: LocationData.municipalities
                              .map((municipality) => DropdownMenuItem(
                                    value: municipality,
                                    child: Text(municipality),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFarmMunicipality = value;
                              _selectedFarmBarangay = null; // Reset farm barangay
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Farm Barangay Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select Farm Barangay'),
                          value: _selectedFarmBarangay,
                          items: _selectedFarmMunicipality == null
                              ? []
                              : LocationData.getBarangays(_selectedFarmMunicipality!)
                                  .map((barangay) => DropdownMenuItem(
                                        value: barangay,
                                        child: Text(barangay),
                                      ))
                                  .toList(),
                          onChanged: _selectedFarmMunicipality == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedFarmBarangay = value;
                                  });
                                },
                          disabledHint: const Text('Please select farm municipality first'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    AuthTextField(
                      label: 'Phone Number',
                      controller: _phoneNumberController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    AuthTextField(
                      label: 'Password',
                      isPassword: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign Up'),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Log In!',
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

  void _handleSignUp() async {
    if (_selectedMunicipality == null || _selectedBarangay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both residence municipality and barangay'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final address = '$_selectedBarangay, $_selectedMunicipality, Biliran';
        final signupData = {
          'username': _phoneNumberController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'phone_number': _phoneNumberController.text,
          'password': _passwordController.text,
          'address': address,
          'municipality': _selectedMunicipality,
          'barangay': _selectedBarangay,
          'farm_municipality': _selectedFarmMunicipality,
          'farm_barangay': _selectedFarmBarangay,
          'role': 'BUYER',
        };

        await ApiService.registerUser(signupData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
