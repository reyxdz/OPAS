import 'dart:convert';

/// Custom Exception Classes for Error Handling
class APIException implements Exception {
  final int statusCode;
  final String message;
  final String? details;
  final dynamic originalError;

  APIException({
    required this.statusCode,
    required this.message,
    this.details,
    this.originalError,
  });

  @override
  String toString() => 'APIException($statusCode): $message${details != null ? ' - $details' : ''}';
}

class BadRequestException extends APIException {
  BadRequestException({
    required String message,
    String? details,
  }) : super(
    statusCode: 400,
    message: message,
    details: details,
  );
}

class UnauthorizedException extends APIException {
  UnauthorizedException({
    required String message,
    String? details,
  }) : super(
    statusCode: 401,
    message: message,
    details: details,
  );
}

class ForbiddenException extends APIException {
  ForbiddenException({
    required String message,
    String? details,
  }) : super(
    statusCode: 403,
    message: message,
    details: details,
  );
}

class NotFoundException extends APIException {
  NotFoundException({
    required String message,
    String? details,
  }) : super(
    statusCode: 404,
    message: message,
    details: details,
  );
}

class ServerException extends APIException {
  ServerException({
    required String message,
    String? details,
  }) : super(
    statusCode: 500,
    message: message,
    details: details,
  );
}

class NetworkException extends APIException {
  NetworkException({
    required String message,
    String? details,
  }) : super(
    statusCode: 0,
    message: message,
    details: details,
  );
}

class TimeoutException extends APIException {
  TimeoutException({
    required String message,
    String? details,
  }) : super(
    statusCode: 0,
    message: message,
    details: details,
  );
}

/// Error Handler Service
/// Handles HTTP error responses and provides user-friendly error messages
class ErrorHandler {
  /// Parse HTTP error response and throw appropriate exception
  static APIException handleError(
    int statusCode,
    String responseBody, {
    required String endpoint,
    StackTrace? stackTrace,
  }) {
    try {
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final errorMessage = _extractErrorMessage(jsonResponse);
      final errorDetails = _extractErrorDetails(jsonResponse);

      switch (statusCode) {
        case 400:
          return BadRequestException(
            message: errorMessage,
            details: errorDetails,
          );
        case 401:
          return UnauthorizedException(
            message: errorMessage,
            details: errorDetails,
          );
        case 403:
          return ForbiddenException(
            message: errorMessage,
            details: errorDetails,
          );
        case 404:
          return NotFoundException(
            message: errorMessage,
            details: errorDetails,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return ServerException(
            message: errorMessage,
            details: errorDetails,
          );
        default:
          return APIException(
            statusCode: statusCode,
            message: errorMessage,
            details: errorDetails,
          );
      }
    } catch (e) {
      // Fallback if response is not JSON
      return _handleRawError(statusCode);
    }
  }

  /// Handle network errors (no connection, timeout, etc.)
  static APIException handleNetworkError(dynamic error) {
    if (error is TimeoutException || error.toString().contains('TimeoutException')) {
      return TimeoutException(
        message: 'Request timed out',
        details: 'The server took too long to respond. Please check your connection and try again.',
      );
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('Connection refused')) {
      return NetworkException(
        message: 'Network error',
        details: 'Unable to connect to the server. Please check your internet connection.',
      );
    } else {
      return NetworkException(
        message: 'Connection error',
        details: error.toString(),
      );
    }
  }

  /// Extract error message from JSON response
  static String _extractErrorMessage(Map<String, dynamic> json) {
    // Try common error field names
    if (json.containsKey('message')) return json['message'] as String;
    if (json.containsKey('error')) return json['error'] as String;
    if (json.containsKey('detail')) return json['detail'] as String;
    
    // Try to get first field error
    if (json.containsKey('errors') && json['errors'] is Map) {
      final errors = json['errors'] as Map<String, dynamic>;
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value[0].toString();
        } else if (value is String) {
          return value;
        }
      }
    }

    return 'An error occurred. Please try again.';
  }

  /// Extract additional error details
  static String? _extractErrorDetails(Map<String, dynamic> json) {
    if (json.containsKey('non_field_errors') && json['non_field_errors'] is List) {
      final errors = json['non_field_errors'] as List;
      if (errors.isNotEmpty) {
        return errors.join(', ');
      }
    }
    return null;
  }

  /// Fallback error handling
  static APIException _handleRawError(int statusCode) {
    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: 'Invalid request data',
          details: 'Please check your input and try again.',
        );
      case 401:
        return UnauthorizedException(
          message: 'Authentication failed',
          details: 'Your session has expired. Please log in again.',
        );
      case 403:
        return ForbiddenException(
          message: 'Access denied',
          details: 'You do not have permission to access this resource.',
        );
      case 404:
        return NotFoundException(
          message: 'Not found',
          details: 'The requested resource could not be found.',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: 'Server error',
          details: 'The server encountered an error. Please try again later.',
        );
      default:
        return APIException(
          statusCode: statusCode,
          message: 'Error $statusCode',
          details: 'An unexpected error occurred.',
        );
    }
  }

  /// Get user-friendly error message
  static String getUserMessage(APIException exception) {
    if (exception is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    } else if (exception is ForbiddenException) {
      return 'You do not have permission to perform this action.';
    } else if (exception is NotFoundException) {
      return 'The item you are looking for was not found.';
    } else if (exception is BadRequestException) {
      return exception.details ?? exception.message;
    } else if (exception is ServerException) {
      return 'Server error. Please try again later.';
    } else if (exception is TimeoutException) {
      return 'Request took too long. Please check your connection and try again.';
    } else if (exception is NetworkException) {
      return 'Network error. Please check your internet connection.';
    }
    return exception.message;
  }

  /// Determine if error requires logout
  static bool shouldLogout(APIException exception) {
    return exception is UnauthorizedException;
  }

  /// Determine if error is retryable
  static bool isRetryable(APIException exception) {
    return exception is TimeoutException ||
        exception is NetworkException ||
        exception is ServerException;
  }

  /// Determine if error is validation error
  static bool isValidationError(APIException exception) {
    return exception is BadRequestException;
  }
}

/// Validation Error Model
class ValidationError {
  final String field;
  final String message;

  ValidationError({
    required this.field,
    required this.message,
  });

  factory ValidationError.fromJson(String field, dynamic value) {
    String message = 'Invalid value';
    if (value is List && value.isNotEmpty) {
      message = value[0].toString();
    } else if (value is String) {
      message = value;
    }
    return ValidationError(field: field, message: message);
  }
}

/// Extract field-level validation errors
List<ValidationError> extractValidationErrors(String responseBody) {
  try {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final errors = <ValidationError>[];

    if (json.containsKey('errors') && json['errors'] is Map) {
      final fieldErrors = json['errors'] as Map<String, dynamic>;
      fieldErrors.forEach((field, value) {
        errors.add(ValidationError.fromJson(field, value));
      });
    }

    return errors;
  } catch (e) {
    return [];
  }
}
