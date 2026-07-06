import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/offer_model.dart';
import '../../domain/repositories/offer_repository.dart';
import '../../data/repositories/supabase_offer_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return SupabaseOfferRepository(ref.watch(supabaseClientProvider));
});

final mySentOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final repo = ref.watch(offerRepositoryProvider);
  return repo.fetchMySentOffers(user.id);
});

final myReceivedOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((ref) async {
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
final sellerOfferStatusFilterProvider = NotifierProvider<SellerOfferStatusFilter, String>(() => SellerOfferStatusFilter());

final filteredReceivedOffersProvider = FutureProvider.autoDispose<List<OfferModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final statusFilter = ref.watch(sellerOfferStatusFilterProvider);
  
  final repo = ref.watch(offerRepositoryProvider);
  return repo.fetchReceivedOffersFiltered(user.id, status: statusFilter);
});

final createOfferControllerProvider = AsyncNotifierProvider<CreateOfferController, void>(() {
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

      await _repo.createOffer(user.id, input);
      ref.invalidate(mySentOffersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final offerActionControllerProvider = AsyncNotifierProvider<OfferActionController, void>(() {
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
      ref.invalidate(myReceivedOffersProvider);
      ref.invalidate(filteredReceivedOffersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
