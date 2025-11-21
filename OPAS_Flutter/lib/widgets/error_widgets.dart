import 'package:flutter/material.dart';
import '../../core/services/error_handler.dart';

/// Error SnackBar Widget
/// Displays error messages in a dismissable snackbar
class ErrorSnackBar {
  static void show(
    BuildContext context,
    String message, {
    String? subtitle,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onDismiss,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.yellow.shade200,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show error from APIException
  static void showFromException(
    BuildContext context,
    APIException exception, {
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onRetry,
  }) {
    final message = ErrorHandler.getUserMessage(exception);
    show(
      context,
      message,
      subtitle: exception.details,
      duration: duration,
      onRetry: onRetry,
    );
  }
}

/// Error Dialog Widget
/// Displays detailed error information in a dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showRetryButton;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.onDismiss,
    this.showRetryButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            if (details != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  details!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('CLOSE'),
        ),
        if (showRetryButton && onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('RETRY'),
          ),
      ],
    );
  }

  /// Show error dialog
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showRetryButton = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        details: details,
        onRetry: onRetry,
        onDismiss: onDismiss,
        showRetryButton: showRetryButton,
      ),
    );
  }

  /// Show from APIException
  static void showFromException(
    BuildContext context,
    APIException exception, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final title = exception is UnauthorizedException
        ? 'Authentication Failed'
        : exception is ForbiddenException
            ? 'Access Denied'
            : exception is NotFoundException
                ? 'Not Found'
                : exception is BadRequestException
                    ? 'Invalid Request'
                    : exception is ServerException
                        ? 'Server Error'
                        : 'Error';

    show(
      context,
      title: title,
      message: ErrorHandler.getUserMessage(exception),
      details: exception.details,
      onRetry: onRetry,
      onDismiss: onDismiss,
      showRetryButton: ErrorHandler.isRetryable(exception),
    );
  }
}

/// Validation Error Display
class ValidationErrorText extends StatelessWidget {
  final String? error;
  final double topPadding;

  const ValidationErrorText(
    this.error, {
    Key? key,
    this.topPadding = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: topPadding, left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network Status Widget
/// Shows network connectivity status
class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final Color offlineColor;

  const NetworkStatusWidget({
    Key? key,
    required this.child,
    this.offlineColor = Colors.orange,
  }) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  final bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: widget.offlineColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Offline - Using cached data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Retry Button Widget
/// Shows retry button with exponential backoff info
class RetryButton extends StatefulWidget {
  final Future<void> Function() onRetry;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final String label;
  final int maxRetries;

  const RetryButton({
    Key? key,
    required this.onRetry,
    this.onSuccess,
    this.onError,
    this.label = 'Retry',
    this.maxRetries = 3,
  }) : super(key: key);

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  bool _isLoading = false;
  int _retryCount = 0;

  void _handleRetry() async {
    setState(() => _isLoading = true);

    try {
      await widget.onRetry();
      widget.onSuccess?.call();
    } catch (e) {
      setState(() => _retryCount++);
      widget.onError?.call();

      if (_retryCount >= widget.maxRetries) {
        if (mounted) {
          ErrorSnackBar.show(
            context,
            'Max retries reached',
            subtitle: 'Please try again later or contact support',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRetry,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _retryCount > 0
                  ? '${widget.label} ($_retryCount/${widget.maxRetries})'
                  : widget.label,
            ),
    );
  }
}

/// Field-level error display with border highlight
class ErrorTextField extends StatelessWidget {
  final String? errorText;
  final InputDecoration baseDecoration;

  const ErrorTextField({
    Key? key,
    this.errorText,
    required this.baseDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return InputDecorator(
      decoration: baseDecoration.copyWith(
        errorText: errorText,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.shade400,
            width: hasError ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.shade400,
            width: hasError ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.blue,
            width: 2,
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
