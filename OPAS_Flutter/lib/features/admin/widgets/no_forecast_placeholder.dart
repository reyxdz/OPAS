import 'package:flutter/material.dart';

/// Placeholder widget displayed when insufficient data is available for forecasting
/// 
/// Shows:
/// - Empty state icon
/// - Message about why forecast is unavailable
/// - Suggestion for next steps
/// - Call-to-action button (optional)
class NoForecastPlaceholder extends StatelessWidget {
  final String? productName;
  final String? reason; // Why no forecast: 'INSUFFICIENT_DATA', 'NOT_SELLING', 'ERROR', etc.
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const NoForecastPlaceholder({
    Key? key,
    this.productName,
    this.reason,
    this.onRetry,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final textColor = isDarkMode ? Colors.white70 : Colors.grey[700];
    final titleColor = isDarkMode ? Colors.white : Colors.grey[800];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Icon(
            _getIconForReason(),
            size: 64,
            color: _getColorForReason(),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            _getTitleForReason(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            _getMessageForReason(),
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Suggestion
          Text(
            _getSuggestionForReason(),
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Retry Button
          if (showRetryButton && onRetry != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getColorForReason(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForReason() {
    switch (reason) {
      case 'INSUFFICIENT_DATA':
        return Icons.data_usage;
      case 'NOT_SELLING':
        return Icons.shopping_cart_outlined;
      case 'ERROR':
        return Icons.error_outline;
      case 'LOADING':
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForReason() {
    switch (reason) {
      case 'INSUFFICIENT_DATA':
        return const Color(0xFFFFC107); // Amber
      case 'NOT_SELLING':
        return const Color(0xFF9C27B0); // Purple
      case 'ERROR':
        return const Color(0xFFF44336); // Red
      case 'LOADING':
        return const Color(0xFF2196F3); // Blue
      default:
        return Colors.grey;
    }
  }

  String _getTitleForReason() {
    switch (reason) {
      case 'INSUFFICIENT_DATA':
        return 'Not Enough Historical Data';
      case 'NOT_SELLING':
        return 'Product Not Yet Available';
      case 'ERROR':
        return 'Unable to Generate Forecast';
      case 'LOADING':
        return 'Generating Forecast...';
      default:
        return 'No Forecast Available';
    }
  }

  String _getMessageForReason() {
    final product = productName ?? 'this product';

    switch (reason) {
      case 'INSUFFICIENT_DATA':
        return 'We need at least 5 weeks of sales data to generate accurate forecasts for $product.';
      case 'NOT_SELLING':
        return '$product is not currently being sold. Forecasts will be available once sales data is available.';
      case 'ERROR':
        return 'An error occurred while generating the forecast. Please try again later.';
      case 'LOADING':
        return 'Please wait while we generate the forecast...';
      default:
        return 'Forecast data is currently unavailable.';
    }
  }

  String _getSuggestionForReason() {
    switch (reason) {
      case 'INSUFFICIENT_DATA':
        return 'Forecasts will be available once more sales data accumulates.\nCheck back in a few weeks.';
      case 'NOT_SELLING':
        return 'Start selling $productName to enable demand and price forecasting.';
      case 'ERROR':
        return 'If the problem persists, contact your administrator.';
      case 'LOADING':
        return 'This typically takes a few moments...';
      default:
        return 'Try refreshing the page or contact support if the issue persists.';
    }
  }
}
