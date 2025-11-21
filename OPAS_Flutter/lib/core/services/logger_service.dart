/// Logger Service
///
/// Provides centralized logging framework for the entire OPAS application.
/// Uses the logger package for comprehensive logging with multiple levels
/// and output filtering.
///
/// Features:
/// - Multiple log levels: TRACE, DEBUG, INFO, WARNING, ERROR, FATAL
/// - Contextual logging with tags and metadata
/// - Stack trace capture for errors
/// - Performance tracking
/// - Structured error reporting
///
/// Usage:
/// ```dart
/// Logger.debug('User logged in', tag: 'auth');
/// Logger.error('Payment failed', error: e, stackTrace: st);
/// Logger.info('Marketplace health: 85%', tag: 'health_check');
/// ```

import 'package:logger/logger.dart' as logger_package;

class LoggerService {
  LoggerService._(); // Private constructor - no instantiation

  static final logger_package.Logger _logger = logger_package.Logger(
    printer: logger_package.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: logger_package.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // ============================================================================
  // Logging Methods
  // ============================================================================

  /// Logs a trace message (lowest priority).
  /// Use for very detailed debugging information.
  static void trace(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _logger.t(
      '[$tag] $message',
      time: DateTime.now(),
    );
    if (metadata != null) {
      _logger.t('Metadata: $metadata');
    }
  }

  /// Logs a debug message.
  /// Use for development and debugging purposes.
  static void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _logger.d(
      '[$tag] $message',
      time: DateTime.now(),
    );
    if (metadata != null) {
      _logger.d('Metadata: $metadata');
    }
  }

  /// Logs an info message.
  /// Use for general informational messages.
  static void info(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _logger.i(
      '[$tag] $message',
      time: DateTime.now(),
    );
    if (metadata != null) {
      _logger.i('Metadata: $metadata');
    }
  }

