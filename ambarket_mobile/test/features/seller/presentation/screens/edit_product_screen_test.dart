import 'dart:typed_data';

import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/category_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/seller/domain/models/create_product_input.dart';
import 'package:ambarket_mobile/features/seller/domain/models/seller_dashboard_stats.dart';
import 'package:ambarket_mobile/features/seller/domain/models/seller_product_stats.dart';
import 'package:ambarket_mobile/features/seller/domain/repositories/seller_repository.dart';
import 'package:ambarket_mobile/features/seller/presentation/providers/seller_provider.dart';
import 'package:ambarket_mobile/features/seller/presentation/screens/edit_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  testWidgets(
    'EditProductScreen submits existing category without reselecting',
    (tester) async {
      final product = ProductModel(
        id: 'prod-1',
        sellerId: 'seller-1',
        categoryId: 'cat-1',
        title: 'Tas Selempang',
        description: 'Masih bagus',
        price: 15000,
        condition: 'good',
        location: 'Semarang',
        isNegotiable: true,
        status: 'active',
        createdAt: DateTime(2026, 7, 12),
      );
      final repository = _FakeSellerRepository(product);
      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/edit',
            builder: (context, state) =>
                const EditProductScreen(productId: 'prod-1'),
          ),
          GoRoute(
            path: '/seller',
            builder: (context, state) => const Scaffold(body: Text('Seller')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              supabase.User(
                id: 'seller-1',
                appMetadata: const {},
                userMetadata: const {},
                aud: 'authenticated',
                createdAt: DateTime(2026, 7, 12).toIso8601String(),
              ),
            ),
            currentProfileProvider.overrideWith(
              (ref) => ProfileModel(
                id: 'seller-1',
                name: 'Seller',
                role: 'seller',
                createdAt: DateTime(2026, 7, 12),
              ),
            ),
            sellerRepositoryProvider.overrideWithValue(repository),
            categoriesProvider.overrideWith(
              (ref) async => [
                CategoryModel(
                  id: 'cat-1',
                  name: 'Tas',
                  createdAt: DateTime(2026, 7, 12),
                ),
              ],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(repository.updatedInput, isNotNull);
      expect(repository.updatedInput!.categoryId, 'cat-1');
      expect(repository.updatedInput!.title, 'Tas Selempang');
    },
  );
}

class _FakeSellerRepository implements SellerRepository {
  _FakeSellerRepository(this.product);

  final ProductModel product;
  UpdateProductInput? updatedInput;

  @override
  Future<List<ProductModel>> fetchMyProducts(
    String sellerId, {
    int offset = 0,
    int limit = 20,
  }) async => [product];

  @override
  Future<List<ProductModel>> fetchSellerProductsFiltered(
    String sellerId, {
    String status = 'all',
    String searchQuery = '',
    int limit = 20,
    int offset = 0,
  }) async => [product];

  @override
  Future<ProductModel> fetchMyProductDetail(
    String productId,
    String sellerId,
  ) async => product;

  @override
  Future<ProductModel> createProduct(
    String sellerId,
    CreateProductInput input,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProduct(
    String productId,
    String sellerId,
    UpdateProductInput input,
  ) async {
    updatedInput = input;
  }

  @override
  Future<void> updateProductStatus(
    String productId,
    String sellerId,
    String status,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> archiveProduct(String productId, String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> reactivateArchivedProduct(String productId, String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProductImage(String imageId, String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadProductImage(
    String productId,
    String sellerId,
    Uint8List imageBytes,
    bool isPrimary,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SellerProductStats> fetchSellerProductStats(String sellerId) async =>
      SellerProductStats.empty();

  @override
  Future<SellerDashboardStats> fetchSellerDashboardStats(String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<List<OrderModel>> fetchRecentSellerOrders(
    String sellerId, {
    int limit = 5,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<OfferModel>> fetchRecentSellerOffers(
    String sellerId, {
    int limit = 5,
  }) {
    throw UnimplementedError();
  }
}
