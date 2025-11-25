/*
QUICK FCM TOKEN GETTER
======================

To quickly get your FCM token without running the full app:

1. Add this code to lib/main.dart in main() before other code:

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    
    print('═══════════════════════════════════════════');
    print('✅ FCM TOKEN OBTAINED:');
    print('═══════════════════════════════════════════');
    print(token);
    print('═══════════════════════════════════════════');
    
    // Continue with normal app startup
    runApp(const MyApp());
  }

2. Run: flutter run

3. Look for "FCM TOKEN OBTAINED:" in console output

4. Copy the token

5. Paste into Firebase Console to send test notification

6. Remove this debug code once token is obtained
*/
