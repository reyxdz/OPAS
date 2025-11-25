# Push Notifications - Quick Start Guide

## What's Been Set Up

✅ **NotificationService** - Full Firebase Cloud Messaging (FCM) integration  
✅ **Local Notifications** - Display notifications when app is open  
✅ **Background Handling** - Receive notifications when app is minimized  
✅ **Notification Routing** - Navigate to correct screens based on action  
✅ **Firebase Config** - Ready for Firebase project connection  

---

## Quick Start (5 Steps)

### Step 1: Create Firebase Project
```
https://console.firebase.google.com/
1. Create new project named "OPAS"
2. Add Android app (package: com.opas.agriculture)
3. Add iOS app (bundle: com.opas.agriculture)
4. Download google-services.json and GoogleService-Info.plist
```

### Step 2: Add Config Files
- Place `google-services.json` → `android/app/`
- Place `GoogleService-Info.plist` → iOS project (via Xcode)

### Step 3: Get Dependencies
```bash
cd OPAS_Flutter
flutter pub get
```

### Step 4: Generate Firebase Options
```bash
flutterfire configure --project=OPAS
```

### Step 5: Run & Test
```bash
flutter run
```

Check logs for:
```
✅ Firebase initialized successfully
✅ Notification service initialized successfully
FCM Token: xxxxxxxxxxxxx
```

---

## Testing Notifications

### Option A: Firebase Console (Easiest)
1. Go to Firebase Console → Cloud Messaging
2. Create campaign → "Send test message"
3. Select target device by FCM token
4. Send!

### Option B: Local Simulation (No Backend Needed)
In your app, create a test screen or add to `main.dart`:

```dart
import 'package:opas_flutter/services/notification_test_helper.dart';

// Call any of these to simulate notifications:
await NotificationTestHelper.simulateApproval();
await NotificationTestHelper.simulateRejection();
await NotificationTestHelper.simulateInfoRequested();
```

### Option C: Backend Integration (Production)
```python
# In your Django backend
from firebase_admin import messaging

def send_notification_to_seller(seller_user, action_type):
    fcm_token = seller_user.fcm_token  # Stored when app registers
    
    message = messaging.Message(
        notification=messaging.Notification(
            title=f"Registration {action_type}",
            body="Check your application status",
        ),
        data={
            "action": action_type,
            "registration_id": str(seller_user.registration.id),
        },
        token=fcm_token,
    )
    
    messaging.send(message)
```

---

## File Structure

```
lib/services/
├── notification_service.dart        ← Main service (Firebase integration)
├── real_api_service.dart            ← Backend API calls (implement with your token)
├── notification_test_helper.dart    ← Testing utilities
└── seller_registration_cache_service.dart

lib/firebase_options.dart            ← Auto-generated Firebase config
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   NOTIFICATION FLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Backend (Django)                                           │
│  └─→ Send FCM Message                                       │
│      └─→ Firebase Cloud Messaging                          │
│          └─→ Platform (Android/iOS)                        │
│              └─→ Flutter App                               │
│                  ├─→ Foreground: Local notification        │
│                  ├─→ Background: Cache + Log               │
│                  └─→ Tap: Route to screen                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Notification Actions Supported

| Action | Behavior | Screen |
|--------|----------|--------|
| `REGISTRATION_APPROVED` | Navigate to seller dashboard | SellerLayout |
| `REGISTRATION_REJECTED` | Show application status | ApplicationStatusScreen |
| `INFO_REQUESTED` | Open edit form | EditRegistrationForm |
| `AUDIT_LOG` | Show audit history | AuditLogScreen |
| (default) | Go to home | HomeScreen |

---

## Implementation Checklist

- [ ] Firebase project created
- [ ] `google-services.json` added to `android/app/`
- [ ] `GoogleService-Info.plist` added to iOS project
- [ ] `firebase_options.dart` generated
- [ ] `flutter pub get` executed
- [ ] App starts without Firebase errors
- [ ] FCM token appears in logs
- [ ] Can receive test notification from Firebase Console
- [ ] Notification displays when app is open
- [ ] Tapping notification navigates correctly
- [ ] Backend can send notifications
- [ ] Navigation helpers implemented

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Firebase initialization error" | Check `firebase_options.dart` is generated |
| No FCM token in logs | Restart app, check Firebase project setup |
| Notifications don't show | Check app has notification permissions |
| Tap does nothing | Implement navigation helpers in service |
| Backend can't send | Store FCM token in backend when app registers |

---

## Next Steps

1. **Complete Firebase Setup** (see PUSH_NOTIFICATIONS_SETUP.md)
2. **Update Real API Service** - Replace YOUR_AUTH_TOKEN with actual token
3. **Implement Navigation** - Update the nav helper methods in NotificationService
4. **Test End-to-End** - Use Firebase Console to send test message
5. **Integrate with Backend** - Send notifications from Django when needed

---

## Key Files to Review

- `lib/main.dart` - Firebase + NotificationService initialization
- `lib/services/notification_service.dart` - Complete notification handling
- `lib/services/notification_test_helper.dart` - Testing utilities
- `PUSH_NOTIFICATIONS_SETUP.md` - Detailed setup instructions

---

## Need Help?

Check Firebase Console logs:
```bash
flutter logs | grep -i "notification\|firebase\|fcm"
```

For backend integration questions, see `real_api_service.dart` example implementation.
