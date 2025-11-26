import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';

class SellerApplicationStatusScreen extends StatefulWidget {
  const SellerApplicationStatusScreen({Key? key}) : super(key: key);

  @override
  State<SellerApplicationStatusScreen> createState() =>
      _SellerApplicationStatusScreenState();
}

class _SellerApplicationStatusScreenState
    extends State<SellerApplicationStatusScreen> {
  late Future<Map<String, dynamic>> _applicationStatusFuture;

  @override
  void initState() {
    super.initState();
    _applicationStatusFuture = _fetchApplicationStatus();
  }

  Future<Map<String, dynamic>> _fetchApplicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('access');
      final sellerStatus = prefs.getString('seller_status') ?? 'BUYER';

      // If user is already approved, no need to show this screen
      if (sellerStatus == 'APPROVED') {
        return {'status': 'APPROVED', 'message': 'Your application is approved!'};
      }

      // If user is not a seller, show buyer message
      if (sellerStatus == 'BUYER') {
        return {
          'status': 'NOT_SELLER',
          'message': 'You are not a seller yet. Use "Become a Seller" to apply.'
        };
      }

      // Fetch application details from API
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users/seller/profile/application_status/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'status': data['seller_status'] ?? sellerStatus,
          'rejectionReason': data['rejection_reason'] ?? '',
          'appliedDate': data['created_at'] ?? '',
          'reviewedDate': data['reviewed_at'] ?? '',
          'reviewedByName': data['reviewed_by_name'] ?? '',
          'message': _getStatusMessage(data['seller_status'] ?? sellerStatus),
        };
      } else {
        // Fallback to local status
        return {
          'status': sellerStatus,
          'message': _getStatusMessage(sellerStatus),
        };
      }
    } catch (e) {
      return {
        'status': 'ERROR',
        'message': 'Error loading application status: $e'
      };
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Your seller application is under review. Please wait for admin approval.';
      case 'APPROVED':
        return 'Congratulations! Your seller application has been approved.';
      case 'REJECTED':
        return 'Your seller application was rejected.';
      case 'SUSPENDED':
        return 'Your seller account has been suspended.';
      default:
        return 'Unknown status';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'SUSPENDED':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'SUSPENDED':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Application Status'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _applicationStatusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _applicationStatusFuture = _fetchApplicationStatus();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final status = snapshot.data;
          if (status == null) {
            return const Center(child: Text('No data available'));
          }

          final statusValue = status['status'] as String;
          final message = status['message'] as String? ?? '';
          final rejectionReason = status['rejectionReason'] as String? ?? '';
          final appliedDate = status['appliedDate'] as String? ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Status Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(statusValue),
                          size: 64,
                          color: _getStatusColor(statusValue),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          statusValue.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _getStatusColor(statusValue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Rejection Reason (if rejected)
                if (statusValue.toUpperCase() == 'REJECTED' &&
                    rejectionReason.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    color: Colors.red.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Rejection Reason',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rejectionReason,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Applied Date
                if (appliedDate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Date',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              appliedDate,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // If rejected, show "Apply Again" button
                      if (statusValue.toUpperCase() == 'REJECTED')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to seller upgrade screen to reapply
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Apply Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
