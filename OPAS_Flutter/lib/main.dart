import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/home/screens/buyer_home_screen.dart';
import 'features/admin_panel/screens/admin_layout.dart';
import 'features/seller_panel/screens/seller_layout.dart';
import 'features/seller_panel/screens/edit_product_screen.dart';
import 'features/seller_panel/screens/update_stock_screen.dart';
import 'features/seller_panel/models/seller_product_model.dart';
import 'core/constants/app_theme.dart';
import 'core/routing/admin_router.dart';
import 'core/routing/seller_router.dart';
import 'core/services/admin_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (skip on web if credentials not configured)
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('ℹ️ Firebase skipped on web platform');
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
  }
  
  // Initialize Notifications (skip on web)
  try {
    if (!kIsWeb) {
      await NotificationService.instance.initialize(null);
      debugPrint('✅ Notification service initialized successfully');
    }
  } catch (e) {
    debugPrint('⚠️ Notification service initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OPAS',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        AdminRoutes.login: (context) => const LoginScreen(),
        AdminRoutes.home: (context) => const BuyerHomeScreen(),
        AdminRoutes.adminDashboard: (context) => const AdminLayout(),
        SellerRouter.seller: (context) => const SellerLayout(),
        ...AdminRoutes.getAllRoutes(),
        ...SellerRouter.getRoutes(),
      },
      onGenerateRoute: _generateRoute,
      navigatorObservers: [
        _RouteObserver(),
      ],
    );
  }

  /// Generate custom routes with error handling
  static Route<dynamic> _generateRoute(RouteSettings settings) {
    
    // Handle edit product route with product argument
    if (settings.name == '/seller/product/edit') {
      final product = settings.arguments as SellerProduct?;
      if (product != null) {
        return MaterialPageRoute(
          builder: (_) => EditProductScreen(product: product),
          settings: settings,
        );
      }
    }
    
    // Handle update stock route with product details
    if (settings.name == '/seller/inventory/update') {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        return MaterialPageRoute(
          builder: (_) => UpdateStockScreen(
            productId: args['productId'] as int? ?? 0,
            productName: args['productName'] as String? ?? 'Unknown',
            currentStock: args['currentStock'] as int? ?? 0,
            minimumStock: args['minimumStock'] as int? ?? 0,
            unit: args['unit'] as String? ?? 'units',
          ),
          settings: settings,
        );
      }
    }
    
    // Default route not found
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Route Not Found')),
        body: Center(
          child: Text('Route ${settings.name} not found'),
        ),
      ),
    );
  }
}

/// Observer to track navigation events for debugging
class _RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
  }

  @override
  void didPop(Route route, Route? previousRoute) {
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
  }
}

/// AuthWrapper handles initial authentication check
/// Routes to either HomeRouteWrapper (if logged in) or LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfLoggedIn(),
      builder: (context, snapshot) {
        // Show loading while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Route based on authentication status
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data == true ? const HomeRouteWrapper() : const LoginScreen();
      },
    );
  }

  /// Check if user is logged in (has access token)
  Future<bool> _checkIfLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.getString('access') != null;
      return hasToken;
    } catch (e) {
      return false;
    }
  }
}

/// HomeRouteWrapper handles role-based routing
/// Routes to AdminLayout (if admin), SellerLayout (if seller), or BuyerHomeScreen (if buyer)
class HomeRouteWrapper extends StatefulWidget {
  const HomeRouteWrapper({super.key});

  @override
  State<HomeRouteWrapper> createState() => _HomeRouteWrapperState();
}

class _HomeRouteWrapperState extends State<HomeRouteWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh user role on startup in case it changed
    AdminService.refreshUserRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh user role when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      AdminService.refreshUserRole();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        // Show loading while checking role
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return const BuyerHomeScreen();
        }

        // Route based on role
        final role = snapshot.data;

        if (role == 'ADMIN') {
          return const AdminLayout();
        } else if (role == 'SELLER') {
          return const SellerLayout();
        } else {
          return const BuyerHomeScreen();
        }
      },
    );
  }

  Future<String?> _getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      return null;
    }
  }
}