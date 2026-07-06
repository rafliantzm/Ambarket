import '../models/offer_model.dart';
import '../../../../features/order/domain/models/order_model.dart';

abstract class OfferRepository {
  Future<OfferModel> createOffer(String buyerId, CreateOfferInput input);
  Future<List<OfferModel>> fetchMySentOffers(String buyerId);
  Future<List<OfferModel>> fetchMyReceivedOffers(String sellerId);
  Future<List<OfferModel>> fetchReceivedOffersFiltered(String sellerId, {String? status});
  Future<List<OfferModel>> fetchOffersForProduct(String productId);
  Future<OrderModel?> findOrderByOfferId(String offerId);
  Future<void> cancelOffer(String offerId, String buyerId);
  Future<void> acceptOffer(String offerId, String sellerId);
  Future<void> rejectOffer(String offerId, String sellerId);
}
