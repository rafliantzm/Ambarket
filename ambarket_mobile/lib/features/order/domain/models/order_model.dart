import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';

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
    this.product,
    this.buyer,
    this.seller,
    this.offer,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      offerId: json['offer_id'] as String?,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      totalPrice: double.parse(json['total_price'].toString()),
      
      receiverName: json['receiver_name'] as String?,
      receiverPhone: json['receiver_phone'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingMethod: json['shipping_method'] as String?,
      shippingCost: json['shipping_cost'] != null ? double.parse(json['shipping_cost'].toString()) : 0,
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paymentDueAt: json['payment_due_at'] != null ? DateTime.parse(json['payment_due_at'] as String) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      invoiceNumber: json['invoice_number'] as String?,
      voucherCode: json['voucher_code'] as String?,
      discountAmount: json['discount_amount'] != null ? double.parse(json['discount_amount'].toString()) : 0,
      serviceFee: json['service_fee'] != null ? double.parse(json['service_fee'].toString()) : 0,
      subtotal: json['subtotal'] != null ? double.parse(json['subtotal'].toString()) : double.parse(json['total_price'].toString()),

      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isReviewed: json['reviews'] != null && (json['reviews'] as List).isNotEmpty,
      product: json['product'] != null ? ProductModel.fromJson(json['product'] as Map<String, dynamic>) : null,
      buyer: json['buyer'] != null ? ProfileModel.fromJson(json['buyer'] as Map<String, dynamic>) : null,
      seller: json['seller'] != null ? ProfileModel.fromJson(json['seller'] as Map<String, dynamic>) : null,
      offer: json['offer'] != null ? OfferModel.fromJson(json['offer'] as Map<String, dynamic>) : null,
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
      product: product ?? this.product,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      offer: offer ?? this.offer,
    );
  }
}
