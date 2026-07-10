import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:ambarket_mobile/features/seller/presentation/providers/seller_provider.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/seller/domain/models/seller_dashboard_stats.dart';
import 'package:ambarket_mobile/features/wallet/presentation/providers/seller_wallet_provider.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_wallet_summary.dart';

class MockMyProductsNotifier extends MyProductsNotifier {
  final List<ProductModel> _products;
  MockMyProductsNotifier(this._products);

  @override
  FutureOr<PaginatedSellerProductsState> build() {
    return PaginatedSellerProductsState(products: _products, hasMore: false);
  }
}

void main() {
  final mockUser = ProfileModel(
    id: 'user1',

    name: 'Test Seller',
    username: 'testseller',
    role: 'seller',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockStats = SellerDashboardStats(
    activeProductsCount: 10,
    pendingOrdersCount: 2,
    totalRevenueDummy: 1500000,
    averageRating: 4.8,
  );

  final mockWalletSummary = SellerWalletSummary(
    availableBalance: 1200000,
    pendingBalance: 300000,
    totalEarning: 1500000,
    completedOrderRevenue: 1500000,
    withdrawalCount: 1,
    pendingWithdrawalCount: 0,
  );

  group('SellerDashboardScreen Tests', () {
    testWidgets('renders header, stats, and quick actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => mockUser),
            sellerDashboardStatsProvider.overrideWith((ref) => mockStats),
            sellerRecentOrdersProvider.overrideWith((ref) => []),
            sellerRecentOffersProvider.overrideWith((ref) => []),
            myProductsProvider.overrideWith(() => MockMyProductsNotifier([])),
            sellerWalletSummaryProvider.overrideWith(
              (ref) => mockWalletSummary,
            ),
          ],
          child: const MaterialApp(home: SellerDashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Header
      expect(find.text('Test Seller'), findsOneWidget);
      expect(find.text('@testseller'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);

      // Quick Actions
      expect(find.text('Aksi Cepat'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(
        find.text('Tambah Produk'),
        findsWidgets,
      ); // Header button + quick action
      expect(find.text('Pesanan'), findsOneWidget);

      // Stats Grid
      expect(find.text('Ringkasan Performa'), findsOneWidget);
      expect(find.text('Produk Aktif'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Pesanan Baru'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Rp1.500.000'), findsWidgets); // Pendapatan
      expect(find.text('Rp1.200.000'), findsOneWidget); // Saldo Dummy
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('renders recent orders and offers empty states', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => mockUser),
            sellerDashboardStatsProvider.overrideWith((ref) => mockStats),
            sellerRecentOrdersProvider.overrideWith((ref) => []),
            sellerRecentOffersProvider.overrideWith((ref) => []),
            myProductsProvider.overrideWith(() => MockMyProductsNotifier([])),
            sellerWalletSummaryProvider.overrideWith(
              (ref) => mockWalletSummary,
            ),
          ],
          child: const MaterialApp(home: SellerDashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Ensure lists are empty but headers are there
      expect(find.text('Pesanan Terbaru'), findsOneWidget);
      expect(find.text('Belum Ada Pesanan'), findsOneWidget);

      expect(find.text('Tawaran Pending'), findsOneWidget);
      expect(find.text('Tidak Ada Tawaran Pending'), findsOneWidget);
    });

    testWidgets('renders product performance empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => mockUser),
            sellerDashboardStatsProvider.overrideWith((ref) => mockStats),
            sellerRecentOrdersProvider.overrideWith((ref) => []),
            sellerRecentOffersProvider.overrideWith((ref) => []),
            myProductsProvider.overrideWith(() => MockMyProductsNotifier([])),
            sellerWalletSummaryProvider.overrideWith(
              (ref) => mockWalletSummary,
            ),
          ],
          child: const MaterialApp(home: SellerDashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Performa Produk'), findsOneWidget);
      expect(find.text('Belum Ada Produk'), findsOneWidget);
    });
  });
}
