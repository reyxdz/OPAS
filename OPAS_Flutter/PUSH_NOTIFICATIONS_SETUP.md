# Push Notifications Setup Guide

## Overview
This guide walks through setting up Firebase Cloud Messaging (FCM) for push notifications in the OPAS Flutter app.

---

## 1. Firebase Console Setup

### Step 1.1: Create Firebase Project (if not already done)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `OPAS`
4. Enable Google Analytics (optional)
5. Click "Create project"

### Step 1.2: Add Android App
1. In Firebase Console, click the Android icon
2. Package name: `com.opas.agriculture` (or your package name)
3. App nickname: `OPAS Android`
4. Debug signing certificate SHA-1: Get this from:
   ```bash
   cd OPAS_Flutter
   flutter pub get
   ./gradlew signingReport
   ```
   Copy the SHA-1 from "debugAndroidDebugStoreFile"

5. Click "Register app"
6. Download `google-services.json`
7. Place it in: `OPAS_Flutter/android/app/google-services.json`
8. Follow the setup instructions in Firebase Console

### Step 1.3: Add iOS App
1. In Firebase Console, click the iOS icon
2. Bundle ID: `com.opas.agriculture` (or your bundle ID)
3. App nickname: `OPAS iOS`
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. In Xcode, add it to the project:
   - Open `OPAS_Flutter/ios/Runner.xcworkspace`
   - Right-click "Runner" folder → "Add Files to Runner"
   - Select `GoogleService-Info.plist`
   - Check "Copy items if needed"
   - Select target: Runner
   - Click "Add"

### Step 1.4: Enable FCM API
1. Go to APIs & Services in Firebase Console
2. Search for "Firebase Cloud Messaging API"
3. Click "Enable"

---

## 2. Android Configuration

### Step 2.1: Update android/build.gradle
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Step 2.2: Update android/app/build.gradle
Add at the end of the file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 2.3: Verify Permissions
Check `android/app/src/main/AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## 3. iOS Configuration

### Step 3.1: Enable Push Notifications in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" project
3. Select "Runner" target
4. Go to "Signing & Capabilities"
5. Click "+ Capability"
6. Search and add "Push Notifications"

### Step 3.2: Add APNs Certificate
1. Go to Apple Developer Portal
2. Create APNs certificate (or use existing)
3. In Firebase Console → Project Settings → Cloud Messaging tab
4. Upload APNs certificate

### Step 3.3: Update Podfile
In `ios/Podfile`, add:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_NOTIFICATIONS=1',
      ]
    end
  end
end
```

Run: `cd ios && pod update && cd ..`

---

## 4. Flutter App Setup

### Step 4.1: Initialize NotificationService
Edit `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:opas_flutter/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  await NotificationService.instance.initialize(null);
  
  runApp(const MyApp());
}
```

### Step 4.2: Generate Firebase Options File
Run in Flutter project:
```bash
flutterfire configure --project=OPAS --ios-out=ios/config --android-out=android/app/src/main
```

This creates `lib/firebase_options.dart`

### Step 4.3: Test Notifications
Use the Firebase Console:
1. Go to Engagement → Cloud Messaging
2. Create your first campaign
3. Select "FCM API" (or "Notifications")
4. Enter title and body
5. Target: Single device (get FCM token from logs)
6. Click "Send test message"

Or check the FCM token in logs:
```bash
flutter logs
# Look for: "FCM Token: xxxxxxxxxx"
```

---

## 5. Receiving Notifications

### How the app receives notifications:

**Foreground (App Open)**
- Triggers `_handleForegroundMessage()` in NotificationService
- Shows local notification
- Calls `onMessageReceived` callback

**Background (App Minimized)**
- Triggers `_firebaseMessagingBackgroundHandler()` 
- Caches notification locally
- Logs to backend

**Terminated (App Closed)**
- FCM stores message temporarily
- Gets retrieved when app starts
- Handles with `_handleMessageOpenedApp()`

### Add Callback Handlers
In your app initialization:
```dart
NotificationService.instance.onMessageReceived = (message) {
  print('Received notification: ${message.notification?.title}');
  // Update UI or state here
};

NotificationService.instance.onMessageOpenedApp = (message) {
  print('Opened from notification: ${message.data}');
  // Handle navigation
};
```

---

## 6. Backend Integration

### Send Push Notification from Django Backend

```python
from firebase_admin import messaging
import firebase_admin

# Initialize Firebase Admin SDK
firebase_admin.initialize_app()

def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None):
    """Send push notification via FCM"""
    
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        token=fcm_token,
    )
    
    response = messaging.send(message)
    return response

# Example usage
send_push_notification(
    fcm_token="...",
    title="Registration Approved",
    body="Your seller registration has been approved!",
    data={
        "action": "REGISTRATION_APPROVED",
        "registration_id": "123",
    }
)
```

### Store FCM Token in Backend

The app will send the token to:
```
POST /api/v1/users/fcm-token/
{
    "token": "..."
}
```

Store this in your Django User model.

---

## 7. Troubleshooting

### No notifications received?
- [ ] Check Firebase Console is accessible
- [ ] Verify app has internet permission
- [ ] Check FCM token is being registered (check logs)
- [ ] Ensure backend API is receiving the token
- [ ] Test with Firebase Console first (not backend yet)

### Token not updating?
- [ ] Call `NotificationService.instance._updateFCMToken()` after login
- [ ] Ensure ApiService is properly implemented
- [ ] Check backend endpoint exists: `/api/v1/users/fcm-token/`

### Background notifications not working?
- [ ] App needs to have notification permission
- [ ] On Android 13+: Request runtime permission
- [ ] On iOS: Ensure APNs certificate is uploaded

### Notifications appear but don't route correctly?
- [ ] Implement navigation helpers: `_navigateToDashboard()`, etc.
- [ ] Pass correct `action` in notification data
- [ ] Check notification payload structure

---

## 8. Testing Checklist

- [ ] Firebase project created
- [ ] Android google-services.json added
- [ ] iOS GoogleService-Info.plist added
- [ ] NotificationService initialized in main.dart
- [ ] firebase_options.dart generated
- [ ] Can receive test notification from Firebase Console
- [ ] FCM token logged to console
- [ ] Token sent to backend API
- [ ] Backend can send notification successfully
- [ ] App receives notification in foreground
- [ ] App receives notification in background
- [ ] App receives notification when closed
- [ ] Notification tap navigates to correct screen

---

## Next Steps

1. Complete Firebase Console setup (Steps 1-3)
2. Update Flutter app (Step 4)
3. Test with Firebase Console (Step 4.3)
4. Implement backend integration (Step 6)
5. Test end-to-end notifications