  /// Logs a warning message.
  /// Use for potentially problematic situations.
  static void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _logger.w(
      '[$tag] $message',
      time: DateTime.now(),
    );
    if (metadata != null) {
      _logger.w('Metadata: $metadata');
    }
  }

  /// Logs an error message with optional error and stack trace.
  /// Use for error conditions that need attention.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _logger.e(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
    if (metadata != null) {
      _logger.e('Metadata: $metadata');
    }
  }

  /// Logs a fatal error message.
  /// Use for critical errors that may crash the application.
  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _logger.f(
      '[$tag] $message - CRITICAL',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
    if (metadata != null) {
      _logger.f('Metadata: $metadata');
    }
  }

  // ============================================================================
  // Performance Tracking
  // ============================================================================

  /// Logs method entry for performance tracking.
  /// Used to track when methods start executing.
  static void methodEntry(
    String methodName, {
    String? tag,
    Map<String, dynamic>? parameters,
  }) {
    info(
      'Entering method: $methodName',
      tag: tag ?? 'PERFORMANCE',
      metadata: parameters,
    );
  }

  /// Logs method exit for performance tracking.
  /// Used to track when methods complete execution.
  static void methodExit(
    String methodName, {
    String? tag,
    Duration? duration,
    Map<String, dynamic>? result,
  }) {
    final message = duration != null
        ? 'Exiting method: $methodName (${duration.inMilliseconds}ms)'
        : 'Exiting method: $methodName';

    info(
      message,
      tag: tag ?? 'PERFORMANCE',
      metadata: result,
    );
  }

  // ============================================================================
  // Business Event Logging
  // ============================================================================

  /// Logs marketplace health calculation results.
  static void logMarketplaceHealth(
    double healthScore,
    String healthLevel, {
    Map<String, dynamic>? componentScores,
  }) {
    info(
      'Marketplace Health Updated: $healthScore ($healthLevel)',
      tag: 'MARKETPLACE_HEALTH',
      metadata: {
        'health_score': healthScore,
        'health_level': healthLevel,
        'timestamp': DateTime.now().toIso8601String(),
        ...?componentScores,
      },
    );
  }

  /// Logs seller performance calculation results.
  static void logSellerPerformance(
    String sellerId,
    double performanceScore,
    String performanceLevel, {
    Map<String, dynamic>? metrics,
  }) {
    info(
      'Seller Performance Updated: $sellerId - $performanceScore ($performanceLevel)',
      tag: 'SELLER_PERFORMANCE',
      metadata: {
        'seller_id': sellerId,
        'performance_score': performanceScore,
        'performance_level': performanceLevel,
        'timestamp': DateTime.now().toIso8601String(),
        ...?metrics,
      },
    );
  }

  /// Logs fraud detection events.
  static void logFraudDetection(
    String sellerId,
    double suspicionScore,
    String fraudPattern, {
    Map<String, dynamic>? details,
  }) {
    warning(
      'Fraud Alert: Seller $sellerId - Pattern: $fraudPattern (Score: $suspicionScore)',
      tag: 'FRAUD_DETECTION',
      metadata: {
        'seller_id': sellerId,
        'suspicion_score': suspicionScore,
        'fraud_pattern': fraudPattern,
        'timestamp': DateTime.now().toIso8601String(),
        ...?details,
      },
    );
  }

  /// Logs demand elasticity analysis results.
  static void logDemandElasticity(
    String productId,
    double elasticityScore,
    String elasticityType, {
    Map<String, dynamic>? analysis,
  }) {
    info(
      'Demand Elasticity Calculated: Product $productId - $elasticityType ($elasticityScore)',
      tag: 'DEMAND_ELASTICITY',
      metadata: {
        'product_id': productId,
        'elasticity_score': elasticityScore,
        'elasticity_type': elasticityType,
        'timestamp': DateTime.now().toIso8601String(),
        ...?analysis,
      },
    );
  }

  /// Logs seasonal trend forecasting results.
  static void logSeasonalTrend(
    String productId,
    String trendDirection,
    int forecastHorizonDays, {
    Map<String, dynamic>? forecast,
  }) {
    info(
      'Seasonal Trend Forecast: Product $productId - $trendDirection (Horizon: ${forecastHorizonDays}d)',
      tag: 'SEASONAL_TREND',
      metadata: {
        'product_id': productId,
        'trend_direction': trendDirection,
        'forecast_horizon_days': forecastHorizonDays,
        'timestamp': DateTime.now().toIso8601String(),
        ...?forecast,
      },
    );
  }

  // ============================================================================
  // API Logging
  // ============================================================================

  /// Logs API request details.
  static void logApiRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? parameters,
    String? tag,
  }) {
    debug(
      'API Request: $method $endpoint',
      tag: tag ?? 'API_REQUEST',
      metadata: {
        'endpoint': endpoint,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      },
    );
  }

  /// Logs API response details.
  static void logApiResponse(
    String endpoint,
    int statusCode,
    Duration duration, {
    Object? response,
    String? tag,
  }) {
    final level = statusCode < 400 ? 'success' : 'error';
    info(
      'API Response: $endpoint - $statusCode (${duration.inMilliseconds}ms)',
      tag: tag ?? 'API_RESPONSE',
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'duration_ms': duration.inMilliseconds,
        'response_level': level,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Logs API errors.
  static void logApiError(
    String endpoint,
    Object error, {
    StackTrace? stackTrace,
    String? tag,
  }) {
    LoggerService.error(
      'API Error: $endpoint',
      tag: tag ?? 'API_ERROR',
      error: error,
      stackTrace: stackTrace,
      metadata: {
        'endpoint': endpoint,
        'error_type': error.runtimeType.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================================
  // Service Lifecycle Logging
  // ============================================================================

  /// Logs service initialization.
  static void logServiceInit(String serviceName) {
    info(
      'Initializing Service: $serviceName',
      tag: 'SERVICE_INIT',
    );
  }

  /// Logs service completion.
  static void logServiceComplete(
    String serviceName,
    Duration duration, {
    Map<String, dynamic>? result,
  }) {
    info(
      'Service Complete: $serviceName (${duration.inMilliseconds}ms)',
      tag: 'SERVICE_COMPLETE',
      metadata: {
        'service': serviceName,
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        ...?result,
      },
    );
  }
}
