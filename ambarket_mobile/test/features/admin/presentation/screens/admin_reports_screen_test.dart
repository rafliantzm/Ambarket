import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:ambarket_mobile/core/widgets/ambarket_loaders.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';

class MockAdminReportsNotifier extends AsyncNotifier<PaginatedAdminReportsState>
    implements AdminReportsNotifier {
  final List<ReportModel> mockData;
  MockAdminReportsNotifier(this.mockData);

  @override
  Future<PaginatedAdminReportsState> build() async {
    return PaginatedAdminReportsState(items: mockData, hasMore: false);
  }

  @override
  Future<void> loadMore() async {}
}

void main() {
  testWidgets('AdminReportsScreen shows empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminReportsProvider.overrideWith(() => MockAdminReportsNotifier([])),
        ],
        child: const MaterialApp(home: AdminReportsScreen()),
      ),
    );

    // Initial loading state
    expect(find.byType(AmbarketListSkeleton), findsOneWidget);

    // Pump to settle Future
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Tidak ada laporan pada status ini.'), findsOneWidget);
  });

  testWidgets('AdminReportsScreen shows reports list', (
    WidgetTester tester,
  ) async {
    final mockReports = [
      ReportModel(
        id: '1',
        reporterId: 'user1',
        targetType: 'product',
        targetId: 'prod1',
        reason: 'Spam',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminReportsProvider.overrideWith(
            () => MockAdminReportsNotifier(mockReports),
          ),
        ],
        child: const MaterialApp(home: AdminReportsScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Target Laporan: Produk'), findsOneWidget);
    expect(find.text('Alasan: Spam'), findsOneWidget);
  });
}
