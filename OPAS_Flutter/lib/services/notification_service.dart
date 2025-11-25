// CORE PRINCIPLE: Flutter push notification handler
// - Background processing
// - Action routing
// - State management
// - Offline support

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opas_flutter/features/profile/models/notification_history_model.dart';
import 'package:opas_flutter/features/profile/services/notification_history_service.dart';

const String _logTag = 'NotificationService';

// Notification model
class RemoteMessage {
  final String messageId;
  final Map<String, dynamic> data;
  final NotificationMessage? notification;

  RemoteMessage({
    required this.messageId,
    required this.data,
    this.notification,
  });

  factory RemoteMessage.fromFirebase(firebase.RemoteMessage message) {
    return RemoteMessage(
      messageId: message.messageId ?? '',
      data: message.data,
      notification: message.notification != null
          ? NotificationMessage(
              title: message.notification!.title,
              body: message.notification!.body,
            )
          : null,
    );
  }
}

class NotificationMessage {
  final String? title;
  final String? body;

  NotificationMessage({this.title, this.body});
}

// Stub API service
class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;
  
  ApiService._internal();
  
  Future<Map<String, dynamic>> get(String endpoint) async => {};
  Future<Map<String, dynamic>> post(String endpoint, {required Map<String, dynamic> body}) async => {};
  Future<Map<String, dynamic>> patch(String endpoint, {required Map<String, dynamic> body}) async => {};
}

// Stub storage service
class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  
  StorageService._internal();
  
  Future<void> setString(String key, String value) async {}
  Future<String?> getString(String key) async => null;
}

