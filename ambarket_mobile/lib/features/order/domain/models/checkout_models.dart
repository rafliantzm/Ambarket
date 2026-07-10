class CheckoutInput {
  final String productId;
  final String? cartItemId;
  final String? offerId;
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final String shippingMethod;
  final double shippingCost;
  final String paymentMethod;
  final String? voucherCode;
  final double discountAmount;
  final double serviceFee;
  final double subtotal;
  final double totalAmount;

  CheckoutInput({
    required this.productId,
    this.cartItemId,
    this.offerId,
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    required this.shippingMethod,
    required this.shippingCost,
    required this.paymentMethod,
    this.voucherCode,
    this.discountAmount = 0,
    this.serviceFee = 0,
    required this.subtotal,
    required this.totalAmount,
  });
}

class ShippingMethodModel {
  final String id;
  final String name;
  final String description;
  final double cost;

  ShippingMethodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
  });
}

class PaymentMethodModel {
  final String id;
  final String name;
  final String description;
  final String type; // e.g. cod, virtual_account, qris, e_wallet

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
  });
}

class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final double discountPercent; // e.g. 10 for 10%
  final double maxDiscount;
  final double flatDiscount; // if not percent
  final double minPurchase;
  final String type; // 'percent' or 'flat_shipping' or 'flat'
  final bool isClaimed;
  final bool isActive;
  final DateTime? expiresAt;
  VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.discountPercent = 0,
    this.maxDiscount = 0,
    this.flatDiscount = 0,
    this.minPurchase = 0,
    required this.type,
    this.isClaimed = false,
    this.isActive = true,
    this.expiresAt,
  });

  factory VoucherModel.fromJson(
    Map<String, dynamic> json, {
    bool isClaimed = false,
  }) {
    final type = json['type'] as String;
    final discountValue = (json['discount_value'] as num).toDouble();
    return VoucherModel(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      type: type,
      discountPercent: type == 'percent' ? discountValue : 0,
      flatDiscount: type != 'percent' ? discountValue : 0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble() ?? 0,
      minPurchase: (json['min_purchase'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isClaimed: isClaimed,
    );
  }

  VoucherModel copyWith({
    bool? isClaimed,
    bool? isActive,
    DateTime? expiresAt,
  }) {
    return VoucherModel(
      id: id,
      code: code,
      title: title,
      description: description,
      discountPercent: discountPercent,
      maxDiscount: maxDiscount,
      flatDiscount: flatDiscount,
      minPurchase: minPurchase,
      type: type,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}
