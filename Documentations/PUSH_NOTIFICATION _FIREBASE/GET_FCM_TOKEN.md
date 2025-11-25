# Getting Your FCM Token - Step by Step

## What is an FCM Token?
A unique identifier that Firebase uses to send notifications to your specific device. 

---

## Method 1: Get Token from Flutter App Logs (Easiest)

### Step 1: Run the app
```bash
cd OPAS_Flutter
flutter run
```

### Step 2: Watch the console logs
Look for this line (appears during app startup):
```
I flutter: FCM Token: eXdZc9AKT5k_Xmpl123ABC...
```

### Step 3: Copy the token
The long string after "FCM Token: " is your device token.

---

## Method 2: Get Token Programmatically

Add this to your app temporarily:

```dart
// In your home screen or init
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

void getAndDisplayToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  print('=== YOUR FCM TOKEN ===');
  print(token);
  print('====================');
  
  // Also save it
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('my_fcm_token', token ?? '');
}

// Call from main or first screen:
// getAndDisplayToken();
```

---

## Method 3: Retrieve Stored Token

If you've already run the app, the token is stored:

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('fcm_token');
}

// Usage:
final token = await getStoredToken();
print('Stored token: $token');
```

---

## Method 4: Get from Backend After Registration

When your app registers the token, check your backend:

```python
# Django Shell
python manage.py shell

from apps.users.models import UserProfile
from django.contrib.auth.models import User

user = User.objects.first()
profile = UserProfile.objects.get(user=user)
print(f"FCM Token: {profile.fcm_token}")
```

---

## Once You Have the Token

### Test with Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project
3. Go to **Engagement** → **Cloud Messaging**
4. Click **Create campaign** or **Send your first message**
5. Choose **Firebase Cloud Messaging API** (or Notifications composer)
6. Enter:
   - **Title**: "Test Notification"
   - **Body**: "Hello from Firebase!"
7. Click **Next** → **Target**
8. Select **Single device** (not Audience)
9. Choose **FCM token** from dropdown
10. Paste your token
11. Click **Send test message**
12. Watch your app receive the notification! 🎉

---

## What to Look for

### Successful Token Registration
In Flutter logs:
```
✅ FCM initialized
✅ Notification service initialized
I flutter: FCM Token: abc123...
```

In Django shell:
```python
>>> profile.fcm_token
'abc123...'
```

---

## Example Flutter Code to Display Token

Add this temporarily to see your token clearly:

```dart
// lib/main.dart or any screen
import 'package:firebase_messaging/firebase_messaging.dart';

class TokenDisplayWidget extends StatefulWidget {
  @override
  _TokenDisplayWidgetState createState() => _TokenDisplayWidgetState();
}

class _TokenDisplayWidgetState extends State<TokenDisplayWidget> {
  String? _token = 'Loading...';
  
  @override
  void initState() {
    super.initState();
    _getToken();
  }
  
  void _getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = token;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My FCM Token')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your FCM Token:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _token ?? 'No token available',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Copy this token and use in Firebase Console to send test notifications!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Firebase Console Test Steps

1. **Copy your token** from Flutter app
2. **Open Firebase Console** → Cloud Messaging tab
3. **Send test message**:
   ```
   Title: "Registration Approved"
   Body: "Your seller registration is approved!"
   Data:
     action: REGISTRATION_APPROVED
     registration_id: 12345
   ```
4. **Select device** → Paste your FCM token
5. **Send** and watch your app respond! 📱

---

## Example Response from App

When notification is received, you'll see in logs:
```
Received notification: Registration Approved
Action: REGISTRATION_APPROVED
Registration ID: 12345
```

And the app will navigate to the appropriate screen.

---

## Troubleshooting Token Issues

| Problem | Solution |
|---------|----------|
| No "FCM Token:" in logs | Check Firebase is initialized (check main.dart) |
| Token is null | Wait a few seconds after app starts |
| Token changes each time | Normal! Tokens can refresh |
| Can't find logs | Run `flutter logs \| grep -i fcm` |
| Token not saved to backend | Check backend API endpoint `/api/v1/users/fcm-token/` |

---

## Token Lifecycle

- **Generated**: When NotificationService.initialize() is called
- **Logged**: Printed to console immediately
- **Refreshed**: Can change if user reinstalls app
- **Stored**: Saved in SharedPreferences locally
- **Sent to Backend**: Via API when user logs in/registers
- **Used**: For sending notifications from backend

---

## Quick Commands

Get token in Flutter:
```bash
flutter run | grep "FCM Token"
```

View stored token:
```bash
# In Flutter app, add this method and call it
String? token = await SharedPreferences.getInstance().getString('fcm_token');
print(token);
```

Test with curl (after you get token):
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/opas-agriculture/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN_HERE",
      "notification": {
        "title": "Test",
        "body": "Hello"
      }
    }
  }'
```

---

## Next: Send First Notification

Once you have your token:
1. Go to Firebase Console
2. Cloud Messaging → Send test message
3. Paste token
4. Send!
5. See notification pop up on your device 🎉
