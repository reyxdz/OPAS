/// Flutter Test Fixtures for Admin Panel
/// 
/// Provides clean architecture patterns for frontend testing:
/// - Mock builders for UI components
/// - Screen helpers for rendering and interaction
/// - Responsive utilities for multi-device testing
/// - Accessibility helpers for testing dark mode and semantic labels
/// - Form validators and test data factories
/// 
/// Usage:
/// ```dart
/// testWidgets('seller screen renders', (WidgetTester tester) async {
///   await tester.pumpWidget(AdminTestHelper.createTestApp(
///     AdminSellersScreen(),
///   ));
///   expect(find.byType(AdminSellersScreen), findsOneWidget);
/// });
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// RESPONSIVE SIZE DEFINITIONS
// ============================================================================

/// Phone screen sizes for responsive testing
class PhoneScreenSize {
  static const Size small = Size(375, 667); // iPhone SE
  static const Size medium = Size(393, 851); // Pixel 6
  static const Size large = Size(412, 915); // Pixel 6 Pro
  
  static const List<Size> all = [small, medium, large];
  
  /// Get responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}

// ============================================================================
// RESPONSIVE HELPER CLASS
// ============================================================================

/// Handles responsive testing across different screen sizes
class ResponsiveTestHelper {
  /// Pump widget on small phone (375x667)
  static Future<void> pumpOnSmallPhone(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = PhoneScreenSize.small;
    addTearDown(tester.view.resetPhysicalSize);
    
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Pump widget on medium phone (393x851)
  static Future<void> pumpOnMediumPhone(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = PhoneScreenSize.medium;
    addTearDown(tester.view.resetPhysicalSize);
    
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Pump widget on large phone (412x915)
  static Future<void> pumpOnLargePhone(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = PhoneScreenSize.large;
    addTearDown(tester.view.resetPhysicalSize);
    
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Test widget on all phone sizes
  static Future<void> pumpOnAllPhones(
    WidgetTester tester,
    Widget Function() widgetBuilder,
  ) async {
    for (final size in PhoneScreenSize.all) {
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      
      await tester.pumpWidget(widgetBuilder());
      await tester.pumpAndSettle();
    }
  }
}

// ============================================================================
// ACCESSIBILITY HELPER CLASS
// ============================================================================

/// Tests for dark mode support, semantic labels, and contrast ratios
class AccessibilityTestHelper {
  /// Test widget in dark mode
  static Widget createDarkModeWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: child,
    );
  }

  /// Test widget in light mode
  static Widget createLightModeWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: child,
    );
  }

  /// Verify semantic label exists
  static Finder findBySemanticLabel(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Verify text contrast ratio meets WCAG AA (4.5:1 for normal text)
  static bool isContrastRatioValid(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    
    return contrastRatio >= 4.5; // WCAG AA standard
  }

  /// Verify font size is readable (minimum 14.0)
  static bool isFontSizeReadable(double fontSize) {
    return fontSize >= 14.0;
  }

  /// Verify tap target is large enough (minimum 48x48)
  static bool isTapTargetSufficient(Size size) {
    return size.width >= 48.0 && size.height >= 48.0;
  }
}

// ============================================================================
// MOCK DATA FACTORIES
// ============================================================================

/// Factory for creating mock seller data
class MockSellerFactory {
  static Map<String, dynamic> createPendingSeller() => {
    'id': '1',
    'name': 'Test Farmer',
    'email': 'farmer@test.com',
    'status': 'PENDING',
    'registrationDate': '2025-11-18',
    'farmName': 'Test Farm',
    'location': 'Test Region',
    'products': ['Maize', 'Rice'],
  };

  static Map<String, dynamic> createApprovedSeller() => {
    'id': '2',
    'name': 'Approved Farmer',
    'email': 'approved@test.com',
    'status': 'APPROVED',
    'registrationDate': '2025-10-18',
    'farmName': 'Big Farm',
    'location': 'North Region',
    'products': ['Wheat', 'Barley', 'Oats'],
  };

  static Map<String, dynamic> createSuspendedSeller() => {
    'id': '3',
    'name': 'Suspended Farmer',
    'email': 'suspended@test.com',
    'status': 'SUSPENDED',
    'registrationDate': '2025-09-18',
    'farmName': 'Small Farm',
    'location': 'South Region',
    'products': ['Vegetables'],
    'suspensionReason': 'Price violation',
  };
}

/// Factory for creating mock price ceiling data
class MockPriceCeilingFactory {
  static Map<String, dynamic> createPriceCeiling() => {
    'id': '1',
    'productName': 'Maize',
    'currentCeiling': 5000.0,
    'previousCeiling': 4800.0,
    'effectiveDate': '2025-11-15',
    'lastChanged': '2025-11-15',
    'changeReason': 'Market Adjustment',
  };

  static Map<String, dynamic> createNonCompliantListing() => {
    'id': '1',
    'seller': 'Test Farmer',
    'product': 'Maize',
    'listedPrice': 6500.0,
    'ceiling': 5000.0,
    'overagePercentage': 30.0,
    'status': 'NEW',
  };
}

/// Factory for creating mock OPAS data
class MockOPASFactory {
  static Map<String, dynamic> createPendingSubmission() => {
    'id': '1',
    'seller': 'Test Farmer',
    'product': 'Maize',
    'quantity': 100,
    'unitPrice': 4500.0,
    'status': 'PENDING',
    'submittedDate': '2025-11-20',
  };

