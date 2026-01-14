import 'package:flutter/material.dart';

// Forecast Detail Model - Phase 5.1 B - Detailed forecast with historical data
class ForecastDetailModel {
  final int id;
  final int? productId;
  final String productName;
  final String? categoryName;
  
  // Model information
  final String modelType;
  final String modelParameters; // e.g., "SARIMA(1,1,1)(0,1,0)_12"
  final int dataPointsCount;
  final DateTime lastTrainingDate;
  final String confidenceLevel;
  
  // Time series data - Historical + Forecast
  final List<ForecastDataPoint> demandHistory;
  final List<ForecastDataPoint> demandForecast;
  final List<ForecastDataPoint> priceHistory;
  final List<ForecastDataPoint> priceForecast;
  
  // Alerts
  final List<ForecastAlertItem> alerts;
  
  // Metadata
  final DateTime forecastDate;
  final double rmseValue;
  final double mapeValue;
  final bool isReliable;
  
  // Validation metrics (NEW)
  final double? validationMape;
  final String? validationConfidence;
  final DateTime? validationDate;
  final ModelAccuracyInfo? modelAccuracyInfo;

  ForecastDetailModel({
    required this.id,
    this.productId,
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
    this.validationMape,
    this.validationConfidence,
    this.validationDate,
    this.modelAccuracyInfo,
  });

  factory ForecastDetailModel.fromJson(Map<String, dynamic> json) {
    return ForecastDetailModel(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String? ?? 'Unknown',
      categoryName: json['category_name'] as String?,
      modelType: json['model_type'] as String? ?? 'UNKNOWN',
      modelParameters: json['model_parameters'] as String? ?? 'N/A',
      dataPointsCount: json['data_points_count'] as int? ?? 0,
      lastTrainingDate: json['last_training_date'] != null
          ? DateTime.parse(json['last_training_date'] as String)
          : DateTime.now(),
      confidenceLevel: json['confidence_level'] as String? ?? 'MEDIUM',
      demandHistory: (json['demand_history'] as List?)
              ?.map((item) => ForecastDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      demandForecast: (json['demand_forecast'] as List?)
              ?.map((item) => ForecastDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      priceHistory: (json['price_history'] as List?)
              ?.map((item) => ForecastDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      priceForecast: (json['price_forecast'] as List?)
              ?.map((item) => ForecastDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      alerts: (json['alerts'] as List?)
              ?.map((item) => ForecastAlertItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      forecastDate: json['forecast_date'] != null
          ? DateTime.parse(json['forecast_date'] as String)
          : DateTime.now(),
      rmseValue: (json['rmse_value'] as num?)?.toDouble() ?? 0.0,
      mapeValue: (json['mape_value'] as num?)?.toDouble() ?? 0.0,
      isReliable: json['is_reliable'] as bool? ?? false,
      validationMape: (json['validation_mape'] as num?)?.toDouble(),
      validationConfidence: json['validation_confidence'] as String?,
      validationDate: json['validation_date'] != null
          ? DateTime.parse(json['validation_date'] as String)
          : null,
      modelAccuracyInfo: json['model_accuracy_info'] != null
          ? ModelAccuracyInfo.fromJson(json['model_accuracy_info'] as Map<String, dynamic>)
          : null,
    );
  }

  String getConfidenceStars() {
    switch (confidenceLevel) {
      case 'HIGH':
        return '⭐⭐⭐⭐⭐';
      case 'MEDIUM':
        return '⭐⭐⭐⭐';
      case 'LOW':
        return '⭐⭐⭐';
      default:
        return '⭐⭐';
    }
  }

  String getLastUpdatedFormatted() {
    final now = DateTime.now();
    final difference = now.difference(lastTrainingDate);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays ~/ 7)}w ago';
    }
  }
}

/// Single data point for forecast chart
class ForecastDataPoint {
  final String period; // e.g., "Week 1", "2025-01-15"
  final double value;
  final double? lowerBound;
  final double? upperBound;
  final DateTime date;

  ForecastDataPoint({
    required this.period,
    required this.value,
    this.lowerBound,
    this.upperBound,
    required this.date,
  });

  factory ForecastDataPoint.fromJson(Map<String, dynamic> json) {
    return ForecastDataPoint(
      period: json['period'] as String? ?? 'N/A',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      lowerBound: (json['lower_bound'] as num?)?.toDouble(),
      upperBound: (json['upper_bound'] as num?)?.toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
    );
  }

  double get midValue => (lowerBound ?? value + (upperBound ?? value)) / 2;
  double get errorMargin => (upperBound ?? value) - value;
}

/// Alert item for forecast detail
class ForecastAlertItem {
  final int id;
  final String type; // DECLINING_DEMAND, PRICE_SPIKE, LOW_CONFIDENCE
  final String severity; // INFO, WARNING, CRITICAL
  final String message;
  final DateTime createdAt;
  final bool isAcknowledged;

  ForecastAlertItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.createdAt,
    required this.isAcknowledged,
  });

