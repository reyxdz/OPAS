# Push Notifications Architecture & Flow Diagrams

## 1. Overall System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        OPAS NOTIFICATION SYSTEM                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    BACKEND (Django)                             │  │
│  │  ┌────────────────────────────────────────────────────────────┐ │  │
│  │  │ User registers/logs in                                     │ │  │
│  │  │ → Receives FCM token from app                              │ │  │
│  │  │ → Stores token in UserProfile.fcm_token                   │ │  │
│  │  └────────────────────────────────────────────────────────────┘ │  │
│  │                                                                  │  │
│  │  ┌────────────────────────────────────────────────────────────┐ │  │
│  │  │ Admin approves/rejects registration                        │ │  │
│  │  │ → Calls PushNotificationService.send_to_user()            │ │  │
│  │  │ → Gets FCM token from database                            │ │  │
│  │  │ → Sends via Firebase Cloud Messaging                      │ │  │
│  │  └────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                              ↓↓↓                                        │
│                     Firebase Cloud Messaging                            │
│                              ↓↓↓                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                  FLUTTER APP (Mobile)                           │  │
│  │  ┌────────────────────────────────────────────────────────────┐ │  │
│  │  │ Foreground (App Open):                                     │ │  │
│  │  │  → Display local notification                              │ │  │
│  │  │  → Fire onMessageReceived callback                         │ │  │
│  │  └────────────────────────────────────────────────────────────┘ │  │
│  │  ┌────────────────────────────────────────────────────────────┐ │  │
│  │  │ Background (App Minimized):                                │ │  │
│  │  │  → Cache notification locally                              │ │  │
│  │  │  → Fire background handler                                 │ │  │
│  │  └────────────────────────────────────────────────────────────┘ │  │
│  │  ┌────────────────────────────────────────────────────────────┐ │  │
│  │  │ User Taps Notification:                                    │ │  │
│  │  │  → Parse action from notification data                     │ │  │
│  │  │  → Route to appropriate screen                             │ │  │
│  │  └────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Notification State Machine

```
                        NOTIFICATION STATES
                        
                    ┌─────────────────────┐
                    │   NOT INITIALIZED   │
                    └──────────┬──────────┘
                               │
                      (Firebase.initializeApp)
                               │
                               ↓
                    ┌─────────────────────┐
                    │   LISTENING READY   │◄──────────────┐
                    └──────────┬──────────┘               │
                               │                        │
                  ┌────────────┼────────────┐            │
                  │            │            │            │
                  ↓            ↓            ↓            │
           ┌──────────────┐ ┌──────────┐ ┌───────────┐   │
           │ FOREGROUND   │ │BACKGROUND│ │ TERMINATED│   │
           │ (App Open)   │ │(Minimized)│ │(App Closed)   │
           └──────┬───────┘ └────┬─────┘ └────┬──────┘   │
                  │               │           │           │
         (Show notification) (Cache) (Retrieve on open)   │
                  │               │           │           │
                  └───────────────┼───────────┘           │
                                  │                       │
                                  ↓                       │
                          (User taps notification)        │
                                  │                       │
                                  ↓                       │
                          (Navigate to screen)            │
                                  │                       │
                                  └───────────────────────┘
                              (Return to listening)
```

---

## 3. Notification Lifecycle

```
┌─ BACKEND ─────────────────────────────────────────────────────────────┐
│                                                                        │
│  Step 1: User Action (Approve Registration)                          │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │ Admin clicks "Approve" button                                │    │
│  │ Django view receives approval request                        │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                            ↓                                          │
│  Step 2: Prepare Notification                                        │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │ Get seller's FCM token from database                         │    │
│  │ Compose notification message                                 │    │
│  │ Prepare action data {action: APPROVED, id: ...}             │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                            ↓                                          │
│  Step 3: Send via FCM                                                │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │ firebase_admin.messaging.send(message)                       │    │
│  └──────────────────────────────────────────────────────────────┘    │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
┌───────▼───────────────────────────────────────────▼──────────────┐
│                  FIREBASE CLOUD MESSAGING                        │
│                                                                  │
│  - Routes message to appropriate platform                       │
│  - Uses FCM token to identify device                            │
│  - Stores if device offline                                     │
└───────┬────────────────────────────────────────────────────┬────┘
        │                                                    │
     Android                                              iOS
        │                                                    │
┌───────▼──────────────────────────────┐  ┌────────────────▼────┐
│        Android Device                │  │   iOS Device        │
│  - FCM service receives message      │  │ - APNs receives     │
│  - Stores in notification tray       │  │   message           │
└───────┬──────────────────────────────┘  └────────┬───────────┘
        │                                           │
        │                                           │
        └───────────────────┬───────────────────────┘
                            │
                ┌───────────▼───────────┐
                │  Flutter App Receives │
                └───────────┬───────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ↓                   ↓                   ↓
    ┌────────┐          ┌────────┐         ┌────────┐
    │FOREGROUND         │BACKGROUND       │TERMINATED
    │App Open           │App Minimized    │App Closed
    │                   │                  │
    │Show local         │Save to cache    │Message stored
    │notification       │Log to backend   │by FCM
    │Call callback      │                  │
    │                   │                 │Retrieved on
    │                   │                  │app restart
    └────────┬──────────┴────────┬─────────┴────────┐
             │                   │                  │
             └───────────────────┼──────────────────┘
                                 │
                         (User taps notification)
                                 │
                    ┌────────────▼────────────┐
                    │ Parse Action Type      │
                    │ {action: APPROVED}     │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Route to Screen        │
                    │ APPROVED → Dashboard   │
                    └────────────┬────────────┘
                                 │
                                 ↓
                          User sees screen!
```

---

## 4. Token Management Flow

