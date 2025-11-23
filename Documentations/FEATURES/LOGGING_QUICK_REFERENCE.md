# Logging Framework - Quick Reference Guide

## Importing the Logger
```dart
import 'package:opas_flutter/core/services/logger_service.dart';
```

## Basic Logging Levels

### Debug (Development)
```dart
LoggerService.debug('User clicked button', tag: 'UI');
LoggerService.trace('Entering calculateScore function', tag: 'CALC');
```

### Info (General Events)
```dart
LoggerService.info('User logged in successfully', tag: 'AUTH');
LoggerService.info('Marketplace health calculated: 85%', tag: 'HEALTH');
```

### Warning (Attention Required)
```dart
LoggerService.warning('Retry attempt 2 of 3', tag: 'API');
LoggerService.warning('High server response time: 2500ms', tag: 'API');
```

### Error (Failures)
```dart
try {
  // some operation
} catch (e) {
  LoggerService.error(
    'Price calculation failed',
    tag: 'CALCULATION',
    error: e,
  );
}
```

### Fatal (Critical Issues)
```dart
LoggerService.fatal(
  'Critical: Database connection lost',
  tag: 'DATABASE',
  error: e,
  stackTrace: st,
);
```

## Adding Metadata

```dart
LoggerService.info(
  'Seller registered',
  tag: 'SELLER',
  metadata: {
    'seller_id': '12345',
    'registration_time': DateTime.now().toIso8601String(),
    'category': 'Electronics',
  },
);
```

## Common Tag Patterns

### By Feature
- `AUTH` - Authentication
- `API` - API calls
- `HEALTH` - Marketplace health
- `SELLER` - Seller operations
- `FRAUD` - Fraud detection
- `PERFORMANCE` - Performance metrics

### By Severity Context
- `CRITICAL` - System-level issues
- `HIGH_RISK` - Fraud/security concerns
- `OPTIMIZATION` - Performance improvements
- `ANALYSIS` - Data analytics

## Performance Tracking

### Track Method Execution
```dart
final startTime = DateTime.now();

// ... do work ...

LoggerService.methodExit(
  'complexCalculation',
  tag: 'PERFORMANCE',
  duration: DateTime.now().difference(startTime),
  result: {'score': calculatedScore},
);
```

## Business Event Logging

### Marketplace Events
```dart
// Marketplace health update
LoggerService.logMarketplaceHealth(
  85.5,  // health score
  'EXCELLENT',  // level
  componentScores: {
    'price_stability': 88.0,
    'compliance_rate': 92.0,
  },
);

// Seller performance update
LoggerService.logSellerPerformance(
  'seller_123',
  4.8,  // performance score
  'TOP_PERFORMER',
  metrics: {
    'products_sold': 1500,
    'return_rate': 0.02,
  },
);
```

### Fraud Alerts
```dart
LoggerService.logFraudDetection(
  'seller_456',
  85.5,  // suspicion score
  'PRICE_MANIPULATION',
  details: {
    'pattern_detected': 'Sudden price drops',
    'affected_products': 25,
  },
);
```

### Demand Analysis
```dart
LoggerService.logDemandElasticity(
  'product_789',
  -1.2,  // elasticity coefficient
  'ELASTIC',
  analysis: {
    'price_sensitivity': 'HIGH',
    'revenue_recommendation': 'DECREASE_PRICE',
  },
);
```

### Trend Forecasting
```dart
LoggerService.logSeasonalTrend(
  'product_999',
  'INCREASING',
  30,  // forecast horizon days
  forecast: {
    'predicted_growth': '15%',
    'confidence_level': '85%',
  },
);
```

## API Logging

### Log API Requests
```dart
LoggerService.logApiRequest(
  '/api/sellers/list',
  'GET',
  parameters: {'page': 1, 'limit': 20},
  tag: 'SELLER_API',
);
```

### Log API Responses
```dart
LoggerService.logApiResponse(
  '/api/sellers/list',
  200,
  Duration(milliseconds: 145),
  response: {'count': 250},
  tag: 'SELLER_API',
);
```

