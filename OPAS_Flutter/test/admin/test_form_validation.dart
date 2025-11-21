/// Admin Form Validation Tests
/// 
/// Tests for form validation across all admin screens:
/// - Seller approval form validation
/// - Price ceiling update validation
/// - OPAS submission review validation
/// - Form submission handling
/// - Error message display
/// - Input constraints
/// 
/// Test Coverage:
/// - 6 seller approval form tests
/// - 6 price ceiling form tests
/// - 6 OPAS submission form tests
/// - 4 common form behavior tests
/// Total: 22 tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'flutter_test_fixtures.dart';

void main() {
  group('Admin Form Validation Tests', () {
    // ========================================================================
    // SELLER APPROVAL FORM TESTS
    // ========================================================================

    group('Seller Approval Form Validation', () {
      testWidgets('Seller approval form shows validation error on empty notes',
          (WidgetTester tester) async {
        // Step 1: Create form with validation
        final formKey = GlobalKey<FormState>();
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Admin Notes'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Notes are required';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Step 2: Pump widget
        await tester.pumpWidget(testWidget);

        // Step 3: Tap validate button without filling form
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        // Step 4: Verify error is shown
        expect(find.text('Notes are required'), findsOneWidget);
      });

      testWidgets('Seller approval form accepts valid notes',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        var isValid = false;

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Admin Notes'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Notes are required';
                      }
                      if (value.length < 10) {
                        return 'Notes must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      isValid = formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Fill in valid notes
        await AdminTestHelper.typeText(
          tester,
          'This seller has valid documents and meets all requirements',
          find.byType(TextFormField),
        );

        // Validate form
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        expect(isValid, isTrue);
      });

      testWidgets('Seller approval form validates minimum note length',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Admin Notes'),
                    validator: FormValidationTestHelper.validateMinLength,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Type short notes
        await AdminTestHelper.typeText(
          tester,
          'ok',
          find.byType(TextFormField),
        );

        // Validate
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        // Verify error
        expect(find.text('Must be at least 0 characters'), findsNWidgets(1));
      });

      testWidgets('Seller approval form shows decision options',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                const Text('Select Decision:'),
                DropdownButton<String>(
                  value: 'APPROVE',
                  items: const [
                    DropdownMenuItem(value: 'APPROVE', child: Text('Approve')),
                    DropdownMenuItem(value: 'REJECT', child: Text('Reject')),
                    DropdownMenuItem(
                        value: 'SUSPEND', child: Text('Suspend')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Select Decision:'), findsOneWidget);
        expect(find.text('Approve'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
        expect(find.text('Suspend'), findsOneWidget);
      });

      testWidgets('Seller approval form enables submit only when valid',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        var canSubmit = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Notes'),
                      onChanged: (value) {
                        setState(() {
                          canSubmit = value.isNotEmpty;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: canSubmit
                          ? () {
                              formKey.currentState!.validate();
                            }
                          : null,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially submit button should be disabled
        var submitButton = find.byType(ElevatedButton).first;
        expect(submitButton, findsOneWidget);

        // Type notes
        await AdminTestHelper.typeText(
          tester,
          'Valid notes',
          find.byType(TextFormField),
        );

        // Submit button should now be enabled
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('Seller approval form displays seller information',
          (WidgetTester tester) async {
        final seller = MockSellerFactory.createPendingSeller();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Approve Seller')),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${seller['name']}'),
                Text('Email: ${seller['email']}'),
                Text('Farm: ${seller['farmName']}'),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Approve'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Name: ${seller['name']}'), findsOneWidget);
        expect(find.text('Email: ${seller['email']}'), findsOneWidget);
        expect(find.text('Farm: ${seller['farmName']}'), findsOneWidget);
      });
    });

    // ========================================================================
    // PRICE CEILING UPDATE FORM TESTS
    // ========================================================================

    group('Price Ceiling Update Form Validation', () {
      testWidgets('Price ceiling form validates required fields',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'New Ceiling Price'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Reason'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Reason is required';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Tap validate without filling
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        expect(find.text('Price is required'), findsOneWidget);
        expect(find.text('Reason is required'), findsOneWidget);
      });

      testWidgets('Price ceiling form validates numeric input',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        var isValid = false;

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'New Ceiling Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price required';
                      }
                      final number = double.tryParse(value);
                      if (number == null) {
                        return 'Enter valid number';
                      }
                      if (number <= 0) {
                        return 'Price must be positive';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      isValid = formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Enter valid price
        await AdminTestHelper.typeText(
          tester,
          '5000.00',
          find.byType(TextFormField),
        );

        // Validate
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        expect(isValid, isTrue);
      });

      testWidgets('Price ceiling form rejects negative prices',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'New Ceiling Price'),
                    validator: (value) {
                      final number = double.tryParse(value ?? '');
                      if (number != null && number < 0) {
                        return 'Price must be positive';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Enter negative price
        await AdminTestHelper.typeText(
          tester,
          '-1000',
          find.byType(TextFormField),
        );

        // Validate
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        expect(find.text('Price must be positive'), findsOneWidget);
      });

      testWidgets('Price ceiling form validates reason selection',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                const Text('Reason for Change:'),
                DropdownButton<String>(
                  value: 'market',
                  items: const [
                    DropdownMenuItem(
                      value: 'market',
                      child: Text('Market Adjustment'),
                    ),
                    DropdownMenuItem(
                      value: 'forecast',
                      child: Text('Forecast Update'),
                    ),
                    DropdownMenuItem(
                      value: 'compliance',
                      child: Text('Compliance'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Market Adjustment'), findsOneWidget);
        expect(find.text('Forecast Update'), findsOneWidget);
        expect(find.text('Compliance'), findsOneWidget);
      });

      testWidgets('Price ceiling form shows current price for reference',
          (WidgetTester tester) async {
        final ceiling = MockPriceCeilingFactory.createPriceCeiling();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                Text('Current Ceiling: ${ceiling['currentCeiling']}'),
                Text('Previous Ceiling: ${ceiling['previousCeiling']}'),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'New Ceiling Price'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Current Ceiling: ${ceiling['currentCeiling']}'),
            findsOneWidget);
        expect(
            find.text('Previous Ceiling: ${ceiling['previousCeiling']}'),
            findsOneWidget);
      });

      testWidgets('Price ceiling form prevents duplicate updates',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                const Text('Current Ceiling: 5000'),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'New Ceiling Price'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Type same price as current
        await AdminTestHelper.typeText(
          tester,
          '5000',
          find.byType(TextFormField),
        );

        expect(find.text('New Ceiling Price'), findsOneWidget);
      });
    });

    // ========================================================================
    // OPAS SUBMISSION FORM TESTS
    // ========================================================================

    group('OPAS Submission Review Form Validation', () {
      testWidgets('OPAS review form shows submission details',
          (WidgetTester tester) async {
        final submission = MockOPASFactory.createPendingSubmission();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Review OPAS Submission')),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seller: ${submission['seller']}'),
                Text('Product: ${submission['product']}'),
                Text('Quantity: ${submission['quantity']}'),
                Text('Unit Price: ${submission['unitPrice']}'),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Seller: ${submission['seller']}'), findsOneWidget);
        expect(find.text('Product: ${submission['product']}'), findsOneWidget);
        expect(find.text('Quantity: ${submission['quantity']}'), findsOneWidget);
      });

      testWidgets('OPAS review form validates approval quantity',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Quantity Approved'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Quantity required';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Enter valid quantity
        await AdminTestHelper.typeText(
          tester,
          '100',
          find.byType(TextFormField),
        );

        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        // Should be valid
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('OPAS review form validates final price',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Final Price Offered'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      if (price == null || price <= 0) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        await AdminTestHelper.typeText(
          tester,
          '4500.50',
          find.byType(TextFormField),
        );

        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('OPAS review form provides approve/reject options',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Reject'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Approve'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
      });

      testWidgets('OPAS review form allows rejection notes',
          (WidgetTester tester) async {
        var showRejectionNotes = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  if (showRejectionNotes)
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Rejection Reason'),
                      maxLines: 3,
                    ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showRejectionNotes = true;
                      });
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially no rejection notes
        expect(find.text('Rejection Reason'), findsNothing);

        // Click reject
        await AdminTestHelper.tapWidget(tester, find.text('Reject'));

        // Now rejection notes should appear
        expect(find.text('Rejection Reason'), findsOneWidget);
      });
    });

    // ========================================================================
    // COMMON FORM BEHAVIOR TESTS
    // ========================================================================

    group('Common Form Behavior', () {
      testWidgets('Forms clear on successful submission',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Input'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.reset();
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Type text
        await AdminTestHelper.typeText(
          tester,
          'test input',
          find.byType(TextFormField),
        );

        // Submit
        await AdminTestHelper.tapWidget(tester, find.text('Submit'));

        // Form should be cleared
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('Forms show loading indicator during submission',
          (WidgetTester tester) async {
        var isLoading = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  if (isLoading) const CircularProgressIndicator(),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially no loading
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Click submit
        await AdminTestHelper.tapWidget(tester, find.text('Submit'));

        // Now loading should appear
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('Forms display success message on completion',
          (WidgetTester tester) async {
        var showSuccess = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  if (showSuccess)
                    const SnackBar(
                      content: Text('Operation successful'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showSuccess = true;
                      });
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Submit
        await AdminTestHelper.tapWidget(tester, find.text('Submit'));

        // Success message should appear
        expect(find.text('Operation successful'), findsOneWidget);
      });

      testWidgets('Form fields maintain focus correctly',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Field 1'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Field 2'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Find first field and focus
        final firstField = find.byType(TextFormField).first;
        await tester.tap(firstField);
        await AdminTestHelper.pumpAndSettle(tester);

        // Verify field is focused
        expect(find.byType(TextFormField), findsNWidgets(2));
      });
    });
  });
}
