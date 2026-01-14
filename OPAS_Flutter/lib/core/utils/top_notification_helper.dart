import 'package:flutter/material.dart';

// Custom top notification widget
class TopNotification extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;

  const TopNotification({super.key, 
    required this.message,
    required this.backgroundColor,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper class for showing top notifications throughout the app
class TopNotificationHelper {
  /// Show a success notification (green)
  static void showSuccess(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showNotification(context, message, Colors.green[600]!, duration);
  }

  /// Show an error notification (red)
  static void showError(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4)}) {
    _showNotification(context, message, Colors.red[600]!, duration);
  }

  /// Show an info notification (blue)
  static void showInfo(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showNotification(context, message, Colors.blue[600]!, duration);
  }

  /// Show a warning notification (orange)
  static void showWarning(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showNotification(context, message, Colors.orange[600]!, duration);
  }

  /// Show a custom notification with specified color
  static void showCustom(BuildContext context, String message, Color color,
      {Duration duration = const Duration(seconds: 3)}) {
    _showNotification(context, message, color, duration);
  }

  /// Internal method to show notification
  static void _showNotification(
      BuildContext context, String message, Color color, Duration duration) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss notification',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: TopNotification(
            message: message,
            backgroundColor: color,
            duration: duration,
          ),
        );
      },
    );
  }
}
