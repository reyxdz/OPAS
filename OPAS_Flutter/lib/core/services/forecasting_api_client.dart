/// ForecastingApiClient - Phase 5.3 API Integration
/// 
/// High-level API client for forecasting feature that wraps AdminService methods
/// and provides convenient access to forecasting endpoints with DTO conversion

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/core/models/forecast_dto.dart';

/// Main API client for forecasting endpoints
/// 
/// Provides clean, type-safe access to:
/// - List all forecasts: GET /api/admin/forecasts/
/// - Get forecast detail: GET /api/admin/forecasts/{product_id}/
/// - Get metadata: GET /api/admin/forecasts/metadata/
/// - Get alerts: GET /api/admin/forecasts/alerts/
/// - Refresh forecasts: POST /api/admin/forecasts/refresh/
class ForecastingApiClient {
  /// Fetch all forecasts
  /// 
  /// Returns list of forecast summaries for all products with sufficient data
  /// Used by: ForecastingDashboardScreen for displaying forecast list
  /// 
  /// Returns:
  ///   - List<ForecastDto> - Parsed forecast list
  ///   - Empty list if API fails or returns no data
  /// 
  /// Throws:
  ///   - Exception on network error or API error
  Future<List<ForecastDto>> getAllForecasts() async {
    try {
      debugPrint('📡 ForecastingApiClient: Fetching all forecasts...');
      
      final response = await AdminService.getAllForecasts();
      
      if (response.isEmpty) {
        debugPrint('⚠️ ForecastingApiClient: No forecasts returned');
        return [];
      }
      
      // Convert dynamic list to list of maps
      final forecastsList = response
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            }
            return item as Map<String, dynamic>;
          })
          .toList();
      
      // Convert to DTOs
      final forecasts = forecastsList
          .map((json) => ForecastDto.fromJson(json))
          .toList();
      
      debugPrint('✅ ForecastingApiClient: Retrieved ${forecasts.length} forecasts');
      return forecasts;
    } catch (e) {
      debugPrint('❌ ForecastingApiClient.getAllForecasts error: $e');
      rethrow;
    }
  }

  /// Fetch detailed forecast for a specific product
  /// 
  /// Returns comprehensive forecast data including:
  /// - Time series data (historical + forecast)
  /// - Confidence intervals
  /// - Model information
  /// - Alerts
  /// Used by: ProductForecastDetailScreen for displaying detail view
  /// 
  /// Parameters:
  ///   - productId: ID of product to get forecast for
  /// 
  /// Returns:
  ///   - ForecastDetailDto - Detailed forecast data with time series
  /// 
  /// Throws:
  ///   - Exception if product not found (404)
  ///   - Exception if unauthorized (401/403)
  ///   - Exception on network error
  Future<ForecastDetailDto> getForecastDetail(int productId) async {
    try {
      debugPrint('📡 ForecastingApiClient: Fetching forecast detail for product $productId...');
      
      final response = await AdminService.getForecastDetail(productId);
      
      if (response.isEmpty) {
        throw Exception('No forecast detail found for product $productId');
      }
      
      final detail = ForecastDetailDto.fromJson(response);
      debugPrint('✅ ForecastingApiClient: Retrieved forecast detail for ${detail.productName}');
      
      return detail;
    } catch (e) {
      debugPrint('❌ ForecastingApiClient.getForecastDetail error: $e');
      rethrow;
    }
  }

  /// Fetch forecast metadata (model info and statistics)
  /// 
  /// Returns information about forecasting models across all products:
  /// - Model types in use
  /// - Data coverage statistics
  /// - Model reliability indicators
  /// - Training dates
  /// Used by: Analytics dashboard or admin info panel
  /// 
  /// Returns:
  ///   - ForecastMetadataDto - Model metadata
  ///   - Empty metadata if API fails
  /// 
  /// Throws:
  ///   - Exception on network error or API error
  Future<ForecastMetadataDto> getMetadata() async {
    try {
      debugPrint('📡 ForecastingApiClient: Fetching forecast metadata...');
      
      final response = await AdminService.getForecastMetadata();
      
      if (response.isEmpty) {
        debugPrint('⚠️ ForecastingApiClient: No metadata returned');
        // Return empty/default metadata
        return ForecastMetadataDto(
          modelType: 'UNKNOWN',
          dataPointsCount: 0,
          lastTrainingDate: DateTime.now(),
          isReliable: false,
          dataCoveragePercentage: 0,
          modelParameters: 'N/A',
        );
      }
      
      final metadata = ForecastMetadataDto.fromJson(response);
      debugPrint('✅ ForecastingApiClient: Retrieved metadata for model ${metadata.modelType}');
      
      return metadata;
    } catch (e) {
      debugPrint('❌ ForecastingApiClient.getMetadata error: $e');
      rethrow;
    }
  }

  /// Fetch forecast alerts
  /// 
  /// Returns list of alerts about forecast anomalies:
  /// - Declining demand trends
  /// - Price spikes
  /// - Low confidence forecasts
  /// Used by: Alerts panel or dashboard notifications
  /// 
  /// Returns:
  ///   - List<ForecastAlertItemDto> - List of alerts
  ///   - Empty list if no alerts or API fails
  /// 
  /// Throws:
  ///   - Exception on network error
  Future<List<ForecastAlertItemDto>> getAlerts() async {
    try {
      debugPrint('📡 ForecastingApiClient: Fetching forecast alerts...');
      
      final response = await AdminService.getForecastAlerts();
      
      if (response.isEmpty) {
        debugPrint('✅ ForecastingApiClient: No alerts');
        return [];
      }
      
      final alerts = response
          .map((json) => ForecastAlertItemDto.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ ForecastingApiClient: Retrieved ${alerts.length} alerts');
      return alerts;
    } catch (e) {
      debugPrint('❌ ForecastingApiClient.getAlerts error: $e');
      rethrow;
    }
  }

  /// Trigger manual forecast refresh (Super Admin only)
  /// 
  /// Regenerates all forecasts immediately instead of waiting for scheduled task
  /// Returns job status and estimated completion time
  /// Used by: Admin dashboard refresh button
  /// 
  /// Returns:
  ///   - Map with status and job info
  ///   - {'status': 'success', 'jobId': '...'} on success
  ///   - {'status': 'error', 'message': '...'} on error
  /// 
  /// Throws:
  ///   - Exception if not super admin (403)
  ///   - Exception on network error
  Future<Map<String, dynamic>> refreshForecasts() async {
    try {
      debugPrint('📡 ForecastingApiClient: Triggering forecast refresh...');
      
      final response = await AdminService.refreshForecasts();
      
      if (response['status'] == 'success' || response['status'] == null) {
        debugPrint('✅ ForecastingApiClient: Forecast refresh triggered');
        return response;
      } else {
        debugPrint('⚠️ ForecastingApiClient: Refresh returned non-success status');
        return response;
      }
    } catch (e) {
      debugPrint('❌ ForecastingApiClient.refreshForecasts error: $e');
      rethrow;
    }
  }
}