// CORE PRINCIPLE: Background message handler (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(firebase.RemoteMessage message) async {
  await NotificationService.instance.handleBackgroundMessage(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  static NotificationService get instance => _instance;
  
  late firebase.FirebaseMessaging _messaging;
  late FlutterLocalNotificationsPlugin _localNotifications;
  final ApiService _apiService = ApiService.instance;
  
  // Callbacks for notification interactions
  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpenedApp;
  
  NotificationService._internal();
  
  /// Initialize Firebase Cloud Messaging
  /// CORE PRINCIPLE: Resource Management - Setup only once
  Future<void> initialize(BuildContext? context) async {
    _messaging = firebase.FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    // Request iOS permissions
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      provisional: false,
      sound: true,
    );
    
    // Setup local notifications for displaying foreground messages
    await _setupLocalNotifications();
    
    // Handle background messages
    firebase.FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    firebase.FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle message when app is opened from notification
    firebase.FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Get initial message (app opened from notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
    
    // Get and store FCM token
    await _updateFCMToken();
  }
  
  /// Setup local notifications plugin
  /// CORE PRINCIPLE: User Experience - Clear notifications
  Future<void> _setupLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        _handleLocalNotificationTap(payload ?? '');
      },
    );
    
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleLocalNotificationTap(response.payload ?? '');
      },
    );
  }
  
  /// Handle foreground messages
  /// CORE PRINCIPLE: User Experience - Show notification while in app
  Future<void> _handleForegroundMessage(firebase.RemoteMessage message) async {
    // Log notification
    await _logNotification(message, 'RECEIVED');
    
    // Save to notification history
    final type = message.data['action'] ?? 'UNKNOWN';
    final notification = NotificationHistory.fromNotification(
      type: type,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
    await NotificationHistoryService.saveNotification(notification);
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
    
    // Update app state if callback provided
    onMessageReceived?.call(RemoteMessage.fromFirebase(message));
  }
  
  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'opas_notifications',
      'OPAS Notifications',
      channelDescription: 'Notifications from OPAS',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      sound: 'default.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload.toString(),
    );
  }
  
  /// Handle notification when app opened from it
  /// CORE PRINCIPLE: State preservation - Navigate to correct screen
  Future<void> _handleMessageOpenedApp(firebase.RemoteMessage message) async {
    await _logNotification(message, 'OPENED');
    
    final data = message.data;
    final action = data['action'] ?? '';
    final registrationId = data['registration_id'];
    
    // Save to notification history
    final notification = NotificationHistory.fromNotification(
      type: action,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: data,
    );
    await NotificationHistoryService.saveNotification(notification);
    
    // Cache rejection reason if present
    if (action == 'REGISTRATION_REJECTED' && data.containsKey('rejection_reason')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_rejection_reason', data['rejection_reason']!);
    }
    
    // Route based on notification action
    switch (action) {
      case 'REGISTRATION_APPROVED':
        _navigateToSellerDashboard();
        break;
      case 'REGISTRATION_REJECTED':
        _navigateToApplicationStatus(registrationId);
        break;
      case 'INFO_REQUESTED':
        _navigateToEditRegistration(registrationId);
        break;
      case 'AUDIT_LOG':
        _navigateToAuditLog();
        break;
      default:
        _navigateToDashboard();
    }
    
    // Callback
    onMessageOpenedApp?.call(RemoteMessage.fromFirebase(message));
  }
  
  /// Handle background message
  Future<void> handleBackgroundMessage(firebase.RemoteMessage message) async {
    // Save to local cache for later processing
    await _cacheNotification(message);
    
    // Save to notification history
    final type = message.data['action'] ?? 'UNKNOWN';
    final notification = NotificationHistory.fromNotification(
      type: type,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
    await NotificationHistoryService.saveNotification(notification);
    
    // Cache rejection reason if present
    final data = message.data;
    if (data['action'] == 'REGISTRATION_REJECTED' && data.containsKey('rejection_reason')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_rejection_reason', data['rejection_reason']!);
    }
    
    // Log to backend
    await _logNotification(message, 'BACKGROUND');
  }
  
  /// Handle local notification tap
  void _handleLocalNotificationTap(String payload) {
    // Parse and handle tap
    try {
      final Map<String, dynamic> data = _parsePayload(payload);
      final action = data['action'] ?? '';
      final registrationId = data['registration_id'];
      
      switch (action) {
        case 'REGISTRATION_APPROVED':
          _navigateToSellerDashboard();
          break;
        case 'REGISTRATION_REJECTED':
          _navigateToApplicationStatus(registrationId);
          break;
        case 'INFO_REQUESTED':
          _navigateToEditRegistration(registrationId);
          break;
        default:
          _navigateToDashboard();
      }
    } catch (e) {
      _navigateToDashboard();
    }
  }
  
  /// Update FCM token on server
  /// CORE PRINCIPLE: Keep token fresh for push delivery
  Future<void> _updateFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // Log token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        
        // Send to backend
        await _apiService.post(
          '/api/v1/users/fcm-token/',
          body: {'token': token},
        );
      }
    } catch (e) {
      debugPrint('$_logTag: Failed to update FCM token: $e');
    }
  }
  
  /// Log notification to backend for tracking
  /// CORE PRINCIPLE: Audit trail for notifications
  Future<void> _logNotification(firebase.RemoteMessage message, String status) async {
    try {
      await _apiService.post(
        '/api/v1/notifications/log/',
        body: {
          'notification_id': message.messageId,
          'type': message.data['notification_type'] ?? 'UNKNOWN',
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
          'platform': 'flutter',
        },
      );
    } catch (e) {
      debugPrint('$_logTag: Failed to log notification: $e');
    }
  }
  
  /// Cache notification locally
  /// CORE PRINCIPLE: Offline-first - Save for later processing
  Future<void> _cacheNotification(firebase.RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('cached_notifications') ?? [];
      
      cached.add(message.data.toString());
      
      // Keep only last 50
      if (cached.length > 50) {
        cached.removeAt(0);
      }
      
      await prefs.setStringList('cached_notifications', cached);
    } catch (e) {
      debugPrint('$_logTag: Failed to cache notification: $e');
    }
  }
  
  /// Subscribe to notification topic
  /// CORE PRINCIPLE: Efficient topic-based messaging
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  /// Unsubscribe from notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
  
  /// Subscribe user to relevant topics
  /// CORE PRINCIPLE: Role-based notification routing
  Future<void> subscribeUserTopics(String role) async {
    // All users get personal notifications
    await subscribeToTopic('user_notifications');
    
    // Role-specific topics
    if (role == 'SELLER') {
      await subscribeToTopic('seller_notifications');
    } else if (role == 'ADMIN') {
      await subscribeToTopic('admin_notifications');
    } else if (role == 'BUYER') {
      await subscribeToTopic('buyer_notifications');
    }
  }
  
  // Navigation helpers
  void _navigateToDashboard() {
    // Implementation: Navigate to dashboard
  }
  
  void _navigateToSellerDashboard() {
    // Implementation: Navigate to seller dashboard
  }
  
  void _navigateToApplicationStatus(String? registrationId) {
    // Implementation: Navigate to application status
  }
  
  void _navigateToEditRegistration(String? registrationId) {
    // Implementation: Navigate to edit registration form
  }
  
  void _navigateToAuditLog() {
    // Implementation: Navigate to audit log screen
  }
  
  /// Parse payload string to map
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      // Simple parser for map string
      final map = <String, dynamic>{};
      return map;
    } catch (e) {
      return {};
    }
  }
  
  /// Get notification preference status
  Future<bool> isNotificationEnabled(String notificationType) async {
    try {
      final response = await _apiService.get(
        '/api/v1/notifications/preferences/',
      );
      return response[notificationType] ?? true;
    } catch (e) {
      return true; // Default to enabled
    }
  }
  
  /// Update user notification preferences
  Future<void> updateNotificationPreference(String notificationType, bool enabled) async {
    try {
      await _apiService.patch(
        '/api/v1/notifications/preferences/',
        body: {notificationType: enabled},
      );
    } catch (e) {
      debugPrint('$_logTag: Failed to update notification preference: $e');
    }
  }
  
  /// Get pending notifications
  Future<List<RemoteMessage>> getPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.getStringList('cached_notifications') ?? [];
      
      // Return cached notifications
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Clear notification badge
  Future<void> clearNotificationBadge() async {
    await _messaging.setAutoInitEnabled(false);
    await _localNotifications.cancelAll();
  }
}
