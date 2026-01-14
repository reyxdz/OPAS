import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/forecast_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin/widgets/forecast_card.dart';
import 'package:opas_flutter/features/admin/screens/forecast_detail_screen.dart';
import 'package:opas_flutter/features/admin/screens/forecast_history_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Forecasting Dashboard Screen - Phase 5.1 A
/// 
/// Main admin dashboard for viewing demand and price forecasts:
/// - Lists all product forecasts with demand and price predictions
/// - Filter by product category and confidence level
/// - Refresh forecasts manually (Super Admin)
/// - Export forecast data as CSV
/// - Shows last update time
/// 
/// Data sourced from backend API:
/// - GET /api/admin/forecasts/ - List all forecasts
/// - GET /api/admin/forecasts/metadata/ - Model info and statistics
class ForecastingDashboardScreen extends StatefulWidget {
  const ForecastingDashboardScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ForecastingDashboardScreenState createState() =>
      _ForecastingDashboardScreenState();
}

class _ForecastingDashboardScreenState extends State<ForecastingDashboardScreen> {
  late Future<List<ForecastModel>> _forecastsFuture;
  List<ForecastModel> _forecasts = [];
  List<ForecastModel> _filteredForecasts = [];
  
  String _selectedConfidence = 'All';
  String _selectedCategory = 'All';
  String _selectedType = 'All';
  String _searchQuery = '';
  DateTime? _lastUpdated;
  bool _isRefreshing = false;
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _confidenceFilters = ['All', 'HIGH', 'MEDIUM', 'LOW'];
  final List<String> _categoryFilters = [
    'All',
    'VEGETABLE',
    'FRUIT',
    'LIVESTOCK',
    'POULTRY',
    'SEEDS',
    'FERTILIZERS',
    'FEEDS',
    'MEDICINES'
  ];
  List<String> _typeFilters = ['All']; // Dynamically populated

  @override
  void initState() {
    super.initState();
    _refreshForecasts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshForecasts() {
    _forecastsFuture = _fetchForecasts();
  }

  Future<List<ForecastModel>> _fetchForecasts() async {
    try {
      final data = await AdminService.getAllForecasts();
      
      final forecasts = (data)
          .map((item) => ForecastModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _forecasts = forecasts;
        _lastUpdated = DateTime.now();
        _applyFilters();
      });

      return forecasts;
    } catch (e) {
      debugPrint('Error fetching forecasts: $e');
      return [];
    }
  }

