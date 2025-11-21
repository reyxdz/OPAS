import 'dart:async';
import 'error_handler.dart';

/// Retry Service
/// Implements exponential backoff strategy for failed API requests
class RetryService {
  static const int _defaultMaxRetries = 3;
  static const int _defaultInitialDelayMs = 1000;
  static const double _defaultBackoffMultiplier = 2.0;

  /// Execute function with retry logic and exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() function, {
    int maxRetries = _defaultMaxRetries,
    int initialDelayMs = _defaultInitialDelayMs,
    double backoffMultiplier = _defaultBackoffMultiplier,
    bool Function(APIException)? shouldRetry,
  }) async {
    int retries = 0;
    int delayMs = initialDelayMs;

    while (true) {
      try {
        return await function();
      } on APIException catch (e) {
        // Check if this error is retryable
        if (!ErrorHandler.isRetryable(e)) {
          rethrow;
        }

        // Check custom retry condition
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Check if max retries reached
        if (retries >= maxRetries) {
          rethrow;
        }

        retries++;

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: delayMs));

        // Calculate next delay
        delayMs = (delayMs * backoffMultiplier).toInt();
      } catch (e) {
        // For non-API exceptions, convert to network error
        if (e is TimeoutException) {
          throw TimeoutException(
            message: 'Request timeout after $retries retries',
            details: 'The server did not respond in time.',
          );
        } else if (e is APIException) {
          rethrow;
        } else {
          throw NetworkException(
            message: 'Request failed after $retries retries',
            details: e.toString(),
          );
        }
      }
    }
  }

  /// Execute function with timeout and retry
  static Future<T> executeWithTimeout<T>(
    Future<T> Function() function, {
    Duration timeout = const Duration(seconds: 15),
    int maxRetries = _defaultMaxRetries,
  }) async {
    return retryWithBackoff<T>(
      () => function().timeout(timeout),
      maxRetries: maxRetries,
      shouldRetry: (e) => e is TimeoutException || e is NetworkException,
    );
  }

  /// Calculate delay for next retry
  static int calculateNextDelay(
    int attempt, {
    int initialDelayMs = _defaultInitialDelayMs,
    double backoffMultiplier = _defaultBackoffMultiplier,
  }) {
    return (initialDelayMs * (backoffMultiplier * attempt)).toInt();
  }

  /// Get retry info for display
  static String getRetryInfo(int attempt, int maxRetries) {
    return 'Attempt $attempt of $maxRetries';
  }

  /// Check if should give up and show manual retry
  static bool shouldShowManualRetry(int attempt, int maxRetries) {
    return attempt >= maxRetries;
  }
}

/// Retry State for UI
class RetryState {
  final int currentAttempt;
  final int maxAttempts;
  final Duration nextRetryIn;
  final bool isRetrying;

  RetryState({
    required this.currentAttempt,
    required this.maxAttempts,
    required this.nextRetryIn,
    required this.isRetrying,
  });

  bool get hasRetriesLeft => currentAttempt < maxAttempts;
  double get progressPercent => (currentAttempt / maxAttempts) * 100;

  @override
  String toString() =>
      'RetryState(attempt: $currentAttempt/$maxAttempts, nextRetry: ${nextRetryIn.inSeconds}s, isRetrying: $isRetrying)';
}

/// Batch Retry Manager for multiple operations
class BatchRetryManager {
  final List<String> operations = [];
  final Map<String, int> retryCount = {};
  final int maxRetries;

  BatchRetryManager({this.maxRetries = 3});

  /// Add operation to batch
  void addOperation(String id) {
    operations.add(id);
    retryCount[id] = 0;
  }

  /// Mark operation as failed and increment retry count
  bool incrementRetry(String id) {
    retryCount[id] = (retryCount[id] ?? 0) + 1;
    return retryCount[id]! <= maxRetries;
  }

  /// Mark operation as completed
  void removeOperation(String id) {
    operations.remove(id);
    retryCount.remove(id);
  }

  /// Get operations that need retry
  List<String> getFailedOperations() {
    return [
      for (final op in operations)
        if ((retryCount[op] ?? 0) < maxRetries) op
    ];
  }

  /// Get completion percentage
  double getCompletionPercent() {
    if (operations.isEmpty) return 100;
    final completed = operations.length - getFailedOperations().length;
    return (completed / operations.length) * 100;
  }

  /// Clear all
  void clear() {
    operations.clear();
    retryCount.clear();
  }
}
