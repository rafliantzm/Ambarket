import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';

import 'package:ambarket_mobile/core/widgets/app_loading_skeleton.dart';

void main() {
  testWidgets('AdminDashboardScreen shows stats', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardStatsProvider.overrideWith(
            (ref) => Future.value({
              'pendingReports': 10,
              'totalUsers': 50,
              'totalProducts': 100,
            }),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );

    // Initial loading state
    expect(find.byType(AppLoadingSkeleton), findsOneWidget);

    // Pump to settle Future
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // Pending reports
    expect(find.text('50'), findsOneWidget); // Total users
    expect(find.text('100'), findsOneWidget); // Total products
    // We don't use ListTile anymore in the new UI, we use custom AppGlassCard tiles.
    await tester.scrollUntilVisible(
      find.text('Moderasi Produk'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Moderasi Produk'), findsOneWidget);
  });
}