  void _applyFilters() {
    // Extract unique product types from all forecasts
    final types = <String>{'All'};
    for (final forecast in _forecasts) {
      if (forecast.productType != null && forecast.productType!.isNotEmpty) {
        types.add(forecast.productType!);
      }
    }
    _typeFilters = types.toList()..sort();

    _filteredForecasts = _forecasts.where((forecast) {
      bool confidenceMatch = _selectedConfidence == 'All' ||
          forecast.confidenceLevel == _selectedConfidence;
      
      bool categoryMatch = _selectedCategory == 'All' ||
          forecast.categoryName == _selectedCategory;
      
      bool typeMatch = _selectedType == 'All' ||
          forecast.productType == _selectedType;
      
      // Search match - search in product name
      bool searchMatch = _searchQuery.isEmpty ||
          forecast.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return confidenceMatch && categoryMatch && typeMatch && searchMatch;
    }).toList();
    
    setState(() {});
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final result = await AdminService.refreshForecasts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['status'] == 'success' || result['status'] == 'queued'
                ? 'Forecast refresh initiated'
                : 'Failed to refresh forecasts'),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the list after a short delay
        await Future.delayed(const Duration(seconds: 1));
        _refreshForecasts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _exportAsCSV() async {
    try {
      // Generate CSV content
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln(
        'Product,Category,Forecast Period,Model,Confidence,Demand (kg),Demand Lower,Demand Upper,Price (₱/kg),Price Lower,Price Upper',
      );
      
      // Data rows
      for (final forecast in _filteredForecasts) {
        buffer.writeln(
          '"${forecast.productName}",'
          '"${forecast.categoryName ?? "N/A"}",'
          '"${forecast.forecastPeriod}",'
          '"${forecast.modelType}",'
          '"${forecast.confidenceLevel}",'
          '${forecast.demandForecastKg},'
          '${forecast.demandLowerBound},'
          '${forecast.demandUpperBound},'
          '${forecast.priceForecast},'
          '${forecast.priceLowerBound},'
          '${forecast.priceUpperBound}',
        );
      }
      
      // Get documents directory and create file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'OPAS_Forecasts_$timestamp.csv';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(buffer.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported: $filename\nSaved to: ${directory.path}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // Show the file path in a dialog for user reference
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('File Exported'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filename: $filename'),
                          const SizedBox(height: 8),
                          Text('Location: ${directory.path}'),
                          const SizedBox(height: 16),
                          const Text('You can find this file in your device\'s Documents folder or use a file manager to access it.'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatLastUpdated() {
    if (_lastUpdated == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(_lastUpdated!);
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'VEGETABLE':
        return 'Vegetables';
      case 'FRUIT':
        return 'Fruits';
      case 'LIVESTOCK':
        return 'Livestock';
      case 'POULTRY':
        return 'Poultry';
      case 'SEEDS':
        return 'Seeds';
      case 'FERTILIZERS':
        return 'Fertilizers';
      case 'FEEDS':
        return 'Feeds';
      case 'MEDICINES':
        return 'Medicines';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final cardBgColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Forecasting Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        foregroundColor: textColor,
        actions: [
          Tooltip(
            message: 'Export as CSV',
            child: IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _exportAsCSV,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<ForecastModel>>(
        future: _forecastsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF00B464),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading forecasts...',
                    style: TextStyle(color: subtleColor),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 24),
                  Text(
                    'Unable to Load Forecasts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _refreshForecasts()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (_forecasts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Forecasts Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Forecasts will appear here once they are generated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _manualRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Generate Forecasts'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _manualRefresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section with Stats
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Forecasts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_forecasts.length}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Updated',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatLastUpdated(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00B464),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: TextStyle(color: subtleColor),
                            prefixIcon: Icon(Icons.search_rounded, color: subtleColor),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, color: subtleColor),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: cardBgColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF00B464),
                                width: 2,
                              ),
                            ),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Three-column filter layout
                        Row(
                          children: [
                            // Confidence Filter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Confidence',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtleColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: DropdownButton<String>(
                                      value: _selectedConfidence,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: _confidenceFilters
                                          .map((conf) => DropdownMenuItem(
                                                value: conf,
                                                child: Text(conf),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() =>
                                              _selectedConfidence = value);
                                          _applyFilters();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Category Filter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtleColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: _categoryFilters
                                          .map((cat) => DropdownMenuItem(
                                                value: cat,
                                                child: Text(cat == 'All'
                                                    ? 'All'
                                                    : _getCategoryLabel(cat)),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                              () => _selectedCategory = value);
                                          _applyFilters();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Type Filter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Type',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtleColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: DropdownButton<String>(
                                      value: _selectedType,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: _typeFilters
                                          .map((type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(type),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _selectedType = value);
                                          _applyFilters();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Results Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Showing ${_filteredForecasts.length} of ${_forecasts.length} forecasts',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Forecasts List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredForecasts.length,
                      itemBuilder: (context, index) {
                        final forecast = _filteredForecasts[index];
                        return ForecastCard(
                          forecast: forecast,
                          onViewDetails: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForecastDetailScreen(
                                  forecast: forecast,
                                ),
                              ),
                            );
                          },
                          onViewHistory: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ForecastHistoryScreen(
                                  productName: forecast.productName,
                                  categoryName: forecast.categoryName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
