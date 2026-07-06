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
  final String code;
  final String title;
  final String description;
  final double discountPercent; // e.g. 10 for 10%
  final double maxDiscount;
  final double flatDiscount; // if not percent
  final String type; // 'percent' or 'flat_shipping'

  VoucherModel({
    required this.code,
    required this.title,
    required this.description,
    this.discountPercent = 0,
    this.maxDiscount = 0,
    this.flatDiscount = 0,
    required this.type,
  });
}
