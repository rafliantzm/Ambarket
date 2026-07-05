import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';

void main() {
  testWidgets('AdminDashboardScreen shows stats', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardStatsProvider.overrideWith((ref) => Future.value({
            'pendingReports': 10,
            'totalUsers': 50,
            'totalProducts': 100,
          })),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to settle Future
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // Pending reports
    expect(find.text('50'), findsOneWidget); // Total users
    expect(find.text('100'), findsOneWidget); // Total products
    // List tiles might be off-screen in the test environment due to lazy loading
    // So we don't strictly require finding them all by text without scrolling.
    expect(find.byType(ListTile), findsWidgets);
  });
}
