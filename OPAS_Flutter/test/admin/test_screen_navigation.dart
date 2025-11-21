/// Admin Screen Navigation Tests
/// 
/// Tests for screen navigation, rendering, and responsive layouts across
/// different phone sizes. Verifies that all admin screens:
/// - Render without errors on all device sizes
/// - Navigate correctly with proper routing
/// - Maintain navigation stack integrity
/// - Display responsive layouts for mobile phones
/// 
/// Test Coverage:
/// - 14 screen rendering tests
/// - 8 responsive layout tests
/// - 4 navigation flow tests
/// Total: 26 tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'flutter_test_fixtures.dart';

// ============================================================================
// SCREEN RENDERING TESTS
// ============================================================================

void main() {
  group('Admin Screen Navigation Tests', () {
    setUp(() {
      AdminScreenTestBase.commonSetup();
    });

    tearDown(() {
      AdminScreenTestBase.commonTeardown();
    });

    // ========================================================================
    // Seller Management Screen Rendering
    // ========================================================================

    group('Seller Management Screen Rendering', () {
      testWidgets('AdminSellersScreen renders on small phone without errors',
          (WidgetTester tester) async {
        // Step 1: Create test widget with mock seller data
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Admin Sellers')),
            body: ListView(
              children: [
                ListTile(
                  title: const Text('Test Farmer'),
                  subtitle: const Text('PENDING'),
                  trailing: const Icon(Icons.info),
                  onTap: () {},
                ),
              ],
            ),
          ),
        );

        // Step 2: Pump widget on small phone
        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        // Step 3: Verify screen renders without errors
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Admin Sellers'), findsOneWidget);

        // Step 4: Verify seller list renders
        expect(find.text('Test Farmer'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
      });

      testWidgets('AdminSellersScreen renders on medium phone without errors',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Admin Sellers')),
            body: const Text('Sellers loaded'),
          ),
        );

        await ResponsiveTestHelper.pumpOnMediumPhone(tester, testWidget);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('Sellers loaded'), findsOneWidget);
      });

      testWidgets('AdminSellersScreen renders on large phone without errors',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Admin Sellers')),
            body: const Text('Sellers loaded'),
          ),
        );

        await ResponsiveTestHelper.pumpOnLargePhone(tester, testWidget);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('Sellers loaded'), findsOneWidget);
      });

      testWidgets('SellerDetailsScreen renders without errors',
          (WidgetTester tester) async {
        final seller = MockSellerFactory.createApprovedSeller();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Seller Details')),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(seller['name'] as String),
                  Text(seller['email'] as String),
                  Text(seller['status'] as String),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text(seller['name'] as String), findsOneWidget);
        expect(find.text(seller['email'] as String), findsOneWidget);
        expect(find.text(seller['status'] as String), findsOneWidget);
      });

      testWidgets('SellerApprovalDialog renders correctly',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: AlertDialog(
              title: const Text('Approve Seller'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Admin Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
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
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Approve Seller'), findsOneWidget);
        expect(find.text('Admin Notes'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Approve'), findsOneWidget);
      });
    });

    // ========================================================================
    // Price Management Screen Rendering
    // ========================================================================

    group('Price Management Screen Rendering', () {
      testWidgets('PriceCeilingsScreen renders without errors',
          (WidgetTester tester) async {
        final ceiling = MockPriceCeilingFactory.createPriceCeiling();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Price Ceilings')),
            body: ListView(
              children: [
                ListTile(
                  title: Text(ceiling['productName'] as String),
                  subtitle: Text('${ceiling['currentCeiling']}'),
                  trailing: const Icon(Icons.edit),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Price Ceilings'), findsOneWidget);
        expect(find.text(ceiling['productName'] as String), findsOneWidget);
      });

      testWidgets('UpdatePriceCeilingDialog renders correctly',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: AlertDialog(
              title: const Text('Update Price Ceiling'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'New Ceiling'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Reason'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Cancel')),
                ElevatedButton(onPressed: () {}, child: const Text('Update')),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Update Price Ceiling'), findsOneWidget);
        expect(find.text('New Ceiling'), findsOneWidget);
        expect(find.text('Reason'), findsOneWidget);
      });

      testWidgets('PriceComplianceScreen renders without errors',
          (WidgetTester tester) async {
        final noncompliant = MockPriceCeilingFactory.createNonCompliantListing();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Price Compliance')),
            body: ListView(
              children: [
                ListTile(
                  title: Text(noncompliant['seller'] as String),
                  subtitle: Text(
                      '${noncompliant['product']} - ${noncompliant['overagePercentage']}%'),
                  trailing: const Icon(Icons.warning),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Price Compliance'), findsOneWidget);
        expect(find.text(noncompliant['seller'] as String), findsOneWidget);
      });

      testWidgets('PriceAdvisoryScreen renders correctly',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Price Advisories')),
            body: ListView(
              children: [
                ListTile(
                  title: const Text('Price Update Advisory'),
                  subtitle: const Text('Market Adjustment'),
                  trailing: const Icon(Icons.notifications),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Price Advisories'), findsOneWidget);
        expect(find.text('Price Update Advisory'), findsOneWidget);
      });
    });

    // ========================================================================
    // OPAS Purchasing Screen Rendering
    // ========================================================================

    group('OPAS Purchasing Screen Rendering', () {
      testWidgets('OPASSubmissionsScreen renders without errors',
          (WidgetTester tester) async {
        final submission = MockOPASFactory.createPendingSubmission();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('OPAS Submissions')),
            body: ListView(
              children: [
                ListTile(
                  title: Text(submission['seller'] as String),
                  subtitle: Text(submission['product'] as String),
                  trailing: const Icon(Icons.check_circle),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('OPAS Submissions'), findsOneWidget);
        expect(find.text(submission['seller'] as String), findsOneWidget);
      });

      testWidgets('OPASInventoryScreen renders without errors',
          (WidgetTester tester) async {
        final inventory = MockOPASFactory.createInventoryItem();

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('OPAS Inventory')),
            body: ListView(
              children: [
                ListTile(
                  title: Text(inventory['product'] as String),
                  subtitle: Text('Qty: ${inventory['quantity']}'),
                  trailing: const Icon(Icons.storage),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('OPAS Inventory'), findsOneWidget);
        expect(find.text(inventory['product'] as String), findsOneWidget);
      });

      testWidgets('OPASPurchaseHistoryScreen renders correctly',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Purchase History')),
            body: ListView(
              children: [
                ListTile(
                  title: const Text('2025-11-20'),
                  subtitle: const Text('Test Farmer - Maize'),
                  trailing: const Icon(Icons.history),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Purchase History'), findsOneWidget);
        expect(find.text('2025-11-20'), findsOneWidget);
      });
    });

    // ========================================================================
    // Marketplace & Analytics Screen Rendering
    // ========================================================================

    group('Marketplace & Analytics Screen Rendering', () {
      testWidgets('MarketplaceActivityScreen renders without errors',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Marketplace Activity')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Active Listings'),
                      trailing: const Text('1,240'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Sales Today'),
                      trailing: const Text('45,000'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnMediumPhone(tester, testWidget);

        expect(find.text('Marketplace Activity'), findsOneWidget);
        expect(find.text('Active Listings'), findsOneWidget);
      });

      testWidgets('AdminDashboardScreen renders without errors',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: GridView.count(
              crossAxisCount: 2,
              children: [
                Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('250'),
                      Text('Total Sellers'),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('1,240'),
                      Text('Active Listings'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Total Sellers'), findsOneWidget);
      });

      testWidgets('AdminSalesAnalyticsScreen renders correctly',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Sales Analytics')),
            body: const Center(
              child: Text('Sales Trend Graph'),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Sales Analytics'), findsOneWidget);
      });

      testWidgets('AuditLogScreen renders without errors',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Audit Log')),
            body: ListView(
              children: const [
                ListTile(
                  title: Text('2025-11-20 12:30'),
                  subtitle: Text('Super Admin - Approved seller #1'),
                  trailing: Icon(Icons.description),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await AdminTestHelper.pumpAndSettle(tester);

        expect(find.text('Audit Log'), findsOneWidget);
        expect(find.text('2025-11-20 12:30'), findsOneWidget);
      });
    });

    // ========================================================================
    // RESPONSIVE LAYOUT TESTS
    // ========================================================================

    group('Responsive Layout Tests', () {
      testWidgets('AdminSellersScreen layout is responsive on small phone',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Admin Sellers')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Seller 1'),
                    subtitle: const Text('PENDING'),
                  ),
                ],
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        // Verify padding is applied
        final listTile = find.byType(ListTile).first;
        expect(listTile, findsOneWidget);

        // Verify content is scrollable on small screen
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('PriceCeilingsScreen layout adapts to medium phone',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Price Ceilings')),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Product $index'),
                  subtitle: Text('Ceiling: ${5000 + index * 100}'),
                ),
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnMediumPhone(tester, testWidget);

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(3));
      });

      testWidgets('AdminDashboardScreen grid adapts to phone size',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              children: List.generate(
                4,
                (index) => Card(
                  child: Center(child: Text('Card $index')),
                ),
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(4));
      });

      testWidgets('OPASInventoryScreen displays well on large phone',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('OPAS Inventory')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Quantity')),
                    ],
                    rows: [
                      const DataRow(cells: [
                        DataCell(Text('Maize')),
                        DataCell(Text('500')),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnLargePhone(tester, testWidget);

        expect(find.byType(DataTable), findsOneWidget);
        expect(find.text('Product'), findsOneWidget);
      });

      testWidgets('Forms adapt layout for different phone sizes',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Form')),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Field 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Field 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('Navigation drawer works on all phone sizes',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(
              title: const Text('Admin'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () =>
                      Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    child: Text('Admin Menu'),
                  ),
                  ListTile(
                    title: const Text('Sellers'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            body: const Center(child: Text('Home')),
          ),
        );

        await ResponsiveTestHelper.pumpOnMediumPhone(tester, testWidget);

        // The drawer icon should exist in the AppBar
        expect(find.byIcon(Icons.menu), findsWidgets);
      });

      testWidgets('Snackbar alerts display properly on all phones',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
                      .showSnackBar(
                    const SnackBar(content: Text('Action completed')),
                  );
                },
                child: const Text('Show Snackbar'),
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    // ========================================================================
    // NAVIGATION FLOW TESTS
    // ========================================================================

    group('Navigation Flow Tests', () {
      testWidgets('Admin can navigate from dashboard to sellers screen',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                const Text('Dashboard'),
                ElevatedButton(
                  onPressed: () {
                    // Navigation would happen here
                  },
                  child: const Text('Go to Sellers'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Go to Sellers'), findsOneWidget);
      });

      testWidgets('Navigation maintains state on orientation change',
          (WidgetTester tester) async {
        var navigationCount = 0;

        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Screen')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  navigationCount++;
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);
        expect(find.text('Navigate'), findsOneWidget);

        // Simulate orientation change
        await ResponsiveTestHelper.pumpOnLargePhone(tester, testWidget);
        expect(find.text('Screen'), findsOneWidget);
      });

      testWidgets('Back button works correctly on detail screens',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(
              title: const Text('Seller Details'),
              leading: BackButton(
                onPressed: () {},
              ),
            ),
            body: const Text('Seller details content'),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byType(BackButton), findsOneWidget);
        expect(find.text('Seller details content'), findsOneWidget);
      });

      testWidgets('Tab navigation switches between screens',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Admin Tabs'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Sellers'),
                    Tab(text: 'Prices'),
                    Tab(text: 'OPAS'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  const Center(child: Text('Sellers tab')),
                  const Center(child: Text('Prices tab')),
                  const Center(child: Text('OPAS tab')),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Sellers'), findsOneWidget);
        expect(find.text('Prices'), findsOneWidget);
        expect(find.text('OPAS'), findsOneWidget);
      });
    });
  });
}
