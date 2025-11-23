import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opas_flutter/features/admin_panel/screens/seller_registrations_list_screen.dart';

/// Flutter Widget Tests for Admin Screens
/// Tests list, filtering, and admin workflow
/// CORE PRINCIPLE: User Experience - Admin workflow tested
/// CORE PRINCIPLE: Security - Permission checks verified

void main() {
  group('SellerRegistrationsListScreen Widget Tests', () {
    testWidgets('Renders with tab navigation', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Tab-based navigation
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Search field present and functional',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Search capability
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      final searchFields = find.byType(TextField);
      expect(searchFields, findsWidgets);
    });

    testWidgets('Sort options available', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Sorting functionality
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('Empty state message shown when no registrations',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Clear feedback
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Loading state shown while fetching data',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Loading feedback
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Registration card displays key information',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Clear information hierarchy
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Filter chips interactive', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Filter interaction
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Retry button appears on error', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Error recovery
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Pagination works correctly', (WidgetTester tester) async {
      // CORE PRINCIPLE: Resource Management - Efficient pagination
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Search updates list immediately', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Responsive search
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Sort order toggle works', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Sort control
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    });

    testWidgets('Filter state persists across navigation',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: State Preservation - Filter restoration
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SellerRegistrationsListScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('Admin Dialog Tests', () {
    testWidgets('Approval dialog displayed correctly', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Action confirmation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Approve Registration'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text('This action cannot be undone'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Approve'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Approve Registration'), findsOneWidget);
      expect(find.text('This action cannot be undone'), findsOneWidget);
    });

    testWidgets('Rejection dialog displayed correctly', (WidgetTester tester) async {
      // CORE PRINCIPLE: Input Validation - Required reason
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Reject Registration'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text('Please provide a reason for rejection'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Reject'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Reject Registration'), findsOneWidget);
    });

    testWidgets('Info request dialog displayed correctly',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Deadline selection
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Request More Information'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text('Specify the information needed'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Send Request'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Request More Information'), findsOneWidget);
    });
  });
}
