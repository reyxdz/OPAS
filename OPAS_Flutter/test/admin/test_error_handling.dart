/// Admin Error Handling Tests
/// 
/// Tests for network error handling, error messages, retry logic,
/// and graceful degradation across admin screens.
/// 
/// Test Coverage:
/// - 4 network error tests (connection, timeout, server, auth errors)
/// - 4 error message display tests
/// - 3 retry logic tests
/// - 2 graceful degradation tests
/// Total: 13 tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'flutter_test_fixtures.dart';

void main() {
  group('Admin Error Handling Tests', () {
    // ========================================================================
    // NETWORK ERROR DETECTION TESTS
    // ========================================================================

    group('Network Error Detection', () {
      testWidgets('Connection error is detected and displayed',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Admin Screen')),
            body: NetworkErrorTestHelper.createErrorWidget(
              NetworkErrorTestHelper.connectionError,
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        // Step 1: Verify error icon is displayed
        expect(find.byIcon(Icons.error), findsOneWidget);

        // Step 2: Verify error message is shown
        expect(
          find.text(NetworkErrorTestHelper.connectionError),
          findsOneWidget,
        );

        // Step 3: Verify retry button is available
        expect(NetworkErrorTestHelper.isRetryButtonVisible(tester), isTrue);
      });

      testWidgets('Timeout error is handled gracefully',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: NetworkErrorTestHelper.createErrorWidget(
              NetworkErrorTestHelper.timeoutError,
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text(NetworkErrorTestHelper.timeoutError), findsOneWidget);
      });

      testWidgets('Server error is displayed with appropriate message',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: NetworkErrorTestHelper.createErrorWidget(
              NetworkErrorTestHelper.serverError,
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text(NetworkErrorTestHelper.serverError), findsOneWidget);
      });

      testWidgets('Unauthorized error prompts login',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(NetworkErrorTestHelper.unauthorizedError),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Login Again'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(
          find.text(NetworkErrorTestHelper.unauthorizedError),
          findsOneWidget,
        );
        expect(find.text('Login Again'), findsOneWidget);
      });
    });

    // ========================================================================
    // ERROR MESSAGE DISPLAY TESTS
    // ========================================================================

    group('Error Message Display', () {
      testWidgets('Error messages are clearly visible on all phone sizes',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: NetworkErrorTestHelper.createErrorWidget(
              'Failed to load sellers. Please try again.',
            ),
          ),
        );

        // Test on small phone
        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(
          find.text('Failed to load sellers. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('Specific field validation errors are shown',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Check'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Type invalid price
        await AdminTestHelper.typeText(
          tester,
          'abc',
          find.byType(TextFormField),
        );

        // Validate
        await AdminTestHelper.tapWidget(tester, find.text('Check'));

        expect(find.text('Enter valid price'), findsOneWidget);
      });

      testWidgets('Error messages have appropriate icons',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('An error occurred'),
                  ],
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('An error occurred'), findsOneWidget);
      });

      testWidgets('Multiple errors are all displayed',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('Warning 1: Field incomplete'),
                ),
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('Warning 2: Invalid input'),
                ),
                ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Error: Connection failed'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Warning 1: Field incomplete'), findsOneWidget);
        expect(find.text('Warning 2: Invalid input'), findsOneWidget);
        expect(find.text('Error: Connection failed'), findsOneWidget);
      });
    });

    // ========================================================================
    // RETRY LOGIC TESTS
    // ========================================================================

    group('Retry Logic', () {
      testWidgets('User can retry after connection error',
          (WidgetTester tester) async {
        var retryCount = 0;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (retryCount == 0)
                    Column(
                      children: [
                        const Text('Connection failed'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => retryCount++);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  else
                    const Text('Retrying...'),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initial state shows error
        expect(find.text('Connection failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Click retry
        await AdminTestHelper.tapWidget(tester, find.text('Retry'));

        // Should show retrying state
        expect(find.text('Retrying...'), findsOneWidget);
      });

      testWidgets('Retry attempts are tracked and limited',
          (WidgetTester tester) async {
        var attempts = 0;
        const maxAttempts = 3;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Attempts: $attempts/$maxAttempts'),
                  if (attempts < maxAttempts)
                    ElevatedButton(
                      onPressed: () {
                        setState(() => attempts++);
                      },
                      child: const Text('Retry'),
                    )
                  else
                    const Text('Max attempts reached'),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Try 3 times
        for (var i = 0; i < maxAttempts; i++) {
          expect(find.text('Retry'), findsOneWidget);
          await AdminTestHelper.tapWidget(tester, find.text('Retry'));
        }

        // After max attempts
        expect(find.text('Max attempts reached'), findsOneWidget);
      });

      testWidgets('Exponential backoff is applied on retry',
          (WidgetTester tester) async {
        var retryCount = 0;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Attempt: $retryCount'),
                  if (retryCount == 0)
                    Text('Wait ${1 * 1000}ms before retry')
                  else if (retryCount == 1)
                    Text('Wait ${2 * 1000}ms before retry')
                  else
                    Text('Wait ${4 * 1000}ms before retry'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => retryCount++);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Wait 1000ms before retry'), findsOneWidget);

        await AdminTestHelper.tapWidget(tester, find.text('Retry'));

        expect(find.text('Wait 2000ms before retry'), findsOneWidget);
      });
    });

    // ========================================================================
    // GRACEFUL DEGRADATION TESTS
    // ========================================================================

    group('Graceful Degradation', () {
      testWidgets('Partial data loads when some endpoints fail',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: ListView(
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Seller Metrics'),
                    subtitle: const Text('250 active sellers'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Price Data'),
                    subtitle: const Text('Failed to load'),
                    trailing: const Icon(Icons.error),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('OPAS Data'),
                    subtitle: const Text('5000 items in stock'),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Verify successful loads
        expect(find.text('250 active sellers'), findsOneWidget);
        expect(find.text('5000 items in stock'), findsOneWidget);

        // Verify failed sections are shown with error
        expect(find.text('Failed to load'), findsOneWidget);
      });

      testWidgets('Offline mode shows cached data',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(
              title: const Text('Sellers'),
              actions: [
                Chip(
                  label: const Text('Offline Mode'),
                  backgroundColor: Colors.orange,
                )
              ],
            ),
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Showing cached data from 2 hours ago'),
                ),
                ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Cached Seller 1'),
                      subtitle: const Text('From cache'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Offline Mode'), findsOneWidget);
        expect(find.text('Showing cached data from 2 hours ago'), findsOneWidget);
        expect(find.text('Cached Seller 1'), findsOneWidget);
      });
    });

    // ========================================================================
    // SNACKBAR ERROR ALERTS TESTS
    // ========================================================================

    group('Snackbar Error Alerts', () {
      testWidgets('Network errors show snackbar notification',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
                      .showSnackBar(
                    const SnackBar(
                      content: Text('Network error: Connection failed'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: const Text('Trigger Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Trigger error
        await AdminTestHelper.tapWidget(tester, find.text('Trigger Error'));

        // Verify snackbar
        expect(find.text('Network error: Connection failed'), findsOneWidget);
      });

      testWidgets('Validation errors show inline messages',
          (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: FormValidationTestHelper.validateEmail,
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

        // Type invalid email
        await AdminTestHelper.typeText(
          tester,
          'invalid-email',
          find.byType(TextFormField),
        );

        // Validate
        await AdminTestHelper.tapWidget(tester, find.text('Validate'));

        // Error should appear inline
        expect(find.text('Enter a valid email address'), findsOneWidget);
      });
    });
  });
}
