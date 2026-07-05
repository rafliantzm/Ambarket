import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';

void main() {
  testWidgets('AdminReportsScreen shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminReportsByStatusProvider.overrideWith((ref, arg) => Future.value([])),
        ],
        child: const MaterialApp(
          home: AdminReportsScreen(),
        ),
      ),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to settle Future
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada laporan.'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(4)); // pending, reviewed, resolved, rejected
  });

  testWidgets('AdminReportsScreen shows reports list', (WidgetTester tester) async {
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
      )
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminReportsByStatusProvider.overrideWith((ref, arg) => Future.value(mockReports)),
        ],
        child: const MaterialApp(
          home: AdminReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Target: product - Spam'), findsOneWidget);
  });
}
