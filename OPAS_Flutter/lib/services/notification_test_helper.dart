// Notification Testing Helper
// Use this to test notifications locally without sending from backend

import 'package:opas_flutter/services/notification_service.dart';

class NotificationTestHelper {
  /// Simulate receiving a push notification
  static Future<void> simulateNotification({
    required String title,
    required String body,
    required String action,
    String? registrationId,
  }) async {
    final msg = RemoteMessage(
      messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'action': action,
        if (registrationId != null) 'registration_id': registrationId,
      },
      notification: NotificationMessage(
        title: title,
        body: body,
      ),
    );
    
    // Simulate foreground message by calling callback
    NotificationService.instance.onMessageReceived?.call(msg);
  }
  
  /// Simulate approval notification
  static Future<void> simulateApproval({
    String registrationId = '12345',
  }) async {
    await simulateNotification(
      title: 'Registration Approved',
      body: 'Your seller registration has been approved!',
      action: 'REGISTRATION_APPROVED',
      registrationId: registrationId,
    );
  }
  
  /// Simulate rejection notification
  static Future<void> simulateRejection({
    String registrationId = '12345',
  }) async {
    await simulateNotification(
      title: 'Registration Rejected',
      body: 'Your registration was rejected. Please contact support.',
      action: 'REGISTRATION_REJECTED',
      registrationId: registrationId,
    );
  }
  
  /// Simulate info request notification
  static Future<void> simulateInfoRequested({
    String registrationId = '12345',
  }) async {
    await simulateNotification(
      title: 'Information Requested',
      body: 'Please provide additional information for your application.',
      action: 'INFO_REQUESTED',
      registrationId: registrationId,
    );
  }
  
  /// Get current FCM token
  static Future<String?> getFCMToken() async {
    try {
      // Read from shared preferences
      return null; // Implement based on your storage
    } catch (e) {
      return null;
    }
  }
  
  /// Print notification setup status
  static void printSetupStatus() {
  }
}
