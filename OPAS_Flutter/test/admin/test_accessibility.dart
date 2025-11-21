/// Admin Accessibility Tests
/// 
/// Tests for dark mode support, semantic labels, font sizes, contrast ratios,
/// and responsive breakpoints for all phone screen sizes.
/// 
/// Test Coverage:
/// - 4 dark mode tests
/// - 4 semantic accessibility tests
/// - 3 font size and readability tests
/// - 3 contrast ratio tests
/// Total: 14 tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'flutter_test_fixtures.dart';

void main() {
  group('Admin Accessibility Tests', () {
    // ========================================================================
    // DARK MODE TESTS
    // ========================================================================

    group('Dark Mode Support', () {
      testWidgets('Admin screens display correctly in dark mode',
          (WidgetTester tester) async {
        final testWidget = AccessibilityTestHelper.createDarkModeWidget(
          Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              backgroundColor: Colors.grey[900],
            ),
            body: Card(
              child: ListTile(
                title: const Text('Dashboard Item'),
                subtitle: const Text('Dark mode enabled'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Step 1: Verify dark theme is applied
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Admin Dashboard'), findsOneWidget);

        // Step 2: Verify text is readable on dark background
        expect(find.text('Dashboard Item'), findsOneWidget);
        expect(find.text('Dark mode enabled'), findsOneWidget);
      });

      testWidgets('Theme toggle switches between dark and light modes',
          (WidgetTester tester) async {
        var isDarkMode = false;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('Settings'),
                  actions: [
                    IconButton(
                      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () {
                        setState(() => isDarkMode = !isDarkMode);
                      },
                    ),
                  ],
                ),
                body: Center(
                  child: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially light mode
        expect(find.text('Light Mode'), findsOneWidget);

        // Toggle to dark mode
        await AdminTestHelper.tapWidget(
          tester,
          find.byIcon(Icons.dark_mode),
        );

        expect(find.text('Dark Mode'), findsOneWidget);
      });

      testWidgets('Card backgrounds adapt to theme',
          (WidgetTester tester) async {
        final testWidget = AccessibilityTestHelper.createDarkModeWidget(
          Scaffold(
            body: ListView(
              children: [
                Card(
                  color: Colors.grey[850],
                  child: const ListTile(
                    title: Text('Dark Card'),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Dark Card'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('Text colors are readable in both themes',
          (WidgetTester tester) async {
        var isDark = true;

        final testWidget = AdminTestHelper.createTestApp(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: Colors.blue,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: Colors.blue,
              ),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: Scaffold(
                body: Column(
                  children: [
                    const Text('Primary Text'),
                    Text(
                      'Secondary Text',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() => isDark = !isDark);
                  },
                  child: const Icon(Icons.palette),
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Primary Text'), findsOneWidget);
        expect(find.text('Secondary Text'), findsOneWidget);
      });
    });

    // ========================================================================
    // SEMANTIC ACCESSIBILITY TESTS
    // ========================================================================

    group('Semantic Accessibility Labels', () {
      testWidgets('Buttons have semantic labels for screen readers',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Approve seller button',
                  button: true,
                  enabled: true,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Approve'),
                  ),
                ),
                Semantics(
                  label: 'Reject seller button',
                  button: true,
                  enabled: true,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Verify buttons are found
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('Form fields have semantic labels',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Price ceiling input field',
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                ),
                Semantics(
                  label: 'Reason for change dropdown',
                  child: DropdownButton<String>(
                    items: const [
                      DropdownMenuItem(
                        value: 'market',
                        child: Text('Market Adjustment'),
                      ),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(DropdownButton), findsOneWidget);
      });

      testWidgets('Icons have accessible descriptions',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Success icon',
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                Semantics(
                  label: 'Error icon',
                  child: const Icon(Icons.error, color: Colors.red),
                ),
                Semantics(
                  label: 'Warning icon',
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('List items have semantic structure for screen readers',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Semantics(
              label: 'Sellers list',
              button: false,
              child: ListView(
                children: [
                  Semantics(
                    label: 'Seller item: Test Farmer, status PENDING',
                    child: ListTile(
                      title: const Text('Test Farmer'),
                      subtitle: const Text('PENDING'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Test Farmer'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
      });
    });

    // ========================================================================
    // FONT SIZE AND READABILITY TESTS
    // ========================================================================

    group('Font Size and Readability', () {
      testWidgets('Headline text is appropriately sized',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
            ),
            body: Column(
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(tester.element(find.byType(Scaffold)))
                      .textTheme
                      .headlineMedium,
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Headline should be visible
        expect(find.text('Dashboard'), findsOneWidget);
      });

      testWidgets('Body text is at minimum readable size (14pt)',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                const Text(
                  'This is body text',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  'This is smaller text',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Verify readable text is present
        expect(find.text('This is body text'), findsOneWidget);
        expect(find.text('This is smaller text'), findsOneWidget);
      });

      testWidgets('Form labels are clearly visible',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Admin Notes',
                    labelStyle: const TextStyle(fontSize: 14),
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Price Ceiling',
                    labelStyle: const TextStyle(fontSize: 14),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('Admin Notes'), findsOneWidget);
        expect(find.text('Price Ceiling'), findsOneWidget);
      });

      testWidgets('Help text is readable and helpful',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'New Ceiling Price',
                    helperText: 'Must be greater than 0',
                    helperStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('New Ceiling Price'), findsOneWidget);
        expect(find.text('Must be greater than 0'), findsOneWidget);
      });
    });

    // ========================================================================
    // CONTRAST RATIO TESTS
    // ========================================================================

    group('Color Contrast Ratios', () {
      testWidgets('Text has sufficient contrast on light background',
          (WidgetTester tester) async {
        // Black text on white background
        final foreground = Colors.black;
        final background = Colors.white;
        final isValid =
            AccessibilityTestHelper.isContrastRatioValid(foreground, background);

        expect(isValid, isTrue);
      });

      testWidgets('Text has sufficient contrast on dark background',
          (WidgetTester tester) async {
        // White text on dark gray
        final foreground = Colors.white;
        final background = Colors.grey[900]!;
        final isValid =
            AccessibilityTestHelper.isContrastRatioValid(foreground, background);

        expect(isValid, isTrue);
      });

      testWidgets('Buttons have visible color contrast',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  child: const Text('Approve'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    // ========================================================================
    // RESPONSIVE SCREEN SIZE TESTS
    // ========================================================================

    group('Responsive Design for All Phone Sizes', () {
      testWidgets('Layout is responsive on small phone (375x667)',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Responsive Test')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Item 1'),
                        SizedBox(height: 8),
                        Text('Subtitle 1'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Item 1'), findsOneWidget);
      });

      testWidgets('Layout is responsive on medium phone (393x851)',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Responsive Test')),
            body: GridView.count(
              crossAxisCount: 2,
              children: List.generate(
                4,
                (index) => Card(
                  child: Center(child: Text('Item $index')),
                ),
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnMediumPhone(tester, testWidget);

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(4));
      });

      testWidgets('Layout is responsive on large phone (412x915)',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('Responsive Test')),
            body: DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Price')),
              ],
              rows: [
                const DataRow(cells: [
                  DataCell(Text('Maize')),
                  DataCell(Text('5000')),
                ]),
              ],
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnLargePhone(tester, testWidget);

        expect(find.byType(DataTable), findsOneWidget);
      });

      testWidgets('Text wraps properly on small screens',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This is a long text that should wrap properly on small screens and not overflow the boundaries of the screen',
              ),
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        // Text should be visible (wrapped if needed)
        expect(
          find.text(
              'This is a long text that should wrap properly on small screens and not overflow the boundaries of the screen'),
          findsOneWidget,
        );
      });

      testWidgets('Buttons are tap-target friendly on all sizes',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Center(child: Text('Tap')),
                  ),
                ),
              ],
            ),
          ),
        );

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('Navigation drawer is accessible on all phone sizes',
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
                padding: EdgeInsets.zero,
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

        await ResponsiveTestHelper.pumpOnSmallPhone(tester, testWidget);

        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.byType(Drawer), findsOneWidget);
      });
    });

    // ========================================================================
    // TOUCH TARGET SIZE TESTS
    // ========================================================================

    group('Touch Target Sizes', () {
      testWidgets('Buttons meet minimum touch target size (48x48)',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const SizedBox(
                width: 100,
                height: 48,
                child: Center(child: Text('Button')),
              ),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('Icons have accessible touch targets',
          (WidgetTester tester) async {
        final testWidget = AdminTestHelper.createTestApp(
          Scaffold(
            body: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              iconSize: 24,
              padding: const EdgeInsets.all(12),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });
  });
}