```
┌─────────────────────────────────────────────────────┐
│            FCM TOKEN LIFECYCLE                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. App Installation                               │
│     └─→ NotificationService.initialize()           │
│         └─→ FirebaseMessaging.instance.getToken()  │
│             └─→ FCM generates unique token         │
│                                                     │
│  2. Token Retrieved                                │
│     └─→ Token = "eXdZc9AKT5k_Xmpl123ABC..."       │
│         └─→ Stored in SharedPreferences            │
│         └─→ Printed to console logs                │
│                                                     │
│  3. Token Sent to Backend                          │
│     └─→ POST /api/v1/users/fcm-token/             │
│         {token: "eXdZc9AKT5k_..."}               │
│             └─→ Stored in UserProfile.fcm_token    │
│                                                     │
│  4. Token Used for Notifications                   │
│     └─→ Backend reads token from DB                │
│         └─→ Sends via firebase_admin.messaging     │
│             └─→ FCM routes to device               │
│                                                     │
│  5. Token Refresh (Optional)                       │
│     └─→ Token may change on:                       │
│         - App reinstall                            │
│         - Clear app cache                          │
│         - Monthly Firebase refresh                 │
│             └─→ New token generated                │
│             └─→ Sent to backend again              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 5. Notification Data Structure

```
┌─────────────────────────────────────────────────────┐
│         FIREBASE MESSAGE STRUCTURE                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Message {                                          │
│    notification: {                                  │
│      title: "Registration Approved",               │
│      body: "Your registration is approved!",       │
│    },                                               │
│                                                     │
│    data: {                                          │
│      action: "REGISTRATION_APPROVED",              │
│      registration_id: "12345",                      │
│      timestamp: "2025-11-23T10:30:00Z",           │
│      [other custom data...]                        │
│    },                                               │
│                                                     │
│    token: "eXdZc9AKT5k_Xmpl123ABC..."            │
│  }                                                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│  Where:                                             │
│  - notification: Displayed to user                  │
│  - data: Passed to app logic                        │
│  - token: Identifies target device                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 6. Action-to-Screen Routing

```
Notification received with action:
│
├─ REGISTRATION_APPROVED
│  └─→ route to SellerLayout (Seller Dashboard)
│
├─ REGISTRATION_REJECTED
│  └─→ route to ApplicationStatusScreen
│      └─→ Show rejection reason
│
├─ INFO_REQUESTED
│  └─→ route to EditRegistrationForm
│      └─→ Show required fields
│
├─ AUDIT_LOG
│  └─→ route to AuditLogScreen
│
└─ (unknown action)
   └─→ route to HomeScreen (default)
```

---

## 7. Error Handling Flow

```
┌─────────────────────────────────────────┐
│      NOTIFICATION ERROR HANDLING        │
├─────────────────────────────────────────┤
│                                         │
│  No FCM Token?                          │
│  └─→ Log warning                        │
│      └─→ User can still use app         │
│      └─→ Won't receive notifications    │
│      └─→ Retry token request on restart │
│                                         │
│  Backend API unreachable?               │
│  └─→ Notification still shows locally   │
│      └─→ Log event not sent             │
│      └─→ Notification cached            │
│      └─→ Retry on next connection       │
│                                         │
│  Invalid action type?                   │
│  └─→ Default to home screen             │
│      └─→ Log warning                    │
│      └─→ User not stuck                 │
│                                         │
│  Notification permission denied?        │
│  └─→ Android 13+: Request permission    │
│      └─→ iOS: Already requested         │
│      └─→ User can re-enable in settings │
│                                         │
└─────────────────────────────────────────┘
```

---

## 8. Testing Flow

```
Test Notification Sent from Firebase Console:
│
├─ Firebase Console → Cloud Messaging
│  └─→ Create test message
│
├─ Enter test parameters
│  ├─ Title: "Test"
│  ├─ Body: "Hello"
│  ├─ Data: {action: TEST}
│  └─ Target: FCM token
│
├─ Click "Send test message"
│  └─→ FCM receives request
│
├─ Firebase sends to device
│  └─→ Check app status:
│      ├─ If foreground:
│      │  └─→ Show notification immediately
│      ├─ If background:
│      │  └─→ Show in notification tray
│      └─ If closed:
│         └─→ Store for later
│
└─ Verify in app logs:
   └─→ "Received notification: Test"
       └─→ Check if action is parsed correctly
```

---

## 9. Integration Points

```
┌─────────────────────────────────────┐
│  KEY INTEGRATION POINTS             │
├─────────────────────────────────────┤
│                                     │
│  1. App Startup                     │
│     lib/main.dart                   │
│     └─→ Firebase.initializeApp()    │
│     └─→ NotificationService.init()  │
│                                     │
│  2. User Login                      │
│     └─→ Get FCM token               │
│     └─→ POST to backend with token  │
│                                     │
│  3. Admin Approval                  │
│     Django admin view               │
│     └─→ Call PushNotificationService │
│     └─→ Send to user's FCM token    │
│                                     │
│  4. Notification Received           │
│     NotificationService             │
│     └─→ Parse action & data         │
│     └─→ Route to screen             │
│                                     │
│  5. UI Updates                      │
│     Navigation                      │
│     └─→ Show relevant screen        │
│     └─→ Display status info         │
│                                     │
└─────────────────────────────────────┘
```

---

## Summary Flow

```
App Start → Get FCM Token → Send to Backend
                              ↓
                  Admin approves registration
                              ↓
                  Backend sends notification
                              ↓
                  Firebase routes to device
                              ↓
           App receives (foreground/background)
                              ↓
                       Show notification
                              ↓
                        User taps
                              ↓
                      Parse action type
                              ↓
                      Navigate to screen
                              ↓
                      User sees updated status ✅
```