### Log API Errors
```dart
try {
  final response = await http.get(url);
} catch (e, st) {
  LoggerService.logApiError(
    '/api/sellers/list',
    e,
    stackTrace: st,
    tag: 'SELLER_API',
  );
}
```

## Best Practices

### 1. Always Include Relevant Context
```dart
// Good
LoggerService.error(
  'Seller verification failed',
  tag: 'VERIFICATION',
  error: e,
  metadata: {'seller_id': sellerId},
);

// Avoid
LoggerService.error('Error', error: e);
```

### 2. Use Consistent Tags
Define tags at the top of your file or in a constants file:
```dart
const String TAG_AUTH = 'AUTH';
const String TAG_SELLER = 'SELLER';
const String TAG_API = 'API';

LoggerService.info('Login successful', tag: TAG_AUTH);
```

### 3. Include Timestamps
```dart
metadata: {
  'timestamp': DateTime.now().toIso8601String(),
  'user_id': userId,
}
```

### 4. Use Appropriate Levels
- `debug()` - Development only
- `info()` - Important business events
- `warning()` - Unexpected but recoverable
- `error()` - Failures that need fixing
- `fatal()` - System-level critical issues

### 5. Include Stack Traces for Errors
```dart
catch (e, stackTrace) {
  LoggerService.error(
    'Calculation failed',
    tag: 'CALC',
    error: e,
    stackTrace: stackTrace,  // Include full stack trace
  );
}
```

## Common Scenarios

### API Retry with Logging
```dart
for (int attempt = 1; attempt <= maxRetries; attempt++) {
  try {
    LoggerService.info(
      'API attempt $attempt of $maxRetries',
      tag: 'API_RETRY',
      metadata: {'endpoint': endpoint},
    );
    
    final response = await apiCall();
    
    LoggerService.info(
      'API successful on attempt $attempt',
      tag: 'API_RETRY',
    );
    return response;
  } catch (e) {
    if (attempt == maxRetries) {
      LoggerService.error(
        'API failed after $maxRetries attempts',
        tag: 'API_RETRY',
        error: e,
      );
      rethrow;
    }
    await Future.delayed(Duration(seconds: backoffSeconds));
  }
}
```

### Calculation Pipeline with Logging
```dart
try {
  LoggerService.methodEntry('calculateHealthScore', tag: 'HEALTH');
  
  final priceStability = await calculatePriceStability();
  LoggerService.debug('Price stability: $priceStability', tag: 'HEALTH');
  
  final compliance = await calculateCompliance();
  LoggerService.debug('Compliance: $compliance', tag: 'HEALTH');
  
  final finalScore = (priceStability + compliance) / 2;
  
  LoggerService.methodExit(
    'calculateHealthScore',
    tag: 'HEALTH',
    result: {'score': finalScore},
  );
  
  return finalScore;
} catch (e, st) {
  LoggerService.error(
    'Health score calculation failed',
    tag: 'HEALTH',
    error: e,
    stackTrace: st,
  );
  rethrow;
}
```

## Troubleshooting

### Logs Not Showing
1. Verify LoggerService is imported
2. Check that tag is correct (case-sensitive)
3. Ensure log level is appropriate
4. Run in debug mode for full output

### Too Much Log Output
Use filtering:
```dart
// Filter by tag in IDE search
// Search for "[PERFORMANCE]" to see only performance logs

// Or use appropriate log levels:
// - Use debug() for verbose output
// - Use info() for important events only
```

### Memory Issues
- Avoid logging very large objects
- Use metadata sparingly for large data
- Consider sampling logs in production

## Performance Impact

LoggerService is optimized for minimal overhead:
- Lazy evaluation of messages
- Efficient formatting
- Minimal allocations per log call
- Safe to use in hot paths with appropriate levels

## Next Steps

For production deployment:
1. Enable remote logging integration
2. Set up log aggregation service
3. Create log level policies
4. Implement log retention strategy
5. Set up monitoring for ERROR and FATAL logs

See LOGGING_FRAMEWORK_IMPLEMENTATION.md for advanced configuration.
