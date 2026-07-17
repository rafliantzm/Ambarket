import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/offer_model.dart';
import '../../domain/repositories/offer_repository.dart';
import '../../data/repositories/supabase_offer_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../features/notification/presentation/providers/notification_provider.dart';
import '../../../../features/marketplace/presentation/providers/marketplace_provider.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return SupabaseOfferRepository(ref.watch(supabaseClientProvider));
});

final mySentOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = ref.watch(offerRepositoryProvider);
  return repo.fetchMySentOffers(user.id);
});

final myReceivedOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = ref.watch(offerRepositoryProvider);
  return repo.fetchMyReceivedOffers(user.id);
});

// Filter provider for seller offers
class SellerOfferStatusFilter extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String val) => state = val;
}

final sellerOfferStatusFilterProvider =
    NotifierProvider<SellerOfferStatusFilter, String>(
      () => SellerOfferStatusFilter(),
    );

final filteredReceivedOffersProvider =
    FutureProvider.autoDispose<List<OfferModel>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return [];

      final statusFilter = ref.watch(sellerOfferStatusFilterProvider);

      final repo = ref.watch(offerRepositoryProvider);
      return repo.fetchReceivedOffersFiltered(user.id, status: statusFilter);
    });

final sellerAcceptedOfferOrderIdsProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, offerIdsKey) async {
      if (offerIdsKey.isEmpty) return {};

      final offerIds = offerIdsKey
          .split(',')
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
      if (offerIds.isEmpty) return {};

      final repo = ref.watch(offerRepositoryProvider);
      return repo.findOrderIdsByOfferIds(offerIds);
    });

final validAcceptedOfferProvider = FutureProvider.family
    .autoDispose<OfferModel?, String>((ref, productId) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return null;

      final repo = ref.watch(offerRepositoryProvider);
      return repo.fetchValidAcceptedOffer(productId, user.id);
    });

final createOfferControllerProvider =
    AsyncNotifierProvider<CreateOfferController, void>(() {
      return CreateOfferController();
    });

class CreateOfferController extends AsyncNotifier<void> {
  late final OfferRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(offerRepositoryProvider);
  }

  Future<void> createOffer(CreateOfferInput input) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu.');

      final offer = await _repo.createOffer(user.id, input);

      // Notify seller
      final productState = ref
          .read(productDetailProvider(input.productId))
          .value;
      if (productState != null) {
        ref
            .read(notificationRepositoryProvider)
            .createDummyNotification(
              userId: productState.sellerId,
              type: 'offer_received',
              title: 'Tawaran Baru',
              body:
                  'Anda mendapat tawaran baru untuk produk ${productState.title}',
              relatedType: 'offer',
              relatedId: offer.id,
            );
      }

      ref.invalidate(mySentOffersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final offerActionControllerProvider =
    AsyncNotifierProvider<OfferActionController, void>(() {
      return OfferActionController();
    });

class OfferActionController extends AsyncNotifier<void> {
  late final OfferRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(offerRepositoryProvider);
  }

  Future<void> cancelOffer(String offerId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu.');

      await _repo.cancelOffer(offerId, user.id);
      ref.invalidate(mySentOffersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> acceptOffer(String offerId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu.');

      await _repo.acceptOffer(offerId, user.id);

      // Notify buyer
      final offers = ref.read(myReceivedOffersProvider).value ?? [];
      final offer = offers.where((o) => o.id == offerId).firstOrNull;
      if (offer != null) {
        ref
            .read(notificationRepositoryProvider)
            .createDummyNotification(
              userId: offer.buyerId,
              type: 'offer_accepted',
              title: 'Tawaran Diterima!',
              body:
                  'Tawaran Anda telah diterima oleh penjual. Segera lakukan pembayaran.',
              relatedType: 'offer',
              relatedId: offer.id,
            );
      }

      ref.invalidate(myReceivedOffersProvider);
      ref.invalidate(filteredReceivedOffersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> rejectOffer(String offerId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu.');

      await _repo.rejectOffer(offerId, user.id);

      // Notify buyer
      final offers = ref.read(myReceivedOffersProvider).value ?? [];
      final offer = offers.where((o) => o.id == offerId).firstOrNull;
      if (offer != null) {
        ref
            .read(notificationRepositoryProvider)
            .createDummyNotification(
              userId: offer.buyerId,
              type: 'offer_rejected',
              title: 'Tawaran Ditolak',
              body: 'Maaf, tawaran Anda ditolak oleh penjual.',
              relatedType: 'offer',
              relatedId: offer.id,
            );
      }

      ref.invalidate(myReceivedOffersProvider);
      ref.invalidate(filteredReceivedOffersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
