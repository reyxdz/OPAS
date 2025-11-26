import 'package:flutter/material.dart';

/// Reusable widget for displaying read/unread state indicator
/// 
/// CLEAN ARCHITECTURE PRINCIPLE: Single Responsibility
/// This widget is solely responsible for rendering the read/unread indicator
/// It doesn't know about the notification data, just the read state
class NotificationReadStateIndicator extends StatelessWidget {
  final bool isRead;
  final EdgeInsets padding;
  final Color? color;

  const NotificationReadStateIndicator({
    super.key,
    required this.isRead,
    this.padding = const EdgeInsets.all(0),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isRead) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 12,
      height: 12,
      margin: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Reusable widget for notification card background based on read state
/// 
/// CLEAN ARCHITECTURE PRINCIPLE: Composition
/// Wraps a child widget with appropriate read/unread styling
class NotificationReadStateBackground extends StatelessWidget {
  final bool isRead;
  final Widget child;
  final Color unreadColor;
  final Color readColor;

  const NotificationReadStateBackground({
    super.key,
    required this.isRead,
    required this.child,
    this.unreadColor = const Color(0x1F2196F3), // Light blue
    this.readColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isRead ? readColor : unreadColor,
      child: child,
    );
  }
}

/// Reusable widget for notification text styling based on read state
/// 
/// CLEAN ARCHITECTURE PRINCIPLE: Reusability
/// Centralizes text styling logic to ensure consistency across the app
class NotificationText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final bool isRead;
  final int maxLines;
  final TextOverflow overflow;

  const NotificationText(
    this.text, {
    super.key,
    this.baseStyle,
    required this.isRead,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        color: isRead ? Colors.grey[700] : Colors.black87,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