  factory ForecastAlertItem.fromJson(Map<String, dynamic> json) {
    return ForecastAlertItem(
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

  String getAlertIcon() {
    switch (severity) {
      case 'CRITICAL':
        return '🔴';
      case 'WARNING':
        return '🟡';
      case 'INFO':
        return '🔵';
      default:
        return 'ℹ️';
    }
  }

  Color getAlertColor() {
    switch (severity) {
      case 'CRITICAL':
        return const Color(0xFFFF5252);
      case 'WARNING':
        return const Color(0xFFFFC107);
      case 'INFO':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Model accuracy information - shows all 3 models compared
class ModelAccuracyInfo {
  final ModelAccuracyGroup? demand;
  final ModelAccuracyGroup? price;

  ModelAccuracyInfo({
    this.demand,
    this.price,
  });

  factory ModelAccuracyInfo.fromJson(Map<String, dynamic> json) {
    return ModelAccuracyInfo(
      demand: json['demand'] != null
          ? ModelAccuracyGroup.fromJson(json['demand'] as Map<String, dynamic>)
          : null,
      price: json['price'] != null
          ? ModelAccuracyGroup.fromJson(json['price'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model accuracy group containing best model and all models
class ModelAccuracyGroup {
  final String bestModel;
  final List<ModelMetric> models;

  ModelAccuracyGroup({
    required this.bestModel,
    required this.models,
  });

  factory ModelAccuracyGroup.fromJson(Map<String, dynamic> json) {
    return ModelAccuracyGroup(
      bestModel: json['best_model'] as String? ?? 'UNKNOWN',
      models: (json['models'] as List?)
              ?.map((item) => ModelMetric.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Individual model metrics (ARIMA, SARIMA, SIMPLE)
class ModelMetric {
  final String model; // ARIMA, SARIMA, SIMPLE
  final double mape; // Mean Absolute Percentage Error %
  final double? rmse; // Root Mean Squared Error (optional)
  final double? mae; // Mean Absolute Error (optional)

  ModelMetric({
    required this.model,
    required this.mape,
    this.rmse,
    this.mae,
  });

  factory ModelMetric.fromJson(Map<String, dynamic> json) {
    return ModelMetric(
      model: json['model'] as String? ?? 'UNKNOWN',
      mape: (json['mape'] as num?)?.toDouble() ?? 0.0,
      rmse: (json['rmse'] as num?)?.toDouble(),
      mae: (json['mae'] as num?)?.toDouble(),
    );
  }

  /// Get confidence level based on MAPE
  String getConfidenceFromMape() {
    if (mape <= 10) {
      return 'HIGH';
    } else if (mape <= 20) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }

  /// Get emoji representation of accuracy
  String getAccuracyEmoji() {
    if (mape <= 5) {
      return '⭐'; // Excellent
    } else if (mape <= 10) {
      return '✅'; // Very Good
    } else if (mape <= 20) {
      return '👍'; // Good
    } else {
      return '⚠️'; // Needs improvement
    }
  }
}

