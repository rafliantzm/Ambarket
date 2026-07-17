import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/wallet/presentation/screens/seller_wallet_screen.dart';
import 'package:ambarket_mobile/features/wallet/presentation/providers/seller_wallet_provider.dart';
import 'package:ambarket_mobile/features/wallet/presentation/widgets/dummy_withdrawal_dialog.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/dummy_withdrawal_input.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_wallet_summary.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_withdrawal_model.dart';
import 'package:ambarket_mobile/features/wallet/domain/repositories/seller_wallet_repository.dart';
import 'package:ambarket_mobile/core/widgets/app_empty_state.dart';
import 'package:ambarket_mobile/core/widgets/app_button.dart';
import 'package:ambarket_mobile/features/notification/domain/models/notification_model.dart';
import 'package:ambarket_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:ambarket_mobile/features/notification/presentation/providers/notification_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';

void main() {
  final mockUser = User(
    id: 'user1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

  final mockSummary = SellerWalletSummary(
    availableBalance: 500000,
    pendingBalance: 150000,
    totalEarning: 1500000,
    completedOrderRevenue: 1500000,
    withdrawalCount: 2,
    pendingWithdrawalCount: 1,
  );

  final mockWithdrawals = [
    SellerWithdrawalModel(
      id: 'w1',
      sellerId: 'user1',
      amount: 1000000,
      status: 'approved_dummy',
      bankName: 'BCA',
      accountNumber: '1234567890',
      accountHolder: 'Test Seller',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SellerWithdrawalModel(
      id: 'w2',
      sellerId: 'user1',
      amount: 150000,
      status: 'pending',
      bankName: 'BCA',
      accountNumber: '1234567890',
      accountHolder: 'Test Seller',
      note: 'Butuh cepat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  group('SellerWalletScreen Tests', () {
    testWidgets('renders summary and withdrawals', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            sellerWalletSummaryProvider.overrideWith((ref) => mockSummary),
            sellerWithdrawalsProvider.overrideWith((ref) => mockWithdrawals),
          ],
          child: const MaterialApp(home: SellerWalletScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Header and description
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Wallet Seller'), findsOneWidget);
      expect(
        find.text('Pantau saldo seller dan riwayat penarikan dana.'),
        findsOneWidget,
      );

      // Summary
      expect(find.text('Saldo Tersedia'), findsOneWidget);
      expect(find.text('Rp500.000'), findsOneWidget);
      expect(find.text('Pending Settlement'), findsOneWidget);
      expect(
        find.text('Rp150.000'),
        findsWidgets,
      ); // Summary pending and withdrawal list
      expect(find.text('Total Pendapatan'), findsOneWidget);
      expect(find.text('Rp1.500.000'), findsOneWidget);
      expect(find.text('Penarikan Pending'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Withdrawals
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Riwayat Penarikan'), findsOneWidget);
      expect(find.text('Rp1.000.000'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Catatan: Butuh cepat'), findsOneWidget);
    });

    testWidgets('renders empty state for withdrawals', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            sellerWalletSummaryProvider.overrideWith((ref) => mockSummary),
            sellerWithdrawalsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: SellerWalletScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum ada riwayat penarikan'), findsOneWidget);
    });

    testWidgets('Ajukan Penarikan Dummy button disabled if balance is zero', (
      WidgetTester tester,
    ) async {
      final zeroSummary = SellerWalletSummary(
        availableBalance: 0,
        pendingBalance: 0,
        totalEarning: 0,
        completedOrderRevenue: 0,
        withdrawalCount: 0,
        pendingWithdrawalCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            sellerWalletSummaryProvider.overrideWith((ref) => zeroSummary),
            sellerWithdrawalsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: SellerWalletScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull); // Disabled
    });

    testWidgets('Opens dialog and validates form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            sellerWalletSummaryProvider.overrideWith((ref) => mockSummary),
            sellerWithdrawalsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: SellerWalletScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Tap button
      await tester.tap(find.text('Ajukan Penarikan Dummy'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Penarikan Dummy (Simulasi)'), findsOneWidget);
      expect(find.text('Saldo Tersedia: Rp500000'), findsOneWidget);

      // Try submit empty
      await tester.tap(find.text('Ajukan'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Wajib diisi'), findsWidgets);

      // Try amount too big
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '1000000',
      ); // Nominal
      await tester.tap(find.text('Ajukan'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Melebihi saldo'), findsOneWidget);

      // Valid form
      await tester.enterText(find.byType(TextFormField).at(0), '50000');
      await tester.enterText(find.byType(TextFormField).at(1), 'BCA'); // Bank
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '1234567890',
      ); // No rek
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Test User',
      ); // Name

      await tester.tap(find.text('Ajukan'));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
      'withdrawal submit syncs wallet and shows success only on save',
      (WidgetTester tester) async {
        final repository = _FakeSellerWalletRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => mockUser),
              sellerWalletRepositoryProvider.overrideWithValue(repository),
              notificationRepositoryProvider.overrideWithValue(
                _FakeNotificationRepository(),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: DummyWithdrawalDialog(availableBalance: 500000),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField).at(0), '50000');
        await tester.enterText(find.byType(TextFormField).at(1), 'BCA');
        await tester.enterText(find.byType(TextFormField).at(2), '1234567890');
        await tester.enterText(find.byType(TextFormField).at(3), 'Test User');
        await tester.tap(find.text('Ajukan'));
        await tester.pump(const Duration(seconds: 1));

        expect(repository.ensureWalletCalls, 1);
        expect(repository.syncWalletCalls, 1);
        expect(repository.requestedAmounts, [50000]);
        expect(
          find.text('Pengajuan penarikan dummy berhasil dibuat.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('withdrawal submit keeps dialog open when save fails', (
      WidgetTester tester,
    ) async {
      final repository = _FakeSellerWalletRepository(shouldFailRequest: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            sellerWalletRepositoryProvider.overrideWithValue(repository),
            notificationRepositoryProvider.overrideWithValue(
              _FakeNotificationRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DummyWithdrawalDialog(availableBalance: 500000),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '50000');
      await tester.enterText(find.byType(TextFormField).at(1), 'BCA');
      await tester.enterText(find.byType(TextFormField).at(2), '1234567890');
      await tester.enterText(find.byType(TextFormField).at(3), 'Test User');
      await tester.tap(find.text('Ajukan'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Penarikan Dummy (Simulasi)'), findsOneWidget);
      expect(find.textContaining('Database gagal menyimpan'), findsOneWidget);
      expect(
        find.text('Pengajuan penarikan dummy berhasil dibuat.'),
        findsNothing,
      );
    });
  });
}

class _FakeSellerWalletRepository implements SellerWalletRepository {
  _FakeSellerWalletRepository({this.shouldFailRequest = false});

  final bool shouldFailRequest;
  int ensureWalletCalls = 0;
  int syncWalletCalls = 0;
  final List<double> requestedAmounts = [];

  @override
  Future<void> calculateSellerEarningsFromCompletedOrders(
    String sellerId,
  ) async {
    syncWalletCalls++;
  }

  @override
  Future<void> ensureSellerWalletExists(String sellerId) async {
    ensureWalletCalls++;
  }

  @override
  Future<SellerWalletSummary> fetchSellerWalletSummary(String sellerId) async =>
      SellerWalletSummary.empty();

  @override
  Future<List<SellerWithdrawalModel>> fetchSellerWithdrawals(
    String sellerId,
  ) async => [];

  @override
  Future<SellerWithdrawalModel> requestDummyWithdrawal(
    String sellerId,
    DummyWithdrawalInput input,
  ) async {
    if (shouldFailRequest) {
      throw Exception('Database gagal menyimpan pengajuan.');
    }
    requestedAmounts.add(input.amount);
    final now = DateTime(2026, 7, 11, 23);
    return SellerWithdrawalModel(
      id: 'withdrawal-1',
      sellerId: sellerId,
      amount: input.amount,
      status: 'pending',
      bankName: input.bankName,
      accountNumber: input.accountNumber,
      accountHolder: input.accountHolder,
      note: input.note,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<void> createDummyNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedType,
    String? relatedId,
  }) async {}

  @override
  Future<List<NotificationModel>> fetchNotifications() async => [];

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}
}