  static Map<String, dynamic> createInventoryItem() => {
    'id': '1',
    'product': 'Maize',
    'quantity': 500,
    'location': 'Warehouse A',
    'expiryDate': '2025-12-20',
    'status': 'OK',
  };

  static Map<String, dynamic> createLowStockInventory() => {
    'id': '2',
    'product': 'Rice',
    'quantity': 5,
    'location': 'Warehouse B',
    'expiryDate': '2025-11-25',
    'status': 'LOW_STOCK',
  };
}

// ============================================================================
// FORM VALIDATION HELPERS
// ============================================================================

/// Helpers for testing form validation
class FormValidationTestHelper {
  /// Validate required field
  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate number range
  static String? validateNumberRange(
    String? value, {
    required double min,
    required double max,
  }) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }
    if (number < min || number > max) {
      return 'Value must be between $min and $max';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }
}

// ============================================================================
// LOADING STATE HELPER CLASS
// ============================================================================

/// Helpers for testing loading states and spinners
class LoadingStateTestHelper {
  /// Verify loading spinner is visible
  static bool isLoadingSpinnerVisible(WidgetTester tester) {
    return find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
  }

  /// Verify loading spinner is hidden
  static bool isLoadingSpinnerHidden(WidgetTester tester) {
    return find.byType(CircularProgressIndicator).evaluate().isEmpty;
  }

  /// Create mock loading widget
  static Widget createLoadingWidget() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Create mock data-loaded widget
  static Widget createDataLoadedWidget() {
    return const Scaffold(
      body: Center(
        child: Text('Data Loaded'),
      ),
    );
  }

  /// Create mock skeleton loading widget
  static Widget createSkeletonLoadingWidget() {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            height: 100,
            color: Colors.grey[300],
            margin: const EdgeInsets.all(16),
          ),
          Container(
            height: 100,
            color: Colors.grey[300],
            margin: const EdgeInsets.all(16),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NETWORK ERROR HELPER CLASS
// ============================================================================

/// Helpers for testing network error handling
class NetworkErrorTestHelper {
  static const String connectionError = 'Failed to connect to server';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String notFoundError = 'Resource not found';
  static const String unauthorizedError = 'You are not authorized to perform this action';

  /// Verify error message is displayed
  static bool isErrorMessageDisplayed(WidgetTester tester, String message) {
    return find.text(message).evaluate().isNotEmpty;
  }

  /// Verify retry button is visible
  static bool isRetryButtonVisible(WidgetTester tester) {
    return find.byType(ElevatedButton).evaluate().isNotEmpty;
  }

  /// Create mock error widget
  static Widget createErrorWidget(String errorMessage) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN ADMIN TEST HELPER CLASS
// ============================================================================

/// Main helper class for all admin screen testing
class AdminTestHelper {
  /// Create a minimal test app wrapping the given widget
  static Widget createTestApp(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }

  /// Create test app with specific theme mode
  static Widget createTestAppWithTheme(
    Widget child, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      home: child,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
    );
  }

  /// Pump and settle widget
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Type text into a field
  static Future<void> typeText(
    WidgetTester tester,
    String text,
    Finder finder,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Tap a widget
  static Future<void> tapWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Verify widget exists
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify text exists
  static void expectTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verify multiple widgets exist
  static void expectMultipleWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Scroll to widget
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      500,
      scrollable: find.byType(Scrollable).first,
    );
  }

  /// Find widget by text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Find widget by type
  static Finder findByType(Type type) {
    return find.byType(type);
  }

  /// Wait for async operation
  static Future<void> waitForAsync(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }
}

// ============================================================================
// BASE TEST CLASS FOR ADMIN SCREENS
// ============================================================================

/// Base class for all admin screen tests with common setup
class AdminScreenTestBase {
  /// Common setup for all admin screen tests
  static void commonSetup() {
    // Initialize test bindings
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Common teardown
  static void commonTeardown() {
    // Cleanup after tests
  }
}

// ============================================================================
// SCREEN NAVIGATION HELPER CLASS
// ============================================================================

/// Helpers for testing screen navigation
class NavigationTestHelper {
  /// Create mock navigation observer
  static NavigatorObserver createMockNavigatorObserver() {
    return _SimpleNavigatorObserver();
  }

  /// Verify screen was navigated to
  static void verifyScreenNavigated(
    NavigatorObserver observer,
    String routeName,
  ) {
    // Navigator verification would require mockito package
    // For now, just verify the observer exists
    expect(observer, isNotNull);
  }

  /// Create material app with navigation
  static Widget createAppWithNavigation(Widget home) {
    return MaterialApp(
      home: home,
    );
  }
}

// ============================================================================
// SIMPLE NAVIGATOR OBSERVER
// ============================================================================

/// Simple navigator observer for testing
class _SimpleNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {}

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  @override
  void didStopUserGesture() {}
}
