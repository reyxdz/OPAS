import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_history_model.dart';

/// Notification History Service
/// Manages persistent storage and retrieval of notification history
class NotificationHistoryService {
  static const String _baseStorageKey = 'notification_history';
  static const int _maxHistoryItems = 100;

  /// Get user-specific storage key
  /// This ensures each user has their own notification history
  /// PRIMARY: Uses user_id (database primary key) as it never changes
  /// FALLBACK: Uses phone_number if user_id is missing (for backward compatibility)
  /// NEVER uses 'anonymous' as it would cause multiple accounts to share notifications
  static Future<String> _getStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to get user_id first (most reliable identifier)
    String? userId = prefs.getString('user_id');
    
    // If user_id is missing, use phone_number as fallback
    if (userId == null || userId.isEmpty) {
      final phoneNumber = prefs.getString('phone_number') ?? '';
      if (phoneNumber.isNotEmpty) {
        userId = phoneNumber;
        debugPrint('⚠️ NotificationService._getStorageKey() -> user_id missing, using phone_number=$userId');
      } else {
        // Only log this if truly no identifiers are available
        debugPrint('❌ NotificationService._getStorageKey() -> No user_id or phone_number found!');
        // Don't use 'anonymous' - it would cause multiple accounts to share notifications
        // Instead, generate a unique key based on timestamp to prevent data leakage
        userId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    
    final key = '${_baseStorageKey}_$userId';
    debugPrint('🔑 NotificationService._getStorageKey() -> key=$key (identifier=$userId)');
    return key;
  }

  /// Get the notification storage key without loading all notifications
  /// Used during logout to backup notifications before clearing preferences
  static Future<String> getStorageKeyForLogout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use same logic as _getStorageKey() for consistency
    String? identifier = prefs.getString('user_id');
    
    if (identifier == null || identifier.isEmpty) {
      identifier = prefs.getString('phone_number') ?? '';
    }
    
    if (identifier.isEmpty) {
      identifier = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return '${_baseStorageKey}_$identifier';
  }

  /// Save a new notification to history
  /// IMPORTANT: If notification already exists, preserve its read state!
  static Future<void> saveNotification(NotificationHistory notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = await _getStorageKey();
      final history = await getAllNotifications();
      
      // Check if this notification already exists (by type + rejection reason or approval notes)
      final existingIndex = history.indexWhere((n) {
        final sameType = n.type == notification.type;
        final sameReason = n.rejectionReason == notification.rejectionReason;
        final sameNotes = n.approvalNotes == notification.approvalNotes;
        return sameType && sameReason && sameNotes;
      });
      
      if (existingIndex != -1) {
        debugPrint('⚠️ Notification already exists at index $existingIndex, preserving isRead=${history[existingIndex].isRead}');
        // Preserve the existing notification's read state
        final existingNotif = history[existingIndex];
        final updatedNotif = notification.copyWith(
          id: existingNotif.id,
          isRead: existingNotif.isRead,
        );
        history[existingIndex] = updatedNotif;
      } else {
        // New notification, insert at top
        history.insert(0, notification);
        debugPrint('✅ New notification added to history: ${notification.type}');
      }
      
      final limited = history.length > _maxHistoryItems 
          ? history.take(_maxHistoryItems).toList() 
          : history;
      final jsonList = limited.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(storageKey, jsonList);
      debugPrint('💾 Saved notification to history: ${notification.type} (Total: ${limited.length})');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  /// Get all notifications sorted by date (newest first)
  static Future<List<NotificationHistory>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = await _getStorageKey();
      final jsonList = prefs.getStringList(storageKey) ?? [];
      debugPrint('📖 getAllNotifications: Retrieved ${jsonList.length} notifications from key=$storageKey');
      
      if (jsonList.isEmpty) {
        debugPrint('⚠️ No notifications found for this user');
      }

      final notifications = jsonList
          .map((json) => NotificationHistory.fromJson(
              jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      // Log the read state of each notification
      for (var notif in notifications) {
        debugPrint('  - ID: ${notif.id}, Type: ${notif.type}, isRead: ${notif.isRead}');
      }
      
      return notifications;
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
      debugPrint('✏️ markAsRead: notificationId=$notificationId, index=$index');

      if (index != -1) {
        all[index] = all[index].copyWithRead();
        
        final prefs = await SharedPreferences.getInstance();
        final storageKey = await _getStorageKey();
        final jsonList = all.map((n) => jsonEncode(n.toJson())).toList();
        await prefs.setStringList(storageKey, jsonList);
        debugPrint('✅ markAsRead: Successfully saved ${jsonList.length} notifications to storage');
      } else {
        debugPrint('⚠️ markAsRead: Notification not found');
      }
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final all = await getAllNotifications();
      final updated = all.map((n) => n.copyWithRead()).toList();

      final prefs = await SharedPreferences.getInstance();
      final storageKey = await _getStorageKey();
      final jsonList = updated.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(storageKey, jsonList);
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
      final storageKey = await _getStorageKey();
      final jsonList = all.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(storageKey, jsonList);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = await _getStorageKey();
      await prefs.remove(storageKey);
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
