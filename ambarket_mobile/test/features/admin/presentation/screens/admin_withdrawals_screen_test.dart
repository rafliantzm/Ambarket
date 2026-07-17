import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_withdrawals_screen.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_withdrawal_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AdminWithdrawalsScreen renders withdrawal queue', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAdminRepository(
      withdrawals: [_pendingWithdrawal()],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AdminWithdrawalsScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Penarikan Dana'), findsOneWidget);
    expect(find.text('Rp150.000'), findsOneWidget);
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('Test Seller'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  testWidgets('AdminWithdrawalsScreen renders empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(_FakeAdminRepository()),
        ],
        child: const MaterialApp(home: AdminWithdrawalsScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Belum ada pengajuan'), findsOneWidget);
    expect(
      find.text('Pengajuan penarikan dana seller akan muncul di sini.'),
      findsOneWidget,
    );
    expect(find.text('Muat Ulang'), findsOneWidget);
  });

  testWidgets('AdminWithdrawalsScreen approves pending withdrawal', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAdminRepository(
      withdrawals: [_pendingWithdrawal()],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AdminWithdrawalsScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Setujui'));
    await tester.pump(const Duration(seconds: 1));

    expect(repository.updatedStatuses, ['approved_dummy']);
    expect(find.text('Penarikan disetujui.'), findsOneWidget);
  });
}

SellerWithdrawalModel _pendingWithdrawal() {
  final now = DateTime(2026, 7, 11, 15, 30);
  return SellerWithdrawalModel(
    id: 'withdrawal-1',
    sellerId: 'seller-1',
    amount: 150000,
    status: 'pending',
    bankName: 'BCA',
    accountNumber: '1234567890',
    accountHolder: 'Test Seller',
    note: 'Tolong diproses',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({List<SellerWithdrawalModel> withdrawals = const []})
    : _withdrawals = List.of(withdrawals);

  final List<SellerWithdrawalModel> _withdrawals;
  final List<String> updatedStatuses = [];

  @override
  Future<Map<String, dynamic>> fetchAdminDashboardStats() async => {
    'pendingReports': 0,
    'totalUsers': 0,
    'totalProducts': 0,
    'pendingWithdrawals': _withdrawals
        .where((withdrawal) => withdrawal.status == 'pending')
        .length,
  };

  @override
  Future<List<SellerWithdrawalModel>> fetchAllWithdrawalsForAdmin({
    int limit = 20,
    int offset = 0,
  }) async {
    return _withdrawals.skip(offset).take(limit).toList();
  }

  @override
  Future<List<RefundRequestModel>> fetchRefundRequestsForAdmin({
    int limit = 30,
    int offset = 0,
  }) async => [];

  @override
  Future<void> updateWithdrawalStatus(
    String withdrawalId,
    String status,
  ) async {
    updatedStatuses.add(status);
    final index = _withdrawals.indexWhere(
      (withdrawal) => withdrawal.id == withdrawalId,
    );
    if (index == -1) return;
    final previous = _withdrawals[index];
    _withdrawals[index] = SellerWithdrawalModel(
      id: previous.id,
      sellerId: previous.sellerId,
      amount: previous.amount,
      status: status,
      bankName: previous.bankName,
      accountNumber: previous.accountNumber,
      accountHolder: previous.accountHolder,
      note: previous.note,
      createdAt: previous.createdAt,
      updatedAt: DateTime(2026, 7, 11, 16),
    );
  }

  @override
  Future<RefundRequestModel> resolveRefundRequest({
    required String refundId,
    required String decision,
    double approvedAmount = 0,
    String? adminNote,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ReportModel>> fetchAllReports({
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<List<ReportModel>> fetchReportsByStatus(
    String status, {
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<void> updateReportStatus(String reportId, String status) async {}

  @override
  Future<List<ProductModel>> fetchAllProductsForAdmin({
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<List<ProductModel>> fetchProductsByStatusForAdmin(
    String status, {
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<List<ProfileModel>> fetchAllUsersForAdmin({
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<List<ReviewModel>> fetchAllReviewsForAdmin({
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<void> hideProduct(String productId, String note) async {}

  @override
  Future<void> rejectProduct(String productId, String note) async {}

  @override
  Future<void> restoreProduct(String productId) async {}

  @override
  Future<void> suspendUser(String userId, String reason) async {}

  @override
  Future<void> unsuspendUser(String userId) async {}

  @override
  Future<void> hideReview(String reviewId, String note) async {}

  @override
  Future<void> restoreReview(String reviewId) async {}

  @override
  Future<List<AdminAuditLogModel>> fetchAuditLogs({
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<void> createAuditLog(
    String action,
    String targetType,
    String targetId,
    Map<String, dynamic>? metadata,
  ) async {}
}
