/// DTOs for Forecasting API responses (Phase 5.3)
/// 
/// These DTOs match the backend API response structure and are used
/// for serialization/deserialization of forecast data from the Django REST API

import 'package:opas_flutter/core/models/forecast_model.dart';
import 'package:opas_flutter/core/models/forecast_detail_model.dart';

/// DTO for forecast list items (returned from /api/admin/forecasts/)
/// 
/// Matches ProductForecast model from Django with all required fields
class ForecastDto {
  final int id;
  final int productId;
  final String productName;
  final String? categoryName;
  final DateTime forecastDate;
  final String forecastPeriod;
  
  // Demand forecast
  final double demandForecastKg;
  final double demandLowerBound;
  final double demandUpperBound;
  
  // Price forecast
  final double priceForecast;
  final double priceLowerBound;
  final double priceUpperBound;
  
  // Model info
  final String confidenceLevel;
  final String modelType;
  final bool isCurrent;
  
  ForecastDto({
    required this.id,
    required this.productId,
    required this.productName,
    this.categoryName,
    required this.forecastDate,
    required this.forecastPeriod,
    required this.demandForecastKg,
    required this.demandLowerBound,
    required this.demandUpperBound,
    required this.priceForecast,
    required this.priceLowerBound,
    required this.priceUpperBound,
    required this.confidenceLevel,
    required this.modelType,
    required this.isCurrent,
  });

