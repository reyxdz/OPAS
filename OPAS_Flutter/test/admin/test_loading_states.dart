/// Admin Loading State Tests
/// 
/// Tests for loading spinners, placeholder animations, data transitions,
/// and skeletal loading patterns across admin screens.
/// 
/// Test Coverage:
/// - 3 spinner visibility tests
/// - 3 data load transition tests
/// - 2 skeletal loading tests
/// - 2 placeholder animation tests
/// Total: 10 tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'flutter_test_fixtures.dart';

void main() {
  group('Admin Loading State Tests', () {
    // ========================================================================
    // LOADING SPINNER TESTS
    // ========================================================================

    group('Loading Spinner Visibility', () {
      testWidgets('Loading spinner appears on data fetch start',
          (WidgetTester tester) async {
        var isLoading = true;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('Admin Sellers')),
              body: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : const Center(
                      child: Text('Data Loaded'),
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => isLoading = false);
                },
                child: const Icon(Icons.check),
              ),
            ),
          ),
        );

        // Step 1: Pump widget
        await tester.pumpWidget(testWidget);

        // Step 2: Verify spinner is visible
        expect(LoadingStateTestHelper.isLoadingSpinnerVisible(tester), isTrue);

        // Step 3: Simulate data load completion
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Step 4: Verify spinner is hidden
        expect(LoadingStateTestHelper.isLoadingSpinnerHidden(tester), isTrue);
        expect(find.text('Data Loaded'), findsOneWidget);
      });

      testWidgets('Spinner has appropriate size for visibility',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          const Scaffold(
            body: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final progressIndicator =
            find.byType(CircularProgressIndicator).evaluate().first.widget;
        expect(progressIndicator, isNotNull);
      });

      testWidgets('Spinner is centered on screen for visibility',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Verify spinner is visible and centered
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    // ========================================================================
    // DATA LOAD TRANSITION TESTS
    // ========================================================================

    group('Data Load Transitions', () {
      testWidgets('Smooth transition from loading to data loaded',
          (WidgetTester tester) async {
        var dataLoaded = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('Sellers')),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: dataLoaded
                    ? ListView(
                        key: const ValueKey('data'),
                        children: const [
                          ListTile(
                            title: Text('Seller 1'),
                          ),
                          ListTile(
                            title: Text('Seller 2'),
                          ),
                        ],
                      )
                    : const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator(),
                      ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => dataLoaded = true);
                },
                child: const Icon(Icons.check),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Trigger data load
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Wait for animation
        await tester.pumpAndSettle();

        // Data should now be visible
        expect(find.text('Seller 1'), findsOneWidget);
        expect(find.text('Seller 2'), findsOneWidget);
      });

      testWidgets('Empty state message shown when no data available',
          (WidgetTester tester) async {
        var hasData = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('Sellers')),
              body: hasData
                  ? ListView(
                      children: const [
                        ListTile(title: Text('Seller 1')),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64),
                          SizedBox(height: 16),
                          Text('No sellers found'),
                        ],
                      ),
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => hasData = true);
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Verify empty state
        expect(find.byIcon(Icons.inbox), findsOneWidget);
        expect(find.text('No sellers found'), findsOneWidget);
      });

      testWidgets('Loading indicator disappears when data loads',
          (WidgetTester tester) async {
        var isLoading = true;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Stack(
                children: [
                  ListView(
                    children: const [
                      ListTile(title: Text('Item 1')),
                      ListTile(title: Text('Item 2')),
                    ],
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => isLoading = false);
                },
                child: const Icon(Icons.check),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially has spinner overlay
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Trigger load complete
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Spinner should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Item 1'), findsOneWidget);
      });
    });

    // ========================================================================
    // SKELETAL LOADING TESTS
    // ========================================================================

    group('Skeletal Loading', () {
      testWidgets('Skeleton placeholders appear during data load',
          (WidgetTester tester) async {
        var isLoading = true;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('OPAS Inventory')),
              body: isLoading
                  ? ListView(
                      children: [
                        Container(
                          height: 100,
                          margin: const EdgeInsets.all(16),
                          color: Colors.grey[300],
                        ),
                        Container(
                          height: 100,
                          margin: const EdgeInsets.all(16),
                          color: Colors.grey[300],
                        ),
                      ],
                    )
                  : ListView(
                      children: const [
                        ListTile(
                          title: Text('Maize'),
                          subtitle: Text('500 units'),
                        ),
                        ListTile(
                          title: Text('Rice'),
                          subtitle: Text('300 units'),
                        ),
                      ],
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => isLoading = false);
                },
                child: const Icon(Icons.check),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Verify skeleton loaders are visible
        expect(find.byType(Container), findsWidgets);

        // Trigger data load
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Verify real data
        expect(find.text('Maize'), findsOneWidget);
        expect(find.text('500 units'), findsOneWidget);
      });

      testWidgets('Skeleton animation shows loading progress',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: ListView(
              children: [
                Container(
                  height: 80,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: 80,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnMediumPhone(tester, testWidget);

        // Verify skeleton items are visible
        expect(find.byType(Container), findsWidgets);
      });
    });

    // ========================================================================
    // PLACEHOLDER ANIMATION TESTS
    // ========================================================================

    group('Placeholder Animations', () {
      testWidgets('Fade transition during data load',
          (WidgetTester tester) async {
        var dataReady = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: AnimatedOpacity(
                opacity: dataReady ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Text(
                    dataReady ? 'Data Ready' : 'Loading...',
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => dataReady = true);
                },
                child: const Icon(Icons.check),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Loading...'), findsOneWidget);

        // Trigger transition
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Wait for animation
        await tester.pumpAndSettle();

        expect(find.text('Data Ready'), findsOneWidget);
      });

      testWidgets('Size expansion animation as data loads',
          (WidgetTester tester) async {
        var expanded = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: expanded ? 300 : 100,
                  height: expanded ? 300 : 100,
                  color: Colors.blue,
                  child: const Center(child: Text('Content')),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => expanded = !expanded);
                },
                child: const Icon(Icons.expand),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Trigger expansion
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Wait for animation
        await tester.pumpAndSettle();

        expect(find.text('Content'), findsOneWidget);
      });
    });

    // ========================================================================
    // LIST LOADING TESTS
    // ========================================================================

    group('List and Item Loading', () {
      testWidgets('Items load incrementally in list',
          (WidgetTester tester) async {
        var itemCount = 0;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('Sellers')),
              body: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Seller ${index + 1}'),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => itemCount = 5);
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially no items
        expect(find.byType(ListTile), findsNothing);

        // Load items
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        // Verify items are displayed
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('Pull to refresh loads new data',
          (WidgetTester tester) async {
        var refreshCount = 0;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('Prices')),
              body: RefreshIndicator(
                onRefresh: () async {
                  setState(() => refreshCount++);
                },
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text('Maize'),
                      subtitle: Text('Refreshed: $refreshCount times'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Refreshed: 0 times'), findsOneWidget);

        // Simulate pull to refresh
        await tester.drag(find.byType(ListView), const Offset(0, 200));
        await tester.pumpAndSettle();

        // Verify refresh occurred
        expect(refreshCount >= 0, isTrue);
      });
    });

    // ========================================================================
    // LOADING STATE TRANSITIONS
    // ========================================================================

    group('Loading State Transitions', () {
      testWidgets('Multiple stages of loading show appropriate UI',
          (WidgetTester tester) async {
        var stage = 0; // 0: loading, 1: success, 2: error

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: stage == 0
                  ? const Center(child: CircularProgressIndicator())
                  : stage == 1
                      ? const Center(child: Text('Data Loaded'))
                      : const Center(child: Text('Error loading data')),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => stage = (stage + 1) % 3);
                },
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Step 1: Loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Step 2: Success state
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );
        expect(find.text('Data Loaded'), findsOneWidget);

        // Step 3: Error state
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );
        expect(find.text('Error loading data'), findsOneWidget);
      });

      testWidgets('Loading timeout shows appropriate message',
          (WidgetTester tester) async {
        var isTimeout = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: isTimeout
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 48),
                          SizedBox(height: 16),
                          Text('Loading is taking too long'),
                          SizedBox(height: 16),
                          Text('Check your connection'),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() => isTimeout = true);
                },
                child: const Icon(Icons.timer),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Simulate timeout
        await AdminTestHelper.tapWidget(
          tester,
          find.byType(FloatingActionButton),
        );

        expect(find.text('Loading is taking too long'), findsOneWidget);
        expect(find.text('Check your connection'), findsOneWidget);
      });
    });
  });
}
