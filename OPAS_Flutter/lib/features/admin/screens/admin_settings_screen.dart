import 'package:flutter/material.dart';
import 'package:opas_flutter/core/models/admin_settings_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin/widgets/settings_section.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  AdminSettingsScreenState createState() => AdminSettingsScreenState();
}

class AdminSettingsScreenState extends State<AdminSettingsScreen> {
  AdminSettingsModel? _settings;
  bool _isLoading = false;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await AdminService.getAdminSettings();
      setState(() {
        _settings = AdminSettingsModel.fromJson(response);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    try {
      await AdminService.updateAdminSettings(_settings!.toJson());
      if (!mounted) return;
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  void _updateSetting(AdminSettingsModel newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _settings == null
                  ? const Center(child: Text('No settings found'))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Notification Preferences Section
                          SettingsSection(
                            title: 'Notifications',
                            subtitle: 'Configure how and when you receive alerts',
                            children: [
                              _buildToggleSetting(
                                'Email Notifications',
                                _settings!.enableEmailNotifications,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      enableEmailNotifications: value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildToggleSetting(
                                'Push Notifications',
                                _settings!.enablePushNotifications,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      enablePushNotifications: value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildToggleSetting(
                                'Dashboard Notifications',
                                _settings!.enableDashboardNotifications,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      enableDashboardNotifications: value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownSetting(
                                'Notification Frequency',
                                _settings!.notificationFrequency,
                                ['immediate', 'hourly', 'daily'],
                                (value) {
                                  if (value != null) {
                                    _updateSetting(
                                      _settings!.copyWith(
                                        notificationFrequency: value,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          // Alert Categories Section
                          SettingsSection(
                            title: 'Alert Categories',
                            subtitle: 'Select which types of alerts to receive',
                            children: [
                              _buildCheckboxSetting(
                                'Price Violations',
                                _settings!.alertCategories.contains('price_violations'),
                                (value) {
                                  final categories = List<String>.from(_settings!.alertCategories);
                                  if (value == true) {
                                    categories.add('price_violations');
                                  } else {
                                    categories.remove('price_violations');
                                  }
                                  _updateSetting(
                                    _settings!.copyWith(
                                      alertCategories: categories,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCheckboxSetting(
                                'Low Inventory Alerts',
                                _settings!.alertCategories.contains('inventory'),
                                (value) {
                                  final categories = List<String>.from(_settings!.alertCategories);
                                  if (value == true) {
                                    categories.add('inventory');
                                  } else {
                                    categories.remove('inventory');
                                  }
                                  _updateSetting(
                                    _settings!.copyWith(
                                      alertCategories: categories,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCheckboxSetting(
                                'Seller Issues',
                                _settings!.alertCategories.contains('seller_issues'),
                                (value) {
                                  final categories = List<String>.from(_settings!.alertCategories);
                                  if (value == true) {
                                    categories.add('seller_issues');
                                  } else {
                                    categories.remove('seller_issues');
                                  }
                                  _updateSetting(
                                    _settings!.copyWith(
                                      alertCategories: categories,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // Dashboard Customization Section
                          SettingsSection(
                            title: 'Dashboard Widgets',
                            subtitle: 'Choose which widgets to display',
                            children: [
                              _buildCheckboxSetting(
                                'Price Trend Chart',
                                _settings!.showPriceTrendChart,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      showPriceTrendChart: value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCheckboxSetting(
                                'Sales Analytics Chart',
                                _settings!.showSalesAnalyticsChart,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      showSalesAnalyticsChart: value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCheckboxSetting(
                                'Alert Widget',
                                _settings!.showAlertWidget,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      showAlertWidget: value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCheckboxSetting(
                                'Recent Activity Widget',
                                _settings!.showRecentActivityWidget,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      showRecentActivityWidget: value,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // System Settings Section
                          SettingsSection(
                            title: 'System Settings',
                            subtitle: 'Configure display formats and preferences',
                            children: [
                              _buildDropdownSetting(
                                'Price Display Format',
                                _settings!.priceDisplayFormat,
                                ['decimal', 'currency', 'percentage'],
                                (value) {
                                  if (value != null) {
                                    _updateSetting(
                                      _settings!.copyWith(
                                        priceDisplayFormat: value,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownSetting(
                                'Currency',
                                _settings!.currency,
                                ['UGX', 'USD', 'EUR', 'GBP', 'KES'],
                                (value) {
                                  if (value != null) {
                                    _updateSetting(
                                      _settings!.copyWith(
                                        currency: value,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownSetting(
                                'Date Format',
                                _settings!.dateFormat,
                                ['MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'],
                                (value) {
                                  if (value != null) {
                                    _updateSetting(
                                      _settings!.copyWith(
                                        dateFormat: value,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownSetting(
                                'Time Format',
                                _settings!.timeFormat,
                                ['12h', '24h'],
                                (value) {
                                  if (value != null) {
                                    _updateSetting(
                                      _settings!.copyWith(
                                        timeFormat: value,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          // Report Scheduling Section
                          SettingsSection(
                            title: 'Report Scheduling',
                            subtitle: 'Configure automatic report generation',
                            children: [
                              _buildToggleSetting(
                                'Enable Auto Export',
                                _settings!.enableAutoExport,
                                (value) {
                                  _updateSetting(
                                    _settings!.copyWith(
                                      enableAutoExport: value,
                                    ),
                                  );
                                },
                              ),
                              if (_settings!.enableAutoExport) ...[
                                const SizedBox(height: 16),
                                _buildDropdownSetting(
                                  'Schedule Frequency',
                                  _settings!.reportScheduleFrequency,
                                  ['daily', 'weekly', 'monthly'],
                                  (value) {
                                    if (value != null) {
                                      _updateSetting(
                                        _settings!.copyWith(
                                          reportScheduleFrequency: value,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTimePickerSetting(
                                  'Schedule Time',
                                  _settings!.reportScheduleTime,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildCheckboxSetting(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2196F3),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: options
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerSetting(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            if (!mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(value.split(':')[0]),
                minute: int.parse(value.split(':')[1]),
              ),
            );
            if (time != null && mounted) {
              final timeString =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              _updateSetting(
                _settings!.copyWith(
                  reportScheduleTime: timeString,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                ),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