  /// Parse from JSON response from backend
  factory ForecastDto.fromJson(Map<String, dynamic> json) {
    return ForecastDto(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      categoryName: json['product_category'] as String?,
      forecastDate: json['forecast_date'] != null
          ? DateTime.parse(json['forecast_date'] as String)
          : DateTime.now(),
      forecastPeriod: json['forecast_period'] as String? ?? '',
      demandForecastKg: (json['demand_forecast_kg'] as num?)?.toDouble() ?? 0.0,
      demandLowerBound: (json['demand_lower_bound'] as num?)?.toDouble() ?? 0.0,
      demandUpperBound: (json['demand_upper_bound'] as num?)?.toDouble() ?? 0.0,
      priceForecast: (json['price_forecast'] as num?)?.toDouble() ?? 0.0,
      priceLowerBound: (json['price_lower_bound'] as num?)?.toDouble() ?? 0.0,
      priceUpperBound: (json['price_upper_bound'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: json['confidence_level'] as String? ?? 'MEDIUM',
      modelType: json['model_type'] as String? ?? 'UNKNOWN',
      isCurrent: json['is_current'] as bool? ?? true,
    );
  }

  /// Convert to ForecastModel for UI display
  ForecastModel toModel() {
    return ForecastModel(
      id: id,
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      forecastDate: forecastDate,
      forecastPeriod: forecastPeriod,
      demandForecastKg: demandForecastKg,
      demandLowerBound: demandLowerBound,
      demandUpperBound: demandUpperBound,
      priceForecast: priceForecast,
      priceLowerBound: priceLowerBound,
      priceUpperBound: priceUpperBound,
      confidenceLevel: confidenceLevel,
      modelType: modelType,
      isCurrent: isCurrent,
    );
  }

  @override
  String toString() {
    return 'ForecastDto($id - $productName, $modelType, $confidenceLevel)';
  }
}

/// DTO for forecast detail response (from /api/admin/forecasts/{product_id}/)
/// 
/// Contains full time series data with historical records and forecast data
class ForecastDetailDto {
  final int id;
  final int productId;
  final String productName;
  final String? categoryName;
  
  // Model information
  final String modelType;
  final String modelParameters;
  final int dataPointsCount;
  final DateTime lastTrainingDate;
  final String confidenceLevel;
  
  // Time series data
  final List<ForecastDataPointDto> demandHistory;
  final List<ForecastDataPointDto> demandForecast;
  final List<ForecastDataPointDto> priceHistory;
  final List<ForecastDataPointDto> priceForecast;
  
  // Alerts
  final List<ForecastAlertItemDto> alerts;
  
  // Metadata
  final DateTime forecastDate;
  final double rmseValue;
  final double mapeValue;
  final bool isReliable;

  ForecastDetailDto({
    required this.id,
    required this.productId,
    required this.productName,
    this.categoryName,
    required this.modelType,
    required this.modelParameters,
    required this.dataPointsCount,
    required this.lastTrainingDate,
    required this.confidenceLevel,
    required this.demandHistory,
    required this.demandForecast,
    required this.priceHistory,
    required this.priceForecast,
    required this.alerts,
    required this.forecastDate,
    required this.rmseValue,
    required this.mapeValue,
    required this.isReliable,
  });

  /// Parse from JSON response from backend
  factory ForecastDetailDto.fromJson(Map<String, dynamic> json) {
    return ForecastDetailDto(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      categoryName: json['product_category'] as String?,
      modelType: json['model_type'] as String? ?? 'UNKNOWN',
      modelParameters: json['model_parameters'] as String? ?? 'N/A',
      dataPointsCount: json['data_points_count'] as int? ?? 0,
      lastTrainingDate: json['last_training_date'] != null
          ? DateTime.parse(json['last_training_date'] as String)
          : DateTime.now(),
      confidenceLevel: json['confidence_level'] as String? ?? 'MEDIUM',
      demandHistory: (json['demand_history'] as List?)
              ?.map((item) => ForecastDataPointDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      demandForecast: (json['demand_forecast'] as List?)
              ?.map((item) => ForecastDataPointDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      priceHistory: (json['price_history'] as List?)
              ?.map((item) => ForecastDataPointDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      priceForecast: (json['price_forecast'] as List?)
              ?.map((item) => ForecastDataPointDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      alerts: (json['alerts'] as List?)
              ?.map((item) => ForecastAlertItemDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      forecastDate: json['forecast_date'] != null
          ? DateTime.parse(json['forecast_date'] as String)
          : DateTime.now(),
      rmseValue: (json['rmse_value'] as num?)?.toDouble() ?? 0.0,
      mapeValue: (json['mape_value'] as num?)?.toDouble() ?? 0.0,
      isReliable: json['is_reliable'] as bool? ?? false,
    );
  }

  /// Convert to ForecastDetailModel for UI display
  ForecastDetailModel toModel() {
    return ForecastDetailModel(
      id: id,
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      modelType: modelType,
      modelParameters: modelParameters,
      dataPointsCount: dataPointsCount,
      lastTrainingDate: lastTrainingDate,
      confidenceLevel: confidenceLevel,
      demandHistory: demandHistory.map((d) => d.toModel()).toList(),
      demandForecast: demandForecast.map((d) => d.toModel()).toList(),
      priceHistory: priceHistory.map((d) => d.toModel()).toList(),
      priceForecast: priceForecast.map((d) => d.toModel()).toList(),
      alerts: alerts.map((a) => a.toModel()).toList(),
      forecastDate: forecastDate,
      rmseValue: rmseValue,
      mapeValue: mapeValue,
      isReliable: isReliable,
    );
  }

  @override
  String toString() {
    return 'ForecastDetailDto($id - $productName, $modelType)';
  }
}

/// DTO for single data point in time series
class ForecastDataPointDto {
  final String period;
  final double value;
  final double? lowerBound;
  final double? upperBound;
  final DateTime date;

  ForecastDataPointDto({
    required this.period,
    required this.value,
    this.lowerBound,
    this.upperBound,
    required this.date,
  });

  factory ForecastDataPointDto.fromJson(Map<String, dynamic> json) {
    return ForecastDataPointDto(
      period: json['period'] as String? ?? 'N/A',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      lowerBound: (json['lower_bound'] as num?)?.toDouble(),
      upperBound: (json['upper_bound'] as num?)?.toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to ForecastDataPoint model
  ForecastDataPoint toModel() {
    return ForecastDataPoint(
      period: period,
      value: value,
      lowerBound: lowerBound,
      upperBound: upperBound,
      date: date,
    );
  }
}

/// DTO for forecast alert
class ForecastAlertItemDto {
  final int id;
  final String type;
  final String severity;
  final String message;
  final DateTime createdAt;
  final bool isAcknowledged;

  ForecastAlertItemDto({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.createdAt,
    required this.isAcknowledged,
  });

  factory ForecastAlertItemDto.fromJson(Map<String, dynamic> json) {
    return ForecastAlertItemDto(
      id: json['id'] as int? ?? 0,
      type: json['alert_type'] as String? ?? 'INFO',
      severity: json['severity'] as String? ?? 'INFO',
      message: json['message'] as String? ?? 'No message',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
    );
  }

  /// Convert to ForecastAlertItem model
  ForecastAlertItem toModel() {
    return ForecastAlertItem(
      id: id,
      type: type,
      severity: severity,
      message: message,
      createdAt: createdAt,
      isAcknowledged: isAcknowledged,
    );
  }
}

/// DTO for forecast metadata (from /api/admin/forecasts/metadata/)
/// 
/// Contains information about forecasting models and data coverage across products
class ForecastMetadataDto {
  final String modelType;
  final int dataPointsCount;
  final DateTime lastTrainingDate;
  final bool isReliable;
  final String? notes;
  final double dataCoveragePercentage;
  final String modelParameters;

  ForecastMetadataDto({
    required this.modelType,
    required this.dataPointsCount,
    required this.lastTrainingDate,
    required this.isReliable,
    this.notes,
    required this.dataCoveragePercentage,
    required this.modelParameters,
  });

  factory ForecastMetadataDto.fromJson(Map<String, dynamic> json) {
    return ForecastMetadataDto(
      modelType: json['model_type'] as String? ?? 'UNKNOWN',
      dataPointsCount: json['data_points_count'] as int? ?? 0,
      lastTrainingDate: json['last_training_date'] != null
          ? DateTime.parse(json['last_training_date'] as String)
          : DateTime.now(),
      isReliable: json['is_reliable'] as bool? ?? false,
      notes: json['notes'] as String?,
      dataCoveragePercentage: (json['data_coverage_percentage'] as num?)?.toDouble() ?? 0.0,
      modelParameters: json['model_parameters'] as String? ?? 'N/A',
    );
  }

  @override
  String toString() {
    return 'ForecastMetadataDto($modelType, reliability: ${isReliable ? 'Yes' : 'No'})';
  }
}
