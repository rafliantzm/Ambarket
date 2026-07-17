import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';

class OrderModel {
  final String id;
  final String? offerId;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double totalPrice; // legacy

  // New Phase 8D fields
  final String? receiverName;
  final String? receiverPhone;
  final String? shippingAddress;
  final String? shippingMethod;
  final double shippingCost;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? paymentDueAt;
  final DateTime? paidAt;
  final String? invoiceNumber;
  final String? voucherCode;
  final double discountAmount;
  final double serviceFee;
  final double subtotal;

  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReviewed;
  final List<RefundRequestModel> refundRequests;

  final ProductModel? product;
  final ProfileModel? buyer;
  final ProfileModel? seller;
  final OfferModel? offer;

  OrderModel({
    required this.id,
    this.offerId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.totalPrice,

    this.receiverName,
    this.receiverPhone,
    this.shippingAddress,
    this.shippingMethod,
    this.shippingCost = 0,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'unpaid',
    this.paymentDueAt,
    this.paidAt,
    this.invoiceNumber,
    this.voucherCode,
    this.discountAmount = 0,
    this.serviceFee = 0,
    this.subtotal = 0,

    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isReviewed = false,
    this.refundRequests = const [],
    this.product,
    this.buyer,
    this.seller,
    this.offer,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_at']);
    final totalPrice = _doubleValue(json['total_price']);

    return OrderModel(
      id: _stringValue(json['id'], fallback: 'unknown-order'),
      offerId: _nullableString(json['offer_id']),
      productId: _stringValue(json['product_id']),
      buyerId: _stringValue(json['buyer_id']),
      sellerId: _stringValue(json['seller_id']),
      totalPrice: totalPrice,

      receiverName: _nullableString(json['receiver_name']),
      receiverPhone: _nullableString(
        json['receiver_phone'] ?? json['shipping_phone'],
      ),
      shippingAddress: _nullableString(json['shipping_address']),
      shippingMethod: _nullableString(json['shipping_method']),
      shippingCost: _doubleValue(json['shipping_cost']),
      paymentMethod: _stringValue(json['payment_method'], fallback: 'cod'),
      paymentStatus: _stringValue(json['payment_status'], fallback: 'unpaid'),
      paymentDueAt: _parseNullableDate(json['payment_due_at']),
      paidAt: _parseNullableDate(json['paid_at']),
      invoiceNumber: _nullableString(json['invoice_number']),
      voucherCode: _nullableString(json['voucher_code']),
      discountAmount: _doubleValue(json['discount_amount']),
      serviceFee: _doubleValue(json['service_fee']),
      subtotal: _doubleValue(json['subtotal'], fallback: totalPrice),

      status: _stringValue(json['status'], fallback: 'pending_payment'),
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at'], fallback: createdAt),
      isReviewed: _hasReviews(json['reviews']),
      refundRequests: _parseRefundRequests(json['refund_requests']),
      product: _parseProduct(json['product']),
      buyer: _parseProfile(json['buyer']),
      seller: _parseProfile(json['seller']),
      offer: _parseOffer(json['offer']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_price': totalPrice,

      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'shipping_address': shippingAddress,
      'shipping_method': shippingMethod,
      'shipping_cost': shippingCost,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_due_at': paymentDueAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'invoice_number': invoiceNumber,
      'voucher_code': voucherCode,
      'discount_amount': discountAmount,
      'service_fee': serviceFee,
      'subtotal': subtotal,

      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? offerId,
    String? productId,
    String? buyerId,
    String? sellerId,
    double? totalPrice,

    String? receiverName,
    String? receiverPhone,
    String? shippingAddress,
    String? shippingMethod,
    double? shippingCost,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? paymentDueAt,
    DateTime? paidAt,
    String? invoiceNumber,
    String? voucherCode,
    double? discountAmount,
    double? serviceFee,
    double? subtotal,

    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReviewed,
    List<RefundRequestModel>? refundRequests,
    ProductModel? product,
    ProfileModel? buyer,
    ProfileModel? seller,
    OfferModel? offer,
  }) {
    return OrderModel(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      totalPrice: totalPrice ?? this.totalPrice,

      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippingCost: shippingCost ?? this.shippingCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDueAt: paymentDueAt ?? this.paymentDueAt,
      paidAt: paidAt ?? this.paidAt,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      subtotal: subtotal ?? this.subtotal,

      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReviewed: isReviewed ?? this.isReviewed,
      refundRequests: refundRequests ?? this.refundRequests,
      product: product ?? this.product,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      offer: offer ?? this.offer,
    );
  }

  RefundRequestModel? get activeRefundRequest {
    for (final request in refundRequests) {
      if (request.isOpen) {
        return request;
      }
    }
    return null;
  }

  bool get hasActiveRefundRequest => activeRefundRequest != null;

  bool get canBuyerRequestRefund {
    return !hasActiveRefundRequest &&
        (status == 'paid' ||
            status == 'packed' ||
            status == 'shipped' ||
            status == 'delivered');
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

double _doubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

DateTime _parseDate(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ??
        fallback ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

bool _hasReviews(dynamic value) {
  return value is List && value.isNotEmpty;
}

ProductModel? _parseProduct(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  try {
    return ProductModel.fromJson(value);
  } catch (_) {
    return null;
  }
}

ProfileModel? _parseProfile(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  try {
    return ProfileModel.fromJson(value);
  } catch (_) {
    return null;
  }
}

OfferModel? _parseOffer(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  try {
    return OfferModel.fromJson(value);
  } catch (_) {
    return null;
  }
}

List<RefundRequestModel> _parseRefundRequests(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map((row) {
        try {
          return RefundRequestModel.fromJson(row);
        } catch (_) {
          return null;
        }
      })
      .whereType<RefundRequestModel>()
      .toList(growable: false);
}
