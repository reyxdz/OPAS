import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_history_model.dart';

/// Notification History Service
/// Manages persistent storage and retrieval of notification history
class NotificationHistoryService {
  static const String _storageKey = 'notification_history';
  static const int _maxHistoryItems = 100;

  /// Save a new notification to history
  static Future<void> saveNotification(NotificationHistory notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getAllNotifications();
      history.insert(0, notification);
      final limited = history.length > _maxHistoryItems 
          ? history.take(_maxHistoryItems).toList() 
          : history;
      final jsonList = limited.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
      debugPrint('💾 Saved notification to history: ${notification.type} (Total: ${limited.length})');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  /// Get all notifications sorted by date (newest first)
  static Future<List<NotificationHistory>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      debugPrint('📖 Retrieved ${jsonList.length} notification JSONs from storage');

      return jsonList
          .map((json) => NotificationHistory.fromJson(
              jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get notifications by type
  static Future<List<NotificationHistory>> getNotificationsByType(
      String type) async {
    final all = await getAllNotifications();
    return all.where((n) => n.type == type).toList();
  }

  /// Get unread notifications count
  static Future<int> getUnreadCount() async {
    final all = await getAllNotifications();
    return all.where((n) => !n.isRead).length;
  }

  /// Get unread notifications
  static Future<List<NotificationHistory>> getUnreadNotifications() async {
    final all = await getAllNotifications();
    return all.where((n) => !n.isRead).toList();
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final all = await getAllNotifications();
      final index = all.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        all[index] = all[index].copyWithRead();
        
        final prefs = await SharedPreferences.getInstance();
        final jsonList = all.map((n) => jsonEncode(n.toJson())).toList();
        await prefs.setStringList(_storageKey, jsonList);
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final all = await getAllNotifications();
      final updated = all.map((n) => n.copyWithRead()).toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonList = updated.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final all = await getAllNotifications();
      all.removeWhere((n) => n.id == notificationId);

      final prefs = await SharedPreferences.getInstance();
      final jsonList = all.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Get rejection notifications
  static Future<List<NotificationHistory>> getRejectionNotifications() async {
    return getNotificationsByType('REGISTRATION_REJECTED');
  }

  /// Get approval notifications
  static Future<List<NotificationHistory>> getApprovalNotifications() async {
    return getNotificationsByType('REGISTRATION_APPROVED');
  }

  /// Get the latest rejection notification (if any)
  static Future<NotificationHistory?> getLatestRejection() async {
    final rejections = await getRejectionNotifications();
    return rejections.isNotEmpty ? rejections.first : null;
  }
}
