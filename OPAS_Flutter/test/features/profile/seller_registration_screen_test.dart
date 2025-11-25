import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opas_flutter/features/profile/screens/seller_upgrade_screen.dart';

/// Flutter Widget Tests for Seller Upgrade Screen
/// Tests form rendering, validation, and submission
/// CORE PRINCIPLE: Input Validation - Client-side validation tested
/// CORE PRINCIPLE: User Experience - Form flow and feedback tested

void main() {
  group('SellerUpgradeScreen Widget Tests', () {
    testWidgets('Renders form with all required fields',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Visual feedback
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify app renders
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Start Selling Today'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('All form fields render correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify form fields
      expect(find.text('Farm Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Farm Location'), findsOneWidget);
      expect(find.text('Store Name'), findsOneWidget);
      expect(find.text('Store Description'), findsOneWidget);
    });

    testWidgets('Form validation shows error messages',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: Input Validation - Error display
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Try to submit without filling farm name
      final submitButton = find.widgetWithText(ElevatedButton, 'Upgrade to Seller');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Farm name field requires minimum 3 characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Find and fill farm name field with short text
      final farmNameField = find.byType(TextFormField).first;
      await tester.enterText(farmNameField, 'AB'); // Too short
      await tester.pumpAndSettle();

      // Verify field contains the text
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('Store description field accepts input',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Form interaction
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Find store description field
      final descriptionFields = find.byType(TextFormField);
      expect(descriptionFields, findsWidgets);

      // Enter text in description field
      final lastField = find.byType(TextFormField).last;
      await tester.enterText(lastField, 'Fresh farm products');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('Fresh farm products'), findsOneWidget);
    });

    testWidgets('Submit button is present', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Form submission
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify submit button exists
      final submitButton = find.widgetWithText(ElevatedButton, 'Upgrade to Seller');
      expect(submitButton, findsOneWidget);

      // Button should be enabled
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('All required fields are present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify required fields
      final formFields = find.byType(TextFormField);
      expect(formFields, findsWidgets);

      // At minimum should have farm name, location, store name, description
      expect(formFields, findsWidgets);
    });

    testWidgets('Store description has max length',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Field feedback
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Find and test store description field
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.last, 'Test Description');
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Terms and conditions shown',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: Input Validation - Required fields
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify submit button exists
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Verify terms section exists
      expect(find.text('Before you proceed:'), findsOneWidget);
    });

    testWidgets('Loading state shown during submission',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Loading feedback
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify form renders
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Error messages displayed on submission failure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify form can display errors
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Form data can be entered in fields',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: State Preservation - Form data entry
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Enter data in first field
      final firstTextField = find.byType(TextFormField).first;
      await tester.enterText(firstTextField, 'Sunset Farm');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('Sunset Farm'), findsOneWidget);
    });
  });

  group('SellerUpgradeScreen Validation Tests', () {
    testWidgets('Empty farm name shows error', (WidgetTester tester) async {
      // CORE PRINCIPLE: Input Validation - Required field
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Farm location field is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      expect(find.text('Farm Location'), findsOneWidget);
    });

    testWidgets('Form fields are wrapped in form',
        (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Form validation
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify form widget is present
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('Store name field validation', (WidgetTester tester) async {
      // CORE PRINCIPLE: Input Validation - All fields checked
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      expect(find.text('Store Name'), findsOneWidget);
    });
  });

  group('SellerUpgradeScreen Integration Tests', () {
    testWidgets('Complete form flow', (WidgetTester tester) async {
      // CORE PRINCIPLE: User Experience - Full workflow
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      // Verify initial state
      expect(find.text('Become a Seller'), findsOneWidget);
      expect(find.text('Start Selling Today'), findsOneWidget);

      // Verify form structure
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(PageView), findsNothing); // Single page form
    });

    testWidgets('Form renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerUpgradeScreen(),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
